export type AppMode = 'CUSTOMER' | 'MERCHANT' | 'DELIVERY_BOY';

export type Language = 'EN' | 'HI' | 'MRW';

export interface DeliverySettings {
  deliveryAvailable: boolean;
  radiusKm: number;
  minOrder: number;
  freeDeliveryAbove: number;
  deliveryCharge: number;
  expectedDeliveryTime: string;
  scheduledDeliveryEnabled: boolean;
}

export interface PaymentSettings {
  codEnabled: boolean;
  upiEnabled: boolean;
  payAtShopEnabled: boolean;
  onlineUdhaarEnabled: boolean;
}

export interface KiranaStore {
  id: string;
  code: string; // e.g. "BALAJI123"
  name: string;
  ownerName: string;
  phone: string;
  address: string;
  landmark: string;
  pincode: string;
  distanceKm?: number;
  isOpen: boolean;
  logo: string;
  banner: string;
  description: string;
  openingTime: string;
  closingTime: string;
  deliverySettings: DeliverySettings;
  paymentSettings: PaymentSettings;
  allowNearbyDiscovery: boolean;
}

export interface Product {
  id: string;
  storeId: string;
  nameEn: string;
  nameHi: string;
  nameMrw: string;
  category: string;
  packSize: string;
  mrp: number;
  sellingPrice: number;
  stock: number;
  image: string;
  availableForOnline: boolean;
  isHidden: boolean;
}

export interface CustomerAddress {
  id: string;
  label: 'Home' | 'Office' | 'Other';
  addressLine: string;
  landmark: string;
  pincode: string;
}

export interface CustomerProfile {
  id: string;
  storeId: string;
  name: string;
  mobile: string;
  addresses: CustomerAddress[];
  allowOnlineUdhaar: boolean;
  udhaarBalance: number;
  totalOrders: number;
  totalSpent: number;
  lastOrderDate?: string;
}

export interface KhataEntry {
  id: string;
  storeId: string;
  customerId: string;
  date: string;
  type: 'DEBIT' | 'CREDIT';
  amount: number;
  orderId?: string;
  note: string;
  balanceAfter: number;
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export type OrderStatus =
  | 'NEW'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'CANCELLED';

export type PaymentMethod = 'COD' | 'UPI' | 'PAY_AT_SHOP' | 'UDHAAR';

export interface OrderItem {
  productId: string;
  nameEn: string;
  nameHi: string;
  nameMrw: string;
  packSize: string;
  price: number;
  mrp: number;
  quantity: number;
  originalQuantity?: number; // In case merchant modified quantity
}

export interface Order {
  id: string; // e.g. "KS1025"
  storeId: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  deliveryAddress: CustomerAddress;
  items: OrderItem[];
  subtotal: number;
  discount: number;
  deliveryCharge: number;
  totalAmount: number;
  paymentMethod: PaymentMethod;
  paymentStatus: 'PENDING' | 'COLLECTED' | 'UDHAAR_POSTED';
  status: OrderStatus;
  rejectionReason?: string;
  deliveryInstructions?: string;
  scheduledSlot?: string;
  deliveryBoyId?: string;
  deliveryBoyName?: string;
  deliveryBoyPhone?: string;
  deliveryOtp?: string;
  createdAt: string;
  updatedAt: string;
  modifiedByMerchant?: boolean;
}

export interface DeliveryStaff {
  id: string;
  storeId: string;
  name: string;
  mobile: string;
  pin: string;
  isActive: boolean;
  assignedOrdersCount: number;
  cashCollectedToday: number;
}

export interface KiranaListItem {
  id: string;
  name: string;
  quantity: string;
  category: string;
}

export interface KiranaList {
  id: string;
  customerId: string;
  title: string;
  items: KiranaListItem[];
}

export interface SaleRecord {
  id: string;
  storeId: string;
  orderId?: string;
  channel: 'COUNTER' | 'ONLINE';
  amount: number;
  paymentMethod: PaymentMethod;
  date: string;
  itemCount: number;
}
