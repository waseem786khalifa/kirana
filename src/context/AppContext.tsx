import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  AppMode,
  Language,
  KiranaStore,
  Product,
  CustomerProfile,
  Order,
  CartItem,
  DeliveryStaff,
  KhataEntry,
  KiranaList,
  OrderStatus,
} from '../types';
import {
  INITIAL_STORES,
  INITIAL_PRODUCTS,
  INITIAL_CUSTOMERS,
  INITIAL_ORDERS,
  INITIAL_DELIVERY_STAFF,
  INITIAL_KIRANA_LIST,
} from '../data/mockData';

interface AppContextType {
  mode: AppMode;
  setMode: (mode: AppMode) => void;
  language: Language;
  setLanguage: (lang: Language) => void;
  
  stores: KiranaStore[];
  activeStore: KiranaStore;
  selectStore: (storeId: string) => void;
  connectShopByCode: (code: string) => Promise<boolean>;
  
  products: Product[];
  activeCategory: string;
  setActiveCategory: (cat: string) => void;

  cart: CartItem[];
  addToCart: (product: Product, qty?: number) => void;
  updateCartQuantity: (productId: string, qty: number) => void;
  removeFromCart: (productId: string) => void;
  clearCart: () => void;
  cartSubtotal: number;
  cartDiscount: number;
  cartDeliveryCharge: number;
  cartTotal: number;

  customer: CustomerProfile;
  setCustomer: (cust: CustomerProfile) => void;
  savedCustomers: CustomerProfile[];
  
  orders: Order[];
  placeOrder: (orderData: Partial<Order>) => Promise<Order | null>;
  cancelOrder: (orderId: string) => Promise<void>;
  acceptOrder: (orderId: string) => Promise<void>;
  rejectOrder: (orderId: string, reason: string) => Promise<void>;
  updateOrderStatus: (orderId: string, status: OrderStatus, extra?: any) => Promise<void>;
  modifyOrderItems: (orderId: string, items: any[], totals: any) => Promise<void>;
  reorderPastOrder: (order: Order) => void;

  deliveryStaff: DeliveryStaff[];
  addDeliveryStaff: (staff: Partial<DeliveryStaff>) => Promise<void>;

  khataEntries: KhataEntry[];
  toggleOnlineUdhaarPermission: (customerId: string, allow: boolean) => Promise<void>;
  addKhataPayment: (customerId: string, amount: number, note: string) => Promise<void>;

  kiranaList: KiranaList;
  updateKiranaList: (list: KiranaList) => void;
  addAllKiranaListToCart: () => void;

  updateStoreSettings: (settings: Partial<KiranaStore>) => Promise<void>;
  addProduct: (prod: Partial<Product>) => Promise<void>;
  updateProduct: (id: string, prod: Partial<Product>) => Promise<void>;

  soundAlertEnabled: boolean;
  setSoundAlertEnabled: (enabled: boolean) => void;
  newOrderNotification: Order | null;
  clearNotification: () => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [mode, setMode] = useState<AppMode>('CUSTOMER');
  const [language, setLanguage] = useState<Language>('HI');
  
  const [stores, setStores] = useState<KiranaStore[]>(INITIAL_STORES);
  const [activeStoreId, setActiveStoreId] = useState<string>('store_1');
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [activeCategory, setActiveCategory] = useState<string>('All');
  
  const [cart, setCart] = useState<CartItem[]>([]);
  const [savedCustomers, setSavedCustomers] = useState<CustomerProfile[]>(INITIAL_CUSTOMERS);
  const [customer, setCustomer] = useState<CustomerProfile>(INITIAL_CUSTOMERS[0]);
  
  const [orders, setOrders] = useState<Order[]>(INITIAL_ORDERS);
  const [deliveryStaff, setDeliveryStaff] = useState<DeliveryStaff[]>(INITIAL_DELIVERY_STAFF);
  const [khataEntries, setKhataEntries] = useState<KhataEntry[]>([]);
  const [kiranaList, setKiranaList] = useState<KiranaList>(INITIAL_KIRANA_LIST);
  
  const [soundAlertEnabled, setSoundAlertEnabled] = useState<boolean>(true);
  const [newOrderNotification, setNewOrderNotification] = useState<Order | null>(null);

  // Fetch API State from Server on Load
  useEffect(() => {
    fetch('/api/stores')
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data) && data.length > 0) setStores(data);
      })
      .catch((err) => console.log('Using local store fallback', err));

    fetch('/api/products?storeId=store_1')
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data) && data.length > 0) setProducts(data);
      })
      .catch((err) => console.log('Using local products fallback', err));

    fetch('/api/orders?storeId=store_1')
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data)) setOrders(data);
      })
      .catch((err) => console.log('Using local orders fallback', err));

    fetch('/api/customers?storeId=store_1')
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data) && data.length > 0) {
          setSavedCustomers(data);
          setCustomer(data[0]);
        }
      })
      .catch((err) => console.log('Using local customer fallback', err));
  }, []);

  const activeStore = stores.find((s) => s.id === activeStoreId) || stores[0];

  const selectStore = (storeId: string) => {
    setActiveStoreId(storeId);
    setCart([]);
    fetch(`/api/products?storeId=${storeId}`)
      .then((res) => res.json())
      .then((data) => {
        if (Array.isArray(data)) setProducts(data);
      });
  };

  const connectShopByCode = async (code: string): Promise<boolean> => {
    try {
      const res = await fetch(`/api/stores/by-code/${code}`);
      if (res.ok) {
        const store = await res.json();
        selectStore(store.id);
        return true;
      }
    } catch {
      const found = stores.find((s) => s.code.toUpperCase() === code.toUpperCase());
      if (found) {
        selectStore(found.id);
        return true;
      }
    }
    return false;
  };

  // Cart Calculations
  const cartSubtotal = cart.reduce((sum, item) => sum + item.product.sellingPrice * item.quantity, 0);
  const cartMrpTotal = cart.reduce((sum, item) => sum + item.product.mrp * item.quantity, 0);
  const cartDiscount = Math.max(0, cartMrpTotal - cartSubtotal);
  
  const deliveryCharge =
    cartSubtotal === 0
      ? 0
      : cartSubtotal >= activeStore.deliverySettings.freeDeliveryAbove
      ? 0
      : activeStore.deliverySettings.deliveryCharge;

  const cartTotal = cartSubtotal + deliveryCharge;

  const addToCart = (product: Product, qty: number = 1) => {
    if (product.stock <= 0) return;
    setCart((prev) => {
      const existingIndex = prev.findIndex((item) => item.product.id === product.id);
      if (existingIndex > -1) {
        const updated = [...prev];
        const newQty = Math.min(product.stock, updated[existingIndex].quantity + qty);
        updated[existingIndex].quantity = newQty;
        return updated;
      }
      return [...prev, { product, quantity: Math.min(product.stock, qty) }];
    });
  };

  const updateCartQuantity = (productId: string, qty: number) => {
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }
    setCart((prev) =>
      prev.map((item) =>
        item.product.id === productId
          ? { ...item, quantity: Math.min(item.product.stock, qty) }
          : item
      )
    );
  };

  const removeFromCart = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.product.id !== productId));
  };

  const clearCart = () => setCart([]);

  // Place Order
  const placeOrder = async (orderData: Partial<Order>): Promise<Order | null> => {
    const payload = {
      storeId: activeStore.id,
      customerName: customer.name,
      customerPhone: customer.mobile,
      deliveryAddress: customer.addresses[0],
      items: cart.map((item) => ({
        productId: item.product.id,
        nameEn: item.product.nameEn,
        nameHi: item.product.nameHi,
        nameMrw: item.product.nameMrw,
        packSize: item.product.packSize,
        price: item.product.sellingPrice,
        mrp: item.product.mrp,
        quantity: item.quantity,
      })),
      subtotal: cartSubtotal,
      discount: cartDiscount,
      deliveryCharge,
      totalAmount: cartTotal,
      paymentMethod: orderData.paymentMethod || 'COD',
      deliveryInstructions: orderData.deliveryInstructions || '',
      scheduledSlot: orderData.scheduledSlot || 'Deliver Now (30-45 mins)',
    };

    try {
      const res = await fetch('/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (res.ok) {
        const createdOrder = await res.json();
        setOrders((prev) => [createdOrder, ...prev]);
        clearCart();
        
        // Trigger sound + popup if merchant mode is observing
        if (soundAlertEnabled) {
          playNotificationSound();
        }
        setNewOrderNotification(createdOrder);
        return createdOrder;
      }
    } catch {
      // Fallback local creation
      const localOrder: Order = {
        id: `KS${1026 + orders.length}`,
        storeId: activeStore.id,
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.mobile,
        deliveryAddress: customer.addresses[0],
        items: payload.items,
        subtotal: cartSubtotal,
        discount: cartDiscount,
        deliveryCharge,
        totalAmount: cartTotal,
        paymentMethod: (orderData.paymentMethod as any) || 'COD',
        paymentStatus: 'PENDING',
        status: 'NEW',
        deliveryInstructions: orderData.deliveryInstructions,
        scheduledSlot: orderData.scheduledSlot,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      setOrders((prev) => [localOrder, ...prev]);
      clearCart();
      setNewOrderNotification(localOrder);
      return localOrder;
    }
    return null;
  };

  const playNotificationSound = () => {
    try {
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(587.33, audioCtx.currentTime); // D5
      osc.frequency.setValueAtTime(880, audioCtx.currentTime + 0.15); // A5
      gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.6);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.6);
    } catch {
      // Audio fallback
    }
  };

  const cancelOrder = async (orderId: string) => {
    await updateOrderStatus(orderId, 'CANCELLED', { rejectionReason: 'Cancelled by customer' });
  };

  const acceptOrder = async (orderId: string) => {
    await updateOrderStatus(orderId, 'ACCEPTED');
  };

  const rejectOrder = async (orderId: string, reason: string) => {
    await updateOrderStatus(orderId, 'CANCELLED', { rejectionReason: reason });
  };

  const updateOrderStatus = async (orderId: string, status: OrderStatus, extra?: any) => {
    try {
      const res = await fetch(`/api/orders/${orderId}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, ...extra }),
      });
      if (res.ok) {
        const updated = await res.json();
        setOrders((prev) => prev.map((o) => (o.id === orderId ? updated : o)));
      }
    } catch {
      setOrders((prev) =>
        prev.map((o) => (o.id === orderId ? { ...o, status, ...extra, updatedAt: new Date().toISOString() } : o))
      );
    }
  };

  const modifyOrderItems = async (orderId: string, items: any[], totals: any) => {
    try {
      const res = await fetch(`/api/orders/${orderId}/modify-items`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ items, ...totals }),
      });
      if (res.ok) {
        const updated = await res.json();
        setOrders((prev) => prev.map((o) => (o.id === orderId ? updated : o)));
      }
    } catch {
      setOrders((prev) =>
        prev.map((o) => (o.id === orderId ? { ...o, items, ...totals, modifiedByMerchant: true } : o))
      );
    }
  };

  const reorderPastOrder = (pastOrder: Order) => {
    pastOrder.items.forEach((item) => {
      const prod = products.find((p) => p.id === item.productId);
      if (prod && prod.stock > 0) {
        addToCart(prod, item.quantity);
      }
    });
  };

  const addDeliveryStaff = async (staff: Partial<DeliveryStaff>) => {
    try {
      const res = await fetch('/api/delivery-staff', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ storeId: activeStore.id, ...staff }),
      });
      if (res.ok) {
        const newStaff = await res.json();
        setDeliveryStaff((prev) => [...prev, newStaff]);
      }
    } catch {
      const localStaff: DeliveryStaff = {
        id: `db_${Date.now()}`,
        storeId: activeStore.id,
        name: staff.name || '',
        mobile: staff.mobile || '',
        pin: staff.pin || '1234',
        isActive: true,
        assignedOrdersCount: 0,
        cashCollectedToday: 0,
      };
      setDeliveryStaff((prev) => [...prev, localStaff]);
    }
  };

  const toggleOnlineUdhaarPermission = async (customerId: string, allow: boolean) => {
    setSavedCustomers((prev) =>
      prev.map((c) => (c.id === customerId ? { ...c, allowOnlineUdhaar: allow } : c))
    );
    if (customer.id === customerId) {
      setCustomer((prev) => ({ ...prev, allowOnlineUdhaar: allow }));
    }
    try {
      await fetch(`/api/customers/${customerId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ allowOnlineUdhaar: allow }),
      });
    } catch (e) {
      console.log('Update udhaar error', e);
    }
  };

  const addKhataPayment = async (customerId: string, amount: number, note: string) => {
    try {
      const res = await fetch('/api/khata/payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ storeId: activeStore.id, customerId, amount, note }),
      });
      if (res.ok) {
        const data = await res.json();
        setSavedCustomers((prev) => prev.map((c) => (c.id === customerId ? data.customer : c)));
        setKhataEntries((prev) => [data.entry, ...prev]);
      }
    } catch {
      setSavedCustomers((prev) =>
        prev.map((c) =>
          c.id === customerId
            ? { ...c, udhaarBalance: Math.max(0, c.udhaarBalance - amount) }
            : c
        )
      );
    }
  };

  const addAllKiranaListToCart = () => {
    kiranaList.items.forEach((item) => {
      const matchedProd = products.find(
        (p) =>
          p.nameEn.toLowerCase().includes(item.name.toLowerCase()) ||
          p.nameHi.toLowerCase().includes(item.name.toLowerCase())
      );
      if (matchedProd && matchedProd.stock > 0) {
        addToCart(matchedProd, 1);
      }
    });
  };

  const updateStoreSettings = async (settings: Partial<KiranaStore>) => {
    setStores((prev) =>
      prev.map((s) => (s.id === activeStore.id ? { ...s, ...settings } : s))
    );
    try {
      await fetch(`/api/stores/${activeStore.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(settings),
      });
    } catch (e) {
      console.log('Store update error', e);
    }
  };

  const addProduct = async (prod: Partial<Product>) => {
    try {
      const res = await fetch('/api/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ storeId: activeStore.id, ...prod }),
      });
      if (res.ok) {
        const newP = await res.json();
        setProducts((prev) => [newP, ...prev]);
      }
    } catch {
      const localP: Product = {
        id: `p_${Date.now()}`,
        storeId: activeStore.id,
        nameEn: prod.nameEn || '',
        nameHi: prod.nameHi || '',
        nameMrw: prod.nameMrw || '',
        category: prod.category || 'Other',
        packSize: prod.packSize || '1 unit',
        mrp: prod.mrp || 100,
        sellingPrice: prod.sellingPrice || 90,
        stock: prod.stock || 10,
        image: prod.image || 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400',
        availableForOnline: true,
        isHidden: false,
      };
      setProducts((prev) => [localP, ...prev]);
    }
  };

  const updateProduct = async (id: string, prodData: Partial<Product>) => {
    setProducts((prev) => prev.map((p) => (p.id === id ? { ...p, ...prodData } : p)));
    try {
      await fetch(`/api/products/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(prodData),
      });
    } catch (e) {
      console.log('Product update error', e);
    }
  };

  const clearNotification = () => setNewOrderNotification(null);

  return (
    <AppContext.Provider
      value={{
        mode,
        setMode,
        language,
        setLanguage,
        stores,
        activeStore,
        selectStore,
        connectShopByCode,
        products,
        activeCategory,
        setActiveCategory,
        cart,
        addToCart,
        updateCartQuantity,
        removeFromCart,
        clearCart,
        cartSubtotal,
        cartDiscount,
        cartDeliveryCharge: deliveryCharge,
        cartTotal,
        customer,
        setCustomer,
        savedCustomers,
        orders,
        placeOrder,
        cancelOrder,
        acceptOrder,
        rejectOrder,
        updateOrderStatus,
        modifyOrderItems,
        reorderPastOrder,
        deliveryStaff,
        addDeliveryStaff,
        khataEntries,
        toggleOnlineUdhaarPermission,
        addKhataPayment,
        kiranaList,
        updateKiranaList: setKiranaList,
        addAllKiranaListToCart,
        updateStoreSettings,
        addProduct,
        updateProduct,
        soundAlertEnabled,
        setSoundAlertEnabled,
        newOrderNotification,
        clearNotification,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
};
