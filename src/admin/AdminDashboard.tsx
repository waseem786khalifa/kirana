import { useCallback, useEffect, useMemo, useState, type FormEvent, type ReactNode } from 'react';
import {
  AlertCircle, Boxes, ChevronRight, CircleDollarSign, ClipboardList,
  LayoutDashboard, Loader2, LogOut, Menu, Package, Pencil, RefreshCw, Search, ShieldCheck,
  ShoppingBag, Store, Truck, UserRound, UsersRound, X,
} from 'lucide-react';
import {
  AdminApiError, adminApi, type AdminCustomer, type AdminOrder, type AdminOverview,
  type AdminOrderStatus, type AdminOrderStatusUpdate, type AdminProduct, type AdminProductUpdate,
  type AdminRider, type AdminSession, type AdminStore, type AdminAuditLog,
} from './api';

type Tab = 'overview' | 'stores' | 'orders' | 'products' | 'customers' | 'riders';
type Props = { session: AdminSession; onLogout: () => void };

const tabs: { id: Tab; label: string; icon: typeof Store }[] = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard },
  { id: 'stores', label: 'Stores', icon: Store },
  { id: 'orders', label: 'Orders', icon: ClipboardList },
  { id: 'products', label: 'Products', icon: Boxes },
  { id: 'customers', label: 'Customers', icon: UsersRound },
  { id: 'riders', label: 'Delivery staff', icon: Truck },
];

const money = (value: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(value || 0);
const date = (value?: string | null) => value ? new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value.replace(' ', 'T'))) : '-';
const ORDER_TRANSITIONS: Record<AdminOrderStatus, AdminOrderStatus[]> = {
  NEW: ['ACCEPTED', 'CANCELLED'],
  ACCEPTED: ['PREPARING', 'CANCELLED'],
  PREPARING: ['READY', 'CANCELLED'],
  READY: ['OUT_FOR_DELIVERY', 'CANCELLED'],
  OUT_FOR_DELIVERY: ['DELIVERED'],
  DELIVERED: [],
  CANCELLED: [],
};
const ORDER_STATUS_LABELS: Record<AdminOrderStatus, string> = {
  NEW: 'New', ACCEPTED: 'Accept order', PREPARING: 'Start preparing', READY: 'Mark ready',
  OUT_FOR_DELIVERY: 'Dispatch for delivery', DELIVERED: 'Mark delivered', CANCELLED: 'Cancel order',
};

function statusTone(status: string) {
  if (['OPEN', 'ACTIVE', 'DELIVERED', 'COLLECTED', 'ONLINE'].includes(status)) return 'bg-emerald-50 text-emerald-700 border-emerald-200';
  if (['CANCELLED', 'INACTIVE', 'HIDDEN', 'OUT OF STOCK'].includes(status)) return 'bg-red-50 text-red-700 border-red-200';
  if (['NEW', 'PENDING', 'READY'].includes(status)) return 'bg-amber-50 text-amber-700 border-amber-200';
  return 'bg-blue-50 text-blue-700 border-blue-200';
}

function Badge({ children }: { children: string }) {
  return <span className={`inline-flex items-center rounded-full border px-2.5 py-1 text-[11px] font-black tracking-wide ${statusTone(children)}`}>{children}</span>;
}

function Metric({ label, value, hint, icon: Icon, tone = 'emerald' }: { label: string; value: string; hint: string; icon: typeof Store; tone?: string }) {
  const tones: Record<string, string> = { emerald: 'bg-emerald-100 text-emerald-800', blue: 'bg-blue-100 text-blue-700', amber: 'bg-amber-100 text-amber-700', violet: 'bg-violet-100 text-violet-700' };
  return <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
    <div className="flex items-start justify-between"><div><p className="text-sm font-bold text-slate-500">{label}</p><p className="mt-2 text-3xl font-black tracking-tight text-slate-950">{value}</p></div><span className={`grid w-11 h-11 place-items-center rounded-xl ${tones[tone]}`}><Icon className="w-5 h-5" /></span></div>
    <p className="mt-4 text-xs font-semibold text-slate-500">{hint}</p>
  </article>;
}

function Empty({ label }: { label: string }) { return <div className="py-16 text-center text-sm text-slate-500">{label}</div>; }

export function AdminDashboard({ session, onLogout }: Props) {
  const [tab, setTab] = useState<Tab>('overview');
  const [mobileNav, setMobileNav] = useState(false);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [overview, setOverview] = useState<AdminOverview | null>(null);
  const [stores, setStores] = useState<AdminStore[]>([]);
  const [orders, setOrders] = useState<AdminOrder[]>([]);
  const [products, setProducts] = useState<AdminProduct[]>([]);
  const [customers, setCustomers] = useState<AdminCustomer[]>([]);
  const [riders, setRiders] = useState<AdminRider[]>([]);
  const [auditLogs, setAuditLogs] = useState<AdminAuditLog[]>([]);
  const [busyKey, setBusyKey] = useState('');
  const [showStoreForm, setShowStoreForm] = useState(false);
  const [resetPinRider, setResetPinRider] = useState<AdminRider | null>(null);
  const [showRiderForm, setShowRiderForm] = useState(false);
  const [productToEdit, setProductToEdit] = useState<AdminProduct | null>(null);
  const [orderToManage, setOrderToManage] = useState<AdminOrder | null>(null);

  const load = useCallback(async (refresh = false) => {
    refresh ? setRefreshing(true) : setLoading(true);
    setError('');
    try {
      const [nextOverview, nextStores, nextOrders, nextProducts, nextCustomers, nextRiders, nextAuditLogs] = await Promise.all([
        adminApi.overview(session.token), adminApi.stores(session.token), adminApi.orders(session.token),
        adminApi.products(session.token), adminApi.customers(session.token), adminApi.riders(session.token), adminApi.auditLogs(session.token),
      ]);
      setOverview(nextOverview); setStores(nextStores); setOrders(nextOrders); setProducts(nextProducts); setCustomers(nextCustomers); setRiders(nextRiders); setAuditLogs(nextAuditLogs);
    } catch (reason) {
      const apiError = reason instanceof AdminApiError ? reason : new AdminApiError('Dashboard load nahi hua.');
      if (apiError.status === 401) onLogout(); else setError(apiError.message);
    } finally { setLoading(false); setRefreshing(false); }
  }, [onLogout, session.token]);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => { setQuery(''); }, [tab]);

  async function action(key: string, callback: () => Promise<unknown>) {
    if (busyKey) return;
    setBusyKey(key); setError('');
    try { await callback(); await load(true); }
    catch (reason) {
      const apiError = reason instanceof AdminApiError ? reason : new AdminApiError('Action complete nahi hui.');
      if (apiError.status === 401) onLogout(); else setError(apiError.message);
    }
    finally { setBusyKey(''); }
  }

  const storeNames = useMemo(() => new Map(stores.map((store) => [store.id, store.name])), [stores]);
  const needle = query.trim().toLowerCase();
  const matches = (...values: unknown[]) => !needle || values.some((value) => String(value ?? '').toLowerCase().includes(needle));

  const content = loading ? <div className="min-h-[50vh] grid place-items-center"><div className="text-center"><Loader2 className="w-8 h-8 animate-spin text-emerald-700 mx-auto" /><p className="mt-3 text-sm text-slate-500">Live platform data load ho raha hai...</p></div></div>
    : tab === 'overview' ? <Overview overview={overview} stores={stores} auditLogs={auditLogs} onNavigate={setTab} />
    : tab === 'stores' ? <><div className="mb-4 flex justify-end"><button onClick={() => setShowStoreForm(true)} className="rounded-xl bg-emerald-800 px-4 py-2.5 text-sm font-black text-white hover:bg-emerald-700">+ Add new store</button></div><Stores rows={stores.filter((x) => matches(x.name, x.code, x.owner_name, x.pincode))} busyKey={busyKey} onToggle={(store) => action(`store-${store.id}`, () => adminApi.updateStore(session.token, store.id, { is_open: !store.is_open }))} /></>
    : tab === 'orders' ? <Orders rows={orders.filter((x) => matches(x.order_number, x.customer_name, x.customer_phone, x.status, storeNames.get(x.store_id)))} storeNames={storeNames} onManage={(order) => { setError(''); setOrderToManage(order); }} />
    : tab === 'products' ? <Products rows={products.filter((x) => matches(x.name_en, x.category, storeNames.get(x.store_id)))} storeNames={storeNames} onEdit={(product) => { setError(''); setProductToEdit(product); }} />
    : tab === 'customers' ? <Customers rows={customers.filter((x) => matches(x.name, x.mobile, storeNames.get(x.store_id)))} storeNames={storeNames} busyKey={busyKey} onToggleUdhaar={(customer) => action(`customer-udhaar-${customer.id}`, () => adminApi.updateCustomer(session.token, customer.id, !customer.allow_online_udhaar))} />
    : <><div className="mb-4 flex justify-end"><button onClick={() => setShowRiderForm(true)} className="rounded-xl bg-emerald-800 px-4 py-2.5 text-sm font-black text-white hover:bg-emerald-700">+ Add delivery staff</button></div><Riders rows={riders.filter((x) => matches(x.name, x.mobile, storeNames.get(x.store_id)))} storeNames={storeNames} busyKey={busyKey} onToggle={(rider) => action(`rider-${rider.id}`, () => adminApi.updateRider(session.token, rider.id, { is_active: !rider.is_active }))} onResetPin={setResetPinRider} /></>;

  return <div className="min-h-screen bg-[#f4f6f3] text-slate-900 lg:grid lg:grid-cols-[260px_1fr]">
    <aside className={`fixed inset-y-0 left-0 z-50 w-[280px] bg-[#073d2b] text-white px-4 py-5 transition-transform lg:sticky lg:top-0 lg:h-screen lg:w-auto ${mobileNav ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}>
      <div className="flex items-center justify-between px-2"><div className="flex items-center gap-3"><span className="grid w-10 h-10 place-items-center rounded-xl bg-emerald-400 text-emerald-950"><ShoppingBag className="w-5 h-5" /></span><div><p className="font-black">Kirana Saarthi</p><p className="text-[11px] text-emerald-200">Super Admin</p></div></div><button className="lg:hidden p-2" onClick={() => setMobileNav(false)}><X className="w-5 h-5" /></button></div>
      <nav className="mt-9 space-y-1">{tabs.map(({ id, label, icon: Icon }) => <button key={id} onClick={() => { setTab(id); setMobileNav(false); }} className={`w-full flex items-center gap-3 rounded-xl px-3 py-3 text-sm font-bold transition ${tab === id ? 'bg-white text-emerald-950 shadow' : 'text-emerald-100 hover:bg-white/10'}`}><Icon className="w-5 h-5" />{label}{id === 'orders' && overview?.orders.new ? <span className="ml-auto rounded-full bg-red-500 px-2 py-0.5 text-[10px] text-white">{overview.orders.new}</span> : null}</button>)}</nav>
      <div className="absolute left-4 right-4 bottom-5 rounded-2xl border border-white/10 bg-white/5 p-3"><div className="flex items-center gap-3"><span className="grid w-10 h-10 place-items-center rounded-xl bg-emerald-200 text-emerald-900 font-black">W</span><div className="min-w-0"><p className="truncate text-sm font-bold">{session.user.name}</p><p className="truncate text-[10px] text-emerald-200">{session.user.email}</p></div></div><button onClick={onLogout} className="mt-3 flex w-full items-center justify-center gap-2 rounded-lg bg-white/10 py-2 text-xs font-bold hover:bg-white/20"><LogOut className="w-4 h-4" /> Secure logout</button></div>
    </aside>
    {mobileNav && <button className="fixed inset-0 z-40 bg-slate-950/50 lg:hidden" onClick={() => setMobileNav(false)} />}

    <main className="min-w-0">
      <header className="sticky top-0 z-30 border-b border-slate-200/80 bg-white/90 backdrop-blur-xl"><div className="flex h-17 items-center gap-3 px-4 sm:px-6 xl:px-9"><button onClick={() => setMobileNav(true)} className="grid w-10 h-10 place-items-center rounded-xl border border-slate-200 lg:hidden"><Menu className="w-5 h-5" /></button><div><p className="text-lg font-black capitalize">{tabs.find((item) => item.id === tab)?.label}</p><p className="hidden sm:block text-xs text-slate-500">Live backend  /  All three applications</p></div><div className="ml-auto flex items-center gap-2"><span className="hidden md:inline-flex items-center gap-2 rounded-full bg-emerald-50 px-3 py-2 text-xs font-black text-emerald-700"><span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> System connected</span><button onClick={() => load(true)} disabled={refreshing} className="grid w-10 h-10 place-items-center rounded-xl border border-slate-200 bg-white hover:bg-slate-50"><RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} /></button></div></div></header>
      <div className="p-4 sm:p-6 xl:p-9 max-w-[1600px] mx-auto">
        {tab !== 'overview' && <div className="mb-5 flex flex-wrap items-center gap-3"><label className="relative min-w-[260px] flex-1 max-w-xl"><Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder={`Search ${tabs.find((item) => item.id === tab)?.label.toLowerCase()}...`} className="w-full h-11 rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm outline-none focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100" /></label><span className="text-xs font-bold text-slate-500">Data updates dashboard aur apps dono mein reflect honge</span></div>}
        {error && <div role="alert" className="mb-5 flex items-start gap-3 rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700"><AlertCircle className="w-5 h-5 shrink-0" /><span className="flex-1">{error}</span><button onClick={() => setError('')}><X className="w-4 h-4" /></button></div>}
        {content}
      </div>
    </main>
    {showStoreForm && <CreateStoreDialog busy={busyKey === 'create-store'} onClose={() => setShowStoreForm(false)} onSubmit={(body) => action('create-store', async () => { await adminApi.createStore(session.token, body); setShowStoreForm(false); })} />}
    {resetPinRider && <ResetPinDialog rider={resetPinRider} busy={busyKey === `reset-pin-${resetPinRider.id}`} onClose={() => setResetPinRider(null)} onSubmit={(pin) => action(`reset-pin-${resetPinRider.id}`, async () => { await adminApi.resetRiderPin(session.token, resetPinRider.id, pin); setResetPinRider(null); })} />}
    {showRiderForm && <CreateRiderDialog stores={stores} busy={busyKey === 'create-rider'} onClose={() => setShowRiderForm(false)} onSubmit={(body) => action('create-rider', async () => { await adminApi.createRider(session.token, body); setShowRiderForm(false); })} />}
    {productToEdit && <ProductEditDialog product={productToEdit} busy={busyKey === `product-edit-${productToEdit.id}`} error={error} onClose={() => setProductToEdit(null)} onSubmit={(body) => action(`product-edit-${productToEdit.id}`, async () => { await adminApi.updateProduct(session.token, productToEdit.id, body); setProductToEdit(null); })} />}
    {orderToManage && <OrderWorkflowDialog order={orderToManage} riders={riders} busy={busyKey === `order-workflow-${orderToManage.id}`} error={error} onClose={() => setOrderToManage(null)} onSubmit={(body) => action(`order-workflow-${orderToManage.id}`, async () => { await adminApi.updateOrderStatus(session.token, orderToManage.id, body); setOrderToManage(null); })} />}
  </div>;
}

function ProductEditDialog({ product, busy, error, onClose, onSubmit }: {
  product: AdminProduct;
  busy: boolean;
  error: string;
  onClose: () => void;
  onSubmit: (body: AdminProductUpdate) => void;
}) {
  const [stock, setStock] = useState(String(product.stock));
  const [mrp, setMrp] = useState(String(product.mrp));
  const [sellingPrice, setSellingPrice] = useState(String(product.selling_price));
  const [availableOnline, setAvailableOnline] = useState(product.is_hidden ? false : product.available_for_online);
  const [hidden, setHidden] = useState(product.is_hidden);
  const [validation, setValidation] = useState('');

  function submit(event: FormEvent) {
    event.preventDefault();
    const nextStock = Number(stock);
    const nextMrp = Number(mrp);
    const nextSellingPrice = Number(sellingPrice);
    if (!Number.isInteger(nextStock) || nextStock < 0) {
      setValidation('Stock zero ya positive whole number hona chahiye.');
      return;
    }
    if (!Number.isFinite(nextMrp) || nextMrp <= 0 || !Number.isFinite(nextSellingPrice) || nextSellingPrice <= 0) {
      setValidation('MRP aur selling price zero se zyada honi chahiye.');
      return;
    }
    if (nextSellingPrice > nextMrp) {
      setValidation('Selling price MRP se zyada nahi ho sakti.');
      return;
    }
    setValidation('');
    onSubmit({ stock: nextStock, mrp: nextMrp, selling_price: nextSellingPrice, available_for_online: availableOnline, is_hidden: hidden });
  }

  return <div role="dialog" aria-modal="true" aria-labelledby="product-edit-title" className="fixed inset-0 z-[70] grid place-items-center overflow-y-auto bg-slate-950/60 p-4">
    <form onSubmit={submit} className="my-auto w-full max-w-xl rounded-3xl bg-white p-5 shadow-2xl sm:p-7">
      <div className="flex items-start justify-between gap-4"><div><p className="text-xs font-black uppercase tracking-wider text-emerald-700">Product control</p><h2 id="product-edit-title" className="mt-1 text-xl font-black">Edit {product.name_en}</h2><p className="mt-1 text-sm text-slate-500">{product.category}  /  {product.pack_size}</p></div><button type="button" disabled={busy} onClick={onClose} aria-label="Close product editor" className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-slate-100 disabled:opacity-50"><X className="h-5 w-5" /></button></div>
      {(validation || error) && <div role="alert" className="mt-5 flex gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-sm font-semibold text-red-700"><AlertCircle className="h-5 w-5 shrink-0" />{validation || error}</div>}
      <div className="mt-6 grid gap-4 sm:grid-cols-3">
        <label className="text-xs font-black text-slate-600">Stock<input autoFocus required min="0" step="1" inputMode="numeric" type="number" value={stock} onChange={(event) => setStock(event.target.value)} className="mt-2 h-12 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100" /></label>
        <label className="text-xs font-black text-slate-600">MRP (Rs )<input required min="0.01" step="0.01" inputMode="decimal" type="number" value={mrp} onChange={(event) => setMrp(event.target.value)} className="mt-2 h-12 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100" /></label>
        <label className="text-xs font-black text-slate-600">Selling price (Rs )<input required min="0.01" step="0.01" inputMode="decimal" type="number" value={sellingPrice} onChange={(event) => setSellingPrice(event.target.value)} className="mt-2 h-12 w-full rounded-xl border border-slate-200 px-3 text-sm outline-none focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100" /></label>
      </div>
      <div className="mt-5 grid gap-3 sm:grid-cols-2">
        <label className={`flex cursor-pointer items-center gap-3 rounded-2xl border p-4 ${availableOnline ? 'border-emerald-300 bg-emerald-50' : 'border-slate-200'}`}><input type="checkbox" checked={availableOnline} onChange={(event) => { setAvailableOnline(event.target.checked); if (event.target.checked) setHidden(false); }} className="h-5 w-5 accent-emerald-700" /><span><span className="block text-sm font-black">Available online</span><span className="mt-0.5 block text-xs text-slate-500">Customer app par order kiya ja sakta hai</span></span></label>
        <label className={`flex cursor-pointer items-center gap-3 rounded-2xl border p-4 ${hidden ? 'border-red-200 bg-red-50' : 'border-slate-200'}`}><input type="checkbox" checked={hidden} onChange={(event) => { setHidden(event.target.checked); if (event.target.checked) setAvailableOnline(false); }} className="h-5 w-5 accent-red-600" /><span><span className="block text-sm font-black">Hide from catalogue</span><span className="mt-0.5 block text-xs text-slate-500">All online catalogue views se hide karein</span></span></label>
      </div>
      <div className="mt-7 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end"><button type="button" disabled={busy} onClick={onClose} className="rounded-xl border border-slate-200 px-4 py-3 text-sm font-black disabled:opacity-50">Cancel</button><button disabled={busy} className="rounded-xl bg-emerald-800 px-5 py-3 text-sm font-black text-white disabled:opacity-50">{busy ? 'Saving changes...' : 'Save product changes'}</button></div>
    </form>
  </div>;
}

function OrderWorkflowDialog({ order, riders, busy, error, onClose, onSubmit }: {
  order: AdminOrder;
  riders: AdminRider[];
  busy: boolean;
  error: string;
  onClose: () => void;
  onSubmit: (body: AdminOrderStatusUpdate) => void;
}) {
  const eligibleRiders = riders.filter((rider) => rider.store_id === order.store_id && rider.is_active);
  const transitions = ORDER_TRANSITIONS[order.status];
  const choices: AdminOrderStatus[] = order.status === 'READY' ? ['READY', ...transitions] : transitions;
  const initialStatus = order.status === 'READY' && !order.delivery_staff_id ? 'READY' : (transitions[0] || order.status);
  const initialRider = eligibleRiders.some((rider) => rider.id === order.delivery_staff_id)
    ? Number(order.delivery_staff_id)
    : 0;
  const [targetStatus, setTargetStatus] = useState<AdminOrderStatus>(initialStatus);
  const [riderId, setRiderId] = useState(initialRider);
  const [cancellationReason, setCancellationReason] = useState('');
  const [validation, setValidation] = useState('');
  const showRider = targetStatus === 'READY' || targetStatus === 'OUT_FOR_DELIVERY';
  const riderRequired = showRider;
  const terminal = transitions.length === 0;

  function submit(event: FormEvent) {
    event.preventDefault();
    if (targetStatus === 'CANCELLED' && cancellationReason.trim().length < 3) {
      setValidation('Cancellation ka clear reason likhna zaroori hai.');
      return;
    }
    if (riderRequired && !riderId) {
      setValidation('Is action ke liye active delivery rider select karein.');
      return;
    }
    const body: AdminOrderStatusUpdate = { status: targetStatus };
    if (targetStatus === 'CANCELLED') body.rejection_reason = cancellationReason.trim();
    if (showRider && riderId) body.delivery_staff_id = riderId;
    setValidation('');
    onSubmit(body);
  }

  return <div role="dialog" aria-modal="true" aria-labelledby="order-workflow-title" className="fixed inset-0 z-[70] grid place-items-center overflow-y-auto bg-slate-950/60 p-4">
    <form onSubmit={submit} className="my-auto w-full max-w-2xl rounded-3xl bg-white p-5 shadow-2xl sm:p-7">
      <div className="flex items-start justify-between gap-4"><div><p className="text-xs font-black uppercase tracking-wider text-emerald-700">Order workflow</p><h2 id="order-workflow-title" className="mt-1 text-xl font-black">{order.order_number}</h2><p className="mt-1 text-sm text-slate-500">{order.customer_name}  /  {money(order.total_amount)}</p></div><button type="button" disabled={busy} onClick={onClose} aria-label="Close order workflow" className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-slate-100 disabled:opacity-50"><X className="h-5 w-5" /></button></div>
      <div className="mt-5 flex flex-wrap items-center gap-2 rounded-2xl bg-slate-50 p-4"><span className="text-xs font-black uppercase tracking-wide text-slate-500">Current status</span><Badge>{order.status}</Badge>{order.delivery_staff_name && <span className="ml-auto text-xs font-bold text-slate-600">Rider: {order.delivery_staff_name}</span>}</div>
      {(validation || error) && <div role="alert" className="mt-4 flex gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-sm font-semibold text-red-700"><AlertCircle className="h-5 w-5 shrink-0" />{validation || error}</div>}
      {terminal ? <div className="mt-6 rounded-2xl border border-slate-200 p-5 text-sm text-slate-600">Ye order final state mein hai. Delivered ya cancelled order ko dobara change nahi kiya ja sakta.</div> : <>
        <fieldset className="mt-6"><legend className="text-xs font-black uppercase tracking-wider text-slate-500">Choose next action</legend><div className="mt-3 grid gap-3 sm:grid-cols-2">{choices.map((status) => {
          const isAssignmentOnly = status === order.status && status === 'READY';
          return <label key={status} className={`flex cursor-pointer items-center gap-3 rounded-2xl border p-4 transition ${targetStatus === status ? status === 'CANCELLED' ? 'border-red-300 bg-red-50' : 'border-emerald-400 bg-emerald-50' : 'border-slate-200 hover:bg-slate-50'}`}><input type="radio" name="target-status" checked={targetStatus === status} onChange={() => { setTargetStatus(status); setValidation(''); }} className="h-4 w-4 accent-emerald-700" /><span><span className="block text-sm font-black">{isAssignmentOnly ? 'Assign / change rider' : ORDER_STATUS_LABELS[status]}</span><span className="mt-0.5 block text-xs text-slate-500">{isAssignmentOnly ? 'Order READY hi rahega' : `${order.status} to ${status}`}</span></span></label>;
        })}</div></fieldset>
        {showRider && <label className="mt-5 block text-xs font-black text-slate-600">Delivery rider {riderRequired && <span className="text-red-600">*</span>}<select value={riderId} onChange={(event) => setRiderId(Number(event.target.value))} className="mt-2 h-12 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm outline-none focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100"><option value={0}>{eligibleRiders.length ? 'Select active rider' : 'No active rider available for this store'}</option>{eligibleRiders.map((rider) => <option key={rider.id} value={rider.id}>{rider.name}  /  {rider.mobile}  /  {rider.assigned_orders_count} assigned</option>)}</select>{!eligibleRiders.length && <span className="mt-2 block text-xs font-semibold text-amber-700">Delivery Staff section mein rider add ya activate karein.</span>}</label>}
        {targetStatus === 'CANCELLED' && <label className="mt-5 block text-xs font-black text-slate-600">Cancellation reason <span className="text-red-600">*</span><textarea autoFocus required minLength={3} maxLength={500} value={cancellationReason} onChange={(event) => setCancellationReason(event.target.value)} placeholder="Example: Item unavailable; customer informed" className="mt-2 min-h-24 w-full resize-y rounded-xl border border-slate-200 p-3 text-sm outline-none focus:border-red-500 focus:ring-4 focus:ring-red-100" /></label>}
      </>}
      <div className="mt-7 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end"><button type="button" disabled={busy} onClick={onClose} className="rounded-xl border border-slate-200 px-4 py-3 text-sm font-black disabled:opacity-50">Close</button>{!terminal && <button disabled={busy || (riderRequired && !riderId)} className={`rounded-xl px-5 py-3 text-sm font-black text-white disabled:opacity-50 ${targetStatus === 'CANCELLED' ? 'bg-red-600' : 'bg-emerald-800'}`}>{busy ? 'Updating order...' : targetStatus === order.status ? 'Assign rider' : ORDER_STATUS_LABELS[targetStatus]}</button>}</div>
    </form>
  </div>;
}

function CreateRiderDialog({ stores, busy, onClose, onSubmit }: { stores: AdminStore[]; busy: boolean; onClose: () => void; onSubmit: (body: Record<string, unknown>) => void }) {
  const [storeId, setStoreId] = useState(stores[0]?.id || 0); const [name, setName] = useState(''); const [mobile, setMobile] = useState(''); const [pin, setPin] = useState('');
  return <div className="fixed inset-0 z-[70] grid place-items-center bg-slate-950/60 p-4"><form onSubmit={(event) => { event.preventDefault(); onSubmit({ store_id: storeId, name, mobile, pin, is_active: true }); }} className="w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl"><div className="flex justify-between"><div><h2 className="text-xl font-black">Add delivery staff</h2><p className="mt-1 text-xs text-slate-500">Rider ko selected kirana store se connect karein.</p></div><button type="button" onClick={onClose} className="grid w-10 h-10 place-items-center rounded-xl bg-slate-100"><X className="w-5 h-5" /></button></div><div className="mt-6 space-y-4"><label className="block text-xs font-black text-slate-600">Store<select required value={storeId} onChange={(event) => setStoreId(Number(event.target.value))} className="mt-2 h-11 w-full rounded-xl border border-slate-200 px-3 text-sm">{stores.map((store) => <option value={store.id} key={store.id}>{store.name}</option>)}</select></label><label className="block text-xs font-black text-slate-600">Rider name<input required value={name} onChange={(event) => setName(event.target.value)} className="mt-2 h-11 w-full rounded-xl border border-slate-200 px-3 text-sm" /></label><label className="block text-xs font-black text-slate-600">Mobile number<input required inputMode="numeric" value={mobile} onChange={(event) => setMobile(event.target.value.replace(/\D/g, '').slice(0, 15))} className="mt-2 h-11 w-full rounded-xl border border-slate-200 px-3 text-sm" /></label><label className="block text-xs font-black text-slate-600">Login PIN<input required pattern="[0-9]{4,12}" inputMode="numeric" value={pin} onChange={(event) => setPin(event.target.value.replace(/\D/g, '').slice(0, 12))} className="mt-2 h-11 w-full rounded-xl border border-slate-200 px-3 text-sm tracking-[0.3em]" /></label></div><div className="mt-6 flex justify-end gap-2"><button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-black">Cancel</button><button disabled={busy || pin.length < 4} className="rounded-xl bg-emerald-800 px-5 py-2.5 text-sm font-black text-white disabled:opacity-50">{busy ? 'Creating...' : 'Create rider'}</button></div></form></div>;
}

function ResetPinDialog({ rider, busy, onClose, onSubmit }: { rider: AdminRider; busy: boolean; onClose: () => void; onSubmit: (pin: string) => void }) {
  const [pin, setPin] = useState('');
  return <div className="fixed inset-0 z-[70] grid place-items-center bg-slate-950/60 p-4"><form onSubmit={(event) => { event.preventDefault(); onSubmit(pin); }} className="w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl"><div className="flex justify-between gap-4"><div><h2 className="text-xl font-black">Reset rider PIN</h2><p className="mt-1 text-sm text-slate-500">{rider.name}  /  {rider.mobile}</p></div><button type="button" onClick={onClose} className="grid w-10 h-10 place-items-center rounded-xl bg-slate-100"><X className="w-5 h-5" /></button></div><label className="mt-6 block text-xs font-black text-slate-600">New 4-12 digit PIN<input autoFocus required pattern="[0-9]{4,12}" inputMode="numeric" value={pin} onChange={(event) => setPin(event.target.value.replace(/\D/g, '').slice(0, 12))} className="mt-2 h-12 w-full rounded-xl border border-slate-200 px-4 text-lg tracking-[0.3em] outline-none focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100" /></label><p className="mt-3 text-xs leading-5 text-amber-700">PIN reset se rider ke existing login sessions revoke ho jayenge.</p><div className="mt-6 flex justify-end gap-2"><button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-black">Cancel</button><button disabled={busy || pin.length < 4} className="rounded-xl bg-emerald-800 px-5 py-2.5 text-sm font-black text-white disabled:opacity-50">{busy ? 'Resetting...' : 'Reset PIN'}</button></div></form></div>;
}

function CreateStoreDialog({ busy, onClose, onSubmit }: { busy: boolean; onClose: () => void; onSubmit: (body: Record<string, unknown>) => void }) {
  const [values, setValues] = useState({ code: '', name: '', owner_name: '', phone: '', address: '', landmark: '', pincode: '', description: '' });
  function submit(event: FormEvent) { event.preventDefault(); onSubmit(values); }
  return <div className="fixed inset-0 z-[70] grid place-items-center bg-slate-950/60 p-4"><form onSubmit={submit} className="w-full max-w-2xl max-h-[90vh] overflow-auto rounded-3xl bg-white p-6 shadow-2xl"><div className="flex items-start justify-between"><div><h2 className="text-xl font-black">Add kirana store</h2><p className="mt-1 text-xs text-slate-500">New store customer aur manager apps mein live available hoga.</p></div><button type="button" onClick={onClose} className="grid w-10 h-10 place-items-center rounded-xl bg-slate-100"><X className="w-5 h-5" /></button></div><div className="mt-6 grid gap-4 sm:grid-cols-2">{([['name','Store name'],['code','Unique store code'],['owner_name','Owner name'],['phone','Mobile number'],['pincode','6-digit pincode'],['landmark','Landmark'],['address','Full address'],['description','Description']] as const).map(([field,label]) => <label key={field} className={`text-xs font-black text-slate-600 ${field === 'address' || field === 'description' ? 'sm:col-span-2' : ''}`}>{label}<input required={!['landmark','description'].includes(field)} value={values[field]} onChange={(event) => setValues((current) => ({ ...current, [field]: field === 'code' ? event.target.value.toUpperCase() : event.target.value }))} className="mt-2 h-11 w-full rounded-xl border border-slate-200 px-3 text-sm font-medium outline-none focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100" /></label>)}</div><div className="mt-6 flex justify-end gap-2"><button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-black">Cancel</button><button disabled={busy} className="rounded-xl bg-emerald-800 px-5 py-2.5 text-sm font-black text-white disabled:opacity-50">{busy ? 'Creating...' : 'Create store'}</button></div></form></div>;
}

function Overview({ overview, stores, auditLogs, onNavigate }: { overview: AdminOverview | null; stores: AdminStore[]; auditLogs: AdminAuditLog[]; onNavigate: (tab: Tab) => void }) {
  if (!overview) return <Empty label="Overview data available nahi hai." />;
  return <div className="space-y-7">
    <section className="overflow-hidden rounded-3xl bg-[#0a4a34] p-6 sm:p-8 text-white relative"><div className="absolute -right-20 -top-32 w-80 h-80 rounded-full bg-emerald-300/10" /><div className="relative flex flex-col gap-6 md:flex-row md:items-end md:justify-between"><div><span className="inline-flex items-center gap-2 text-xs font-black uppercase tracking-[0.16em] text-emerald-300"><ShieldCheck className="w-4 h-4" /> Platform control centre</span><h1 className="mt-3 text-3xl sm:text-4xl font-black tracking-tight">Namaste, Wasim</h1><p className="mt-2 text-sm text-emerald-100/75">Aaj ke live operations aur business health ek jagah.</p></div><div className="flex gap-2"><button onClick={() => onNavigate('orders')} className="rounded-xl bg-white px-4 py-3 text-sm font-black text-emerald-900">Review new orders</button><button onClick={() => onNavigate('stores')} className="rounded-xl border border-white/20 bg-white/10 px-4 py-3 text-sm font-black">Manage stores</button></div></div></section>
    <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><Metric label="Total stores" value={String(overview.stores.total)} hint={`${overview.stores.open} operational  /  ${overview.stores.delivery_enabled} delivery enabled`} icon={Store} /><Metric label="Total orders" value={String(overview.orders.total)} hint={`${overview.orders.new} new  /  ${overview.orders.active} in progress`} icon={ShoppingBag} tone="blue" /><Metric label="Monthly sales" value={money(overview.revenue.online_sales)} hint={`${overview.orders.delivered} delivered orders`} icon={CircleDollarSign} tone="amber" /><Metric label="Customers" value={String(overview.customers.total)} hint={`${money(overview.customers.udhaar_outstanding)} udhaar outstanding`} icon={UsersRound} tone="violet" /></section>
    <section className="grid gap-5 xl:grid-cols-[1.4fr_0.6fr]"><div className="rounded-2xl border border-slate-200 bg-white shadow-sm"><div className="flex items-center justify-between border-b border-slate-100 p-5"><div><h2 className="font-black">Recent orders</h2><p className="text-xs text-slate-500 mt-1">Across all connected stores</p></div><button onClick={() => onNavigate('orders')} className="text-xs font-black text-emerald-700">View all</button></div><div className="divide-y divide-slate-100">{overview.recent_orders.length ? overview.recent_orders.slice(0, 6).map((order) => <div key={order.id} className="flex items-center gap-3 p-4"><span className="grid w-10 h-10 place-items-center rounded-xl bg-slate-100"><Package className="w-5 h-5 text-slate-600" /></span><div className="min-w-0 flex-1"><p className="truncate text-sm font-black">{order.order_number}  /  {order.customer_name}</p><p className="text-xs text-slate-500">{money(order.total_amount)}  /  {date(order.created_at)}</p></div><Badge>{order.status}</Badge></div>) : <Empty label="Abhi koi order nahi hai." />}</div></div><div className="space-y-5"><div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="font-black">Store health</h2><p className="mt-1 text-xs text-slate-500">Catalogue and delivery readiness</p><div className="mt-5 space-y-4">{stores.map((store) => <button onClick={() => onNavigate('stores')} key={store.id} className="w-full flex items-center gap-3 text-left"><span className="grid w-10 h-10 place-items-center rounded-xl bg-emerald-50 text-emerald-800 font-black">{store.name[0]}</span><span className="min-w-0 flex-1"><span className="block truncate text-sm font-black">{store.name}</span><span className="block text-xs text-slate-500">{store.product_count} products  /  {store.delivery_settings.expected_delivery_time}</span></span><ChevronRight className="w-4 h-4 text-slate-400" /></button>)}</div></div><div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><h2 className="font-black">Security activity</h2><p className="mt-1 text-xs text-slate-500">Latest audited admin actions</p><div className="mt-4 space-y-3">{auditLogs.slice(0, 4).map((log) => <div key={log.id} className="flex items-start gap-3"><span className="mt-1 w-2 h-2 rounded-full bg-emerald-500" /><div className="min-w-0"><p className="truncate text-xs font-black">{log.action.replaceAll('_', ' ')}</p><p className="text-[11px] text-slate-500">{log.resource_type} #{log.resource_id || '-'}  /  {date(log.created_at)}</p></div></div>)}{!auditLogs.length && <p className="text-xs text-slate-500">No admin changes yet.</p>}</div></div></div></section>
  </div>;
}

function TableShell({ children, empty }: { children: ReactNode; empty: boolean }) { return <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">{empty ? <Empty label="Matching records nahi mile." /> : <div className="overflow-x-auto">{children}</div>}</div>; }
const th = 'px-5 py-3 text-left text-[11px] font-black uppercase tracking-wider text-slate-500';
const td = 'px-5 py-4 text-sm align-middle';

function Stores({ rows, busyKey, onToggle }: { rows: AdminStore[]; busyKey: string; onToggle: (store: AdminStore) => void }) { return <TableShell empty={!rows.length}><table className="w-full min-w-[980px]"><thead className="bg-slate-50"><tr><th className={th}>Store</th><th className={th}>Owner & location</th><th className={th}>Catalogue</th><th className={th}>Delivery</th><th className={th}>Status</th><th className={th}>Control</th></tr></thead><tbody className="divide-y divide-slate-100">{rows.map((store) => <tr key={store.id} className="hover:bg-slate-50/70"><td className={td}><div className="flex items-center gap-3"><span className="grid w-11 h-11 place-items-center rounded-xl bg-emerald-100 text-emerald-800 font-black text-lg">{store.name[0]}</span><div><p className="font-black">{store.name}</p><p className="text-xs text-slate-500">{store.code}  /  {store.phone}</p></div></div></td><td className={td}><p className="font-bold">{store.owner_name}</p><p className="max-w-xs truncate text-xs text-slate-500">{store.address}, {store.pincode}</p></td><td className={td}><p className="font-black">{store.product_count} products</p><p className="text-xs text-slate-500">{store.categories.slice(0, 2).join('  /  ') || 'No categories'}</p></td><td className={td}><p className="font-bold">{store.delivery_settings.expected_delivery_time || 'Not configured'}</p><p className="text-xs text-slate-500">Free above {money(store.delivery_settings.free_delivery_above)}</p></td><td className={td}><Badge>{store.is_open ? 'OPEN' : 'CLOSED'}</Badge></td><td className={td}><button disabled={busyKey === `store-${store.id}`} onClick={() => onToggle(store)} className={`rounded-lg px-3 py-2 text-xs font-black ${store.is_open ? 'bg-red-50 text-red-700' : 'bg-emerald-100 text-emerald-800'}`}>{busyKey === `store-${store.id}` ? 'Saving...' : store.is_open ? 'Close store' : 'Open store'}</button></td></tr>)}</tbody></table></TableShell>; }

function Orders({ rows, storeNames, onManage }: { rows: AdminOrder[]; storeNames: Map<number, string>; onManage: (order: AdminOrder) => void }) { return <TableShell empty={!rows.length}><table className="w-full min-w-[980px]"><thead className="bg-slate-50"><tr><th className={th}>Order</th><th className={th}>Store</th><th className={th}>Customer</th><th className={th}>Payment</th><th className={th}>Rider</th><th className={th}>Status</th><th className={th}>Control</th></tr></thead><tbody className="divide-y divide-slate-100">{rows.map((order) => { const terminal = ORDER_TRANSITIONS[order.status].length === 0; return <tr key={order.id}><td className={td}><p className="font-black">{order.order_number}</p><p className="text-xs text-slate-500">{date(order.created_at)}</p></td><td className={td}><p className="font-bold">{storeNames.get(order.store_id) || `Store #${order.store_id}`}</p></td><td className={td}><p className="font-bold">{order.customer_name}</p><p className="text-xs text-slate-500">{order.customer_phone}</p></td><td className={td}><p className="font-black">{money(order.total_amount)}</p><p className="text-xs text-slate-500">{order.payment_method}  /  {order.payment_status}</p></td><td className={td}>{order.delivery_staff_name || <span className="text-slate-400">Unassigned</span>}</td><td className={td}><Badge>{order.status}</Badge></td><td className={td}><button onClick={() => onManage(order)} className={`rounded-lg px-3 py-2 text-xs font-black ${terminal ? 'bg-slate-100 text-slate-600' : 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'}`}>{terminal ? 'View final state' : 'Manage workflow'}</button></td></tr>; })}</tbody></table></TableShell>; }

function Products({ rows, storeNames, onEdit }: { rows: AdminProduct[]; storeNames: Map<number, string>; onEdit: (product: AdminProduct) => void }) { return <TableShell empty={!rows.length}><table className="w-full min-w-[900px]"><thead className="bg-slate-50"><tr><th className={th}>Product</th><th className={th}>Store</th><th className={th}>Pricing</th><th className={th}>Stock</th><th className={th}>Visibility</th><th className={th}>Control</th></tr></thead><tbody className="divide-y divide-slate-100">{rows.map((product) => <tr key={product.id}><td className={td}><p className="font-black">{product.name_en}</p><p className="text-xs text-slate-500">{product.category}  /  {product.pack_size}</p></td><td className={td}>{storeNames.get(product.store_id)}</td><td className={td}><p className="font-black">{money(product.selling_price)}</p><p className="text-xs text-slate-400 line-through">{money(product.mrp)}</p></td><td className={td}><span className={`font-black ${product.stock === 0 ? 'text-red-600' : 'text-slate-900'}`}>{product.stock}</span></td><td className={td}><Badge>{product.is_hidden ? 'HIDDEN' : product.available_for_online ? 'ONLINE' : 'OFFLINE'}</Badge></td><td className={td}><button onClick={() => onEdit(product)} className="inline-flex items-center gap-2 rounded-lg bg-slate-100 px-3 py-2 text-xs font-black text-slate-700 hover:bg-slate-200"><Pencil className="h-3.5 w-3.5" /> Edit product</button></td></tr>)}</tbody></table></TableShell>; }

function Customers({ rows, storeNames, busyKey, onToggleUdhaar }: { rows: AdminCustomer[]; storeNames: Map<number, string>; busyKey: string; onToggleUdhaar: (customer: AdminCustomer) => void }) { return <TableShell empty={!rows.length}><table className="w-full min-w-[980px]"><thead className="bg-slate-50"><tr><th className={th}>Customer</th><th className={th}>Store</th><th className={th}>Orders</th><th className={th}>Total spent</th><th className={th}>Udhaar balance</th><th className={th}>Online udhaar</th><th className={th}>Last order</th></tr></thead><tbody className="divide-y divide-slate-100">{rows.map((customer) => { const busy = busyKey === `customer-udhaar-${customer.id}`; return <tr key={customer.id}><td className={td}><div className="flex items-center gap-3"><span className="grid w-10 h-10 place-items-center rounded-full bg-violet-100 font-black text-violet-700">{customer.name[0]}</span><div><p className="font-black">{customer.name}</p><p className="text-xs text-slate-500">{customer.mobile}</p></div></div></td><td className={td}>{storeNames.get(customer.store_id)}</td><td className={td}><b>{customer.total_orders}</b></td><td className={td}><b>{money(customer.total_spent)}</b></td><td className={td}><p className="font-black">{money(customer.udhaar_balance)}</p></td><td className={td}><button type="button" role="switch" aria-checked={customer.allow_online_udhaar} aria-label={`${customer.allow_online_udhaar ? 'Disable' : 'Enable'} online udhaar for ${customer.name}`} disabled={busy} onClick={() => onToggleUdhaar(customer)} className="inline-flex items-center gap-2 rounded-full py-1.5 text-xs font-black text-slate-700 transition disabled:opacity-50"><span className={`relative h-6 w-11 rounded-full transition ${customer.allow_online_udhaar ? 'bg-emerald-600' : 'bg-slate-300'}`}><span className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow-sm transition ${customer.allow_online_udhaar ? 'left-[22px]' : 'left-0.5'}`} /></span>{busy ? 'Saving...' : customer.allow_online_udhaar ? 'Enabled' : 'Disabled'}</button></td><td className={td}>{customer.last_order_date || '-'}</td></tr>; })}</tbody></table></TableShell>; }

function Riders({ rows, storeNames, busyKey, onToggle, onResetPin }: { rows: AdminRider[]; storeNames: Map<number, string>; busyKey: string; onToggle: (rider: AdminRider) => void; onResetPin: (rider: AdminRider) => void }) { return <TableShell empty={!rows.length}><table className="w-full min-w-[900px]"><thead className="bg-slate-50"><tr><th className={th}>Delivery partner</th><th className={th}>Store</th><th className={th}>Assigned</th><th className={th}>Cash collected</th><th className={th}>Status</th><th className={th}>Control</th></tr></thead><tbody className="divide-y divide-slate-100">{rows.map((rider) => <tr key={rider.id}><td className={td}><div className="flex items-center gap-3"><span className="grid w-10 h-10 place-items-center rounded-full bg-blue-100 text-blue-700"><UserRound className="w-5 h-5" /></span><div><p className="font-black">{rider.name}</p><p className="text-xs text-slate-500">{rider.mobile}</p></div></div></td><td className={td}>{storeNames.get(rider.store_id)}</td><td className={td}><b>{rider.assigned_orders_count}</b> orders</td><td className={td}><b>{money(rider.cash_collected_today)}</b></td><td className={td}><Badge>{rider.is_active ? 'ACTIVE' : 'INACTIVE'}</Badge></td><td className={td}><div className="flex gap-2"><button onClick={() => onResetPin(rider)} className="rounded-lg bg-blue-50 px-3 py-2 text-xs font-black text-blue-700">Reset PIN</button><button disabled={busyKey === `rider-${rider.id}`} onClick={() => onToggle(rider)} className={`rounded-lg px-3 py-2 text-xs font-black ${rider.is_active ? 'bg-red-50 text-red-700' : 'bg-emerald-100 text-emerald-800'}`}>{busyKey === `rider-${rider.id}` ? 'Saving...' : rider.is_active ? 'Deactivate' : 'Activate'}</button></div></td></tr>)}</tbody></table></TableShell>; }
