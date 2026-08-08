import React from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { Truck, Phone, MapPin, CheckCircle2, DollarSign } from 'lucide-react';

export const DeliveryBoyView: React.FC = () => {
  const { orders, updateOrderStatus, deliveryStaff, language } = useApp();

  const activeDeliveries = orders.filter(
    (o) => o.status === 'READY' || o.status === 'OUT_FOR_DELIVERY' || o.status === 'ACCEPTED'
  );

  return (
    <div className="space-y-5 pb-20 max-w-2xl mx-auto">
      <div className="bg-gradient-to-r from-emerald-900 to-slate-900 text-white p-5 rounded-2xl shadow-md space-y-1">
        <div className="flex items-center gap-2">
          <Truck className="w-6 h-6 text-amber-400" />
          <h1 className="font-black text-xl">Delivery Staff Order Portal</h1>
        </div>
        <p className="text-xs text-emerald-200">View assigned home delivery orders & record cash collection</p>
      </div>

      <div className="space-y-4">
        {activeDeliveries.length === 0 ? (
          <div className="p-12 text-center bg-white rounded-2xl border border-slate-200 text-slate-500 text-xs font-medium space-y-2">
            <p className="text-2xl">🛵</p>
            <p className="font-bold text-slate-800 text-sm">No active home deliveries assigned</p>
            <p>New assigned orders will appear here for pickup!</p>
          </div>
        ) : (
          activeDeliveries.map((order) => (
            <div key={order.id} className="bg-white rounded-2xl border-2 border-emerald-600 p-5 shadow-lg space-y-4">
              <div className="flex justify-between items-center border-b pb-2">
                <span className="bg-emerald-900 text-white font-black text-xs px-2.5 py-1 rounded-md">
                  Order #{order.id}
                </span>
                <span className="font-black text-emerald-950 text-base">₹{order.totalAmount} ({order.paymentMethod})</span>
              </div>

              <div className="space-y-1 text-xs">
                <p className="font-extrabold text-slate-900 text-sm">{order.customerName}</p>
                <p className="text-slate-600 font-bold flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5 text-emerald-700" />
                  <a href={`tel:${order.customerPhone}`} className="hover:underline text-emerald-900">
                    {order.customerPhone}
                  </a>
                </p>
                <p className="text-slate-700 font-medium mt-1 flex items-start gap-1">
                  <MapPin className="w-3.5 h-3.5 text-amber-500 shrink-0 mt-0.5" />
                  <span>{order.deliveryAddress.addressLine}, {order.deliveryAddress.landmark} ({order.deliveryAddress.pincode})</span>
                </p>
                {order.deliveryInstructions && (
                  <p className="bg-amber-50 text-amber-900 p-2 rounded-lg font-bold border border-amber-200 mt-2">
                    Note: "{order.deliveryInstructions}"
                  </p>
                )}
              </div>

              {/* Items */}
              <div className="bg-slate-50 p-2.5 rounded-xl text-xs space-y-1">
                {order.items.map((i, idx) => (
                  <div key={idx} className="flex justify-between font-medium text-slate-800">
                    <span>{i.nameEn} ({i.packSize}) × {i.quantity}</span>
                    <span>₹{i.price * i.quantity}</span>
                  </div>
                ))}
              </div>

              {/* Delivery Boy Action buttons */}
              <div className="flex gap-2 pt-2 border-t">
                {order.status !== 'OUT_FOR_DELIVERY' && (
                  <button
                    onClick={() => updateOrderStatus(order.id, 'OUT_FOR_DELIVERY')}
                    className="flex-1 bg-purple-600 hover:bg-purple-500 text-white font-extrabold py-2.5 rounded-xl text-xs shadow"
                  >
                    PICKED UP & OUT FOR DELIVERY 🛵
                  </button>
                )}

                <button
                  onClick={() => updateOrderStatus(order.id, 'DELIVERED')}
                  className="flex-1 bg-emerald-800 hover:bg-emerald-700 text-white font-extrabold py-2.5 rounded-xl text-xs shadow flex items-center justify-center gap-1"
                >
                  <CheckCircle2 className="w-4 h-4 text-amber-300" />
                  <span>MARK DELIVERED & COLLECT CASH</span>
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
