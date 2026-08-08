# Kirana Saarthi PHP API

Dependency-free REST backend for the customer, merchant, and delivery portals. It uses PDO prepared statements, InnoDB transactions, server-calculated order totals, transactional stock reservation, hashed delivery PINs, and consistent snake_case JSON.

The code is written for PHP 8 and deliberately remains compatible with the installed XAMPP PHP 7.4.33 and MariaDB 10.4.27.

## XAMPP setup

1. Start Apache and MySQL from XAMPP.
2. Import `backend/schema.sql` in phpMyAdmin, or run this from the `backend` directory:

   ```powershell
   D:\xampp-projects\mysql\bin\mysql.exe -h 127.0.0.1 -P 3306 -u root --default-character-set=utf8mb4 --execute="SOURCE schema.sql"
   ```

   The import is non-destructive and repeatable: it uses `CREATE ... IF NOT EXISTS` and stable `INSERT IGNORE` seed rows. It never drops or truncates data.

3. Defaults already match a standard local XAMPP database (`127.0.0.1:3306`, database `kirana_saarthi`, user `root`, empty password). To override them, copy `.env.example` to `.env` and edit the copy. `.env` is ignored by Git.
4. Point Apache's document root or an Alias at `backend/public`. Ensure `mod_rewrite` and `AllowOverride All` are enabled so `.htaccess` can route requests.
5. Open `http://localhost/<alias>/health`. If the project is exposed directly below `htdocs`, a typical URL is `http://localhost/kirana-main/backend/public/health`.

For a quick local server without Apache, from `backend/public` run:

```powershell
D:\xampp-projects\php\php.exe -S 127.0.0.1:8080 index.php
```

Then use `http://127.0.0.1:8080/health` as the base URL.

Both `/stores` and `/api/stores` forms are accepted. This makes an Apache proxy mounted at `/api` straightforward while keeping the API usable as its own virtual host.

## JSON conventions

Every field is snake_case. IDs are JSON integers and money values are JSON numbers with two-decimal database precision.

Single-resource success:

```json
{"data":{"id":1}}
```

List success:

```json
{"data":[],"meta":{"count":0,"limit":100,"offset":0}}
```

Error:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "One or more fields are invalid.",
    "request_id": "6f93862a50ab92d4",
    "details": {"mobile":["Must contain 10 to 15 digits."]}
  }
}
```

JSON write requests must send `Content-Type: application/json`; bodies larger than 1 MB are rejected. List endpoints support `limit` (1-200) and `offset`.

## Enums and order workflow

- `payment_method`: `COD`, `UPI`, `PAY_AT_SHOP`, `UDHAAR`
- `payment_status`: `PENDING`, `COLLECTED`, `UDHAAR_POSTED`
- `khata.type`: `DEBIT`, `CREDIT`
- Order transitions:

  ```text
  NEW -> ACCEPTED -> PREPARING -> READY -> OUT_FOR_DELIVERY -> DELIVERED
   |        |           |          |
   +--------+-----------+----------+----> CANCELLED
  ```

`DELIVERED` and `CANCELLED` are terminal. Repeating a same-status request is idempotent. A manager may assign/change the rider with a same-status `READY` request. `OUT_FOR_DELIVERY` requires an assigned active rider from the same store.

Order creation locks product rows, verifies tenant/store ownership and stock, calculates all prices from the database, and reserves stock in the same transaction. Cancellation restores a reservation once. Delivery consumes the reservation and writes customer totals, sale, khata debit (for udhaar), and payment status once under the locked order row.

## Endpoints

### Health and stores

- `GET /health`
- `GET /stores?pincode=302003&nearby=true&limit=100&offset=0`
- `GET /stores/by-code/BALAJI123`

Store resource fields:

```text
id, code, name, owner_name, phone, address, landmark, pincode, is_open,
logo, banner, description, opening_time, closing_time,
delivery_settings { delivery_available, radius_km, min_order,
  free_delivery_above, delivery_charge, expected_delivery_time,
  scheduled_delivery_enabled },
payment_settings { cod_enabled, upi_enabled, pay_at_shop_enabled,
  online_udhaar_enabled },
allow_nearby_discovery
```

### Products

- `GET /products?store_id=1&available_online=true&category=Rice`
- `POST /products`
- `PUT /products/{id}` (partial update; immutable server ID)

Create body:

```json
{
  "store_id": 1,
  "name_en": "Tata Salt",
  "name_hi": "टाटा नमक",
  "name_mrw": "टाटा लूण",
  "category": "Staples",
  "pack_size": "1 kg",
  "mrp": 30,
  "selling_price": 28,
  "stock": 50,
  "image": "",
  "available_for_online": true,
  "is_hidden": false
}
```

Resource fields: `id, store_id, name_en, name_hi, name_mrw, category, pack_size, mrp, selling_price, stock, image, available_for_online, is_hidden, created_at, updated_at`.

### Customers

- `GET /customers?store_id=1&mobile=9829012345`
- `POST /customers`
- `PUT /customers/{id}` (allows `name`, `mobile`, `addresses`, `allow_online_udhaar`; financial counters cannot be mass-assigned)

Create body:

```json
{
  "store_id": 1,
  "name": "Ramesh Kumar",
  "mobile": "9829012345",
  "allow_online_udhaar": false,
  "addresses": [
    {"label":"Home","address_line":"Flat 302, Green Park","landmark":"Near Water Tank","pincode":"302003"}
  ]
}
```

Resource fields: `id, store_id, name, mobile, addresses[{id,label,address_line,landmark,pincode}], allow_online_udhaar, udhaar_balance, total_orders, total_spent, last_order_date, created_at, updated_at`.

### Orders

- `GET /orders?store_id=1&customer_phone=9829012345&delivery_staff_id=1&status=READY`
- `GET /orders/{id}`
- `POST /orders`
- `PATCH /orders/{id}/status`

Create for an existing customer:

```json
{
  "store_id": 1,
  "customer_id": 1,
  "delivery_address": {"id": 1},
  "items": [{"product_id":1,"quantity":2}],
  "payment_method": "COD",
  "delivery_instructions": "Call at the gate",
  "scheduled_slot": "Deliver now",
  "idempotency_key": "checkout-9829012345-001"
}
```

For a new/phone-matched customer, replace `customer_id` with:

```json
"customer": {
  "name": "New Customer",
  "mobile": "9000000000",
  "address": {"label":"Home","address_line":"12 Market Road","landmark":"Bus stand","pincode":"302003"}
}
```

The client must not send prices, discount, delivery charge, total, customer balance, payment status, or order status. Those are server-owned. Send the same 8-100 character value in the `Idempotency-Key` header (or `idempotency_key` body field) when retrying checkout; a retry returns the original order.

Status body:

```json
{"status":"READY","delivery_staff_id":1}
```

Cancellation requires `{"status":"CANCELLED","rejection_reason":"Customer requested cancellation"}`.

Order resource fields: `id, order_number, store_id, customer_id, customer_name, customer_phone, delivery_address{id,label,address_line,landmark,pincode}, items[{id,product_id,name_en,name_hi,name_mrw,pack_size,price,mrp,quantity}], subtotal, discount, delivery_charge, total_amount, payment_method, payment_status, status, rejection_reason, delivery_instructions, scheduled_slot, delivery_staff_id, delivery_staff_name, delivery_staff_phone, created_at, updated_at`.

`subtotal` is the sum of current selling prices. `discount` is the informational MRP saving. `total_amount = subtotal + delivery_charge`; discount is not subtracted a second time.

### Delivery staff

- `GET /delivery-staff?store_id=1&is_active=true`
- `POST /delivery-staff`
- `POST /delivery-staff/login`

Create body: `{"store_id":1,"name":"Mukesh Saini","mobile":"9828877665","pin":"1234"}`.

Login body: `{"store_id":1,"mobile":"9828877665","pin":"1234"}`. The response contains `token`, `token_type`, `expires_at`, and `staff`. Raw PINs and hashes are never returned. PINs are stored through `password_hash`; only the SHA-256 hash of each opaque session token is stored. Seed logins are `9828877665 / 1234` and `9928112233 / 5678`.

The delivery app must send `Authorization: Bearer <token>` when moving its assigned order to `OUT_FOR_DELIVERY` or `DELIVERED`. The token's rider and store must match the assignment. Earlier merchant-managed transitions and same-status `READY` assignment do not use the rider token.

Staff resource fields: `id, store_id, name, mobile, is_active, assigned_orders_count, cash_collected_today, created_at, updated_at`.

### Khata

- `GET /khata?store_id=1&customer_id=1`
- `POST /khata`

Payment body:

```json
{"store_id":1,"customer_id":1,"type":"CREDIT","amount":500,"note":"Cash received"}
```

Only credits/payments can be posted through the public route. Udhaar debits are created internally when an udhaar order is delivered. Negative, zero, mismatched-tenant, and overpayment entries are rejected transactionally.

Resource fields: `id, store_id, customer_id, date, type, amount, order_id, note, balance_after, created_at`.

### Reports

- `GET /reports?store_id=1&date_from=2026-08-01&date_to=2026-08-31`

Dates default to the current calendar month in `APP_TIMEZONE`. The result contains `store_id, date_from, date_to, counter_sales, online_sales, total_sales, order_count, delivered_orders, average_order_value, payment_breakdown{cod,upi,pay_at_shop,udhaar}, sales_records[]`.

## Security boundary

This local backend validates payloads, prevents cross-store references, hashes rider credentials, and avoids exposing PINs. It does **not** yet define merchant or customer identity/login endpoints because those were outside the requested API contract. Before an internet deployment, add merchant/customer authentication and require role/tenant authorization on every non-public route; do not treat CORS or a frontend role switch as authentication. Also set `APP_ENV=production`, `APP_DEBUG=false`, a non-root database user/password, HTTPS, rate limiting (especially login), and token revocation/logout.
