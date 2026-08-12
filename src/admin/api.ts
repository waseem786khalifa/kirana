export type AdminStore = {
  id: number;
  code: string;
  name: string;
  owner_name: string;
  phone: string;
  address: string;
  landmark: string;
  pincode: string;
  is_open: boolean;
  description: string;
  opening_time: string;
  closing_time: string;
  delivery_settings: {
    delivery_available: boolean;
    radius_km: number;
    min_order: number;
    free_delivery_above: number;
    delivery_charge: number;
    expected_delivery_time: string;
    scheduled_delivery_enabled: boolean;
  };
  payment_settings: {
    cod_enabled: boolean;
    upi_enabled: boolean;
    pay_at_shop_enabled: boolean;
    online_udhaar_enabled: boolean;
  };
  categories: string[];
  product_count: number;
  max_saving: number;
};

export type AdminOrderStatus =
  | 'NEW'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'CANCELLED';

export type AdminOrder = {
  id: number;
  order_number: string;
  store_id: number;
  customer_name: string;
  customer_phone: string;
  total_amount: number;
  payment_method: string;
  payment_status: string;
  status: AdminOrderStatus;
  rejection_reason?: string | null;
  delivery_staff_id?: number | null;
  delivery_staff_name?: string | null;
  created_at: string;
};

export type AdminProduct = {
  id: number;
  store_id: number;
  name_en: string;
  category: string;
  pack_size: string;
  mrp: number;
  selling_price: number;
  stock: number;
  image: string;
  available_for_online: boolean;
  is_hidden: boolean;
};

export type AdminCustomer = {
  id: number;
  store_id: number;
  name: string;
  mobile: string;
  allow_online_udhaar: boolean;
  udhaar_balance: number;
  total_orders: number;
  total_spent: number;
  last_order_date?: string | null;
};

export type AdminRider = {
  id: number;
  store_id: number;
  name: string;
  mobile: string;
  is_active: boolean;
  assigned_orders_count: number;
  cash_collected_today: number;
};

export type AdminProductUpdate = {
  stock: number;
  mrp: number;
  selling_price: number;
  available_for_online: boolean;
  is_hidden: boolean;
};

export type AdminOrderStatusUpdate = {
  status: AdminOrderStatus;
  rejection_reason?: string;
  delivery_staff_id?: number;
};

export type AdminOverview = {
  stores: { total: number; open: number; delivery_enabled: number };
  orders: { total: number; new: number; active: number; delivered: number; cancelled: number };
  customers: { total: number; udhaar_outstanding: number };
  products: { total: number; online: number; out_of_stock: number };
  delivery_staff: { total: number; active: number; cash_collected: number };
  revenue: { online_sales: number; today_sales: number };
  recent_orders: AdminOrder[];
};

type AdminOverviewResponse = {
  generated_at: string;
  stores: AdminOverview['stores'];
  products: AdminOverview['products'];
  people: { customers: number; riders: number; active_riders: number };
  orders: { total: number; today: number; new: number; delivered: number; cancelled: number };
  finance: { sales_today: number; sales_month: number; outstanding_udhaar: number; rider_cod_recorded: number };
};

export type AdminSession = {
  token: string;
  expires_at: string;
  user: { id: number; email: string; name: string; role: string };
};

export type AdminAuditLog = {
  id: number;
  action: string;
  resource_type: string;
  resource_id?: number | null;
  request_id: string;
  created_at: string;
};

const configuredBase = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim();
export const API_BASE_URL = (configuredBase || '/admin-api').replace(/\/$/, '');

export class AdminApiError extends Error {
  constructor(message: string, public status = 0, public code = 'REQUEST_FAILED') {
    super(message);
  }
}

type ApiEnvelope<T> = { data: T; meta?: Record<string, unknown> };

async function request<T>(path: string, options: RequestInit = {}, token?: string): Promise<T> {
  return (await requestEnvelope<T>(path, options, token)).data;
}

async function requestEnvelope<T>(path: string, options: RequestInit = {}, token?: string): Promise<ApiEnvelope<T>> {
  const headers = new Headers(options.headers);
  headers.set('Accept', 'application/json');
  if (options.body) headers.set('Content-Type', 'application/json');
  if (token) headers.set('Authorization', `Bearer ${token}`);

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, { ...options, headers });
  } catch {
    throw new AdminApiError('Backend se connection nahi ho pa raha. API URL aur server check karein.');
  }

  let payload: ApiEnvelope<T> | { error?: { code?: string; message?: string } };
  try {
    payload = await response.json();
  } catch {
    throw new AdminApiError('Server ne valid JSON response nahi diya.', response.status, 'INVALID_RESPONSE');
  }

  if (!response.ok) {
    const error = 'error' in payload ? payload.error : undefined;
    throw new AdminApiError(error?.message || 'Request complete nahi hui.', response.status, error?.code);
  }
  if (!('data' in payload)) throw new AdminApiError('Server response envelope invalid hai.', response.status, 'INVALID_RESPONSE');
  return payload as ApiEnvelope<T>;
}

async function requestAll<T>(path: string, token: string): Promise<T[]> {
  const items: T[] = [];
  const pageSize = 200;
  let offset = 0;
  while (true) {
    const separator = path.includes('?') ? '&' : '?';
    const page = await requestEnvelope<T[]>(`${path}${separator}limit=${pageSize}&offset=${offset}`, {}, token);
    items.push(...page.data);
    const total = Number(page.meta?.total ?? items.length);
    if (!page.data.length || items.length >= total) return items;
    offset += page.data.length;
  }
}

export const adminApi = {
  login: async (email: string, password: string) => {
    const response = await request<Omit<AdminSession, 'user'> & { admin: AdminSession['user'] }>('/admin/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) });
    return { token: response.token, expires_at: response.expires_at, user: response.admin };
  },
  me: (token: string) => request<AdminSession['user']>('/admin/auth/me', {}, token),
  logout: (token: string) => request<{ logged_out: boolean }>('/admin/auth/logout', { method: 'POST' }, token),
  overview: async (token: string) => {
    const [summary, recentOrders] = await Promise.all([
      request<AdminOverviewResponse>('/admin/overview', {}, token),
      request<AdminOrder[]>('/admin/orders?limit=8', {}, token),
    ]);
    return {
      stores: summary.stores,
      products: summary.products,
      orders: {
        total: summary.orders.total,
        new: summary.orders.new,
        active: Math.max(0, summary.orders.total - summary.orders.delivered - summary.orders.cancelled),
        delivered: summary.orders.delivered,
        cancelled: summary.orders.cancelled,
      },
      customers: { total: summary.people.customers, udhaar_outstanding: summary.finance.outstanding_udhaar },
      delivery_staff: { total: summary.people.riders, active: summary.people.active_riders, cash_collected: summary.finance.rider_cod_recorded },
      revenue: { online_sales: summary.finance.sales_month, today_sales: summary.finance.sales_today },
      recent_orders: recentOrders,
    } satisfies AdminOverview;
  },
  stores: (token: string) => requestAll<AdminStore>('/admin/stores', token),
  orders: (token: string) => requestAll<AdminOrder>('/admin/orders', token),
  products: (token: string) => requestAll<AdminProduct>('/admin/products', token),
  customers: (token: string) => requestAll<AdminCustomer>('/admin/customers', token),
  riders: (token: string) => requestAll<AdminRider>('/admin/delivery-staff', token),
  auditLogs: (token: string) => request<AdminAuditLog[]>('/admin/audit-logs?limit=50', {}, token),
  updateStore: (token: string, id: number, body: Record<string, unknown>) =>
    request<AdminStore>(`/admin/stores/${id}`, { method: 'PATCH', body: JSON.stringify(body) }, token),
  createStore: (token: string, body: Record<string, unknown>) =>
    request<AdminStore>('/admin/stores', { method: 'POST', body: JSON.stringify(body) }, token),
  updateProduct: (token: string, id: number, body: Partial<AdminProductUpdate>) =>
    request<AdminProduct>(`/admin/products/${id}`, { method: 'PATCH', body: JSON.stringify(body) }, token),
  updateCustomer: (token: string, id: number, allowOnlineUdhaar: boolean) =>
    request<AdminCustomer>(`/admin/customers/${id}`, { method: 'PATCH', body: JSON.stringify({ allow_online_udhaar: allowOnlineUdhaar }) }, token),
  updateOrderStatus: (token: string, id: number, body: AdminOrderStatusUpdate) =>
    request<AdminOrder>(`/admin/orders/${id}/status`, { method: 'PATCH', body: JSON.stringify(body) }, token),
  updateRider: (token: string, id: number, body: Record<string, unknown>) =>
    request<AdminRider>(`/admin/delivery-staff/${id}`, { method: 'PATCH', body: JSON.stringify(body) }, token),
  createRider: (token: string, body: Record<string, unknown>) =>
    request<AdminRider>('/admin/delivery-staff', { method: 'POST', body: JSON.stringify(body) }, token),
  resetRiderPin: (token: string, id: number, pin: string) =>
    request<{ staff: AdminRider; pin_reset: boolean }>(`/admin/delivery-staff/${id}/reset-pin`, { method: 'POST', body: JSON.stringify({ pin }) }, token),
};
