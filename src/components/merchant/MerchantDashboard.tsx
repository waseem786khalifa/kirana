import React from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import {
  ShoppingBag,
  Clock,
  Truck,
  CheckCircle2,
  DollarSign,
  Volume2,
  Bell,
  AlertCircle,
  TrendingUp,
  Store,
  ChevronRight,
} from 'lucide-react';

export const MerchantDashboard: React.FC<{
  onNavigateToTab: (tab: string) => void;
}> = ({ onNavigateToTab }) => {
  const {
    orders,
    activeStore,
    acceptOrder,
    rejectOrder,
    soundAlertEnabled,
    setSoundAlertEnabled,
    language,
  } = useApp();

  const storeOrders = orders.filter((o) => o.storeId === activeStore.id);
  const newOrders = storeOrders.filter((o) => o.status === 'NEW');
  const preparingOrders = storeOrders.filter((o) => o.status === 'PREPARING' || o.status === 'ACCEPTED');
  const outForDeliveryOrders = storeOrders.filter((o) => o.status === 'OUT_FOR_DELIVERY' || o.status === 'READY');
  const deliveredOrders = storeOrders.filter((o) => o.status === 'DELIVERED');

  const onlineSalesToday = deliveredOrders.reduce((sum, o) => sum + o.totalAmount, 0) + 14580; // seeded base + live
  const counterSalesToday = 25000;
  const totalSalesToday = onlineSalesToday + counterSalesToday;

  return (
    <div className="space-y-6 pb-20">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-emerald-900 via-emerald-800 to-slate-900 text-white p-5 rounded-2xl shadow-lg border border-emerald-700 flex flex-wrap items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Store className="w-6 h-6 text-amber-400" />
            <h1 className="font-black text-xl md:text-2xl">{activeStore.name} Portal</h1>
            <span
              className={`text-xs font-bold px-2.5 py-0.5 rounded-full border ${
                activeStore.isOpen
                  ? 'bg-emerald-500 text-white border-emerald-400'
                  : 'bg-red-500 text-white border-red-400'
              }`}
            >
              {activeStore.isOpen ? 'ONLINE STORE OPEN' : 'STORE CLOSED'}
            </span>
          </div>
          <p className="text-xs text-emerald-200 mt-1 font-medium">
            Kirana Saarthi Merchant ID: <strong className="text-amber-300">{activeStore.code}</strong> • Phone: {activeStore.phone}
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setSoundAlertEnabled(!soundAlertEnabled)}
            className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 border shadow ${
              soundAlertEnabled
                ? 'bg-amber-400 text-slate-950 border-amber-300'
                : 'bg-emerald-950 text-emerald-400 border-emerald-800'
            }`}
          >
            <Volume2 className="w-4 h-4" />
            <span>{getTranslation(language, 'soundAlerts')}: {soundAlertEnabled ? 'ON' : 'OFF'}</span>
          </button>
        </div>
      </div>

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3">
        {/* New Orders */}
        <div
          onClick={() => onNavigateToTab('ORDERS')}
          className="bg-red-50 border-2 border-red-400 p-4 rounded-2xl cursor-pointer hover:shadow-md transition relative overflow-hidden"
        >
          <div className="flex justify-between items-start">
            <span className="text-xs font-black text-red-800 uppercase tracking-wider">
              {getTranslation(language, 'newOrders')}
            </span>
            <Bell className="w-5 h-5 text-red-600 animate-bounce" />
          </div>
          <p className="text-2xl md:text-3xl font-black text-red-950 mt-1">{newOrders.length}</p>
          <p className="text-[11px] text-red-700 font-bold mt-1">Requires Immediate Action</p>
        </div>

        {/* Preparing */}
        <div
          onClick={() => onNavigateToTab('ORDERS')}
          className="bg-amber-50 border border-amber-200 p-4 rounded-2xl cursor-pointer hover:shadow-md transition"
        >
          <span className="text-xs font-extrabold text-amber-800 uppercase tracking-wider">
            {getTranslation(language, 'preparingOrders')}
          </span>
          <p className="text-2xl md:text-3xl font-black text-amber-950 mt-1">{preparingOrders.length}</p>
          <p className="text-[11px] text-amber-700 font-medium mt-1">Packing products</p>
        </div>

        {/* Out for Delivery */}
        <div
          onClick={() => onNavigateToTab('ORDERS')}
          className="bg-blue-50 border border-blue-200 p-4 rounded-2xl cursor-pointer hover:shadow-md transition"
        >
          <span className="text-xs font-extrabold text-blue-800 uppercase tracking-wider">
            {getTranslation(language, 'outForDeliveryOrders')}
          </span>
          <p className="text-2xl md:text-3xl font-black text-blue-950 mt-1">{outForDeliveryOrders.length}</p>
          <p className="text-[11px] text-blue-700 font-medium mt-1">On the way</p>
        </div>

        {/* Delivered */}
        <div
          onClick={() => onNavigateToTab('ORDERS')}
          className="bg-emerald-50 border border-emerald-200 p-4 rounded-2xl cursor-pointer hover:shadow-md transition"
        >
          <span className="text-xs font-extrabold text-emerald-800 uppercase tracking-wider">
            {getTranslation(language, 'deliveredOrders')}
          </span>
          <p className="text-2xl md:text-3xl font-black text-emerald-950 mt-1">{deliveredOrders.length + 18}</p>
          <p className="text-[11px] text-emerald-700 font-medium mt-1">Completed today</p>
        </div>

        {/* Online Sales */}
        <div
          onClick={() => onNavigateToTab('REPORTS')}
          className="bg-slate-900 text-white border border-slate-800 p-4 rounded-2xl cursor-pointer hover:shadow-md transition col-span-2 sm:col-span-1"
        >
          <span className="text-xs font-extrabold text-amber-400 uppercase tracking-wider">
            {getTranslation(language, 'onlineSales')}
          </span>
          <p className="text-2xl md:text-3xl font-black text-white mt-1">₹{onlineSalesToday.toLocaleString()}</p>
          <p className="text-[11px] text-slate-400 font-medium mt-1">Combined Online Sales</p>
        </div>
      </div>

      {/* Prominent Incoming New Orders Stream */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="font-extrabold text-base text-slate-900 flex items-center gap-2">
            <Bell className="w-5 h-5 text-red-600 animate-pulse" />
            <span>New Incoming Customer Orders ({newOrders.length})</span>
          </h2>

          <button
            onClick={() => onNavigateToTab('ORDERS')}
            className="text-xs font-bold text-emerald-800 hover:underline flex items-center gap-1"
          >
            <span>View All Orders</span>
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>

        {newOrders.length === 0 ? (
          <div className="bg-white rounded-2xl border border-slate-200 p-6 text-center text-slate-500 text-xs font-medium space-y-1 shadow-sm">
            <p className="text-xl">✅</p>
            <p className="font-bold text-slate-800 text-sm">No new pending orders at this moment</p>
            <p>New customer orders will ring sound alerts and pop up here in real time!</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {newOrders.map((order) => (
              <div
                key={order.id}
                className="bg-white rounded-2xl border-2 border-red-500 p-5 shadow-lg space-y-3 relative overflow-hidden"
              >
                <div className="flex items-center justify-between border-b pb-2">
                  <div>
                    <span className="bg-red-600 text-white font-black text-xs px-2.5 py-0.5 rounded-md">
                      Order #{order.id}
                    </span>
                    <p className="text-xs font-bold text-slate-900 mt-1">
                      Customer: {order.customerName} ({order.customerPhone})
                    </p>
                  </div>

                  <span className="text-lg font-black text-emerald-950 bg-emerald-50 px-3 py-1 rounded-xl border border-emerald-200">
                    ₹{order.totalAmount}
                  </span>
                </div>

                <div className="text-xs text-slate-700 space-y-1">
                  <p className="font-semibold text-slate-900 truncate">
                    📍 {order.deliveryAddress.addressLine} ({order.deliveryAddress.landmark})
                  </p>
                  <p className="text-slate-600 font-medium">
                    💳 Payment: <strong className="text-slate-900">{order.paymentMethod}</strong> • {order.items.length} items
                  </p>
                  {order.deliveryInstructions && (
                    <p className="bg-amber-50 text-amber-900 p-2 rounded-lg font-semibold border border-amber-200">
                      Note: "{order.deliveryInstructions}"
                    </p>
                  )}
                </div>

                {/* Items preview */}
                <div className="bg-slate-50 p-2.5 rounded-xl text-xs space-y-1">
                  {order.items.map((i, idx) => (
                    <div key={idx} className="flex justify-between text-slate-800 font-medium">
                      <span>
                        {i.nameEn} ({i.packSize}) × {i.quantity}
                      </span>
                      <span>₹{i.price * i.quantity}</span>
                    </div>
                  ))}
                </div>

                {/* Accept / Reject Action Bar */}
                <div className="flex gap-2 pt-2 border-t">
                  <button
                    onClick={() => acceptOrder(order.id)}
                    className="flex-1 bg-emerald-700 hover:bg-emerald-600 text-white font-extrabold py-2.5 rounded-xl text-xs shadow transition"
                  >
                    {getTranslation(language, 'acceptOrder')}
                  </button>
                  <button
                    onClick={() => {
                      const reason = prompt('Reason for rejecting order:', 'Product unavailable');
                      if (reason) rejectOrder(order.id, reason);
                    }}
                    className="bg-red-50 hover:bg-red-100 text-red-700 font-extrabold px-4 py-2.5 rounded-xl text-xs border border-red-200 transition"
                  >
                    {getTranslation(language, 'rejectOrder')}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Online vs Offline Sales Split Summary */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
        <h3 className="font-extrabold text-sm text-slate-900 flex items-center gap-2">
          <TrendingUp className="w-4 h-4 text-emerald-700" />
          <span>Combined Kirana Sales Register (Online + Counter)</span>
        </h3>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-center">
          <div className="bg-slate-50 p-3 rounded-xl border border-slate-200">
            <span className="text-xs font-bold text-slate-500">Counter Counter Sales</span>
            <p className="text-xl font-black text-slate-900 mt-0.5">₹{counterSalesToday.toLocaleString()}</p>
          </div>
          <div className="bg-emerald-50 p-3 rounded-xl border border-emerald-200">
            <span className="text-xs font-bold text-emerald-800">Online Store Delivery</span>
            <p className="text-xl font-black text-emerald-950 mt-0.5">₹{onlineSalesToday.toLocaleString()}</p>
          </div>
          <div className="bg-amber-400/20 p-3 rounded-xl border border-amber-300">
            <span className="text-xs font-bold text-amber-900">Total Business Today</span>
            <p className="text-xl font-black text-slate-950 mt-0.5">₹{totalSalesToday.toLocaleString()}</p>
          </div>
        </div>
      </div>
    </div>
  );
};
