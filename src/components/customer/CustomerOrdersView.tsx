import React from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { Order, OrderStatus } from '../../types';
import {
  Package,
  Phone,
  RotateCcw,
  XCircle,
  Clock,
  CheckCircle2,
  Truck,
  Building,
  AlertCircle,
  ChevronRight,
  Store,
} from 'lucide-react';

export const CustomerOrdersView: React.FC<{
  onOpenCart: () => void;
}> = ({ onOpenCart }) => {
  const {
    orders,
    customer,
    activeStore,
    cancelOrder,
    reorderPastOrder,
    language,
  } = useApp();

  // Filter orders for this customer / phone number
  const myOrders = orders.filter(
    (o) => o.customerId === customer.id || o.customerPhone === customer.mobile
  );

  const getStatusStepIndex = (status: OrderStatus) => {
    switch (status) {
      case 'NEW':
        return 1;
      case 'ACCEPTED':
        return 2;
      case 'PREPARING':
        return 3;
      case 'READY':
        return 4;
      case 'OUT_FOR_DELIVERY':
        return 5;
      case 'DELIVERED':
        return 6;
      case 'CANCELLED':
        return 0;
      default:
        return 1;
    }
  };

  const activeOrders = myOrders.filter((o) => o.status !== 'DELIVERED' && o.status !== 'CANCELLED');
  const pastOrders = myOrders.filter((o) => o.status === 'DELIVERED' || o.status === 'CANCELLED');

  return (
    <div className="space-y-6 pb-20">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-extrabold text-xl text-slate-900 tracking-tight flex items-center gap-2">
            <Package className="w-5 h-5 text-emerald-700" />
            <span>My Orders & Live Delivery Tracking</span>
          </h2>
          <p className="text-xs text-slate-500">Track current status or reorder previous grocery purchases</p>
        </div>
      </div>

      {myOrders.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl border border-slate-200 p-6 space-y-3 shadow-sm">
          <div className="w-16 h-16 bg-emerald-50 rounded-full flex items-center justify-center text-3xl mx-auto">
            🛍️
          </div>
          <p className="font-extrabold text-slate-800 text-base">No active or previous orders yet</p>
          <p className="text-xs text-slate-500 max-w-xs mx-auto">
            Place an order with {activeStore.name} to track home delivery here!
          </p>
        </div>
      ) : (
        <>
          {/* Active Orders Section */}
          {activeOrders.length > 0 && (
            <div className="space-y-4">
              <h3 className="font-extrabold text-sm text-slate-900 uppercase tracking-wider text-amber-800 flex items-center gap-1.5">
                <Clock className="w-4 h-4 text-amber-600 animate-spin" />
                <span>Active Orders ({activeOrders.length})</span>
              </h3>

              {activeOrders.map((order) => {
                const stepIdx = getStatusStepIndex(order.status);

                return (
                  <div
                    key={order.id}
                    className="bg-white rounded-2xl border-2 border-emerald-500 shadow-lg overflow-hidden p-5 space-y-4"
                  >
                    {/* Order Header */}
                    <div className="flex flex-wrap items-center justify-between gap-2 border-b pb-3">
                      <div>
                        <span className="bg-emerald-100 text-emerald-950 font-black text-xs px-2.5 py-1 rounded-md">
                          Order #{order.id}
                        </span>
                        <p className="text-xs text-slate-500 mt-1 font-medium">
                          Placed: {new Date(order.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} •{' '}
                          {order.scheduledSlot}
                        </p>
                      </div>

                      <div className="flex items-center gap-2">
                        <a
                          href={`tel:${activeStore.phone}`}
                          className="bg-emerald-800 hover:bg-emerald-700 text-white font-bold px-3 py-1.5 rounded-xl text-xs flex items-center gap-1 shadow-sm"
                        >
                          <Phone className="w-3.5 h-3.5" />
                          <span>{getTranslation(language, 'callShop')}</span>
                        </a>

                        {order.status === 'NEW' && (
                          <button
                            onClick={() => cancelOrder(order.id)}
                            className="bg-red-50 hover:bg-red-100 text-red-700 font-bold px-3 py-1.5 rounded-xl text-xs border border-red-200"
                          >
                            {getTranslation(language, 'cancelOrder')}
                          </button>
                        )}
                      </div>
                    </div>

                    {/* Order Modified Warning by Merchant */}
                    {order.modifiedByMerchant && (
                      <div className="bg-amber-50 border border-amber-200 p-2.5 rounded-xl text-xs text-amber-900 font-semibold flex items-center gap-2">
                        <AlertCircle className="w-4 h-4 text-amber-600 shrink-0" />
                        <span>Shopkeeper updated product quantities based on live stock.</span>
                      </div>
                    )}

                    {/* Status Workflow Progress Stepper */}
                    <div className="space-y-2 py-2 bg-slate-50 p-4 rounded-xl border border-slate-200">
                      <p className="font-bold text-xs text-slate-800">Delivery Status:</p>
                      <div className="relative flex items-center justify-between text-center">
                        <div className="absolute top-1/2 left-0 right-0 h-1 bg-slate-200 -translate-y-1/2 -z-0" />
                        <div
                          className="absolute top-1/2 left-0 h-1 bg-emerald-600 -translate-y-1/2 transition-all duration-500 -z-0"
                          style={{ width: `${((stepIdx - 1) / 5) * 100}%` }}
                        />

                        {/* Step 1: Placed */}
                        <div className="relative z-10 flex flex-col items-center">
                          <div
                            className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${
                              stepIdx >= 1 ? 'bg-emerald-600 text-white' : 'bg-slate-300 text-slate-600'
                            }`}
                          >
                            ✓
                          </div>
                          <span className="text-[10px] font-bold text-slate-700 mt-1">Order Placed</span>
                        </div>

                        {/* Step 2: Accepted */}
                        <div className="relative z-10 flex flex-col items-center">
                          <div
                            className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${
                              stepIdx >= 2 ? 'bg-emerald-600 text-white' : 'bg-slate-300 text-slate-600'
                            }`}
                          >
                            ✓
                          </div>
                          <span className="text-[10px] font-bold text-slate-700 mt-1">Shop Accepted</span>
                        </div>

                        {/* Step 3: Preparing */}
                        <div className="relative z-10 flex flex-col items-center">
                          <div
                            className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${
                              stepIdx >= 3 ? 'bg-emerald-600 text-white' : 'bg-slate-300 text-slate-600'
                            }`}
                          >
                            ✓
                          </div>
                          <span className="text-[10px] font-bold text-slate-700 mt-1">Preparing</span>
                        </div>

                        {/* Step 4: Ready / Out */}
                        <div className="relative z-10 flex flex-col items-center">
                          <div
                            className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${
                              stepIdx >= 5 ? 'bg-emerald-600 text-white' : 'bg-slate-300 text-slate-600'
                            }`}
                          >
                            🚚
                          </div>
                          <span className="text-[10px] font-bold text-slate-700 mt-1">Out for Delivery</span>
                        </div>

                        {/* Step 5: Delivered */}
                        <div className="relative z-10 flex flex-col items-center">
                          <div
                            className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${
                              stepIdx >= 6 ? 'bg-emerald-600 text-white' : 'bg-slate-300 text-slate-600'
                            }`}
                          >
                            🏠
                          </div>
                          <span className="text-[10px] font-bold text-slate-700 mt-1">Delivered</span>
                        </div>
                      </div>
                    </div>

                    {/* Delivery Boy Info if assigned */}
                    {order.deliveryBoyName && (
                      <div className="bg-emerald-50 border border-emerald-200 p-3 rounded-xl flex items-center justify-between text-xs">
                        <div>
                          <p className="font-bold text-emerald-950">Delivery Person Assigned:</p>
                          <p className="text-slate-800">{order.deliveryBoyName}</p>
                        </div>
                        <a
                          href={`tel:${order.deliveryBoyPhone}`}
                          className="bg-emerald-700 text-white font-bold px-2.5 py-1 rounded-lg flex items-center gap-1"
                        >
                          <Phone className="w-3.5 h-3.5" />
                          <span>Call Delivery Boy</span>
                        </a>
                      </div>
                    )}

                    {/* Items Summary */}
                    <div className="space-y-1.5 text-xs text-slate-800">
                      <p className="font-bold text-slate-900">Ordered Items ({order.items.length}):</p>
                      <div className="bg-slate-50 p-2.5 rounded-xl space-y-1 divide-y divide-slate-100">
                        {order.items.map((item, idx) => (
                          <div key={idx} className="flex justify-between pt-1 first:pt-0">
                            <span>
                              {language === 'HI' ? item.nameHi : language === 'MRW' ? item.nameMrw : item.nameEn} (
                              {item.packSize}) × {item.quantity}
                            </span>
                            <span className="font-bold">₹{item.price * item.quantity}</span>
                          </div>
                        ))}
                      </div>

                      <div className="flex justify-between items-baseline pt-2 font-black text-sm text-slate-900">
                        <span>Total ({order.paymentMethod}):</span>
                        <span className="text-base text-emerald-950">₹{order.totalAmount}</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Past Orders Section */}
          {pastOrders.length > 0 && (
            <div className="space-y-3 pt-4">
              <h3 className="font-extrabold text-sm text-slate-900 uppercase tracking-wider">
                Previous Orders History ({pastOrders.length})
              </h3>

              <div className="space-y-3">
                {pastOrders.map((order) => (
                  <div
                    key={order.id}
                    className="bg-white rounded-2xl border border-slate-200 p-4 shadow-sm space-y-3"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-black text-xs text-slate-900">Order #{order.id}</span>
                          <span
                            className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full ${
                              order.status === 'DELIVERED'
                                ? 'bg-emerald-100 text-emerald-800'
                                : 'bg-red-100 text-red-800'
                            }`}
                          >
                            {order.status === 'DELIVERED'
                              ? getTranslation(language, 'statusDelivered')
                              : getTranslation(language, 'statusCancelled')}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 mt-0.5">
                          {new Date(order.createdAt).toLocaleDateString()} • {order.items.length} items • ₹{order.totalAmount}
                        </p>
                      </div>

                      <button
                        onClick={() => {
                          reorderPastOrder(order);
                          onOpenCart();
                        }}
                        className="bg-amber-400 hover:bg-amber-300 text-emerald-950 font-black px-3.5 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow"
                      >
                        <RotateCcw className="w-3.5 h-3.5" />
                        <span>{getTranslation(language, 'reorder')}</span>
                      </button>
                    </div>

                    <div className="text-xs text-slate-600 bg-slate-50 p-2 rounded-lg">
                      <p className="truncate">
                        {order.items.map((i) => i.nameEn).join(', ')}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
};
