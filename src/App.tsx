import React, { useState } from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { TopHeaderNav } from './components/TopHeaderNav';
import { CustomerHeader } from './components/customer/CustomerHeader';
import { CustomerHomeScreen } from './components/customer/CustomerHomeScreen';
import { CustomerShopConnectModal } from './components/customer/CustomerShopConnectModal';
import { CustomerCartDrawer } from './components/customer/CustomerCartDrawer';
import { CustomerCheckoutModal } from './components/customer/CustomerCheckoutModal';
import { CustomerOrdersView } from './components/customer/CustomerOrdersView';
import { CustomerKiranaList } from './components/customer/CustomerKiranaList';

import { MerchantDashboard } from './components/merchant/MerchantDashboard';
import { MerchantOrdersManager } from './components/merchant/MerchantOrdersManager';
import { MerchantInventoryManager } from './components/merchant/MerchantInventoryManager';
import { MerchantKhataManager } from './components/merchant/MerchantKhataManager';
import { MerchantDeliveryStaffManager } from './components/merchant/MerchantDeliveryStaffManager';
import { MerchantOnlineStoreSettings } from './components/merchant/MerchantOnlineStoreSettings';
import { MerchantReportsView } from './components/merchant/MerchantReportsView';

import { DeliveryBoyView } from './components/delivery/DeliveryBoyView';

import {
  Home,
  Grid,
  ShoppingBag,
  Package,
  BookOpen,
  Store,
  Receipt,
  MoreHorizontal,
  Truck,
  Settings,
  TrendingUp,
  Boxes,
  ListOrdered,
} from 'lucide-react';
import { getTranslation } from './i18n';

function AppContent() {
  const { mode, language, cart, orders, activeStore } = useApp();

  // Customer Navigation State
  const [customerTab, setCustomerTab] = useState<'HOME' | 'CATEGORIES' | 'CART' | 'ORDERS' | 'LIST'>('HOME');
  
  // Merchant Navigation State
  const [merchantTab, setMerchantTab] = useState<'HOME' | 'BILLING' | 'ORDERS' | 'KHATA' | 'MORE'>('HOME');
  const [merchantMoreSubTab, setMerchantMoreSubTab] = useState<
    'INVENTORY' | 'STAFF' | 'SETTINGS' | 'REPORTS'
  >('INVENTORY');

  // Modals
  const [showShopConnect, setShowShopConnect] = useState(false);
  const [showCartDrawer, setShowCartDrawer] = useState(false);
  const [showCheckoutModal, setShowCheckoutModal] = useState(false);
  const [checkoutDeliveryNotes, setCheckoutDeliveryNotes] = useState('');

  const cartItemsCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  const newOrdersCount = orders.filter((o) => o.storeId === activeStore.id && o.status === 'NEW').length;

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 font-sans flex flex-col">
      {/* Top Bar Switcher */}
      <TopHeaderNav
        onOpenShopConnect={() => setShowShopConnect(true)}
        onOpenCart={() => setShowCartDrawer(true)}
      />

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-3 sm:p-4 md:p-6">
        {mode === 'CUSTOMER' && (
          <div>
            <CustomerHeader onOpenShopConnect={() => setShowShopConnect(true)} />

            {customerTab === 'HOME' && (
              <CustomerHomeScreen
                onOpenKiranaList={() => setCustomerTab('LIST')}
                onOpenCart={() => setShowCartDrawer(true)}
              />
            )}

            {customerTab === 'CATEGORIES' && (
              <CustomerHomeScreen
                onOpenKiranaList={() => setCustomerTab('LIST')}
                onOpenCart={() => setShowCartDrawer(true)}
              />
            )}

            {customerTab === 'ORDERS' && (
              <CustomerOrdersView onOpenCart={() => setShowCartDrawer(true)} />
            )}

            {customerTab === 'LIST' && (
              <CustomerKiranaList onOpenCart={() => setShowCartDrawer(true)} />
            )}
          </div>
        )}

        {mode === 'MERCHANT' && (
          <div>
            {merchantTab === 'HOME' && (
              <MerchantDashboard
                onNavigateToTab={(tab) => {
                  if (tab === 'ORDERS') setMerchantTab('ORDERS');
                  if (tab === 'REPORTS') {
                    setMerchantTab('MORE');
                    setMerchantMoreSubTab('REPORTS');
                  }
                }}
              />
            )}

            {merchantTab === 'BILLING' && (
              <div className="space-y-4">
                <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
                  <h2 className="font-extrabold text-lg text-slate-900 flex items-center gap-2">
                    <Receipt className="w-5 h-5 text-emerald-800" />
                    <span>Counter Sale Billing Register (POS)</span>
                  </h2>
                  <p className="text-xs text-slate-500 mt-1">
                    Record quick walk-in counter sales. Counter sales combine automatically with online store orders!
                  </p>
                </div>
                <MerchantDashboard onNavigateToTab={(t) => setMerchantTab('ORDERS')} />
              </div>
            )}

            {merchantTab === 'ORDERS' && <MerchantOrdersManager />}

            {merchantTab === 'KHATA' && <MerchantKhataManager />}

            {merchantTab === 'MORE' && (
              <div className="space-y-4">
                {/* Subtab Switcher */}
                <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs font-bold border-b border-slate-200 bg-white p-2.5 rounded-2xl shadow-sm">
                  <button
                    onClick={() => setMerchantMoreSubTab('INVENTORY')}
                    className={`px-3.5 py-2 rounded-xl transition ${
                      merchantMoreSubTab === 'INVENTORY'
                        ? 'bg-emerald-900 text-white font-extrabold'
                        : 'text-slate-600 hover:bg-slate-100'
                    }`}
                  >
                    Inventory Catalogue
                  </button>
                  <button
                    onClick={() => setMerchantMoreSubTab('STAFF')}
                    className={`px-3.5 py-2 rounded-xl transition ${
                      merchantMoreSubTab === 'STAFF'
                        ? 'bg-emerald-900 text-white font-extrabold'
                        : 'text-slate-600 hover:bg-slate-100'
                    }`}
                  >
                    Delivery Staff
                  </button>
                  <button
                    onClick={() => setMerchantMoreSubTab('SETTINGS')}
                    className={`px-3.5 py-2 rounded-xl transition ${
                      merchantMoreSubTab === 'SETTINGS'
                        ? 'bg-emerald-900 text-white font-extrabold'
                        : 'text-slate-600 hover:bg-slate-100'
                    }`}
                  >
                    Online Store Settings
                  </button>
                  <button
                    onClick={() => setMerchantMoreSubTab('REPORTS')}
                    className={`px-3.5 py-2 rounded-xl transition ${
                      merchantMoreSubTab === 'REPORTS'
                        ? 'bg-emerald-900 text-white font-extrabold'
                        : 'text-slate-600 hover:bg-slate-100'
                    }`}
                  >
                    Reports & Sales Split
                  </button>
                </div>

                {merchantMoreSubTab === 'INVENTORY' && <MerchantInventoryManager />}
                {merchantMoreSubTab === 'STAFF' && <MerchantDeliveryStaffManager />}
                {merchantMoreSubTab === 'SETTINGS' && <MerchantOnlineStoreSettings />}
                {merchantMoreSubTab === 'REPORTS' && <MerchantReportsView />}
              </div>
            )}
          </div>
        )}

        {mode === 'DELIVERY_BOY' && <DeliveryBoyView />}
      </main>

      {/* Customer Mode Bottom Navigation Bar */}
      {mode === 'CUSTOMER' && (
        <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white border-t border-slate-200 shadow-2xl py-1.5 px-4">
          <div className="max-w-md mx-auto flex items-center justify-around text-[11px] font-bold text-slate-600">
            <button
              onClick={() => setCustomerTab('HOME')}
              className={`flex flex-col items-center gap-1 transition ${
                customerTab === 'HOME' ? 'text-emerald-800 font-extrabold' : 'hover:text-slate-900'
              }`}
            >
              <Home className="w-5 h-5" />
              <span>Store Home</span>
            </button>

            <button
              onClick={() => setCustomerTab('CATEGORIES')}
              className={`flex flex-col items-center gap-1 transition ${
                customerTab === 'CATEGORIES' ? 'text-emerald-800 font-extrabold' : 'hover:text-slate-900'
              }`}
            >
              <Grid className="w-5 h-5" />
              <span>Categories</span>
            </button>

            <button
              onClick={() => setShowCartDrawer(true)}
              className="relative flex flex-col items-center gap-1 text-slate-600 hover:text-slate-900"
            >
              <ShoppingBag className="w-5 h-5 text-amber-500" />
              <span>Basket</span>
              {cartItemsCount > 0 && (
                <span className="absolute -top-1.5 right-1 bg-red-600 text-white text-[10px] font-black w-4 h-4 rounded-full flex items-center justify-center">
                  {cartItemsCount}
                </span>
              )}
            </button>

            <button
              onClick={() => setCustomerTab('ORDERS')}
              className={`flex flex-col items-center gap-1 transition ${
                customerTab === 'ORDERS' ? 'text-emerald-800 font-extrabold' : 'hover:text-slate-900'
              }`}
            >
              <Package className="w-5 h-5" />
              <span>My Orders</span>
            </button>

            <button
              onClick={() => setCustomerTab('LIST')}
              className={`flex flex-col items-center gap-1 transition ${
                customerTab === 'LIST' ? 'text-emerald-800 font-extrabold' : 'hover:text-slate-900'
              }`}
            >
              <ListOrdered className="w-5 h-5 text-emerald-700" />
              <span>Kirana List</span>
            </button>
          </div>
        </nav>
      )}

      {/* Merchant Mode Revised Bottom Navigation Bar */}
      {mode === 'MERCHANT' && (
        <nav className="fixed bottom-0 left-0 right-0 z-40 bg-emerald-950 text-white border-t border-emerald-800 shadow-2xl py-2 px-4">
          <div className="max-w-lg mx-auto flex items-center justify-around text-[11px] font-bold">
            <button
              onClick={() => setMerchantTab('HOME')}
              className={`flex flex-col items-center gap-1 transition ${
                merchantTab === 'HOME' ? 'text-amber-400 font-black' : 'text-emerald-200 hover:text-white'
              }`}
            >
              <Home className="w-5 h-5" />
              <span>Home</span>
            </button>

            <button
              onClick={() => setMerchantTab('BILLING')}
              className={`flex flex-col items-center gap-1 transition ${
                merchantTab === 'BILLING' ? 'text-amber-400 font-black' : 'text-emerald-200 hover:text-white'
              }`}
            >
              <Receipt className="w-5 h-5" />
              <span>Billing</span>
            </button>

            <button
              onClick={() => setMerchantTab('ORDERS')}
              className={`relative flex flex-col items-center gap-1 transition ${
                merchantTab === 'ORDERS' ? 'text-amber-400 font-black' : 'text-emerald-200 hover:text-white'
              }`}
            >
              <Package className="w-5 h-5" />
              <span>Orders</span>
              {newOrdersCount > 0 && (
                <span className="absolute -top-1 right-1 bg-red-600 text-white text-[10px] font-extrabold w-4 h-4 rounded-full flex items-center justify-center animate-pulse">
                  {newOrdersCount}
                </span>
              )}
            </button>

            <button
              onClick={() => setMerchantTab('KHATA')}
              className={`flex flex-col items-center gap-1 transition ${
                merchantTab === 'KHATA' ? 'text-amber-400 font-black' : 'text-emerald-200 hover:text-white'
              }`}
            >
              <BookOpen className="w-5 h-5" />
              <span>Khata</span>
            </button>

            <button
              onClick={() => setMerchantTab('MORE')}
              className={`flex flex-col items-center gap-1 transition ${
                merchantTab === 'MORE' ? 'text-amber-400 font-black' : 'text-emerald-200 hover:text-white'
              }`}
            >
              <MoreHorizontal className="w-5 h-5" />
              <span>More</span>
            </button>
          </div>
        </nav>
      )}

      {/* Modals & Drawers */}
      <CustomerShopConnectModal
        isOpen={showShopConnect}
        onClose={() => setShowShopConnect(false)}
      />

      <CustomerCartDrawer
        isOpen={showCartDrawer}
        onClose={() => setShowCartDrawer(false)}
        onProceedCheckout={(notes) => {
          setCheckoutDeliveryNotes(notes);
          setShowCartDrawer(false);
          setShowCheckoutModal(true);
        }}
      />

      <CustomerCheckoutModal
        isOpen={showCheckoutModal}
        onClose={() => setShowCheckoutModal(false)}
        deliveryNotes={checkoutDeliveryNotes}
        onOrderSuccess={() => {
          setCustomerTab('ORDERS');
        }}
      />
    </div>
  );
}

export default function App() {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
}
