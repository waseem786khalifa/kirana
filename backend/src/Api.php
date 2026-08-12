<?php

declare(strict_types=1);

const ORDER_STATUSES = array('NEW', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED');
const PAYMENT_METHODS = array('COD', 'UPI', 'PAY_AT_SHOP', 'UDHAAR');

function row_types(array $row, array $integers = array(), array $floats = array(), array $booleans = array()): array
{
    foreach ($integers as $field) {
        if (array_key_exists($field, $row) && $row[$field] !== null) {
            $row[$field] = (int) $row[$field];
        }
    }
    foreach ($floats as $field) {
        if (array_key_exists($field, $row) && $row[$field] !== null) {
            $row[$field] = (float) $row[$field];
        }
    }
    foreach ($booleans as $field) {
        if (array_key_exists($field, $row) && $row[$field] !== null) {
            $row[$field] = (bool) $row[$field];
        }
    }
    return $row;
}

function db_unique_violation(PDOException $exception): bool
{
    return (string) $exception->getCode() === '23000';
}

function store_resource(array $row): array
{
    $row = row_types(
        $row,
        array('id'),
        array('delivery_radius_km', 'min_order', 'free_delivery_above', 'delivery_charge'),
        array(
            'is_open', 'delivery_available', 'scheduled_delivery_enabled', 'cod_enabled',
            'upi_enabled', 'pay_at_shop_enabled', 'online_udhaar_enabled', 'allow_nearby_discovery'
        )
    );

    $categories = array();
    if (isset($row['catalog_categories']) && trim((string) $row['catalog_categories']) !== '') {
        $categories = array_values(array_filter(array_map('trim', explode('||', (string) $row['catalog_categories']))));
    }

    return array(
        'id' => $row['id'],
        'code' => $row['code'],
        'name' => $row['name'],
        'owner_name' => $row['owner_name'],
        'phone' => $row['phone'],
        'address' => $row['address'],
        'landmark' => $row['landmark'],
        'pincode' => $row['pincode'],
        'is_open' => $row['is_open'],
        'logo' => $row['logo'],
        'banner' => $row['banner'],
        'description' => $row['description'],
        'opening_time' => substr((string) $row['opening_time'], 0, 5),
        'closing_time' => substr((string) $row['closing_time'], 0, 5),
        'delivery_settings' => array(
            'delivery_available' => $row['delivery_available'],
            'radius_km' => $row['delivery_radius_km'],
            'min_order' => $row['min_order'],
            'free_delivery_above' => $row['free_delivery_above'],
            'delivery_charge' => $row['delivery_charge'],
            'expected_delivery_time' => $row['expected_delivery_time'],
            'scheduled_delivery_enabled' => $row['scheduled_delivery_enabled'],
        ),
        'payment_settings' => array(
            'cod_enabled' => $row['cod_enabled'],
            'upi_enabled' => $row['upi_enabled'],
            'pay_at_shop_enabled' => $row['pay_at_shop_enabled'],
            'online_udhaar_enabled' => $row['online_udhaar_enabled'],
        ),
        'allow_nearby_discovery' => $row['allow_nearby_discovery'],
        'categories' => $categories,
        'product_count' => isset($row['product_count']) ? (int) $row['product_count'] : 0,
        'max_saving' => isset($row['max_saving']) ? (float) $row['max_saving'] : 0.0,
        'max_discount_percent' => isset($row['max_discount_percent']) ? (int) $row['max_discount_percent'] : 0,
    );
}

function store_catalog_summary_sql(string $storeAlias = 's'): string
{
    return ' LEFT JOIN (' .
        'SELECT store_id, COUNT(*) AS product_count, ' .
        "GROUP_CONCAT(DISTINCT category ORDER BY category SEPARATOR '||') AS catalog_categories, " .
        'MAX(GREATEST(mrp - selling_price, 0)) AS max_saving, ' .
        'MAX(CASE WHEN mrp > 0 THEN ROUND(GREATEST(mrp - selling_price, 0) * 100 / mrp) ELSE 0 END) AS max_discount_percent ' .
        'FROM products WHERE available_for_online = 1 AND is_hidden = 0 GROUP BY store_id' .
        ') catalog ON catalog.store_id = ' . $storeAlias . '.id';
}

function product_resource(array $row): array
{
    return row_types(
        $row,
        array('id', 'store_id', 'stock'),
        array('mrp', 'selling_price'),
        array('available_for_online', 'is_hidden')
    );
}

function address_resource(array $row): array
{
    return row_types($row, array('id'));
}

function customer_resource(PDO $pdo, array $row): array
{
    $row = row_types(
        $row,
        array('id', 'store_id', 'total_orders'),
        array('udhaar_balance', 'total_spent'),
        array('allow_online_udhaar')
    );
    $statement = $pdo->prepare(
        'SELECT id, label, address_line, landmark, pincode FROM customer_addresses WHERE customer_id = ? ORDER BY id'
    );
    $statement->execute(array($row['id']));
    $row['addresses'] = array_map('address_resource', $statement->fetchAll());
    return $row;
}

function delivery_staff_resource(array $row): array
{
    unset($row['pin_hash']);
    return row_types(
        $row,
        array('id', 'store_id', 'assigned_orders_count'),
        array('cash_collected_today'),
        array('is_active')
    );
}

function khata_resource(array $row): array
{
    return row_types(
        $row,
        array('id', 'store_id', 'customer_id', 'order_id'),
        array('amount', 'balance_after')
    );
}

function assert_store_exists(PDO $pdo, int $storeId, bool $lock = false): array
{
    $sql = 'SELECT * FROM stores WHERE id = ?' . ($lock ? ' FOR UPDATE' : '');
    $statement = $pdo->prepare($sql);
    $statement->execute(array($storeId));
    $store = $statement->fetch();
    if (!$store) {
        throw new ApiException(404, 'NOT_FOUND', 'Store not found.');
    }
    return $store;
}

function api_health(): void
{
    db()->query('SELECT 1')->fetchColumn();
    respond_data(array(
        'status' => 'ok',
        'database' => 'ok',
        'service' => 'kirana-saarthi-api',
        'timestamp' => date(DATE_ATOM),
    ));
}

function api_list_stores(): void
{
    $page = pagination();
    $where = array();
    $params = array();
    if (isset($_GET['pincode']) && $_GET['pincode'] !== '') {
        $where[] = 's.pincode = ?';
        $params[] = validate_pincode((string) $_GET['pincode']);
    }
    if (isset($_GET['nearby']) && $_GET['nearby'] !== '') {
        $nearby = filter_var($_GET['nearby'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
        if ($nearby === null) {
            validation_error(array('nearby' => array('Must be a boolean.')));
        }
        $where[] = 's.allow_nearby_discovery = ?';
        $params[] = $nearby ? 1 : 0;
    }

    $sql = 'SELECT s.*, COALESCE(catalog.product_count, 0) AS product_count, ' .
        "COALESCE(catalog.catalog_categories, '') AS catalog_categories, " .
        'COALESCE(catalog.max_saving, 0) AS max_saving, ' .
        'COALESCE(catalog.max_discount_percent, 0) AS max_discount_percent FROM stores s' .
        store_catalog_summary_sql('s');
    if ($where !== array()) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }
    $sql .= ' ORDER BY s.name LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset'];
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $data = array_map('store_resource', $statement->fetchAll());
    respond_data($data, 200, array('count' => count($data), 'limit' => $page['limit'], 'offset' => $page['offset']));
}

function api_store_by_code(string $code): void
{
    $code = strtoupper(trim($code));
    if (!preg_match('/^[A-Z0-9_-]{3,32}$/', $code)) {
        validation_error(array('code' => array('Use 3-32 letters, digits, underscores, or hyphens.')));
    }
    $statement = db()->prepare(
        'SELECT s.*, COALESCE(catalog.product_count, 0) AS product_count, ' .
        "COALESCE(catalog.catalog_categories, '') AS catalog_categories, " .
        'COALESCE(catalog.max_saving, 0) AS max_saving, ' .
        'COALESCE(catalog.max_discount_percent, 0) AS max_discount_percent FROM stores s' .
        store_catalog_summary_sql('s') . ' WHERE s.code = ? LIMIT 1'
    );
    $statement->execute(array($code));
    $store = $statement->fetch();
    if (!$store) {
        throw new ApiException(404, 'NOT_FOUND', 'Store not found.');
    }
    respond_data(store_resource($store));
}

function api_list_products(): void
{
    $page = pagination();
    $where = array();
    $params = array();
    if (isset($_GET['store_id']) && $_GET['store_id'] !== '') {
        $where[] = 'store_id = ?';
        $params[] = query_int('store_id');
    }
    if (isset($_GET['available_online']) && $_GET['available_online'] !== '') {
        $available = filter_var($_GET['available_online'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
        if ($available === null) {
            validation_error(array('available_online' => array('Must be a boolean.')));
        }
        $where[] = 'available_for_online = ?';
        $params[] = $available ? 1 : 0;
    }
    if (isset($_GET['category']) && trim((string) $_GET['category']) !== '') {
        $where[] = 'category = ?';
        $params[] = trim((string) $_GET['category']);
    }

    $sql = 'SELECT id, store_id, name_en, name_hi, name_mrw, category, pack_size, mrp, selling_price, stock, image, available_for_online, is_hidden, created_at, updated_at FROM products';
    if ($where !== array()) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }
    $sql .= ' ORDER BY id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset'];
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $data = array_map('product_resource', $statement->fetchAll());
    respond_data($data, 200, array('count' => count($data), 'limit' => $page['limit'], 'offset' => $page['offset']));
}

function validated_product(array $body, ?array $existing = null): array
{
    reject_unknown_fields($body, array(
        'store_id', 'name_en', 'name_hi', 'name_mrw', 'category', 'pack_size', 'mrp',
        'selling_price', 'stock', 'image', 'available_for_online', 'is_hidden'
    ));

    $creating = $existing === null;
    $data = $existing === null ? array() : $existing;
    if ($creating || array_key_exists('store_id', $body)) {
        $data['store_id'] = required_int($body, 'store_id');
    }
    foreach (array('name_en' => 160, 'name_hi' => 160, 'name_mrw' => 160, 'category' => 80, 'pack_size' => 60) as $field => $max) {
        if ($creating || array_key_exists($field, $body)) {
            $data[$field] = required_string($body, $field, $max);
        }
    }
    if ($creating || array_key_exists('mrp', $body)) {
        $data['mrp'] = required_money($body, 'mrp', 0.01, 10000000.0);
    }
    if ($creating || array_key_exists('selling_price', $body)) {
        $data['selling_price'] = required_money($body, 'selling_price', 0.01, 10000000.0);
    }
    if ($data['selling_price'] > $data['mrp']) {
        validation_error(array('selling_price' => array('Must not exceed mrp.')));
    }
    if ($creating || array_key_exists('stock', $body)) {
        $data['stock'] = required_int($body, 'stock', 0, 100000000);
    }
    if ($creating || array_key_exists('image', $body)) {
        $data['image'] = optional_string($body, 'image', 1000, '');
    }
    $data['available_for_online'] = optional_bool($body, 'available_for_online', $creating ? true : (bool) $data['available_for_online']);
    $data['is_hidden'] = optional_bool($body, 'is_hidden', $creating ? false : (bool) $data['is_hidden']);
    return $data;
}

function api_create_product(): void
{
    $data = validated_product(json_body());
    assert_store_exists(db(), $data['store_id']);
    $statement = db()->prepare(
        'INSERT INTO products (store_id, name_en, name_hi, name_mrw, category, pack_size, mrp, selling_price, stock, image, available_for_online, is_hidden) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $statement->execute(array(
        $data['store_id'], $data['name_en'], $data['name_hi'], $data['name_mrw'], $data['category'],
        $data['pack_size'], $data['mrp'], $data['selling_price'], $data['stock'], $data['image'],
        $data['available_for_online'] ? 1 : 0, $data['is_hidden'] ? 1 : 0,
    ));
    $id = (int) db()->lastInsertId();
    $statement = db()->prepare('SELECT * FROM products WHERE id = ?');
    $statement->execute(array($id));
    respond_data(product_resource($statement->fetch()), 201);
}

function api_update_product(int $id): void
{
    $statement = db()->prepare('SELECT * FROM products WHERE id = ?');
    $statement->execute(array($id));
    $existing = $statement->fetch();
    if (!$existing) {
        throw new ApiException(404, 'NOT_FOUND', 'Product not found.');
    }
    $data = validated_product(json_body(), $existing);
    assert_store_exists(db(), (int) $data['store_id']);
    $statement = db()->prepare(
        'UPDATE products SET store_id=?, name_en=?, name_hi=?, name_mrw=?, category=?, pack_size=?, mrp=?, selling_price=?, stock=?, image=?, available_for_online=?, is_hidden=? WHERE id=?'
    );
    $statement->execute(array(
        $data['store_id'], $data['name_en'], $data['name_hi'], $data['name_mrw'], $data['category'],
        $data['pack_size'], $data['mrp'], $data['selling_price'], $data['stock'], $data['image'],
        $data['available_for_online'] ? 1 : 0, $data['is_hidden'] ? 1 : 0, $id,
    ));
    $statement = db()->prepare('SELECT * FROM products WHERE id = ?');
    $statement->execute(array($id));
    respond_data(product_resource($statement->fetch()));
}

function validated_addresses($value, string $field = 'addresses'): array
{
    if (!is_array($value) || ($value !== array() && array_values($value) !== $value)) {
        validation_error(array($field => array('Must be a JSON array.')));
    }
    if (count($value) > 10) {
        validation_error(array($field => array('At most 10 addresses are allowed.')));
    }

    $addresses = array();
    foreach ($value as $index => $address) {
        if (!is_array($address)) {
            validation_error(array($field . '.' . $index => array('Must be an object.')));
        }
        reject_unknown_fields($address, array('id', 'label', 'address_line', 'landmark', 'pincode'));
        unset($address['id']);
        $addresses[] = validate_address($address, $field . '.' . $index);
    }
    return $addresses;
}

function insert_customer_addresses(PDO $pdo, int $customerId, array $addresses): void
{
    $statement = $pdo->prepare(
        'INSERT INTO customer_addresses (customer_id, label, address_line, landmark, pincode) VALUES (?, ?, ?, ?, ?)'
    );
    foreach ($addresses as $address) {
        $statement->execute(array(
            $customerId, $address['label'], $address['address_line'], $address['landmark'], $address['pincode'],
        ));
    }
}

function fetch_customer(PDO $pdo, int $id, bool $lock = false): array
{
    $statement = $pdo->prepare('SELECT * FROM customers WHERE id = ?' . ($lock ? ' FOR UPDATE' : ''));
    $statement->execute(array($id));
    $customer = $statement->fetch();
    if (!$customer) {
        throw new ApiException(404, 'NOT_FOUND', 'Customer not found.');
    }
    return $customer;
}

function api_list_customers(): void
{
    $page = pagination();
    $where = array();
    $params = array();
    if (isset($_GET['store_id']) && $_GET['store_id'] !== '') {
        $where[] = 'store_id = ?';
        $params[] = query_int('store_id');
    }
    if (isset($_GET['mobile']) && trim((string) $_GET['mobile']) !== '') {
        $where[] = 'mobile = ?';
        $params[] = validate_mobile((string) $_GET['mobile']);
    }

    $sql = 'SELECT * FROM customers';
    if ($where !== array()) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }
    $sql .= ' ORDER BY id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset'];
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $pdo = db();
    $data = array();
    foreach ($statement->fetchAll() as $customer) {
        $data[] = customer_resource($pdo, $customer);
    }
    respond_data($data, 200, array('count' => count($data), 'limit' => $page['limit'], 'offset' => $page['offset']));
}

function api_create_customer(): void
{
    $body = json_body();
    reject_unknown_fields($body, array('store_id', 'name', 'mobile', 'addresses', 'allow_online_udhaar'));
    $storeId = required_int($body, 'store_id');
    $name = required_string($body, 'name', 160);
    $mobile = validate_mobile(required_string($body, 'mobile', 30));
    $addresses = validated_addresses(isset($body['addresses']) ? $body['addresses'] : array());
    $allowOnlineUdhaar = optional_bool($body, 'allow_online_udhaar', false);

    assert_store_exists(db(), $storeId);
    try {
        $customer = in_transaction(function (PDO $pdo) use ($storeId, $name, $mobile, $addresses, $allowOnlineUdhaar): array {
            $statement = $pdo->prepare(
                'INSERT INTO customers (store_id, name, mobile, allow_online_udhaar) VALUES (?, ?, ?, ?)'
            );
            $statement->execute(array($storeId, $name, $mobile, $allowOnlineUdhaar ? 1 : 0));
            $id = (int) $pdo->lastInsertId();
            insert_customer_addresses($pdo, $id, $addresses);
            return fetch_customer($pdo, $id);
        });
    } catch (PDOException $exception) {
        if (db_unique_violation($exception)) {
            throw new ApiException(409, 'CONFLICT', 'A customer with this mobile already exists for the store.');
        }
        throw $exception;
    }
    respond_data(customer_resource(db(), $customer), 201);
}

function api_update_customer(int $id): void
{
    $body = json_body();
    reject_unknown_fields($body, array('name', 'mobile', 'addresses', 'allow_online_udhaar'));

    try {
        $customer = in_transaction(function (PDO $pdo) use ($id, $body): array {
            $existing = fetch_customer($pdo, $id, true);
            $name = array_key_exists('name', $body) ? required_string($body, 'name', 160) : $existing['name'];
            $mobile = array_key_exists('mobile', $body)
                ? validate_mobile(required_string($body, 'mobile', 30))
                : $existing['mobile'];
            $allow = optional_bool($body, 'allow_online_udhaar', (bool) $existing['allow_online_udhaar']);

            $statement = $pdo->prepare('UPDATE customers SET name = ?, mobile = ?, allow_online_udhaar = ? WHERE id = ?');
            $statement->execute(array($name, $mobile, $allow ? 1 : 0, $id));

            if (array_key_exists('addresses', $body)) {
                $addresses = validated_addresses($body['addresses']);
                $statement = $pdo->prepare('DELETE FROM customer_addresses WHERE customer_id = ?');
                $statement->execute(array($id));
                insert_customer_addresses($pdo, $id, $addresses);
            }
            return fetch_customer($pdo, $id);
        });
    } catch (PDOException $exception) {
        if (db_unique_violation($exception)) {
            throw new ApiException(409, 'CONFLICT', 'A customer with this mobile already exists for the store.');
        }
        throw $exception;
    }
    respond_data(customer_resource(db(), $customer));
}

function api_list_delivery_staff(): void
{
    $page = pagination();
    $where = array();
    $params = array();
    if (isset($_GET['store_id']) && $_GET['store_id'] !== '') {
        $where[] = 'store_id = ?';
        $params[] = query_int('store_id');
    }
    if (isset($_GET['is_active']) && $_GET['is_active'] !== '') {
        $active = filter_var($_GET['is_active'], FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
        if ($active === null) {
            validation_error(array('is_active' => array('Must be a boolean.')));
        }
        $where[] = 'is_active = ?';
        $params[] = $active ? 1 : 0;
    }

    $sql = 'SELECT id, store_id, name, mobile, is_active, assigned_orders_count, cash_collected_today, created_at, updated_at FROM delivery_staff';
    if ($where !== array()) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }
    $sql .= ' ORDER BY id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset'];
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $data = array_map('delivery_staff_resource', $statement->fetchAll());
    respond_data($data, 200, array('count' => count($data), 'limit' => $page['limit'], 'offset' => $page['offset']));
}

function api_create_delivery_staff(): void
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
    assert_store_exists(db(), $storeId);

    try {
        $statement = db()->prepare(
            'INSERT INTO delivery_staff (store_id, name, mobile, pin_hash, is_active) VALUES (?, ?, ?, ?, ?)'
        );
        $statement->execute(array($storeId, $name, $mobile, password_hash($pin, PASSWORD_DEFAULT), $active ? 1 : 0));
    } catch (PDOException $exception) {
        if (db_unique_violation($exception)) {
            throw new ApiException(409, 'CONFLICT', 'A delivery staff member with this mobile already exists for the store.');
        }
        throw $exception;
    }
    $id = (int) db()->lastInsertId();
    $statement = db()->prepare(
        'SELECT id, store_id, name, mobile, is_active, assigned_orders_count, cash_collected_today, created_at, updated_at FROM delivery_staff WHERE id = ?'
    );
    $statement->execute(array($id));
    respond_data(delivery_staff_resource($statement->fetch()), 201);
}

function api_delivery_staff_login(): void
{
    $body = json_body();
    reject_unknown_fields($body, array('store_id', 'mobile', 'pin'));
    $mobile = validate_mobile(required_string($body, 'mobile', 30));
    $pin = required_string($body, 'pin', 12, 4);

    $sql = 'SELECT * FROM delivery_staff WHERE mobile = ?';
    $params = array($mobile);
    if (array_key_exists('store_id', $body)) {
        $sql .= ' AND store_id = ?';
        $params[] = required_int($body, 'store_id');
    }
    $rawToken = bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $rawToken);
    $tokenTtl = (int) app_config()['token_ttl_seconds'];
    $result = in_transaction(function (PDO $pdo) use ($sql, $params, $pin, $tokenHash, $tokenTtl): array {
        $statement = $pdo->prepare($sql . ' ORDER BY id FOR UPDATE');
        $statement->execute($params);
        $matches = array();
        foreach ($statement->fetchAll() as $candidate) {
            if ((bool) $candidate['is_active'] && password_verify($pin, $candidate['pin_hash'])) {
                $matches[] = $candidate;
            }
        }
        if ($matches === array()) {
            throw new ApiException(401, 'UNAUTHORIZED', 'Invalid mobile or PIN.');
        }
        if (count($matches) > 1) {
            validation_error(array('store_id' => array('Store ID is required when this mobile belongs to multiple stores.')));
        }
        $staff = $matches[0];
        $expiresAt = (string) $pdo->query(
            'SELECT DATE_ADD(NOW(), INTERVAL ' . $tokenTtl . ' SECOND)'
        )->fetchColumn();
        $pdo->prepare('DELETE FROM api_tokens WHERE expires_at <= NOW()')->execute();
        $statement = $pdo->prepare(
            'INSERT INTO api_tokens (delivery_staff_id, token_hash, expires_at) VALUES (?, ?, ?)'
        );
        $statement->execute(array($staff['id'], $tokenHash, $expiresAt));
        return array('staff' => $staff, 'expires_at' => $expiresAt);
    });

    respond_data(array(
        'token' => $rawToken,
        'token_type' => 'Bearer',
        'expires_at' => date(DATE_ATOM, strtotime($result['expires_at'])),
        'staff' => delivery_staff_resource($result['staff']),
    ));
}

function require_delivery_staff_token(PDO $pdo, int $expectedStaffId, int $storeId): void
{
    $authorization = isset($_SERVER['HTTP_AUTHORIZATION'])
        ? trim((string) $_SERVER['HTTP_AUTHORIZATION'])
        : (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION']) ? trim((string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION']) : '');
    if (!preg_match('/^Bearer\s+([A-Fa-f0-9]{64})$/', $authorization, $matches)) {
        throw new ApiException(401, 'UNAUTHORIZED', 'A valid delivery staff bearer token is required.');
    }

    $statement = $pdo->prepare(
        'SELECT ds.id, ds.store_id, ds.is_active FROM api_tokens t JOIN delivery_staff ds ON ds.id = t.delivery_staff_id WHERE t.token_hash = ? AND t.expires_at > NOW() LIMIT 1'
    );
    $statement->execute(array(hash('sha256', $matches[1])));
    $staff = $statement->fetch();
    if (!$staff) {
        throw new ApiException(401, 'UNAUTHORIZED', 'Delivery staff token is invalid or expired.');
    }
    if (!(bool) $staff['is_active'] || (int) $staff['id'] !== $expectedStaffId || (int) $staff['store_id'] !== $storeId) {
        throw new ApiException(403, 'FORBIDDEN', 'This rider cannot update the selected order.');
    }
}

function api_list_khata(): void
{
    $page = pagination();
    $where = array();
    $params = array();
    if (isset($_GET['store_id']) && $_GET['store_id'] !== '') {
        $where[] = 'store_id = ?';
        $params[] = query_int('store_id');
    }
    if (isset($_GET['customer_id']) && $_GET['customer_id'] !== '') {
        $where[] = 'customer_id = ?';
        $params[] = query_int('customer_id');
    }

    $sql = 'SELECT id, store_id, customer_id, entry_date AS date, type, amount, order_id, note, balance_after, created_at FROM khata_entries';
    if ($where !== array()) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }
    $sql .= ' ORDER BY id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset'];
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $data = array_map('khata_resource', $statement->fetchAll());
    respond_data($data, 200, array('count' => count($data), 'limit' => $page['limit'], 'offset' => $page['offset']));
}

function api_create_khata_credit(): void
{
    $body = json_body();
    reject_unknown_fields($body, array('store_id', 'customer_id', 'type', 'amount', 'note'));
    $storeId = required_int($body, 'store_id');
    $customerId = required_int($body, 'customer_id');
    $type = enum_value($body, 'type', array('CREDIT'));
    $amount = required_money($body, 'amount', 0.01, 10000000.0);
    $note = optional_string($body, 'note', 500, 'Khata Payment Received');

    $entry = in_transaction(function (PDO $pdo) use ($storeId, $customerId, $type, $amount, $note): array {
        $customer = fetch_customer($pdo, $customerId, true);
        if ((int) $customer['store_id'] !== $storeId) {
            validation_error(array('store_id' => array('Customer does not belong to this store.')));
        }
        $balance = (float) $customer['udhaar_balance'];
        if ($amount > $balance) {
            throw new ApiException(409, 'CONFLICT', 'Payment exceeds the current udhaar balance.', array(
                'current_balance' => $balance,
            ));
        }
        $newBalance = round($balance - $amount, 2);
        $statement = $pdo->prepare('UPDATE customers SET udhaar_balance = ? WHERE id = ?');
        $statement->execute(array($newBalance, $customerId));
        $statement = $pdo->prepare(
            'INSERT INTO khata_entries (store_id, customer_id, entry_date, type, amount, note, balance_after) VALUES (?, ?, CURRENT_DATE(), ?, ?, ?, ?)'
        );
        $statement->execute(array($storeId, $customerId, $type, $amount, $note, $newBalance));
        $id = (int) $pdo->lastInsertId();
        $statement = $pdo->prepare(
            'SELECT id, store_id, customer_id, entry_date AS date, type, amount, order_id, note, balance_after, created_at FROM khata_entries WHERE id = ?'
        );
        $statement->execute(array($id));
        return $statement->fetch();
    });
    respond_data(khata_resource($entry), 201);
}

function order_item_resource(array $row): array
{
    return row_types($row, array('id', 'product_id', 'quantity'), array('price', 'mrp'));
}

function fetch_order(PDO $pdo, int $id, bool $lock = false): array
{
    $statement = $pdo->prepare('SELECT * FROM orders WHERE id = ?' . ($lock ? ' FOR UPDATE' : ''));
    $statement->execute(array($id));
    $order = $statement->fetch();
    if (!$order) {
        throw new ApiException(404, 'NOT_FOUND', 'Order not found.');
    }
    return $order;
}

function order_resource(PDO $pdo, array $row): array
{
    $staffName = null;
    $staffPhone = null;
    if ($row['delivery_staff_id'] !== null) {
        $statement = $pdo->prepare('SELECT name, mobile FROM delivery_staff WHERE id = ?');
        $statement->execute(array($row['delivery_staff_id']));
        $staff = $statement->fetch();
        if ($staff) {
            $staffName = $staff['name'];
            $staffPhone = $staff['mobile'];
        }
    }

    $statement = $pdo->prepare(
        'SELECT id, product_id, name_en, name_hi, name_mrw, pack_size, price, mrp, quantity FROM order_items WHERE order_id = ? ORDER BY id'
    );
    $statement->execute(array($row['id']));
    $items = array_map('order_item_resource', $statement->fetchAll());

    return array(
        'id' => (int) $row['id'],
        'order_number' => $row['order_number'],
        'store_id' => (int) $row['store_id'],
        'customer_id' => (int) $row['customer_id'],
        'customer_name' => $row['customer_name'],
        'customer_phone' => $row['customer_phone'],
        'delivery_address' => array(
            'id' => $row['delivery_address_id'] === null ? null : (int) $row['delivery_address_id'],
            'label' => $row['delivery_address_label'],
            'address_line' => $row['delivery_address_line'],
            'landmark' => $row['delivery_address_landmark'],
            'pincode' => $row['delivery_address_pincode'],
        ),
        'items' => $items,
        'subtotal' => (float) $row['subtotal'],
        'discount' => (float) $row['discount'],
        'delivery_charge' => (float) $row['delivery_charge'],
        'total_amount' => (float) $row['total_amount'],
        'payment_method' => $row['payment_method'],
        'payment_status' => $row['payment_status'],
        'status' => $row['status'],
        'rejection_reason' => $row['rejection_reason'],
        'delivery_instructions' => $row['delivery_instructions'],
        'scheduled_slot' => $row['scheduled_slot'],
        'delivery_staff_id' => $row['delivery_staff_id'] === null ? null : (int) $row['delivery_staff_id'],
        'delivery_staff_name' => $staffName,
        'delivery_staff_phone' => $staffPhone,
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at'],
    );
}

function api_list_orders(): void
{
    $page = pagination();
    $where = array();
    $params = array();
    if (isset($_GET['store_id']) && $_GET['store_id'] !== '') {
        $where[] = 'store_id = ?';
        $params[] = query_int('store_id');
    }
    if (isset($_GET['customer_phone']) && trim((string) $_GET['customer_phone']) !== '') {
        $where[] = 'customer_phone = ?';
        $params[] = validate_mobile((string) $_GET['customer_phone'], 'customer_phone');
    }
    if (isset($_GET['delivery_staff_id']) && $_GET['delivery_staff_id'] !== '') {
        $where[] = 'delivery_staff_id = ?';
        $params[] = query_int('delivery_staff_id');
    }
    if (isset($_GET['status']) && trim((string) $_GET['status']) !== '') {
        $status = strtoupper(trim((string) $_GET['status']));
        if (!in_array($status, ORDER_STATUSES, true)) {
            validation_error(array('status' => array('Unknown order status.')));
        }
        $where[] = 'status = ?';
        $params[] = $status;
    }

    $sql = 'SELECT * FROM orders';
    if ($where !== array()) {
        $sql .= ' WHERE ' . implode(' AND ', $where);
    }
    $sql .= ' ORDER BY created_at DESC, id DESC LIMIT ' . $page['limit'] . ' OFFSET ' . $page['offset'];
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $pdo = db();
    $data = array();
    foreach ($statement->fetchAll() as $order) {
        $data[] = order_resource($pdo, $order);
    }
    respond_data($data, 200, array('count' => count($data), 'limit' => $page['limit'], 'offset' => $page['offset']));
}

function api_get_order(int $id): void
{
    respond_data(order_resource(db(), fetch_order(db(), $id)));
}

function resolve_order_address(PDO $pdo, int $customerId, $value): array
{
    if ($value === null) {
        $statement = $pdo->prepare(
            'SELECT id, label, address_line, landmark, pincode FROM customer_addresses WHERE customer_id = ? ORDER BY id LIMIT 1'
        );
        $statement->execute(array($customerId));
        $address = $statement->fetch();
        if (!$address) {
            validation_error(array('delivery_address' => array('A delivery address is required.')));
        }
        return address_resource($address);
    }
    if (!is_array($value)) {
        validation_error(array('delivery_address' => array('Must be an object.')));
    }

    if (array_key_exists('id', $value)) {
        $addressId = required_int($value, 'id');
        $statement = $pdo->prepare(
            'SELECT id, label, address_line, landmark, pincode FROM customer_addresses WHERE id = ? AND customer_id = ?'
        );
        $statement->execute(array($addressId, $customerId));
        $address = $statement->fetch();
        if (!$address) {
            validation_error(array('delivery_address.id' => array('Address does not belong to this customer.')));
        }
        return address_resource($address);
    }

    reject_unknown_fields($value, array('label', 'address_line', 'landmark', 'pincode'));
    $address = validate_address($value, 'delivery_address');
    $address['id'] = null;
    return $address;
}

function resolve_order_customer(PDO $pdo, int $storeId, array $body): array
{
    $hasId = array_key_exists('customer_id', $body);
    $hasObject = array_key_exists('customer', $body);
    if ($hasId === $hasObject) {
        validation_error(array('customer' => array('Provide exactly one of customer_id or customer.')));
    }

    if ($hasId) {
        $customer = fetch_customer($pdo, required_int($body, 'customer_id'), true);
        if ((int) $customer['store_id'] !== $storeId) {
            validation_error(array('customer_id' => array('Customer does not belong to this store.')));
        }
        $address = resolve_order_address(
            $pdo,
            (int) $customer['id'],
            array_key_exists('delivery_address', $body) ? $body['delivery_address'] : null
        );
        return array('customer' => $customer, 'address' => $address);
    }

    if (!is_array($body['customer'])) {
        validation_error(array('customer' => array('Must be an object.')));
    }
    $input = $body['customer'];
    reject_unknown_fields($input, array('name', 'mobile', 'address'));
    $name = required_string($input, 'name', 160);
    $mobile = validate_mobile(required_string($input, 'mobile', 30));
    $addressInput = array_key_exists('delivery_address', $body)
        ? $body['delivery_address']
        : (array_key_exists('address', $input) ? $input['address'] : null);
    if ($addressInput === null || !is_array($addressInput)) {
        validation_error(array('customer.address' => array('A customer address object is required.')));
    }

    $statement = $pdo->prepare('SELECT * FROM customers WHERE store_id = ? AND mobile = ? FOR UPDATE');
    $statement->execute(array($storeId, $mobile));
    $customer = $statement->fetch();
    if (!$customer) {
        $statement = $pdo->prepare('INSERT INTO customers (store_id, name, mobile) VALUES (?, ?, ?)');
        $statement->execute(array($storeId, $name, $mobile));
        $customerId = (int) $pdo->lastInsertId();
        $address = resolve_order_address($pdo, $customerId, $addressInput);
        $statement = $pdo->prepare(
            'INSERT INTO customer_addresses (customer_id, label, address_line, landmark, pincode) VALUES (?, ?, ?, ?, ?)'
        );
        $statement->execute(array(
            $customerId, $address['label'], $address['address_line'], $address['landmark'], $address['pincode'],
        ));
        $address['id'] = (int) $pdo->lastInsertId();
        $customer = fetch_customer($pdo, $customerId);
        return array('customer' => $customer, 'address' => $address);
    }

    $address = resolve_order_address($pdo, (int) $customer['id'], $addressInput);
    return array('customer' => $customer, 'address' => $address);
}

function order_idempotency_key(array $body): ?string
{
    $bodyKey = array_key_exists('idempotency_key', $body)
        ? optional_string($body, 'idempotency_key', 100, null)
        : null;
    $headerKey = isset($_SERVER['HTTP_IDEMPOTENCY_KEY']) ? trim((string) $_SERVER['HTTP_IDEMPOTENCY_KEY']) : null;
    if ($bodyKey !== null && $headerKey !== null && $bodyKey !== $headerKey) {
        validation_error(array('idempotency_key' => array('Body and Idempotency-Key header must match.')));
    }
    $key = $headerKey !== null && $headerKey !== '' ? $headerKey : $bodyKey;
    if ($key !== null && !preg_match('/^[A-Za-z0-9._:-]{8,100}$/', $key)) {
        validation_error(array('idempotency_key' => array('Use 8-100 URL-safe characters.')));
    }
    return $key;
}

function api_create_order(): void
{
    $body = json_body();
    reject_unknown_fields($body, array(
        'store_id', 'customer_id', 'customer', 'delivery_address', 'items', 'payment_method',
        'delivery_instructions', 'scheduled_slot', 'idempotency_key'
    ));
    $storeId = required_int($body, 'store_id');
    $paymentMethod = enum_value($body, 'payment_method', PAYMENT_METHODS);
    $instructions = optional_string($body, 'delivery_instructions', 500, null);
    $scheduledSlot = optional_string($body, 'scheduled_slot', 120, null);
    $idempotencyKey = order_idempotency_key($body);

    if (!array_key_exists('items', $body) || !is_array($body['items']) || $body['items'] === array() || array_values($body['items']) !== $body['items']) {
        validation_error(array('items' => array('A non-empty JSON array is required.')));
    }
    if (count($body['items']) > 100) {
        validation_error(array('items' => array('At most 100 line items are allowed.')));
    }
    $quantities = array();
    foreach ($body['items'] as $index => $item) {
        if (!is_array($item)) {
            validation_error(array('items.' . $index => array('Must be an object.')));
        }
        reject_unknown_fields($item, array('product_id', 'quantity'));
        $productId = required_int($item, 'product_id');
        $quantity = required_int($item, 'quantity', 1, 999);
        $quantities[$productId] = isset($quantities[$productId]) ? $quantities[$productId] + $quantity : $quantity;
        if ($quantities[$productId] > 999) {
            validation_error(array('items.' . $index . '.quantity' => array('Combined quantity cannot exceed 999.')));
        }
    }

    try {
        $result = in_transaction(function (PDO $pdo) use (
            $body, $storeId, $paymentMethod, $instructions, $scheduledSlot, $idempotencyKey, $quantities
        ): array {
            $store = assert_store_exists($pdo, $storeId, true);
            if ($idempotencyKey !== null) {
                $statement = $pdo->prepare('SELECT * FROM orders WHERE store_id = ? AND idempotency_key = ? FOR UPDATE');
                $statement->execute(array($storeId, $idempotencyKey));
                $existing = $statement->fetch();
                if ($existing) {
                    return array('order' => $existing, 'existing' => true);
                }
            }

            if (!(bool) $store['delivery_available']) {
                throw new ApiException(409, 'CONFLICT', 'Delivery is currently unavailable for this store.');
            }
            $paymentColumns = array(
                'COD' => 'cod_enabled',
                'UPI' => 'upi_enabled',
                'PAY_AT_SHOP' => 'pay_at_shop_enabled',
                'UDHAAR' => 'online_udhaar_enabled',
            );
            if (!(bool) $store[$paymentColumns[$paymentMethod]]) {
                validation_error(array('payment_method' => array('This payment method is disabled for the store.')));
            }

            $resolved = resolve_order_customer($pdo, $storeId, $body);
            $customer = $resolved['customer'];
            $address = $resolved['address'];
            if ($paymentMethod === 'UDHAAR' && !(bool) $customer['allow_online_udhaar']) {
                throw new ApiException(403, 'FORBIDDEN', 'Online udhaar is not enabled for this customer.');
            }

            $ids = array_keys($quantities);
            $placeholders = implode(',', array_fill(0, count($ids), '?'));
            $statement = $pdo->prepare('SELECT * FROM products WHERE id IN (' . $placeholders . ') FOR UPDATE');
            $statement->execute($ids);
            $products = array();
            foreach ($statement->fetchAll() as $product) {
                $products[(int) $product['id']] = $product;
            }
            if (count($products) !== count($ids)) {
                validation_error(array('items' => array('One or more products do not exist.')));
            }

            $subtotal = 0.0;
            $mrpTotal = 0.0;
            foreach ($ids as $productId) {
                $product = $products[$productId];
                $quantity = $quantities[$productId];
                if ((int) $product['store_id'] !== $storeId) {
                    validation_error(array('items' => array('Every product must belong to the selected store.')));
                }
                if (!(bool) $product['available_for_online'] || (bool) $product['is_hidden']) {
                    throw new ApiException(409, 'CONFLICT', 'A selected product is not available online.', array(
                        'product_id' => array($productId),
                    ));
                }
                if ((int) $product['stock'] < $quantity) {
                    throw new ApiException(409, 'INSUFFICIENT_STOCK', 'Insufficient product stock.', array(
                        'product_id' => array($productId),
                        'available' => array((int) $product['stock']),
                        'requested' => array($quantity),
                    ));
                }
                $subtotal += (float) $product['selling_price'] * $quantity;
                $mrpTotal += (float) $product['mrp'] * $quantity;
            }
            $subtotal = round($subtotal, 2);
            $discount = round(max(0, $mrpTotal - $subtotal), 2);
            if ($subtotal < (float) $store['min_order']) {
                throw new ApiException(409, 'MINIMUM_ORDER_NOT_MET', 'Order does not meet the store minimum.', array(
                    'minimum_order' => array((float) $store['min_order']),
                    'subtotal' => array($subtotal),
                ));
            }
            $deliveryCharge = $subtotal >= (float) $store['free_delivery_above']
                ? 0.0
                : (float) $store['delivery_charge'];
            $totalAmount = round($subtotal + $deliveryCharge, 2);

            $stockStatement = $pdo->prepare('UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?');
            foreach ($ids as $productId) {
                $quantity = $quantities[$productId];
                $stockStatement->execute(array($quantity, $productId, $quantity));
                if ($stockStatement->rowCount() !== 1) {
                    throw new ApiException(409, 'INSUFFICIENT_STOCK', 'Stock changed while the order was being placed.');
                }
            }

            $orderNumber = 'KS' . date('ymd') . strtoupper(bin2hex(random_bytes(4)));
            $statement = $pdo->prepare(
                'INSERT INTO orders (order_number, store_id, customer_id, customer_name, customer_phone, delivery_address_id, delivery_address_label, delivery_address_line, delivery_address_landmark, delivery_address_pincode, subtotal, discount, delivery_charge, total_amount, payment_method, payment_status, status, delivery_instructions, scheduled_slot, idempotency_key, stock_reserved) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)'
            );
            $statement->execute(array(
                $orderNumber, $storeId, $customer['id'], $customer['name'], $customer['mobile'], $address['id'],
                $address['label'], $address['address_line'], $address['landmark'], $address['pincode'],
                $subtotal, $discount, $deliveryCharge, $totalAmount, $paymentMethod, 'PENDING', 'NEW',
                $instructions, $scheduledSlot, $idempotencyKey,
            ));
            $orderId = (int) $pdo->lastInsertId();

            $itemStatement = $pdo->prepare(
                'INSERT INTO order_items (order_id, product_id, name_en, name_hi, name_mrw, pack_size, price, mrp, quantity) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            foreach ($ids as $productId) {
                $product = $products[$productId];
                $itemStatement->execute(array(
                    $orderId, $productId, $product['name_en'], $product['name_hi'], $product['name_mrw'],
                    $product['pack_size'], $product['selling_price'], $product['mrp'], $quantities[$productId],
                ));
            }
            $statement = $pdo->prepare(
                'INSERT INTO order_status_history (order_id, from_status, to_status, note) VALUES (?, NULL, ?, ?)'
            );
            $statement->execute(array($orderId, 'NEW', 'Order created'));
            return array('order' => fetch_order($pdo, $orderId), 'existing' => false);
        });
    } catch (PDOException $exception) {
        if ($idempotencyKey !== null && db_unique_violation($exception)) {
            $statement = db()->prepare('SELECT * FROM orders WHERE store_id = ? AND idempotency_key = ?');
            $statement->execute(array($storeId, $idempotencyKey));
            $existing = $statement->fetch();
            if ($existing) {
                respond_data(order_resource(db(), $existing));
            }
        }
        throw $exception;
    }

    respond_data(order_resource(db(), $result['order']), $result['existing'] ? 200 : 201);
}

function update_order_status(
    int $id,
    array $body,
    bool $requireRiderAuthorization = true,
    ?callable $afterUpdate = null
): array
{
    reject_unknown_fields($body, array('status', 'rejection_reason', 'delivery_staff_id'));
    $targetStatus = enum_value($body, 'status', ORDER_STATUSES);
    $rejectionReason = optional_string($body, 'rejection_reason', 500, null);

    return in_transaction(function (PDO $pdo) use (
        $id,
        $body,
        $targetStatus,
        $rejectionReason,
        $requireRiderAuthorization,
        $afterUpdate
    ): array {
        $order = fetch_order($pdo, $id, true);
        $currentStatus = $order['status'];
        $transitions = array(
            'NEW' => array('ACCEPTED', 'CANCELLED'),
            'ACCEPTED' => array('PREPARING', 'CANCELLED'),
            'PREPARING' => array('READY', 'CANCELLED'),
            'READY' => array('OUT_FOR_DELIVERY', 'CANCELLED'),
            'OUT_FOR_DELIVERY' => array('DELIVERED'),
            'DELIVERED' => array(),
            'CANCELLED' => array(),
        );

        $sameStatus = $currentStatus === $targetStatus;
        if (!$sameStatus && !in_array($targetStatus, $transitions[$currentStatus], true)) {
            throw new ApiException(409, 'INVALID_STATUS_TRANSITION', sprintf(
                'Order cannot move from %s to %s.',
                $currentStatus,
                $targetStatus
            ));
        }

        $oldStaffId = $order['delivery_staff_id'] === null ? null : (int) $order['delivery_staff_id'];
        $newStaffId = $oldStaffId;
        $staffChanged = false;
        if (array_key_exists('delivery_staff_id', $body)) {
            $newStaffId = required_int($body, 'delivery_staff_id');
            if (in_array($targetStatus, array('DELIVERED', 'CANCELLED'), true) && $newStaffId !== $oldStaffId) {
                validation_error(array('delivery_staff_id' => array('Cannot assign a rider while making an order terminal.')));
            }
            $statement = $pdo->prepare('SELECT * FROM delivery_staff WHERE id = ? FOR UPDATE');
            $statement->execute(array($newStaffId));
            $staff = $statement->fetch();
            if (!$staff || (int) $staff['store_id'] !== (int) $order['store_id'] || !(bool) $staff['is_active']) {
                validation_error(array('delivery_staff_id' => array('Active rider must belong to the order store.')));
            }
            $staffChanged = $newStaffId !== $oldStaffId;
        }

        if ($targetStatus === 'OUT_FOR_DELIVERY' && $newStaffId === null) {
            validation_error(array('delivery_staff_id' => array('Assign a rider before dispatching the order.')));
        }
        if ($targetStatus !== 'CANCELLED' && array_key_exists('rejection_reason', $body)) {
            validation_error(array('rejection_reason' => array('Only cancellation may include a rejection reason.')));
        }
        if ($targetStatus === 'CANCELLED' && $currentStatus !== 'CANCELLED' && ($rejectionReason === null || $rejectionReason === '')) {
            validation_error(array('rejection_reason' => array('A cancellation reason is required.')));
        }

        if ($requireRiderAuthorization && in_array($targetStatus, array('OUT_FOR_DELIVERY', 'DELIVERED'), true)) {
            if ($newStaffId === null) {
                validation_error(array('delivery_staff_id' => array('An assigned rider is required.')));
            }
            require_delivery_staff_token($pdo, $newStaffId, (int) $order['store_id']);
        }

        if ($sameStatus && !$staffChanged && !array_key_exists('rejection_reason', $body)) {
            return $order;
        }
        if (in_array($currentStatus, array('DELIVERED', 'CANCELLED'), true)) {
            return $order;
        }

        if ($staffChanged) {
            if ($oldStaffId !== null) {
                $statement = $pdo->prepare(
                    'UPDATE delivery_staff SET assigned_orders_count = GREATEST(assigned_orders_count - 1, 0) WHERE id = ?'
                );
                $statement->execute(array($oldStaffId));
            }
            $statement = $pdo->prepare(
                'UPDATE delivery_staff SET assigned_orders_count = assigned_orders_count + 1 WHERE id = ?'
            );
            $statement->execute(array($newStaffId));
        }

        $stockReserved = (bool) $order['stock_reserved'];
        $processedAt = $order['delivery_processed_at'];
        $paymentStatus = $order['payment_status'];

        if ($targetStatus === 'CANCELLED' && $stockReserved) {
            $statement = $pdo->prepare('SELECT product_id, quantity FROM order_items WHERE order_id = ?');
            $statement->execute(array($id));
            $restore = $pdo->prepare('UPDATE products SET stock = stock + ? WHERE id = ?');
            foreach ($statement->fetchAll() as $item) {
                $restore->execute(array((int) $item['quantity'], (int) $item['product_id']));
            }
            $stockReserved = false;
        }

        if ($targetStatus === 'DELIVERED' && $processedAt === null) {
            $customer = fetch_customer($pdo, (int) $order['customer_id'], true);
            $newBalance = (float) $customer['udhaar_balance'];
            if ($order['payment_method'] === 'UDHAAR') {
                $newBalance = round($newBalance + (float) $order['total_amount'], 2);
                $statement = $pdo->prepare(
                    'INSERT INTO khata_entries (store_id, customer_id, entry_date, type, amount, order_id, note, balance_after) VALUES (?, ?, CURRENT_DATE(), ?, ?, ?, ?, ?)'
                );
                $statement->execute(array(
                    $order['store_id'], $order['customer_id'], 'DEBIT', $order['total_amount'], $id,
                    'Online order ' . $order['order_number'] . ' udhaar', $newBalance,
                ));
                $paymentStatus = 'UDHAAR_POSTED';
            } else {
                $paymentStatus = 'COLLECTED';
            }

            $statement = $pdo->prepare(
                'UPDATE customers SET udhaar_balance = ?, total_orders = total_orders + 1, total_spent = total_spent + ?, last_order_date = CURRENT_DATE() WHERE id = ?'
            );
            $statement->execute(array($newBalance, $order['total_amount'], $order['customer_id']));

            $statement = $pdo->prepare('SELECT COALESCE(SUM(quantity), 0) FROM order_items WHERE order_id = ?');
            $statement->execute(array($id));
            $itemCount = (int) $statement->fetchColumn();
            $statement = $pdo->prepare(
                'INSERT INTO sales_records (store_id, order_id, channel, amount, payment_method, sale_date, item_count) VALUES (?, ?, ?, ?, ?, CURRENT_DATE(), ?)'
            );
            $statement->execute(array(
                $order['store_id'], $id, 'ONLINE', $order['total_amount'], $order['payment_method'], $itemCount,
            ));

            if ($newStaffId !== null && $order['payment_method'] === 'COD') {
                $statement = $pdo->prepare(
                    'UPDATE delivery_staff SET cash_collected_today = cash_collected_today + ? WHERE id = ?'
                );
                $statement->execute(array($order['total_amount'], $newStaffId));
            }
            $processedAt = date('Y-m-d H:i:s');
            $stockReserved = false;
        }

        if (in_array($targetStatus, array('DELIVERED', 'CANCELLED'), true) && $newStaffId !== null) {
            $statement = $pdo->prepare(
                'UPDATE delivery_staff SET assigned_orders_count = GREATEST(assigned_orders_count - 1, 0) WHERE id = ?'
            );
            $statement->execute(array($newStaffId));
        }

        $finalReason = $targetStatus === 'CANCELLED' ? $rejectionReason : $order['rejection_reason'];
        $statement = $pdo->prepare(
            'UPDATE orders SET status = ?, rejection_reason = ?, delivery_staff_id = ?, stock_reserved = ?, delivery_processed_at = ?, payment_status = ? WHERE id = ?'
        );
        $statement->execute(array(
            $targetStatus, $finalReason, $newStaffId, $stockReserved ? 1 : 0, $processedAt, $paymentStatus, $id,
        ));

        $historyNote = $staffChanged && $sameStatus ? 'Delivery rider assigned' : $rejectionReason;
        $statement = $pdo->prepare(
            'INSERT INTO order_status_history (order_id, from_status, to_status, delivery_staff_id, note) VALUES (?, ?, ?, ?, ?)'
        );
        $statement->execute(array($id, $currentStatus, $targetStatus, $newStaffId, $historyNote));
        $updated = fetch_order($pdo, $id);
        if ($afterUpdate !== null) {
            $afterUpdate($pdo, $order, $updated);
        }
        return $updated;
    });
}

function api_update_order_status(int $id): void
{
    respond_data(order_resource(db(), update_order_status($id, json_body())));
}

function valid_report_date(string $value, string $field): string
{
    $date = DateTime::createFromFormat('!Y-m-d', $value);
    $errors = DateTime::getLastErrors();
    if (!$date || ($errors !== false && ($errors['warning_count'] > 0 || $errors['error_count'] > 0)) || $date->format('Y-m-d') !== $value) {
        validation_error(array($field => array('Use YYYY-MM-DD format.')));
    }
    return $value;
}

function sale_resource(array $row): array
{
    return row_types(
        $row,
        array('id', 'store_id', 'order_id', 'item_count'),
        array('amount')
    );
}

function api_reports(): void
{
    $storeId = query_int('store_id');
    if ($storeId === null) {
        validation_error(array('store_id' => array('This query parameter is required.')));
    }
    assert_store_exists(db(), $storeId);
    $dateFrom = isset($_GET['date_from']) && $_GET['date_from'] !== ''
        ? valid_report_date((string) $_GET['date_from'], 'date_from')
        : date('Y-m-01');
    $dateTo = isset($_GET['date_to']) && $_GET['date_to'] !== ''
        ? valid_report_date((string) $_GET['date_to'], 'date_to')
        : date('Y-m-d');
    if ($dateFrom > $dateTo) {
        validation_error(array('date_to' => array('Must be on or after date_from.')));
    }

    $statement = db()->prepare(
        "SELECT
            COALESCE(SUM(CASE WHEN channel = 'COUNTER' THEN amount ELSE 0 END), 0) AS counter_sales,
            COALESCE(SUM(CASE WHEN channel = 'ONLINE' THEN amount ELSE 0 END), 0) AS online_sales,
            COALESCE(SUM(amount), 0) AS total_sales,
            COALESCE(SUM(CASE WHEN payment_method = 'COD' THEN amount ELSE 0 END), 0) AS cod,
            COALESCE(SUM(CASE WHEN payment_method = 'UPI' THEN amount ELSE 0 END), 0) AS upi,
            COALESCE(SUM(CASE WHEN payment_method = 'PAY_AT_SHOP' THEN amount ELSE 0 END), 0) AS pay_at_shop,
            COALESCE(SUM(CASE WHEN payment_method = 'UDHAAR' THEN amount ELSE 0 END), 0) AS udhaar
         FROM sales_records WHERE store_id = ? AND sale_date BETWEEN ? AND ?"
    );
    $statement->execute(array($storeId, $dateFrom, $dateTo));
    $summary = $statement->fetch();

    $statement = db()->prepare(
        'SELECT COUNT(*) AS order_count, COALESCE(SUM(status = ?), 0) AS delivered_orders FROM orders WHERE store_id = ? AND DATE(created_at) BETWEEN ? AND ?'
    );
    $statement->execute(array('DELIVERED', $storeId, $dateFrom, $dateTo));
    $orderStats = $statement->fetch();

    $statement = db()->prepare(
        'SELECT id, store_id, order_id, channel, amount, payment_method, sale_date AS date, item_count FROM sales_records WHERE store_id = ? AND sale_date BETWEEN ? AND ? ORDER BY sale_date DESC, id DESC LIMIT 200'
    );
    $statement->execute(array($storeId, $dateFrom, $dateTo));
    $salesRecords = array_map('sale_resource', $statement->fetchAll());

    $delivered = (int) $orderStats['delivered_orders'];
    $onlineSales = (float) $summary['online_sales'];
    respond_data(array(
        'store_id' => $storeId,
        'date_from' => $dateFrom,
        'date_to' => $dateTo,
        'counter_sales' => (float) $summary['counter_sales'],
        'online_sales' => $onlineSales,
        'total_sales' => (float) $summary['total_sales'],
        'order_count' => (int) $orderStats['order_count'],
        'delivered_orders' => $delivered,
        'average_order_value' => $delivered > 0 ? round($onlineSales / $delivered, 2) : 0.0,
        'payment_breakdown' => array(
            'cod' => (float) $summary['cod'],
            'upi' => (float) $summary['upi'],
            'pay_at_shop' => (float) $summary['pay_at_shop'],
            'udhaar' => (float) $summary['udhaar'],
        ),
        'sales_records' => $salesRecords,
    ));
}
