import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { ShoppingBag, X, Plus, Minus, Trash2, ArrowRight, Truck, Info, Tag } from 'lucide-react';

export const CustomerCartDrawer: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  onProceedCheckout: (instructions: string) => void;
}> = ({ isOpen, onClose, onProceedCheckout }) => {
  const {
    cart,
    updateCartQuantity,
    removeFromCart,
    clearCart,
    cartSubtotal,
    cartDiscount,
    cartDeliveryCharge,
    cartTotal,
    activeStore,
    language,
  } = useApp();

  const [deliveryNotes, setDeliveryNotes] = useState('');

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-slate-950/75 z-50 flex justify-end">
      <div className="bg-white w-full max-w-md h-full flex flex-col shadow-2xl animate-in slide-in-from-right duration-200">
        {/* Header */}
        <div className="bg-emerald-900 text-white p-4 flex items-center justify-between border-b border-emerald-800">
          <div className="flex items-center gap-2">
            <ShoppingBag className="w-5 h-5 text-amber-400" />
            <h2 className="font-extrabold text-base">{getTranslation(language, 'cartTitle')}</h2>
            <span className="bg-amber-400 text-emerald-950 text-xs font-black px-2 py-0.5 rounded-full">
              {cart.reduce((sum, i) => sum + i.quantity, 0)}
            </span>
          </div>
          <button onClick={onClose} className="text-emerald-200 hover:text-white p-1">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        {cart.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center p-6 text-center space-y-3">
            <div className="w-20 h-20 bg-emerald-50 rounded-full flex items-center justify-center text-3xl">
              🛒
            </div>
            <p className="font-extrabold text-slate-800 text-base">{getTranslation(language, 'emptyCart')}</p>
            <p className="text-xs text-slate-500 max-w-xs">
              Connect with {activeStore.name} to add fresh grocery items to your basket.
            </p>
            <button
              onClick={onClose}
              className="mt-4 bg-emerald-800 hover:bg-emerald-700 text-white font-bold px-5 py-2.5 rounded-xl text-xs shadow"
            >
              Browse Grocery Catalogue
            </button>
          </div>
        ) : (
          <>
            {/* Cart Items List */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3 divide-y divide-slate-100">
              {cart.map((item) => {
                const p = item.product;
                const name =
                  language === 'HI' ? p.nameHi : language === 'MRW' ? p.nameMrw : p.nameEn;

                return (
                  <div key={p.id} className="pt-3 first:pt-0 flex items-center justify-between gap-3">
                    <img
                      src={p.image}
                      alt={name}
                      className="w-14 h-14 object-contain rounded-xl bg-slate-50 border border-slate-200 p-1 shrink-0"
                    />

                    <div className="flex-1 min-w-0">
                      <h4 className="font-bold text-xs md:text-sm text-slate-900 truncate">{name}</h4>
                      <p className="text-[11px] text-slate-500 font-medium">{p.packSize}</p>
                      <div className="flex items-baseline gap-1.5 mt-0.5">
                        <span className="font-black text-xs text-emerald-950">
                          ₹{p.sellingPrice * item.quantity}
                        </span>
                        <span className="text-[10px] text-slate-400">
                          (₹{p.sellingPrice} × {item.quantity})
                        </span>
                      </div>
                    </div>

                    {/* Quantity Controls */}
                    <div className="flex items-center bg-emerald-900 text-white rounded-xl p-1 shadow-sm shrink-0">
                      <button
                        onClick={() => updateCartQuantity(p.id, item.quantity - 1)}
                        className="w-6 h-6 flex items-center justify-center bg-emerald-800 hover:bg-emerald-700 rounded-lg"
                      >
                        <Minus className="w-3 h-3" />
                      </button>
                      <span className="font-black text-xs px-2 text-amber-300">{item.quantity}</span>
                      <button
                        onClick={() => updateCartQuantity(p.id, item.quantity + 1)}
                        className="w-6 h-6 flex items-center justify-center bg-emerald-800 hover:bg-emerald-700 rounded-lg"
                      >
                        <Plus className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                );
              })}

              {/* Delivery Instructions */}
              <div className="pt-4 space-y-1.5">
                <label className="block text-xs font-bold text-slate-800">
                  {getTranslation(language, 'deliveryInstructions')}:
                </label>
                <textarea
                  rows={2}
                  value={deliveryNotes}
                  onChange={(e) => setDeliveryNotes(e.target.value)}
                  placeholder='e.g., "Doodh thanda dena", "Gate par pohanch kar call karna"'
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-600 text-slate-800"
                />
              </div>
            </div>

            {/* Bill Summary & Checkout */}
            <div className="bg-slate-50 p-4 border-t border-slate-200 space-y-3">
              <div className="space-y-1.5 text-xs">
                <div className="flex justify-between text-slate-600">
                  <span>{getTranslation(language, 'subtotal')}</span>
                  <span className="font-bold text-slate-900">₹{cartSubtotal}</span>
                </div>

                {cartDiscount > 0 && (
                  <div className="flex justify-between text-emerald-700 font-semibold">
                    <span>{getTranslation(language, 'discount')}</span>
                    <span>-₹{cartDiscount}</span>
                  </div>
                )}

                <div className="flex justify-between text-slate-600">
                  <span>{getTranslation(language, 'deliveryCharge')}</span>
                  {cartDeliveryCharge === 0 ? (
                    <span className="font-bold text-emerald-700 uppercase">
                      {getTranslation(language, 'freeDelivery')}
                    </span>
                  ) : (
                    <span className="font-bold text-slate-900">₹{cartDeliveryCharge}</span>
                  )}
                </div>

                <div className="pt-2 border-t border-slate-200 flex justify-between items-baseline font-black text-slate-900 text-sm">
                  <span>{getTranslation(language, 'totalAmount')}</span>
                  <span className="text-lg text-emerald-950">₹{cartTotal}</span>
                </div>
              </div>

              <button
                onClick={() => onProceedCheckout(deliveryNotes)}
                className="w-full bg-emerald-800 hover:bg-emerald-700 text-white font-black py-3 rounded-xl text-sm flex items-center justify-center gap-2 shadow-lg transition"
              >
                <span>Proceed to Checkout</span>
                <ArrowRight className="w-4 h-4 text-amber-300" />
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};
