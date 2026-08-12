<?php

declare(strict_types=1);

function admin_actor_id(array $adminContext): int
{
    return (int) $adminContext['user']['id'];
}

function admin_query_text(string $name, int $maxLength = 160): ?string
{
    if (!isset($_GET[$name]) || trim((string) $_GET[$name]) === '') {
        return null;
    }
    $value = trim((string) $_GET[$name]);
    $length = function_exists('mb_strlen') ? mb_strlen($value) : strlen($value);
    if ($length > $maxLength) {
        validation_error(array($name => array(sprintf('Must not exceed %d characters.', $maxLength))));
    }
    return $value;
}

function admin_query_bool(string $name): ?bool
{
    if (!isset($_GET[$name]) || $_GET[$name] === '') {
        return null;
    }
    $value = filter_var($_GET[$name], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    if ($value === null) {
        validation_error(array($name => array('Must be a boolean.')));
    }
    return $value;
}

function admin_list_meta(int $total, array $page): array
{
    return array(
        'count' => min($page['limit'], max(0, $total - $page['offset'])),
        'total' => $total,
        'limit' => $page['limit'],
        'offset' => $page['offset'],
    );
}

function admin_total(string $fromAndWhere, array $params): int
{
    $statement = db()->prepare('SELECT COUNT(*) ' . $fromAndWhere);
    $statement->execute($params);
    return (int) $statement->fetchColumn();
}

function admin_store_resource(array $row): array
{
    $resource = store_resource($row);
    $resource['created_at'] = isset($row['created_at']) ? $row['created_at'] : null;
    $resource['updated_at'] = isset($row['updated_at']) ? $row['updated_at'] : null;
    return $resource;
}

function admin_fetch_store(PDO $pdo, int $id, bool $lock = false): array
{
    $statement = $pdo->prepare('SELECT * FROM stores WHERE id = ?' . ($lock ? ' FOR UPDATE' : ''));
    $statement->execute(array($id));
    $store = $statement->fetch();
    if (!$store) {
        throw new ApiException(404, 'NOT_FOUND', 'Store not found.');
    }
    return $store;
}

function admin_fetch_store_with_catalog(PDO $pdo, int $id): array
{
    $statement = $pdo->prepare(
        'SELECT s.*, COALESCE(catalog.product_count, 0) AS product_count, '
        . "COALESCE(catalog.catalog_categories, '') AS catalog_categories, "
        . 'COALESCE(catalog.max_saving, 0) AS max_saving, '
        . 'COALESCE(catalog.max_discount_percent, 0) AS max_discount_percent FROM stores s'
        . store_catalog_summary_sql('s') . ' WHERE s.id = ? LIMIT 1'
    );
    $statement->execute(array($id));
    $store = $statement->fetch();
    if (!$store) {
        throw new ApiException(404, 'NOT_FOUND', 'Store not found.');
    }
    return $store;
}

function admin_normalize_store_time(string $value, string $field): string
{
    if (!preg_match('/^(?:[01][0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?$/', $value)) {
        validation_error(array($field => array('Use 24-hour HH:MM format.')));
    }
    return strlen($value) === 5 ? $value . ':00' : $value;
}

function admin_media_value(array $body, string $field, string $default): string
{
    $value = (string) optional_string($body, $field, 1000, $default);
    if ($value === '') {
        return $value;
    }
    if (preg_match('/[\\\\\x00-\x1F\x7F]/', $value)) {
        validation_error(array($field => array('Control characters and backslashes are not allowed.')));
    }
    if ($value[0] === '/') {
        if (isset($value[1]) && $value[1] === '/') {
            validation_error(array($field => array('Protocol-relative URLs are not allowed.')));
        }
        return $value;
    }
    $url = filter_var($value, FILTER_VALIDATE_URL);
    $scheme = $url === false ? '' : strtolower((string) parse_url($value, PHP_URL_SCHEME));
    $allowed = $scheme === 'https' || ($scheme === 'http' && app_config()['app_env'] === 'local');
    if (!$allowed) {
        validation_error(array($field => array('Use an HTTPS URL or an absolute application path.')));
    }
    return $value;
}

function admin_validated_store(array $body, ?array $existing = null): array
{
    reject_unknown_fields($body, array(
        'code', 'name', 'owner_name', 'phone', 'address', 'landmark', 'pincode', 'is_open',
        'logo', 'banner', 'description', 'opening_time', 'closing_time', 'delivery_available',
        'delivery_radius_km', 'min_order', 'free_delivery_above', 'delivery_charge',
        'expected_delivery_time', 'scheduled_delivery_enabled', 'cod_enabled', 'upi_enabled',
        'pay_at_shop_enabled', 'online_udhaar_enabled', 'allow_nearby_discovery'
    ));
    if ($existing !== null && $body === array()) {
        validation_error(array('_schema' => array('At least one store field is required.')));
    }
    $creating = $existing === null;
    $data = $creating ? array(
        'landmark' => '',
        'is_open' => true,
        'logo' => '',
        'banner' => '',
        'description' => '',
        'opening_time' => '08:00:00',
        'closing_time' => '22:00:00',
        'delivery_available' => true,
        'delivery_radius_km' => 5.0,
        'min_order' => 100.0,
        'free_delivery_above' => 500.0,
        'delivery_charge' => 30.0,
        'expected_delivery_time' => '30-45 minutes',
        'scheduled_delivery_enabled' => true,
        'cod_enabled' => true,
        'upi_enabled' => true,
        'pay_at_shop_enabled' => true,
        'online_udhaar_enabled' => false,
        'allow_nearby_discovery' => true,
    ) : $existing;

    foreach (array('code' => 32, 'name' => 160, 'owner_name' => 160, 'address' => 500) as $field => $max) {
        if ($creating || array_key_exists($field, $body)) {
            $data[$field] = required_string($body, $field, $max);
        }
    }
    $data['code'] = strtoupper((string) $data['code']);
    if (!preg_match('/^[A-Z0-9_-]{3,32}$/', $data['code'])) {
        validation_error(array('code' => array('Use 3-32 letters, digits, underscores, or hyphens.')));
    }
    if ($creating || array_key_exists('phone', $body)) {
        $data['phone'] = validate_mobile(required_string($body, 'phone', 30), 'phone');
    }
    if ($creating || array_key_exists('pincode', $body)) {
        $data['pincode'] = validate_pincode(required_string($body, 'pincode', 6, 6));
    }
    foreach (array('landmark' => 255, 'description' => 1000, 'expected_delivery_time' => 80) as $field => $max) {
        if ($creating || array_key_exists($field, $body)) {
            $data[$field] = (string) optional_string($body, $field, $max, (string) $data[$field]);
        }
    }
    if (array_key_exists('logo', $body) || $creating) {
        $data['logo'] = admin_media_value($body, 'logo', (string) $data['logo']);
    }
    if (array_key_exists('banner', $body) || $creating) {
        $data['banner'] = admin_media_value($body, 'banner', (string) $data['banner']);
    }
    foreach (array('opening_time', 'closing_time') as $field) {
        if (array_key_exists($field, $body)) {
            $data[$field] = admin_normalize_store_time(required_string($body, $field, 8, 5), $field);
        }
    }
    foreach (array(
        'is_open', 'delivery_available', 'scheduled_delivery_enabled', 'cod_enabled', 'upi_enabled',
        'pay_at_shop_enabled', 'online_udhaar_enabled', 'allow_nearby_discovery'
    ) as $field) {
        $data[$field] = optional_bool($body, $field, (bool) $data[$field]);
    }
    foreach (array(
        'delivery_radius_km' => 0.0,
        'min_order' => 0.0,
        'free_delivery_above' => 0.0,
        'delivery_charge' => 0.0,
    ) as $field => $min) {
        if (array_key_exists($field, $body)) {
            $data[$field] = required_money($body, $field, $min, 10000000.0);
        } else {
            $data[$field] = (float) $data[$field];
        }
    }
    return $data;
}

function api_admin_overview(array $adminContext): void
{
    $pdo = db();
    $stores = $pdo->query(
        'SELECT COUNT(*) AS total, COALESCE(SUM(is_open = 1), 0) AS open_count, '
        . 'COALESCE(SUM(delivery_available = 1), 0) AS delivery_count FROM stores'
    )->fetch();
    $products = $pdo->query(
        'SELECT COUNT(*) AS total, COALESCE(SUM(available_for_online = 1 AND is_hidden = 0), 0) AS online_count, '
        . 'COALESCE(SUM(stock = 0), 0) AS out_of_stock FROM products'
    )->fetch();
    $people = $pdo->query(
        'SELECT (SELECT COUNT(*) FROM customers) AS customers, '
        . '(SELECT COUNT(*) FROM delivery_staff) AS riders, '
        . '(SELECT COUNT(*) FROM delivery_staff WHERE is_active = 1) AS active_riders'
    )->fetch();
    $orders = $pdo->query(
        "SELECT COUNT(*) AS total, COALESCE(SUM(DATE(created_at) = CURRENT_DATE()), 0) AS today, "
        . "COALESCE(SUM(status = 'NEW'), 0) AS new_orders, COALESCE(SUM(status = 'DELIVERED'), 0) AS delivered, "
        . "COALESCE(SUM(status = 'CANCELLED'), 0) AS cancelled FROM orders"
    )->fetch();
    $finance = $pdo->query(
        'SELECT (SELECT COALESCE(SUM(amount), 0) FROM sales_records WHERE sale_date = CURRENT_DATE()) AS sales_today, '
        . '(SELECT COALESCE(SUM(amount), 0) FROM sales_records WHERE sale_date BETWEEN DATE_FORMAT(CURRENT_DATE(), \'%Y-%m-01\') AND CURRENT_DATE()) AS sales_month, '
        . '(SELECT COALESCE(SUM(udhaar_balance), 0) FROM customers) AS outstanding_udhaar, '
        . '(SELECT COALESCE(SUM(cash_collected_today), 0) FROM delivery_staff) AS rider_cod_recorded'
    )->fetch();

    respond_data(array(
        'generated_at' => date(DATE_ATOM),
        'stores' => array(
            'total' => (int) $stores['total'],
            'open' => (int) $stores['open_count'],
            'delivery_enabled' => (int) $stores['delivery_count'],
        ),
        'products' => array(
            'total' => (int) $products['total'],
            'online' => (int) $products['online_count'],
            'out_of_stock' => (int) $products['out_of_stock'],
        ),
        'people' => array(
            'customers' => (int) $people['customers'],
            'riders' => (int) $people['riders'],
            'active_riders' => (int) $people['active_riders'],
        ),
        'orders' => array(
            'total' => (int) $orders['total'],
            'today' => (int) $orders['today'],
            'new' => (int) $orders['new_orders'],
            'delivered' => (int) $orders['delivered'],
            'cancelled' => (int) $orders['cancelled'],
        ),
        'finance' => array(
            'sales_today' => (float) $finance['sales_today'],
            'sales_month' => (float) $finance['sales_month'],
            'outstanding_udhaar' => (float) $finance['outstanding_udhaar'],
            'rider_cod_recorded' => (float) $finance['rider_cod_recorded'],
        ),
    ));
}

function api_admin_list_stores(array $adminContext): void
{
    $page = pagination();
    $where = array();
    $params = array();
    $query = admin_query_text('q');
    if ($query !== null) {
        $where[] = '(s.name LIKE ? OR s.code LIKE ? OR s.owner_name LIKE ? OR s.phone LIKE ?)';
        $like = '%' . $query . '%';
        array_push($params, $like, $like, $like, $like);
    }
    $open = admin_query_bool('is_open');
    if ($open !== null) {
        $where[] = 's.is_open = ?';
        $params[] = $open ? 1 : 0;
    }
    $from = 'FROM stores s';
    $whereSql = $where === array() ? '' : ' WHERE ' . implode(' AND ', $where);
    $total = admin_total($from . $whereSql, $params);
    $sql = 'SELECT s.*, COALESCE(catalog.product_count, 0) AS product_count, '
        . "COALESCE(catalog.catalog_categories, '') AS catalog_categories, "
        . 'COALESCE(catalog.max_saving, 0) AS max_saving, '
        . 'COALESCE(catalog.max_discount_percent, 0) AS max_discount_percent '
        . $from . store_catalog_summary_sql('s') . $whereSql
        . ' ORDER BY s.created_at DESC, s.id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset'];
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $data = array_map('admin_store_resource', $statement->fetchAll());
    respond_data($data, 200, admin_list_meta($total, $page));
}

function api_admin_create_store(array $adminContext): void
{
    $data = admin_validated_store(json_body());
    try {
        $store = in_transaction(function (PDO $pdo) use ($adminContext, $data): array {
            $statement = $pdo->prepare(
                'INSERT INTO stores (code, name, owner_name, phone, address, landmark, pincode, is_open, logo, banner, description, '
                . 'opening_time, closing_time, delivery_available, delivery_radius_km, min_order, free_delivery_above, delivery_charge, '
                . 'expected_delivery_time, scheduled_delivery_enabled, cod_enabled, upi_enabled, pay_at_shop_enabled, '
                . 'online_udhaar_enabled, allow_nearby_discovery) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $statement->execute(array(
                $data['code'], $data['name'], $data['owner_name'], $data['phone'], $data['address'], $data['landmark'], $data['pincode'],
                $data['is_open'] ? 1 : 0, $data['logo'], $data['banner'], $data['description'], $data['opening_time'], $data['closing_time'],
                $data['delivery_available'] ? 1 : 0, $data['delivery_radius_km'], $data['min_order'], $data['free_delivery_above'],
                $data['delivery_charge'], $data['expected_delivery_time'], $data['scheduled_delivery_enabled'] ? 1 : 0,
                $data['cod_enabled'] ? 1 : 0, $data['upi_enabled'] ? 1 : 0, $data['pay_at_shop_enabled'] ? 1 : 0,
                $data['online_udhaar_enabled'] ? 1 : 0, $data['allow_nearby_discovery'] ? 1 : 0,
            ));
            $id = (int) $pdo->lastInsertId();
            $created = admin_fetch_store_with_catalog($pdo, $id);
            admin_audit($pdo, admin_actor_id($adminContext), 'store.create', 'store', (string) $id, $id, null, admin_store_resource($created));
            return $created;
        });
    } catch (PDOException $exception) {
        if (db_unique_violation($exception)) {
            throw new ApiException(409, 'CONFLICT', 'A store with this code already exists.');
        }
        throw $exception;
    }
    respond_data(admin_store_resource($store), 201);
}

function api_admin_update_store(array $adminContext, int $id): void
{
    $body = json_body();
    try {
        $store = in_transaction(function (PDO $pdo) use ($adminContext, $id, $body): array {
            $existing = admin_fetch_store($pdo, $id, true);
            $data = admin_validated_store($body, $existing);
            $statement = $pdo->prepare(
                'UPDATE stores SET code=?, name=?, owner_name=?, phone=?, address=?, landmark=?, pincode=?, is_open=?, logo=?, banner=?, '
                . 'description=?, opening_time=?, closing_time=?, delivery_available=?, delivery_radius_km=?, min_order=?, '
                . 'free_delivery_above=?, delivery_charge=?, expected_delivery_time=?, scheduled_delivery_enabled=?, cod_enabled=?, '
                . 'upi_enabled=?, pay_at_shop_enabled=?, online_udhaar_enabled=?, allow_nearby_discovery=? WHERE id=?'
            );
            $statement->execute(array(
                $data['code'], $data['name'], $data['owner_name'], $data['phone'], $data['address'], $data['landmark'], $data['pincode'],
                $data['is_open'] ? 1 : 0, $data['logo'], $data['banner'], $data['description'], $data['opening_time'], $data['closing_time'],
                $data['delivery_available'] ? 1 : 0, $data['delivery_radius_km'], $data['min_order'], $data['free_delivery_above'],
                $data['delivery_charge'], $data['expected_delivery_time'], $data['scheduled_delivery_enabled'] ? 1 : 0,
                $data['cod_enabled'] ? 1 : 0, $data['upi_enabled'] ? 1 : 0, $data['pay_at_shop_enabled'] ? 1 : 0,
                $data['online_udhaar_enabled'] ? 1 : 0, $data['allow_nearby_discovery'] ? 1 : 0, $id,
            ));
            $updated = admin_fetch_store_with_catalog($pdo, $id);
            $existing['product_count'] = $updated['product_count'];
            $existing['catalog_categories'] = $updated['catalog_categories'];
            $existing['max_saving'] = $updated['max_saving'];
            $existing['max_discount_percent'] = $updated['max_discount_percent'];
            admin_audit(
                $pdo,
                admin_actor_id($adminContext),
                'store.update',
                'store',
                (string) $id,
                $id,
                admin_store_resource($existing),
                admin_store_resource($updated)
            );
            return $updated;
        });
    } catch (PDOException $exception) {
        if (db_unique_violation($exception)) {
            throw new ApiException(409, 'CONFLICT', 'A store with this code already exists.');
        }
        throw $exception;
    }
    respond_data(admin_store_resource($store));
}

function api_admin_list_products(array $adminContext): void
{
    $page = pagination();
    $where = array();
    $params = array();
    $storeId = query_int('store_id');
    if ($storeId !== null) {
        $where[] = 'store_id = ?';
        $params[] = $storeId;
    }
    $query = admin_query_text('q');
    if ($query !== null) {
        $where[] = '(name_en LIKE ? OR name_hi LIKE ? OR name_mrw LIKE ? OR category LIKE ?)';
        $like = '%' . $query . '%';
        array_push($params, $like, $like, $like, $like);
    }
    $category = admin_query_text('category', 80);
    if ($category !== null) {
        $where[] = 'category = ?';
        $params[] = $category;
    }
    foreach (array('available_online' => 'available_for_online', 'is_hidden' => 'is_hidden') as $queryName => $column) {
        $value = admin_query_bool($queryName);
        if ($value !== null) {
            $where[] = $column . ' = ?';
            $params[] = $value ? 1 : 0;
        }
    }
    $from = 'FROM products';
    $whereSql = $where === array() ? '' : ' WHERE ' . implode(' AND ', $where);
    $total = admin_total($from . $whereSql, $params);
    $statement = db()->prepare('SELECT * ' . $from . $whereSql . ' ORDER BY updated_at DESC, id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset']);
    $statement->execute($params);
    respond_data(array_map('product_resource', $statement->fetchAll()), 200, admin_list_meta($total, $page));
}

function api_admin_update_product(array $adminContext, int $id): void
{
    $body = json_body();
    reject_unknown_fields($body, array('stock', 'mrp', 'selling_price', 'available_for_online', 'is_hidden'));
    if ($body === array()) {
        validation_error(array('_schema' => array('At least one product field is required.')));
    }
    $product = in_transaction(function (PDO $pdo) use ($adminContext, $id, $body): array {
        $statement = $pdo->prepare('SELECT * FROM products WHERE id = ? FOR UPDATE');
        $statement->execute(array($id));
        $existing = $statement->fetch();
        if (!$existing) {
            throw new ApiException(404, 'NOT_FOUND', 'Product not found.');
        }
        $stock = array_key_exists('stock', $body) ? required_int($body, 'stock', 0, 100000000) : (int) $existing['stock'];
        $mrp = array_key_exists('mrp', $body) ? required_money($body, 'mrp', 0.01, 10000000.0) : (float) $existing['mrp'];
        $selling = array_key_exists('selling_price', $body)
            ? required_money($body, 'selling_price', 0.01, 10000000.0)
            : (float) $existing['selling_price'];
        if ($selling > $mrp) {
            validation_error(array('selling_price' => array('Must not exceed mrp.')));
        }
        $available = optional_bool($body, 'available_for_online', (bool) $existing['available_for_online']);
        $hidden = optional_bool($body, 'is_hidden', (bool) $existing['is_hidden']);
        $pdo->prepare('UPDATE products SET stock=?, mrp=?, selling_price=?, available_for_online=?, is_hidden=? WHERE id=?')
            ->execute(array($stock, $mrp, $selling, $available ? 1 : 0, $hidden ? 1 : 0, $id));
        $statement = $pdo->prepare('SELECT * FROM products WHERE id = ?');
        $statement->execute(array($id));
        $updated = $statement->fetch();
        admin_audit(
            $pdo,
            admin_actor_id($adminContext),
            'product.update',
            'product',
            (string) $id,
            (int) $existing['store_id'],
            product_resource($existing),
            product_resource($updated)
        );
        return $updated;
    });
    respond_data(product_resource($product));
}

function api_admin_list_customers(array $adminContext): void
{
    $page = pagination();
    $where = array();
    $params = array();
    $storeId = query_int('store_id');
    if ($storeId !== null) {
        $where[] = 'store_id = ?';
        $params[] = $storeId;
    }
    $query = admin_query_text('q');
    if ($query !== null) {
        $where[] = '(name LIKE ? OR mobile LIKE ?)';
        $like = '%' . $query . '%';
        array_push($params, $like, $like);
    }
    $from = 'FROM customers';
    $whereSql = $where === array() ? '' : ' WHERE ' . implode(' AND ', $where);
    $total = admin_total($from . $whereSql, $params);
    $statement = db()->prepare('SELECT * ' . $from . $whereSql . ' ORDER BY updated_at DESC, id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset']);
    $statement->execute($params);
    $data = array();
    foreach ($statement->fetchAll() as $customer) {
        $data[] = customer_resource(db(), $customer);
    }
    respond_data($data, 200, admin_list_meta($total, $page));
}

function api_admin_update_customer(array $adminContext, int $id): void
{
    $body = json_body();
    reject_unknown_fields($body, array('allow_online_udhaar'));
    if (!array_key_exists('allow_online_udhaar', $body)) {
        validation_error(array('allow_online_udhaar' => array('This boolean field is required.')));
    }
    $customer = in_transaction(function (PDO $pdo) use ($adminContext, $id, $body): array {
        $existing = fetch_customer($pdo, $id, true);
        $allow = optional_bool($body, 'allow_online_udhaar', (bool) $existing['allow_online_udhaar']);
        $pdo->prepare('UPDATE customers SET allow_online_udhaar = ? WHERE id = ?')->execute(array($allow ? 1 : 0, $id));
        $updated = fetch_customer($pdo, $id);
        admin_audit(
            $pdo,
            admin_actor_id($adminContext),
            'customer.udhaar_permission_update',
            'customer',
            (string) $id,
            (int) $existing['store_id'],
            array('allow_online_udhaar' => (bool) $existing['allow_online_udhaar']),
            array('allow_online_udhaar' => (bool) $updated['allow_online_udhaar'])
        );
        return $updated;
    });
    respond_data(customer_resource(db(), $customer));
}

function api_admin_list_delivery_staff(array $adminContext): void
{
    $page = pagination();
    $where = array();
    $params = array();
    $storeId = query_int('store_id');
    if ($storeId !== null) {
        $where[] = 'store_id = ?';
        $params[] = $storeId;
    }
    $active = admin_query_bool('is_active');
    if ($active !== null) {
        $where[] = 'is_active = ?';
        $params[] = $active ? 1 : 0;
    }
    $query = admin_query_text('q');
    if ($query !== null) {
        $where[] = '(name LIKE ? OR mobile LIKE ?)';
        $like = '%' . $query . '%';
        array_push($params, $like, $like);
    }
    $from = 'FROM delivery_staff';
    $whereSql = $where === array() ? '' : ' WHERE ' . implode(' AND ', $where);
    $total = admin_total($from . $whereSql, $params);
    $statement = db()->prepare(
        'SELECT id, store_id, name, mobile, is_active, assigned_orders_count, cash_collected_today, created_at, updated_at '
        . $from . $whereSql . ' ORDER BY updated_at DESC, id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset']
    );
    $statement->execute($params);
    respond_data(array_map('delivery_staff_resource', $statement->fetchAll()), 200, admin_list_meta($total, $page));
}

function api_admin_create_delivery_staff(array $adminContext): void
{
    $body = json_body();
    reject_unknown_fields($body, array('store_id', 'name', 'mobile', 'pin', 'is_active'));
    $storeId = required_int($body, 'store_id');
    $name = required_string($body, 'name', 160);
    $mobile = validate_mobile(required_string($body, 'mobile', 30));
    $pin = required_string($body, 'pin', 12, 4);
    if (!preg_match('/^[0-9]{4,12}$/', $pin)) {
        validation_error(array('pin' => array('Must contain 4 to 12 digits.')));
    }
    $active = optional_bool($body, 'is_active', true);

    try {
        $staff = in_transaction(function (PDO $pdo) use ($adminContext, $storeId, $name, $mobile, $pin, $active): array {
            assert_store_exists($pdo, $storeId);
            $statement = $pdo->prepare(
                'INSERT INTO delivery_staff (store_id, name, mobile, pin_hash, is_active) VALUES (?, ?, ?, ?, ?)'
            );
            $statement->execute(array(
                $storeId,
                $name,
                $mobile,
                password_hash($pin, PASSWORD_DEFAULT),
                $active ? 1 : 0,
            ));
            $id = (int) $pdo->lastInsertId();
            $statement = $pdo->prepare(
                'SELECT id, store_id, name, mobile, is_active, assigned_orders_count, cash_collected_today, created_at, updated_at '
                . 'FROM delivery_staff WHERE id = ?'
            );
            $statement->execute(array($id));
            $created = $statement->fetch();
            admin_audit(
                $pdo,
                admin_actor_id($adminContext),
                'delivery_staff.create',
                'delivery_staff',
                (string) $id,
                $storeId,
                null,
                delivery_staff_resource($created)
            );
            return $created;
        });
    } catch (PDOException $exception) {
        if (db_unique_violation($exception)) {
            throw new ApiException(409, 'CONFLICT', 'A rider with this mobile already exists for the store.');
        }
        throw $exception;
    }
    respond_data(delivery_staff_resource($staff), 201);
}

function api_admin_update_delivery_staff(array $adminContext, int $id): void
{
    $body = json_body();
    reject_unknown_fields($body, array('name', 'mobile', 'is_active'));
    if ($body === array()) {
        validation_error(array('_schema' => array('At least one delivery-staff field is required.')));
    }
    try {
        $staff = in_transaction(function (PDO $pdo) use ($adminContext, $id, $body): array {
            $statement = $pdo->prepare('SELECT * FROM delivery_staff WHERE id = ? FOR UPDATE');
            $statement->execute(array($id));
            $existing = $statement->fetch();
            if (!$existing) {
                throw new ApiException(404, 'NOT_FOUND', 'Delivery staff member not found.');
            }
            $name = array_key_exists('name', $body) ? required_string($body, 'name', 160) : $existing['name'];
            $mobile = array_key_exists('mobile', $body)
                ? validate_mobile(required_string($body, 'mobile', 30))
                : $existing['mobile'];
            $active = optional_bool($body, 'is_active', (bool) $existing['is_active']);
            if (!$active && (bool) $existing['is_active']) {
                $statement = $pdo->prepare(
                    "SELECT id, order_number, status FROM orders WHERE delivery_staff_id = ? "
                    . "AND status NOT IN ('DELIVERED', 'CANCELLED') ORDER BY id LIMIT 1 FOR UPDATE"
                );
                $statement->execute(array($id));
                $activeOrder = $statement->fetch();
                if ($activeOrder) {
                    throw new ApiException(
                        409,
                        'RIDER_HAS_ACTIVE_ORDERS',
                        sprintf(
                            'Reassign or complete order %s before deactivating this rider.',
                            (string) $activeOrder['order_number']
                        )
                    );
                }
            }
            $pdo->prepare('UPDATE delivery_staff SET name=?, mobile=?, is_active=? WHERE id=?')
                ->execute(array($name, $mobile, $active ? 1 : 0, $id));
            if (!$active) {
                $pdo->prepare('DELETE FROM api_tokens WHERE delivery_staff_id = ?')->execute(array($id));
            }
            $statement = $pdo->prepare(
                'SELECT id, store_id, name, mobile, is_active, assigned_orders_count, cash_collected_today, created_at, updated_at '
                . 'FROM delivery_staff WHERE id = ?'
            );
            $statement->execute(array($id));
            $updated = $statement->fetch();
            admin_audit(
                $pdo,
                admin_actor_id($adminContext),
                'delivery_staff.update',
                'delivery_staff',
                (string) $id,
                (int) $existing['store_id'],
                delivery_staff_resource($existing),
                delivery_staff_resource($updated),
                array('rider_sessions_revoked' => !$active)
            );
            return $updated;
        });
    } catch (PDOException $exception) {
        if (db_unique_violation($exception)) {
            throw new ApiException(409, 'CONFLICT', 'A rider with this mobile already exists for the store.');
        }
        throw $exception;
    }
    respond_data(delivery_staff_resource($staff));
}

function api_admin_reset_delivery_pin(array $adminContext, int $id): void
{
    $body = json_body();
    reject_unknown_fields($body, array('pin'));
    $pin = required_string($body, 'pin', 12, 4);
    if (!preg_match('/^[0-9]{4,12}$/', $pin)) {
        validation_error(array('pin' => array('Must contain 4 to 12 digits.')));
    }
    $staff = in_transaction(function (PDO $pdo) use ($adminContext, $id, $pin): array {
        $statement = $pdo->prepare('SELECT * FROM delivery_staff WHERE id = ? FOR UPDATE');
        $statement->execute(array($id));
        $existing = $statement->fetch();
        if (!$existing) {
            throw new ApiException(404, 'NOT_FOUND', 'Delivery staff member not found.');
        }
        $pdo->prepare('UPDATE delivery_staff SET pin_hash = ? WHERE id = ?')
            ->execute(array(password_hash($pin, PASSWORD_DEFAULT), $id));
        $pdo->prepare('DELETE FROM api_tokens WHERE delivery_staff_id = ?')->execute(array($id));
        admin_audit(
            $pdo,
            admin_actor_id($adminContext),
            'delivery_staff.pin_reset',
            'delivery_staff',
            (string) $id,
            (int) $existing['store_id'],
            null,
            null,
            array('rider_sessions_revoked' => true)
        );
        $statement = $pdo->prepare(
            'SELECT id, store_id, name, mobile, is_active, assigned_orders_count, cash_collected_today, created_at, updated_at '
            . 'FROM delivery_staff WHERE id = ?'
        );
        $statement->execute(array($id));
        return $statement->fetch();
    });
    respond_data(array('staff' => delivery_staff_resource($staff), 'pin_reset' => true));
}

function api_admin_list_orders(array $adminContext): void
{
    $page = pagination();
    $where = array();
    $params = array();
    $storeId = query_int('store_id');
    if ($storeId !== null) {
        $where[] = 'store_id = ?';
        $params[] = $storeId;
    }
    $status = admin_query_text('status', 24);
    if ($status !== null) {
        $status = strtoupper($status);
        if (!in_array($status, ORDER_STATUSES, true)) {
            validation_error(array('status' => array('Unknown order status.')));
        }
        $where[] = 'status = ?';
        $params[] = $status;
    }
    $query = admin_query_text('q');
    if ($query !== null) {
        $where[] = '(order_number LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?)';
        $like = '%' . $query . '%';
        array_push($params, $like, $like, $like);
    }
    $from = 'FROM orders';
    $whereSql = $where === array() ? '' : ' WHERE ' . implode(' AND ', $where);
    $total = admin_total($from . $whereSql, $params);
    $statement = db()->prepare('SELECT * ' . $from . $whereSql . ' ORDER BY created_at DESC, id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset']);
    $statement->execute($params);
    $data = array();
    foreach ($statement->fetchAll() as $order) {
        $data[] = order_resource(db(), $order);
    }
    respond_data($data, 200, admin_list_meta($total, $page));
}

function api_admin_update_order_status(array $adminContext, int $id): void
{
    $body = json_body();
    $order = update_order_status(
        $id,
        $body,
        false,
        function (PDO $pdo, array $before, array $after) use ($adminContext): void {
            admin_audit(
                $pdo,
                admin_actor_id($adminContext),
                'order.status_update',
                'order',
                (string) $after['id'],
                (int) $after['store_id'],
                array(
                    'status' => $before['status'],
                    'delivery_staff_id' => $before['delivery_staff_id'] === null ? null : (int) $before['delivery_staff_id'],
                    'rejection_reason' => $before['rejection_reason'],
                ),
                array(
                    'status' => $after['status'],
                    'delivery_staff_id' => $after['delivery_staff_id'] === null ? null : (int) $after['delivery_staff_id'],
                    'rejection_reason' => $after['rejection_reason'],
                    'payment_status' => $after['payment_status'],
                )
            );
        }
    );
    respond_data(order_resource(db(), $order));
}

function admin_decode_audit_json($value)
{
    if ($value === null || trim((string) $value) === '') {
        return null;
    }
    $decoded = json_decode((string) $value, true);
    return json_last_error() === JSON_ERROR_NONE ? $decoded : null;
}

function admin_audit_resource(array $row): array
{
    return array(
        'id' => (int) $row['id'],
        'admin_user_id' => $row['admin_user_id'] === null ? null : (int) $row['admin_user_id'],
        'admin_email' => $row['admin_email'],
        'action' => $row['action'],
        'resource_type' => $row['resource_type'],
        'resource_id' => $row['resource_id'],
        'store_id' => $row['store_id'] === null ? null : (int) $row['store_id'],
        'request_id' => $row['request_id'],
        'ip_address' => $row['ip_address'],
        'user_agent' => $row['user_agent'],
        'before' => admin_decode_audit_json($row['before_json']),
        'after' => admin_decode_audit_json($row['after_json']),
        'metadata' => admin_decode_audit_json($row['metadata_json']),
        'created_at' => $row['created_at'],
    );
}

function api_admin_list_audit_logs(array $adminContext): void
{
    $page = pagination();
    $where = array();
    $params = array();
    $storeId = query_int('store_id');
    if ($storeId !== null) {
        $where[] = 'aal.store_id = ?';
        $params[] = $storeId;
    }
    $adminUserId = query_int('admin_user_id');
    if ($adminUserId !== null) {
        $where[] = 'aal.admin_user_id = ?';
        $params[] = $adminUserId;
    }
    foreach (array('action' => 100, 'resource_type' => 80) as $field => $max) {
        $value = admin_query_text($field, $max);
        if ($value !== null) {
            $where[] = 'aal.' . $field . ' = ?';
            $params[] = $value;
        }
    }
    $from = 'FROM admin_audit_logs aal';
    $whereSql = $where === array() ? '' : ' WHERE ' . implode(' AND ', $where);
    $total = admin_total($from . $whereSql, $params);
    $statement = db()->prepare(
        'SELECT aal.*, au.email AS admin_email ' . $from
        . ' LEFT JOIN admin_users au ON au.id = aal.admin_user_id' . $whereSql
        . ' ORDER BY aal.created_at DESC, aal.id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset']
    );
    $statement->execute($params);
    respond_data(array_map('admin_audit_resource', $statement->fetchAll()), 200, admin_list_meta($total, $page));
}
