import express from 'express';
import path from 'path';
import { createServer as createViteServer } from 'vite';
import {
  INITIAL_STORES,
  INITIAL_PRODUCTS,
  INITIAL_CUSTOMERS,
  INITIAL_ORDERS,
  INITIAL_DELIVERY_STAFF,
  INITIAL_KIRANA_LIST,
} from './src/data/mockData';
import {
  KiranaStore,
  Product,
  CustomerProfile,
  Order,
  DeliveryStaff,
  KhataEntry,
  SaleRecord,
  OrderStatus,
} from './src/types';

const app = express();
const PORT = 3000;
const PHP_API_TARGET = process.env.KIRANA_PHP_API_URL || 'http://127.0.0.1/kirana_api/public';

app.disable('x-powered-by');
app.set('trust proxy', process.env.TRUST_PROXY === 'true');
app.use((_request, response, next) => {
  response.setHeader('X-Content-Type-Options', 'nosniff');
  response.setHeader('X-Frame-Options', 'DENY');
  response.setHeader('Referrer-Policy', 'no-referrer');
  response.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; img-src 'self' data: https: http:; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'",
  );
  next();
});

app.use(express.json());

// The admin dashboard always talks to the persistent PHP/MySQL backend. Keeping
// this proxy server-side avoids browser CORS differences in local and deployed builds.
app.use('/admin-api', async (request, response) => {
  try {
    const target = `${PHP_API_TARGET.replace(/\/$/, '')}${request.originalUrl.replace(/^\/admin-api/, '') || '/'}`;
    const headers: Record<string, string> = { accept: 'application/json' };
    if (request.headers.authorization) headers.authorization = request.headers.authorization;
    if (request.headers['content-type']) headers['content-type'] = String(request.headers['content-type']);
    if (request.headers['user-agent']) headers['user-agent'] = String(request.headers['user-agent']);
    if (request.headers['x-request-id']) headers['x-request-id'] = String(request.headers['x-request-id']);
    headers['x-forwarded-for'] = request.ip || request.socket.remoteAddress || '';
    const upstream = await fetch(target, {
      method: request.method,
      headers,
      body: ['GET', 'HEAD'].includes(request.method) ? undefined : JSON.stringify(request.body ?? {}),
    });
    response.status(upstream.status);
    for (const header of ['content-type', 'cache-control', 'x-content-type-options', 'x-frame-options', 'referrer-policy', 'x-request-id']) {
      const value = upstream.headers.get(header);
      if (value) response.setHeader(header, value);
    }
    response.removeHeader('ETag');
    response.send(Buffer.from(await upstream.arrayBuffer()));
  } catch {
    response.status(502).json({ error: { code: 'BACKEND_UNAVAILABLE', message: 'PHP backend is unavailable.' } });
  }
});

// In-Memory Database State
let stores: KiranaStore[] = [...INITIAL_STORES];
let products: Product[] = [...INITIAL_PRODUCTS];
let customers: CustomerProfile[] = [...INITIAL_CUSTOMERS];
let orders: Order[] = [...INITIAL_ORDERS];
let deliveryStaff: DeliveryStaff[] = [...INITIAL_DELIVERY_STAFF];
let khataEntries: KhataEntry[] = [
  {
    id: 'kh_1',
    storeId: 'store_1',
    customerId: 'cust_1',
    date: '2026-08-01',
    type: 'DEBIT',
    amount: 2500,
    note: 'Previous Kirana Udhaar Balance',
    balanceAfter: 2500,
  },
  {
    id: 'kh_2',
    storeId: 'store_1',
    customerId: 'cust_2',
    date: '2026-08-07',
    type: 'DEBIT',
    amount: 850,
    note: 'Order #KS1024 (Online Udhaar)',
    balanceAfter: 850,
  },
];
let salesRecords: SaleRecord[] = [
  {
    id: 'sale_1',
    storeId: 'store_1',
    channel: 'COUNTER',
    amount: 25000,
    paymentMethod: 'COD',
    date: '2026-08-08',
    itemCount: 45,
  },
  {
    id: 'sale_2',
    storeId: 'store_1',
    channel: 'ONLINE',
    amount: 14580,
    paymentMethod: 'UPI',
    date: '2026-08-08',
    itemCount: 28,
  },
];

// Helper: Process Delivery Actions ONCE (Idempotent Transaction)
const deliveredOrdersProcessed = new Set<string>();

function processOrderDelivery(order: Order) {
  if (deliveredOrdersProcessed.has(order.id)) return;
  deliveredOrdersProcessed.add(order.id);

  // 1. Reduce Stock Inventory
  order.items.forEach((item) => {
    const prod = products.find((p) => p.id === item.productId);
    if (prod) {
      prod.stock = Math.max(0, prod.stock - item.quantity);
    }
  });

  // 2. Update Customer Spend Stats & Udhaar Khata if Udhaar
  const cust = customers.find((c) => c.id === order.customerId || c.mobile === order.customerPhone);
  if (cust) {
    cust.totalOrders += 1;
    cust.totalSpent += order.totalAmount;
    cust.lastOrderDate = new Date().toISOString().split('T')[0];

    if (order.paymentMethod === 'UDHAAR') {
      const newBal = cust.udhaarBalance + order.totalAmount;
      cust.udhaarBalance = newBal;

      khataEntries.push({
        id: `kh_${Date.now()}`,
        storeId: order.storeId,
        customerId: cust.id,
        date: new Date().toISOString().split('T')[0],
        type: 'DEBIT',
        amount: order.totalAmount,
        orderId: order.id,
        note: `Online Order #${order.id} Udhaar`,
        balanceAfter: newBal,
      });
      order.paymentStatus = 'UDHAAR_POSTED';
    } else {
      order.paymentStatus = 'COLLECTED';
    }
  }

  // 3. Record Sale Entry
  salesRecords.push({
    id: `sale_${Date.now()}`,
    storeId: order.storeId,
    orderId: order.id,
    channel: 'ONLINE',
    amount: order.totalAmount,
    paymentMethod: order.paymentMethod,
    date: new Date().toISOString().split('T')[0],
    itemCount: order.items.reduce((sum, i) => sum + i.quantity, 0),
  });
}

// --- API ENDPOINTS ---

// 1. STORES API
app.get('/api/stores', (req, res) => {
  res.json(stores);
});

app.get('/api/stores/by-code/:code', (req, res) => {
  const store = stores.find((s) => s.code.toUpperCase() === req.params.code.toUpperCase());
  if (!store) return res.status(404).json({ error: 'Shop Code not found' });
  res.json(store);
});

app.get('/api/stores/:id', (req, res) => {
  const store = stores.find((s) => s.id === req.params.id);
  if (!store) return res.status(404).json({ error: 'Store not found' });
  res.json(store);
});

app.put('/api/stores/:id', (req, res) => {
  const index = stores.findIndex((s) => s.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Store not found' });
  stores[index] = { ...stores[index], ...req.body };
  res.json(stores[index]);
});

// 2. PRODUCTS API
app.get('/api/products', (req, res) => {
  const { storeId } = req.query;
  let list = products;
  if (storeId) list = list.filter((p) => p.storeId === storeId);
  res.json(list);
});

app.post('/api/products', (req, res) => {
  const newProduct: Product = {
    id: `p_${Date.now()}`,
    ...req.body,
  };
  products.unshift(newProduct);
  res.status(201).json(newProduct);
});

app.put('/api/products/:id', (req, res) => {
  const index = products.findIndex((p) => p.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Product not found' });
  products[index] = { ...products[index], ...req.body };
  res.json(products[index]);
});

// 3. CUSTOMERS & KHATA API
app.get('/api/customers', (req, res) => {
  const { storeId } = req.query;
  let list = customers;
  if (storeId) list = list.filter((c) => c.storeId === storeId);
  res.json(list);
});

app.post('/api/customers', (req, res) => {
  const existing = customers.find(
    (c) => c.storeId === req.body.storeId && c.mobile === req.body.mobile
  );
  if (existing) return res.json(existing);

  const newCust: CustomerProfile = {
    id: `cust_${Date.now()}`,
    storeId: req.body.storeId,
    name: req.body.name,
    mobile: req.body.mobile,
    addresses: req.body.addresses || [],
    allowOnlineUdhaar: false,
    udhaarBalance: 0,
    totalOrders: 0,
    totalSpent: 0,
  };
  customers.push(newCust);
  res.status(201).json(newCust);
});

app.put('/api/customers/:id', (req, res) => {
  const index = customers.findIndex((c) => c.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Customer not found' });
  customers[index] = { ...customers[index], ...req.body };
  res.json(customers[index]);
});

app.get('/api/khata', (req, res) => {
  const { storeId, customerId } = req.query;
  let list = khataEntries;
  if (storeId) list = list.filter((k) => k.storeId === storeId);
  if (customerId) list = list.filter((k) => k.customerId === customerId);
  res.json(list);
});

app.post('/api/khata/payment', (req, res) => {
  const { storeId, customerId, amount, note } = req.body;
  const cust = customers.find((c) => c.id === customerId);
  if (!cust) return res.status(404).json({ error: 'Customer not found' });

  const newBal = Math.max(0, cust.udhaarBalance - amount);
  cust.udhaarBalance = newBal;

  const entry: KhataEntry = {
    id: `kh_${Date.now()}`,
    storeId,
    customerId,
    date: new Date().toISOString().split('T')[0],
    type: 'CREDIT',
    amount,
    note: note || 'Khata Payment Received',
    balanceAfter: newBal,
  };
  khataEntries.push(entry);
  res.json({ customer: cust, entry });
});

// 4. ORDERS API
app.get('/api/orders', (req, res) => {
  const { storeId, customerId, phone } = req.query;
  let list = orders;
  if (storeId) list = list.filter((o) => o.storeId === storeId);
  if (customerId) list = list.filter((o) => o.customerId === customerId);
  if (phone) list = list.filter((o) => o.customerPhone === phone);
  res.json(list);
});

app.post('/api/orders', (req, res) => {
  const orderData = req.body;
  
  // Ensure customer profile exists
  let cust = customers.find(
    (c) => c.storeId === orderData.storeId && c.mobile === orderData.customerPhone
  );
  if (!cust) {
    cust = {
      id: `cust_${Date.now()}`,
      storeId: orderData.storeId,
      name: orderData.customerName,
      mobile: orderData.customerPhone,
      addresses: [orderData.deliveryAddress],
      allowOnlineUdhaar: false,
      udhaarBalance: 0,
      totalOrders: 0,
      totalSpent: 0,
    };
    customers.push(cust);
  }

  const orderNum = `KS${1026 + orders.length}`;
  const newOrder: Order = {
    ...orderData,
    id: orderNum,
    customerId: cust.id,
    status: 'NEW',
    paymentStatus: orderData.paymentMethod === 'UDHAAR' ? 'PENDING' : 'PENDING',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  orders.unshift(newOrder);
  res.status(201).json(newOrder);
});

app.put('/api/orders/:id/status', (req, res) => {
  const { status, rejectionReason, deliveryBoyId, deliveryBoyName, deliveryBoyPhone } = req.body;
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ error: 'Order not found' });

  order.status = status as OrderStatus;
  order.updatedAt = new Date().toISOString();

  if (rejectionReason) order.rejectionReason = rejectionReason;
  if (deliveryBoyId) {
    order.deliveryBoyId = deliveryBoyId;
    order.deliveryBoyName = deliveryBoyName;
    order.deliveryBoyPhone = deliveryBoyPhone;
  }

  // If status marked DELIVERED, trigger automated stock reduction & sales/khata entries
  if (status === 'DELIVERED') {
    processOrderDelivery(order);
  }

  res.json(order);
});

app.put('/api/orders/:id/modify-items', (req, res) => {
  const { items, subtotal, discount, deliveryCharge, totalAmount } = req.body;
  const order = orders.find((o) => o.id === req.params.id);
  if (!order) return res.status(404).json({ error: 'Order not found' });

  order.items = items;
  order.subtotal = subtotal;
  order.discount = discount;
  order.deliveryCharge = deliveryCharge;
  order.totalAmount = totalAmount;
  order.modifiedByMerchant = true;
  order.updatedAt = new Date().toISOString();

  res.json(order);
});

// 5. DELIVERY STAFF API
app.get('/api/delivery-staff', (req, res) => {
  const { storeId } = req.query;
  let list = deliveryStaff;
  if (storeId) list = list.filter((d) => d.storeId === storeId);
  res.json(list);
});

app.post('/api/delivery-staff', (req, res) => {
  const staff: DeliveryStaff = {
    id: `db_${Date.now()}`,
    ...req.body,
    isActive: true,
    assignedOrdersCount: 0,
    cashCollectedToday: 0,
  };
  deliveryStaff.push(staff);
  res.status(201).json(staff);
});

// 6. REPORTS & SALES SUMMARY
app.get('/api/reports', (req, res) => {
  const { storeId } = req.query;
  const storeSales = salesRecords.filter((s) => s.storeId === storeId);
  const counterTotal = storeSales
    .filter((s) => s.channel === 'COUNTER')
    .reduce((sum, s) => sum + s.amount, 0);
  const onlineTotal = storeSales
    .filter((s) => s.channel === 'ONLINE')
    .reduce((sum, s) => sum + s.amount, 0);

  res.json({
    counterSales: counterTotal,
    onlineSales: onlineTotal,
    totalSales: counterTotal + onlineTotal,
    salesRecords: storeSales,
  });
});

// VITE MIDDLEWARE SETUP
async function startServer() {
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Kirana Saarthi server running on http://localhost:${PORT}`);
  });
}

startServer();
