import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { Order, OrderStatus } from '../../types';
import {
  Package,
  CheckCircle2,
  XCircle,
  Truck,
  Phone,
  UserCheck,
  Edit2,
  AlertCircle,
  Plus,
  Minus,
  X,
  Search,
} from 'lucide-react';

export const MerchantOrdersManager: React.FC = () => {
  const {
    orders,
    activeStore,
    acceptOrder,
    rejectOrder,
    updateOrderStatus,
    modifyOrderItems,
    deliveryStaff,
    language,
  } = useApp();

  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Modify Order Items Modal State
  const [editingOrder, setEditingOrder] = useState<Order | null>(null);
  const [editingItems, setEditingItems] = useState<any[]>([]);

  const storeOrders = orders.filter((o) => o.storeId === activeStore.id);

  const filteredOrders = storeOrders.filter((o) => {
    const matchesStatus = statusFilter === 'ALL' || o.status === statusFilter;
    const q = searchQuery.toLowerCase().trim();
    const matchesQuery =
      !q ||
      o.id.toLowerCase().includes(q) ||
      o.customerName.toLowerCase().includes(q) ||
      o.customerPhone.includes(q);
    return matchesStatus && matchesQuery;
  });

  const handleOpenEditModal = (order: Order) => {
    setEditingOrder(order);
    setEditingItems(JSON.parse(JSON.stringify(order.items)));
  };

  const handleSaveModifiedItems = () => {
    if (!editingOrder) return;
    const newSubtotal = editingItems.reduce((sum, i) => sum + i.price * i.quantity, 0);
    const newTotal = newSubtotal - editingOrder.discount + editingOrder.deliveryCharge;

    modifyOrderItems(editingOrder.id, editingItems, {
      subtotal: newSubtotal,
      totalAmount: Math.max(0, newTotal),
    });

    setEditingOrder(null);
  };

  const getStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case 'NEW':
        return <span className="bg-red-600 text-white font-extrabold px-2.5 py-0.5 rounded text-[11px] animate-pulse">New Order</span>;
      case 'ACCEPTED':
        return <span className="bg-amber-500 text-slate-950 font-extrabold px-2.5 py-0.5 rounded text-[11px]">Accepted</span>;
      case 'PREPARING':
        return <span className="bg-amber-600 text-white font-extrabold px-2.5 py-0.5 rounded text-[11px]">Packing Products</span>;
      case 'READY':
        return <span className="bg-blue-600 text-white font-extrabold px-2.5 py-0.5 rounded text-[11px]">Ready for Pickup</span>;
      case 'OUT_FOR_DELIVERY':
        return <span className="bg-purple-600 text-white font-extrabold px-2.5 py-0.5 rounded text-[11px]">Out for Delivery</span>;
      case 'DELIVERED':
        return <span className="bg-emerald-700 text-white font-extrabold px-2.5 py-0.5 rounded text-[11px]">Delivered</span>;
      case 'CANCELLED':
        return <span className="bg-slate-300 text-slate-700 font-extrabold px-2.5 py-0.5 rounded text-[11px]">Cancelled</span>;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-5 pb-20">
      {/* Header & Filter Controls */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h2 className="font-extrabold text-lg text-slate-900 tracking-tight flex items-center gap-2">
            <Package className="w-5 h-5 text-emerald-800" />
            <span>Online Orders Management</span>
          </h2>
          <p className="text-xs text-slate-500">Accept, pack, modify quantities & assign home delivery staff</p>
        </div>

        {/* Search Input */}
        <div className="relative w-full sm:w-64">
          <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search Order # or Mobile..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-300 rounded-xl text-xs font-medium text-slate-900"
          />
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-2 text-xs font-bold scrollbar-none">
        {['ALL', 'NEW', 'ACCEPTED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'].map(
          (tab) => {
            const count =
              tab === 'ALL'
                ? storeOrders.length
                : storeOrders.filter((o) => o.status === tab).length;

            return (
              <button
                key={tab}
                onClick={() => setStatusFilter(tab)}
                className={`px-3.5 py-2 rounded-xl whitespace-nowrap transition shadow-sm ${
                  statusFilter === tab
                    ? 'bg-emerald-900 text-white font-extrabold shadow-md'
                    : 'bg-white text-slate-700 hover:bg-slate-100 border border-slate-200'
                }`}
              >
                {tab.replace(/_/g, ' ')} ({count})
              </button>
            );
          }
        )}
      </div>

      {/* Orders List */}
      <div className="space-y-4">
        {filteredOrders.length === 0 ? (
          <div className="p-12 text-center bg-white rounded-2xl border border-slate-200 text-slate-500 text-xs font-medium">
            No orders found under "{statusFilter}" filter.
          </div>
        ) : (
          filteredOrders.map((order) => (
            <div
              key={order.id}
              className={`bg-white rounded-2xl border p-5 shadow-sm space-y-4 transition ${
                order.status === 'NEW'
                  ? 'border-2 border-red-500 shadow-md bg-red-50/20'
                  : 'border-slate-200'
              }`}
            >
              {/* Card Top */}
              <div className="flex flex-wrap items-center justify-between gap-2 border-b pb-3">
                <div className="flex items-center gap-3">
                  <span className="font-black text-sm text-slate-900 bg-slate-100 px-2.5 py-1 rounded-lg border">
                    Order #{order.id}
                  </span>
                  {getStatusBadge(order.status)}
                </div>

                <div className="flex items-center gap-2 text-xs font-bold text-slate-700">
                  <span>📅 {new Date(order.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                  <span>•</span>
                  <span>Payment: <strong className="text-emerald-950 uppercase">{order.paymentMethod}</strong></span>
                </div>
              </div>

              {/* Customer & Delivery Address */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs bg-slate-50 p-3 rounded-xl border border-slate-200">
                <div>
                  <p className="font-extrabold text-slate-900 text-sm">{order.customerName}</p>
                  <p className="text-slate-600 flex items-center gap-1 mt-0.5 font-medium">
                    <Phone className="w-3.5 h-3.5 text-emerald-700" />
                    <a href={`tel:${order.customerPhone}`} className="hover:underline text-emerald-900 font-bold">
                      {order.customerPhone}
                    </a>
                  </p>
                </div>

                <div>
                  <p className="font-bold text-slate-800">Delivery Address:</p>
                  <p className="text-slate-600 font-medium">
                    {order.deliveryAddress.addressLine}, {order.deliveryAddress.landmark} ({order.deliveryAddress.pincode})
                  </p>
                  {order.deliveryInstructions && (
                    <p className="text-amber-900 font-bold bg-amber-100/80 p-1.5 rounded mt-1">
                      Note: "{order.deliveryInstructions}"
                    </p>
                  )}
                </div>
              </div>

              {/* Items Table & Modify Quantity Trigger */}
              <div className="space-y-2">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-extrabold text-slate-800">Ordered Products ({order.items.length}):</span>
                  {order.status === 'NEW' && (
                    <button
                      onClick={() => handleOpenEditModal(order)}
                      className="text-emerald-800 hover:text-emerald-900 font-bold flex items-center gap-1 bg-emerald-50 px-2 py-1 rounded border border-emerald-200"
                    >
                      <Edit2 className="w-3 h-3 text-amber-600" />
                      <span>Modify Stock Quantities</span>
                    </button>
                  )}
                </div>

                <div className="bg-slate-50 rounded-xl p-3 space-y-1.5 text-xs divide-y divide-slate-200">
                  {order.items.map((item, idx) => (
                    <div key={idx} className="pt-1.5 first:pt-0 flex justify-between items-center text-slate-800 font-medium">
                      <div>
                        <span className="font-bold text-slate-900">{item.nameEn}</span>
                        <span className="text-[11px] text-slate-500 ml-1">({item.packSize})</span>
                        {item.originalQuantity && item.originalQuantity !== item.quantity && (
                          <span className="ml-2 text-[10px] bg-amber-200 text-amber-900 font-bold px-1 rounded">
                            Qty changed from {item.originalQuantity} → {item.quantity}
                          </span>
                        )}
                      </div>
                      <span className="font-bold text-slate-900">
                        ₹{item.price} × {item.quantity} = ₹{item.price * item.quantity}
                      </span>
                    </div>
                  ))}

                  <div className="pt-2 flex justify-between items-baseline font-black text-slate-900 text-sm">
                    <span>Order Total:</span>
                    <span className="text-base text-emerald-950">₹{order.totalAmount}</span>
                  </div>
                </div>
              </div>

              {/* Delivery Staff Assignment Bar */}
              {(order.status === 'ACCEPTED' || order.status === 'PREPARING' || order.status === 'READY') && (
                <div className="bg-emerald-50 p-3 rounded-xl border border-emerald-200 flex flex-wrap items-center justify-between gap-2 text-xs">
                  <div className="flex items-center gap-2">
                    <UserCheck className="w-4 h-4 text-emerald-700" />
                    <span className="font-bold text-emerald-950">Delivery Staff Assigned:</span>
                  </div>

                  <select
                    value={order.deliveryBoyId || ''}
                    onChange={(e) => {
                      const staff = deliveryStaff.find((s) => s.id === e.target.value);
                      if (staff) {
                        updateOrderStatus(order.id, order.status, {
                          deliveryBoyId: staff.id,
                          deliveryBoyName: staff.name,
                          deliveryBoyPhone: staff.mobile,
                        });
                      }
                    }}
                    className="bg-white border border-slate-300 rounded-lg font-bold p-1.5 text-slate-900 text-xs focus:ring-emerald-600"
                  >
                    <option value="">Select Delivery Boy...</option>
                    {deliveryStaff.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} ({s.mobile})
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {/* Order Action Buttons Workflow */}
              <div className="flex flex-wrap gap-2 pt-2 border-t">
                {order.status === 'NEW' && (
                  <>
                    <button
                      onClick={() => acceptOrder(order.id)}
                      className="bg-emerald-700 hover:bg-emerald-600 text-white font-extrabold px-4 py-2 rounded-xl text-xs shadow transition"
                    >
                      {getTranslation(language, 'acceptOrder')}
                    </button>
                    <button
                      onClick={() => {
                        const reason = prompt('Reason for rejection:', 'Out of stock');
                        if (reason) rejectOrder(order.id, reason);
                      }}
                      className="bg-red-50 text-red-700 hover:bg-red-100 font-extrabold px-4 py-2 rounded-xl text-xs border border-red-200"
                    >
                      {getTranslation(language, 'rejectOrder')}
                    </button>
                  </>
                )}

                {order.status === 'ACCEPTED' && (
                  <button
                    onClick={() => updateOrderStatus(order.id, 'PREPARING')}
                    className="bg-amber-600 hover:bg-amber-500 text-white font-extrabold px-4 py-2 rounded-xl text-xs shadow"
                  >
                    Start Packing Products
                  </button>
                )}

                {order.status === 'PREPARING' && (
                  <button
                    onClick={() => updateOrderStatus(order.id, 'READY')}
                    className="bg-blue-600 hover:bg-blue-500 text-white font-extrabold px-4 py-2 rounded-xl text-xs shadow"
                  >
                    Mark Order Ready
                  </button>
                )}

                {order.status === 'READY' && (
                  <button
                    onClick={() => updateOrderStatus(order.id, 'OUT_FOR_DELIVERY')}
                    className="bg-purple-600 hover:bg-purple-500 text-white font-extrabold px-4 py-2 rounded-xl text-xs shadow"
                  >
                    Dispatch / Out for Delivery 🚚
                  </button>
                )}

                {order.status === 'OUT_FOR_DELIVERY' && (
                  <button
                    onClick={() => updateOrderStatus(order.id, 'DELIVERED')}
                    className="bg-emerald-800 hover:bg-emerald-700 text-white font-extrabold px-5 py-2.5 rounded-xl text-xs shadow-md flex items-center gap-1.5"
                  >
                    <CheckCircle2 className="w-4 h-4 text-amber-300" />
                    <span>{getTranslation(language, 'markDelivered')}</span>
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modify Order Quantities Modal */}
      {editingOrder && (
        <div className="fixed inset-0 bg-slate-950/75 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-5 space-y-4 shadow-2xl border border-slate-200">
            <div className="flex justify-between items-center border-b pb-3">
              <h3 className="font-extrabold text-slate-900 text-sm">
                Modify Item Quantities – Order #{editingOrder.id}
              </h3>
              <button onClick={() => setEditingOrder(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <p className="text-xs text-slate-500 font-medium">
              If items are partially out of stock, adjust available quantity before accepting:
            </p>

            <div className="space-y-3 max-h-60 overflow-y-auto pr-1">
              {editingItems.map((item, idx) => (
                <div key={idx} className="flex items-center justify-between text-xs bg-slate-50 p-2.5 rounded-xl border">
                  <div>
                    <p className="font-bold text-slate-900">{item.nameEn}</p>
                    <p className="text-[11px] text-slate-500">₹{item.price} / pack</p>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => {
                        const updated = [...editingItems];
                        if (updated[idx].quantity > 0) {
                          updated[idx].originalQuantity = updated[idx].originalQuantity || updated[idx].quantity;
                          updated[idx].quantity -= 1;
                          setEditingItems(updated);
                        }
                      }}
                      className="w-6 h-6 bg-slate-200 rounded flex items-center justify-center font-bold"
                    >
                      -
                    </button>
                    <span className="font-black text-xs w-4 text-center">{item.quantity}</span>
                    <button
                      onClick={() => {
                        const updated = [...editingItems];
                        updated[idx].originalQuantity = updated[idx].originalQuantity || updated[idx].quantity;
                        updated[idx].quantity += 1;
                        setEditingItems(updated);
                      }}
                      className="w-6 h-6 bg-slate-200 rounded flex items-center justify-center font-bold"
                    >
                      +
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-2 border-t flex justify-end gap-2">
              <button
                onClick={() => setEditingOrder(null)}
                className="bg-slate-100 text-slate-700 font-bold px-4 py-2 rounded-xl text-xs"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveModifiedItems}
                className="bg-emerald-800 text-white font-bold px-4 py-2 rounded-xl text-xs shadow"
              >
                Save Updated Quantities
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
