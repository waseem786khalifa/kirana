-- Kirana Saarthi - MySQL 8 / MariaDB 10.4+ schema
-- Safe to import repeatedly: no DROP/TRUNCATE and all seed rows use stable keys.

CREATE DATABASE IF NOT EXISTS kirana_saarthi
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE kirana_saarthi;

CREATE TABLE IF NOT EXISTS stores (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(32) NOT NULL,
  name VARCHAR(160) NOT NULL,
  owner_name VARCHAR(160) NOT NULL,
  phone VARCHAR(15) NOT NULL,
  address VARCHAR(500) NOT NULL,
  landmark VARCHAR(255) NOT NULL DEFAULT '',
  pincode CHAR(6) NOT NULL,
  is_open TINYINT(1) NOT NULL DEFAULT 1,
  logo VARCHAR(1000) NOT NULL DEFAULT '',
  banner VARCHAR(1000) NOT NULL DEFAULT '',
  description VARCHAR(1000) NOT NULL DEFAULT '',
  opening_time TIME NOT NULL DEFAULT '08:00:00',
  closing_time TIME NOT NULL DEFAULT '22:00:00',
  delivery_available TINYINT(1) NOT NULL DEFAULT 1,
  delivery_radius_km DECIMAL(6,2) NOT NULL DEFAULT 5.00,
  min_order DECIMAL(12,2) NOT NULL DEFAULT 100.00,
  free_delivery_above DECIMAL(12,2) NOT NULL DEFAULT 500.00,
  delivery_charge DECIMAL(12,2) NOT NULL DEFAULT 30.00,
  expected_delivery_time VARCHAR(80) NOT NULL DEFAULT '30-45 minutes',
  scheduled_delivery_enabled TINYINT(1) NOT NULL DEFAULT 1,
  cod_enabled TINYINT(1) NOT NULL DEFAULT 1,
  upi_enabled TINYINT(1) NOT NULL DEFAULT 1,
  pay_at_shop_enabled TINYINT(1) NOT NULL DEFAULT 1,
  online_udhaar_enabled TINYINT(1) NOT NULL DEFAULT 0,
  allow_nearby_discovery TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_stores_code (code),
  KEY idx_stores_pincode_discovery (pincode, allow_nearby_discovery)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id BIGINT UNSIGNED NOT NULL,
  name_en VARCHAR(160) NOT NULL,
  name_hi VARCHAR(160) NOT NULL,
  name_mrw VARCHAR(160) NOT NULL,
  category VARCHAR(80) NOT NULL,
  pack_size VARCHAR(60) NOT NULL,
  mrp DECIMAL(12,2) NOT NULL,
  selling_price DECIMAL(12,2) NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,
  image VARCHAR(1000) NOT NULL DEFAULT '',
  available_for_online TINYINT(1) NOT NULL DEFAULT 1,
  is_hidden TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_products_store_catalog (store_id, available_for_online, is_hidden),
  KEY idx_products_store_category (store_id, category),
  CONSTRAINT fk_products_store FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE RESTRICT,
  CONSTRAINT chk_products_prices CHECK (mrp >= 0 AND selling_price >= 0 AND selling_price <= mrp)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  mobile VARCHAR(15) NOT NULL,
  allow_online_udhaar TINYINT(1) NOT NULL DEFAULT 0,
  udhaar_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_orders INT UNSIGNED NOT NULL DEFAULT 0,
  total_spent DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  last_order_date DATE NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customers_store_mobile (store_id, mobile),
  KEY idx_customers_store_name (store_id, name),
  CONSTRAINT fk_customers_store FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE RESTRICT,
  CONSTRAINT chk_customers_balances CHECK (udhaar_balance >= 0 AND total_spent >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customer_addresses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(20) NOT NULL DEFAULT 'Home',
  address_line VARCHAR(500) NOT NULL,
  landmark VARCHAR(255) NOT NULL DEFAULT '',
  pincode CHAR(6) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_addresses_customer (customer_id),
  CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE,
  CONSTRAINT chk_addresses_label CHECK (label IN ('Home', 'Office', 'Other'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS delivery_staff (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL,
  mobile VARCHAR(15) NOT NULL,
  pin_hash VARCHAR(255) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  assigned_orders_count INT UNSIGNED NOT NULL DEFAULT 0,
  cash_collected_today DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_delivery_staff_store_mobile (store_id, mobile),
  KEY idx_delivery_staff_active (store_id, is_active),
  CONSTRAINT fk_delivery_staff_store FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_number VARCHAR(24) NOT NULL,
  store_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  customer_name VARCHAR(160) NOT NULL,
  customer_phone VARCHAR(15) NOT NULL,
  delivery_address_id BIGINT UNSIGNED NULL,
  delivery_address_label VARCHAR(20) NOT NULL DEFAULT 'Home',
  delivery_address_line VARCHAR(500) NOT NULL,
  delivery_address_landmark VARCHAR(255) NOT NULL DEFAULT '',
  delivery_address_pincode CHAR(6) NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL,
  discount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  delivery_charge DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(20) NOT NULL,
  payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  status VARCHAR(24) NOT NULL DEFAULT 'NEW',
  rejection_reason VARCHAR(500) NULL,
  delivery_instructions VARCHAR(500) NULL,
  scheduled_slot VARCHAR(120) NULL,
  delivery_staff_id BIGINT UNSIGNED NULL,
  idempotency_key VARCHAR(100) NULL,
  stock_reserved TINYINT(1) NOT NULL DEFAULT 1,
  delivery_processed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_orders_order_number (order_number),
  UNIQUE KEY uq_orders_store_idempotency (store_id, idempotency_key),
  KEY idx_orders_store_status_created (store_id, status, created_at),
  KEY idx_orders_customer_phone (customer_phone, created_at),
  KEY idx_orders_customer (customer_id, created_at),
  KEY idx_orders_delivery_staff (delivery_staff_id, status),
  CONSTRAINT fk_orders_store FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE RESTRICT,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
  CONSTRAINT fk_orders_address FOREIGN KEY (delivery_address_id) REFERENCES customer_addresses (id) ON DELETE SET NULL,
  CONSTRAINT fk_orders_delivery_staff FOREIGN KEY (delivery_staff_id) REFERENCES delivery_staff (id) ON DELETE SET NULL,
  CONSTRAINT chk_orders_amounts CHECK (subtotal >= 0 AND discount >= 0 AND delivery_charge >= 0 AND total_amount >= 0),
  CONSTRAINT chk_orders_payment_method CHECK (payment_method IN ('COD', 'UPI', 'PAY_AT_SHOP', 'UDHAAR')),
  CONSTRAINT chk_orders_payment_status CHECK (payment_status IN ('PENDING', 'COLLECTED', 'UDHAAR_POSTED')),
  CONSTRAINT chk_orders_status CHECK (status IN ('NEW', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  name_en VARCHAR(160) NOT NULL,
  name_hi VARCHAR(160) NOT NULL,
  name_mrw VARCHAR(160) NOT NULL,
  pack_size VARCHAR(60) NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  mrp DECIMAL(12,2) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_order_items_product (order_id, product_id),
  KEY idx_order_items_product (product_id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT,
  CONSTRAINT chk_order_items_values CHECK (price >= 0 AND mrp >= 0 AND quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_status_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  from_status VARCHAR(24) NULL,
  to_status VARCHAR(24) NOT NULL,
  delivery_staff_id BIGINT UNSIGNED NULL,
  note VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_order_history_order (order_id, created_at),
  CONSTRAINT fk_order_history_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  CONSTRAINT fk_order_history_staff FOREIGN KEY (delivery_staff_id) REFERENCES delivery_staff (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS khata_entries (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  entry_date DATE NOT NULL,
  type VARCHAR(10) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  note VARCHAR(500) NOT NULL,
  balance_after DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_khata_order_type (order_id, type),
  KEY idx_khata_store_date (store_id, entry_date),
  KEY idx_khata_customer_date (customer_id, entry_date),
  CONSTRAINT fk_khata_store FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE RESTRICT,
  CONSTRAINT fk_khata_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
  CONSTRAINT fk_khata_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT,
  CONSTRAINT chk_khata_type CHECK (type IN ('DEBIT', 'CREDIT')),
  CONSTRAINT chk_khata_amount CHECK (amount > 0 AND balance_after >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sales_records (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  channel VARCHAR(10) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(20) NOT NULL,
  sale_date DATE NOT NULL,
  item_count INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sales_order (order_id),
  KEY idx_sales_store_date (store_id, sale_date),
  CONSTRAINT fk_sales_store FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE RESTRICT,
  CONSTRAINT fk_sales_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT,
  CONSTRAINT chk_sales_channel CHECK (channel IN ('COUNTER', 'ONLINE')),
  CONSTRAINT chk_sales_amount CHECK (amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS api_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  delivery_staff_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_api_tokens_hash (token_hash),
  KEY idx_api_tokens_staff_expiry (delivery_staff_id, expires_at),
  CONSTRAINT fk_api_tokens_staff FOREIGN KEY (delivery_staff_id) REFERENCES delivery_staff (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Stable demo stores.
INSERT IGNORE INTO stores (
  id, code, name, owner_name, phone, address, landmark, pincode, is_open, logo, banner,
  description, opening_time, closing_time, delivery_available, delivery_radius_km, min_order,
  free_delivery_above, delivery_charge, expected_delivery_time, scheduled_delivery_enabled,
  cod_enabled, upi_enabled, pay_at_shop_enabled, online_udhaar_enabled, allow_nearby_discovery
) VALUES
  (1, 'BALAJI123', 'Balaji General Store', 'Ramesh Kumar Gupta', '9876543210', 'Shop No. 12, Main Market, Chaura Rasta, Jaipur', 'Near City Post Office', '302003', 1, '', '', 'Daily groceries and household essentials.', '08:00:00', '22:00:00', 1, 5.00, 100.00, 500.00, 30.00, '30-45 minutes', 1, 1, 1, 1, 1, 1),
  (2, 'SHARMA456', 'Sharma Kirana & More', 'Suresh Sharma', '9812345678', 'Plot 45, Station Road, Jodhpur', 'Opposite Railway Colony', '342001', 1, '', '', 'Trusted neighbourhood kirana store.', '07:30:00', '21:30:00', 1, 4.00, 150.00, 600.00, 35.00, '35-50 minutes', 1, 1, 1, 1, 0, 1),
  (3, 'GUPTA789', 'Gupta Provision Store', 'Anil Gupta', '9988776655', 'Near Old Bus Stand, Bikaner', 'Beside Hanuman Temple', '334001', 0, '', '', 'Groceries, snacks, and home supplies.', '08:30:00', '21:00:00', 1, 3.50, 100.00, 400.00, 25.00, '30-45 minutes', 0, 1, 1, 1, 0, 1);

-- Stable demo products. Stock for products 1 and 2 already reflects the active seeded order reservation.
INSERT IGNORE INTO products (
  id, store_id, name_en, name_hi, name_mrw, category, pack_size, mrp, selling_price, stock, image, available_for_online, is_hidden
) VALUES
  (1, 1, 'Aashirvaad Shuddh Chakki Atta', 'आशीर्वाद शुद्ध चक्की आटा', 'आशीर्वाद चक्की आटो', 'Atta & Flour', '5 kg', 260.00, 235.00, 39, '', 1, 0),
  (2, 1, 'Fortune Kachi Ghani Mustard Oil', 'फॉर्च्यून कच्ची घानी सरसों तेल', 'फॉर्च्यून राई रो तेल', 'Cooking Oil', '1 L', 175.00, 152.00, 28, '', 1, 0),
  (3, 1, 'Amul Pure Cow Ghee Pouch', 'अमूल शुद्ध गाय का घी', 'अमूल गाय रो चोखो घी', 'Ghee', '1 L', 650.00, 610.00, 14, '', 1, 0),
  (4, 1, 'Tata Tea Gold', 'टाटा टी गोल्ड चाय', 'टाटा गोल्ड चोखी चाय', 'Tea & Coffee', '500 g', 320.00, 240.00, 22, '', 1, 0),
  (5, 1, 'India Gate Basmati Rice', 'इंडिया गेट बासमती चावल', 'इंडिया गेट बासमती चावल', 'Rice', '5 kg', 550.00, 485.00, 18, '', 1, 0),
  (6, 1, 'Bikanervala Bikaneri Bhujia', 'बीकानेरी भुजिया नमकीन', 'बीकानेरी भुजिया', 'Snacks', '400 g', 140.00, 125.00, 35, '', 1, 0),
  (7, 2, 'Fortune Sunlite Refined Oil', 'फॉर्च्यून सनलाइट तेल', 'फॉर्च्यून सनलाइट तेल', 'Cooking Oil', '1 L', 155.00, 142.00, 40, '', 1, 0),
  (8, 3, 'Tata Salt', 'टाटा नमक', 'टाटा लूण', 'Staples', '1 kg', 30.00, 28.00, 50, '', 1, 0);

INSERT IGNORE INTO customers (
  id, store_id, name, mobile, allow_online_udhaar, udhaar_balance, total_orders, total_spent, last_order_date
) VALUES
  (1, 1, 'Ramesh Kumar', '9829012345', 1, 2500.00, 0, 0.00, NULL),
  (2, 1, 'Priya Sharma', '9784561230', 1, 850.00, 1, 850.00, '2026-08-07'),
  (3, 1, 'Vikram Singh Shekhawat', '9414098765', 0, 0.00, 1, 735.00, '2026-08-08');

INSERT IGNORE INTO customer_addresses (id, customer_id, label, address_line, landmark, pincode) VALUES
  (1, 1, 'Home', 'Flat 302, Green Park Apartments, Chaura Rasta', 'Near Water Tank', '302003'),
  (2, 1, 'Office', 'Shop 14, Commercial Complex, Johri Bazar', 'Near Hawa Mahal', '302003'),
  (3, 2, 'Home', 'House 42, Subhash Colony, C-Scheme', 'Opposite Jain Temple', '302001'),
  (4, 3, 'Home', 'Villa 101, Rajputana Enclave, Tonk Road', 'Behind Chokhi Dhani', '302022');

-- Demo PINs are 1234 and 5678. Only password hashes are stored.
INSERT IGNORE INTO delivery_staff (
  id, store_id, name, mobile, pin_hash, is_active, assigned_orders_count, cash_collected_today
) VALUES
  (1, 1, 'Mukesh Saini', '9828877665', '$2y$10$sWSH2tz0RuDEjdVmSzmq6eTqUl7phLBPYGd/7Z/ll25/QQ6TqF3Xm', 1, 0, 1850.00),
  (2, 1, 'Raju Verma', '9928112233', '$2y$10$BLU2VkVTrWXmHIwAPIR15.TdLkk6QdX49MM7oWbjFP1nnhbRGj1Ly', 1, 0, 3200.00);

INSERT IGNORE INTO orders (
  id, order_number, store_id, customer_id, customer_name, customer_phone,
  delivery_address_id, delivery_address_label, delivery_address_line, delivery_address_landmark,
  delivery_address_pincode, subtotal, discount, delivery_charge, total_amount, payment_method,
  payment_status, status, delivery_instructions, delivery_staff_id, stock_reserved, delivery_processed_at,
  created_at, updated_at
) VALUES
  (1, 'KS-SEED-1025', 1, 1, 'Ramesh Kumar', '9829012345', 1, 'Home', 'Flat 302, Green Park Apartments, Chaura Rasta', 'Near Water Tank', '302003', 539.00, 71.00, 0.00, 539.00, 'COD', 'PENDING', 'NEW', 'Please call at the gate.', NULL, 1, NULL, '2026-08-08 09:15:00', '2026-08-08 09:15:00'),
  (2, 'KS-SEED-1024', 1, 2, 'Priya Sharma', '9784561230', 3, 'Home', 'House 42, Subhash Colony, C-Scheme', 'Opposite Jain Temple', '302001', 850.00, 120.00, 0.00, 850.00, 'UDHAAR', 'UDHAAR_POSTED', 'DELIVERED', 'Use the lift.', 1, 0, '2026-08-07 18:15:00', '2026-08-07 17:20:00', '2026-08-07 18:15:00'),
  (3, 'KS-SEED-1023', 1, 3, 'Vikram Singh Shekhawat', '9414098765', 4, 'Home', 'Villa 101, Rajputana Enclave, Tonk Road', 'Behind Chokhi Dhani', '302022', 735.00, 95.00, 0.00, 735.00, 'UPI', 'COLLECTED', 'DELIVERED', NULL, 1, 0, '2026-08-08 10:10:00', '2026-08-08 09:05:00', '2026-08-08 10:10:00');

INSERT IGNORE INTO order_items (
  id, order_id, product_id, name_en, name_hi, name_mrw, pack_size, price, mrp, quantity
) VALUES
  (1, 1, 1, 'Aashirvaad Shuddh Chakki Atta', 'आशीर्वाद शुद्ध चक्की आटा', 'आशीर्वाद चक्की आटो', '5 kg', 235.00, 260.00, 1),
  (2, 1, 2, 'Fortune Kachi Ghani Mustard Oil', 'फॉर्च्यून कच्ची घानी सरसों तेल', 'फॉर्च्यून राई रो तेल', '1 L', 152.00, 175.00, 2),
  (3, 2, 3, 'Amul Pure Cow Ghee Pouch', 'अमूल शुद्ध गाय का घी', 'अमूल गाय रो चोखो घी', '1 L', 610.00, 650.00, 1),
  (4, 2, 4, 'Tata Tea Gold', 'टाटा टी गोल्ड चाय', 'टाटा गोल्ड चोखी चाय', '500 g', 240.00, 320.00, 1),
  (5, 3, 5, 'India Gate Basmati Rice', 'इंडिया गेट बासमती चावल', 'इंडिया गेट बासमती चावल', '5 kg', 485.00, 550.00, 1),
  (6, 3, 6, 'Bikanervala Bikaneri Bhujia', 'बीकानेरी भुजिया नमकीन', 'बीकानेरी भुजिया', '400 g', 125.00, 140.00, 2);

INSERT IGNORE INTO order_status_history (id, order_id, from_status, to_status, delivery_staff_id, note, created_at) VALUES
  (1, 1, NULL, 'NEW', NULL, 'Seeded order', '2026-08-08 09:15:00'),
  (2, 2, 'OUT_FOR_DELIVERY', 'DELIVERED', 1, 'Seeded delivered order', '2026-08-07 18:15:00'),
  (3, 3, 'OUT_FOR_DELIVERY', 'DELIVERED', 1, 'Seeded delivered order', '2026-08-08 10:10:00');

INSERT IGNORE INTO khata_entries (
  id, store_id, customer_id, entry_date, type, amount, order_id, note, balance_after
) VALUES
  (1, 1, 1, '2026-08-01', 'DEBIT', 2500.00, NULL, 'Previous Kirana Udhaar Balance', 2500.00),
  (2, 1, 2, '2026-08-07', 'DEBIT', 850.00, 2, 'Online order KS-SEED-1024 udhaar', 850.00);

INSERT IGNORE INTO sales_records (
  id, store_id, order_id, channel, amount, payment_method, sale_date, item_count
) VALUES
  (1, 1, NULL, 'COUNTER', 25000.00, 'COD', '2026-08-08', 45),
  (2, 1, 2, 'ONLINE', 850.00, 'UDHAAR', '2026-08-07', 2),
  (3, 1, 3, 'ONLINE', 735.00, 'UPI', '2026-08-08', 3);
