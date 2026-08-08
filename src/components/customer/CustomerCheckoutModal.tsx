import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { PaymentMethod, CustomerAddress } from '../../types';
import {
  CreditCard,
  MapPin,
  Clock,
  CheckCircle2,
  AlertTriangle,
  X,
  Truck,
  Plus,
  BookOpen,
  QrCode,
} from 'lucide-react';

export const CustomerCheckoutModal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  deliveryNotes: string;
  onOrderSuccess: (orderId: string) => void;
}> = ({ isOpen, onClose, deliveryNotes, onOrderSuccess }) => {
  const {
    customer,
    activeStore,
    cartTotal,
    cartSubtotal,
    cartDiscount,
    cartDeliveryCharge,
    placeOrder,
    language,
  } = useApp();

  const [selectedAddress, setSelectedAddress] = useState<CustomerAddress>(
    customer.addresses[0] || {
      id: 'addr_new',
      label: 'Home',
      addressLine: 'House No. 12, Main Street',
      landmark: 'Near Water Tank',
      pincode: '302003',
    }
  );

  const [deliverySlot, setDeliverySlot] = useState('Deliver Now (30-45 mins)');
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('COD');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // New Address state
  const [showAddAddress, setShowAddAddress] = useState(false);
  const [newAddrLine, setNewAddrLine] = useState('');
  const [newLandmark, setNewLandmark] = useState('');
  const [newPincode, setNewPincode] = useState('');

  if (!isOpen) return null;

  const handleAddAddress = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newAddrLine) return;
    const added: CustomerAddress = {
      id: `addr_${Date.now()}`,
      label: 'Other',
      addressLine: newAddrLine,
      landmark: newLandmark,
      pincode: newPincode,
    };
    customer.addresses.push(added);
    setSelectedAddress(added);
    setShowAddAddress(false);
    setNewAddrLine('');
  };

  const handlePlaceOrder = async () => {
    setIsSubmitting(true);
    const created = await placeOrder({
      paymentMethod,
      deliveryInstructions: deliveryNotes,
      scheduledSlot: deliverySlot,
    });
    setIsSubmitting(false);
    if (created) {
      onOrderSuccess(created.id);
      onClose();
    }
  };

  const isUdhaarAllowed = customer.allowOnlineUdhaar && activeStore.paymentSettings.onlineUdhaarEnabled;
  const projectedUdhaarTotal = customer.udhaarBalance + cartTotal;

  return (
    <div className="fixed inset-0 bg-slate-950/75 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-lg w-full max-h-[90vh] overflow-hidden flex flex-col shadow-2xl border border-slate-200">
        {/* Header */}
        <div className="bg-emerald-900 text-white p-4 flex items-center justify-between border-b border-emerald-800 shrink-0">
          <div className="flex items-center gap-2">
            <Truck className="w-5 h-5 text-amber-400" />
            <h2 className="font-extrabold text-base">Checkout – {activeStore.name}</h2>
          </div>
          <button onClick={onClose} className="text-emerald-200 hover:text-white p-1">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable Form Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* 1. Customer & Delivery Address */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <h3 className="font-extrabold text-xs text-slate-900 uppercase tracking-wider flex items-center gap-1.5">
                <MapPin className="w-4 h-4 text-emerald-700" />
                <span>1. {getTranslation(language, 'deliveryAddress')}</span>
              </h3>
              <button
                onClick={() => setShowAddAddress(!showAddAddress)}
                className="text-xs font-bold text-emerald-700 hover:underline flex items-center gap-1"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>{getTranslation(language, 'addAddress')}</span>
              </button>
            </div>

            {/* Address Selector Cards */}
            <div className="space-y-2">
              {customer.addresses.map((addr) => (
                <div
                  key={addr.id}
                  onClick={() => setSelectedAddress(addr)}
                  className={`p-3 rounded-xl border text-xs cursor-pointer transition flex items-start gap-3 ${
                    selectedAddress.id === addr.id
                      ? 'border-emerald-600 bg-emerald-50/80 shadow-sm'
                      : 'border-slate-200 hover:border-slate-300 bg-white'
                  }`}
                >
                  <input
                    type="radio"
                    name="address"
                    checked={selectedAddress.id === addr.id}
                    onChange={() => setSelectedAddress(addr)}
                    className="mt-0.5 text-emerald-700 focus:ring-emerald-600"
                  />
                  <div>
                    <span className="font-bold text-emerald-950 bg-emerald-100 px-1.5 py-0.2 rounded text-[10px]">
                      {addr.label}
                    </span>
                    <p className="font-bold text-slate-900 mt-0.5">{addr.addressLine}</p>
                    <p className="text-slate-500 text-[11px]">
                      Landmark: {addr.landmark} • {addr.pincode}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            {/* Add Address Form */}
            {showAddAddress && (
              <form onSubmit={handleAddAddress} className="p-3 bg-slate-50 border border-slate-200 rounded-xl space-y-2 text-xs">
                <input
                  type="text"
                  placeholder="Address Line (House / Flat / Colony)"
                  required
                  value={newAddrLine}
                  onChange={(e) => setNewAddrLine(e.target.value)}
                  className="w-full p-2 bg-white border border-slate-300 rounded-lg text-slate-900"
                />
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="Landmark"
                    value={newLandmark}
                    onChange={(e) => setNewLandmark(e.target.value)}
                    className="flex-1 p-2 bg-white border border-slate-300 rounded-lg text-slate-900"
                  />
                  <input
                    type="text"
                    placeholder="Pincode"
                    value={newPincode}
                    onChange={(e) => setNewPincode(e.target.value)}
                    className="w-28 p-2 bg-white border border-slate-300 rounded-lg text-slate-900"
                  />
                </div>
                <button
                  type="submit"
                  className="bg-emerald-800 text-white font-bold px-3 py-1.5 rounded-lg text-xs"
                >
                  Save Address
                </button>
              </form>
            )}
          </div>

          {/* 2. Scheduled Slot Selection */}
          <div className="space-y-2">
            <h3 className="font-extrabold text-xs text-slate-900 uppercase tracking-wider flex items-center gap-1.5">
              <Clock className="w-4 h-4 text-emerald-700" />
              <span>2. {getTranslation(language, 'selectSlot')}</span>
            </h3>

            <div className="grid grid-cols-2 gap-2 text-xs">
              <button
                type="button"
                onClick={() => setDeliverySlot('Deliver Now (30-45 mins)')}
                className={`p-2.5 rounded-xl border text-left font-bold transition ${
                  deliverySlot.includes('Deliver Now')
                    ? 'border-emerald-600 bg-emerald-50 text-emerald-950 shadow-sm'
                    : 'border-slate-200 text-slate-700 hover:bg-slate-50'
                }`}
              >
                ⚡ {getTranslation(language, 'deliverNow')}
              </button>

              <button
                type="button"
                onClick={() => setDeliverySlot('Today 7:00 PM - 8:00 PM')}
                className={`p-2.5 rounded-xl border text-left font-bold transition ${
                  deliverySlot.includes('7:00 PM')
                    ? 'border-emerald-600 bg-emerald-50 text-emerald-950 shadow-sm'
                    : 'border-slate-200 text-slate-700 hover:bg-slate-50'
                }`}
              >
                📅 Today 7:00 PM - 8:00 PM
              </button>
            </div>
          </div>

          {/* 3. Payment Method Selection */}
          <div className="space-y-2">
            <h3 className="font-extrabold text-xs text-slate-900 uppercase tracking-wider flex items-center gap-1.5">
              <CreditCard className="w-4 h-4 text-emerald-700" />
              <span>3. {getTranslation(language, 'paymentMethod')}</span>
            </h3>

            <div className="space-y-2 text-xs">
              {/* Cash on Delivery */}
              <label
                className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition ${
                  paymentMethod === 'COD'
                    ? 'border-emerald-600 bg-emerald-50 shadow-sm'
                    : 'border-slate-200 bg-white'
                }`}
              >
                <div className="flex items-center gap-2">
                  <input
                    type="radio"
                    name="payment"
                    checked={paymentMethod === 'COD'}
                    onChange={() => setPaymentMethod('COD')}
                    className="text-emerald-700 focus:ring-emerald-600"
                  />
                  <div>
                    <span className="font-bold text-slate-900">{getTranslation(language, 'cod')}</span>
                    <p className="text-[11px] text-slate-500">Pay cash upon home delivery</p>
                  </div>
                </div>
                <span className="text-lg">💵</span>
              </label>

              {/* UPI */}
              <label
                className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition ${
                  paymentMethod === 'UPI'
                    ? 'border-emerald-600 bg-emerald-50 shadow-sm'
                    : 'border-slate-200 bg-white'
                }`}
              >
                <div className="flex items-center gap-2">
                  <input
                    type="radio"
                    name="payment"
                    checked={paymentMethod === 'UPI'}
                    onChange={() => setPaymentMethod('UPI')}
                    className="text-emerald-700 focus:ring-emerald-600"
                  />
                  <div>
                    <span className="font-bold text-slate-900">{getTranslation(language, 'upi')}</span>
                    <p className="text-[11px] text-slate-500">Google Pay, PhonePe, Paytm, BHIM</p>
                  </div>
                </div>
                <span className="text-lg">📱</span>
              </label>

              {/* Pay at Shop */}
              <label
                className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition ${
                  paymentMethod === 'PAY_AT_SHOP'
                    ? 'border-emerald-600 bg-emerald-50 shadow-sm'
                    : 'border-slate-200 bg-white'
                }`}
              >
                <div className="flex items-center gap-2">
                  <input
                    type="radio"
                    name="payment"
                    checked={paymentMethod === 'PAY_AT_SHOP'}
                    onChange={() => setPaymentMethod('PAY_AT_SHOP')}
                    className="text-emerald-700 focus:ring-emerald-600"
                  />
                  <div>
                    <span className="font-bold text-slate-900">{getTranslation(language, 'payAtShop')}</span>
                    <p className="text-[11px] text-slate-500">Self-pickup from store counter</p>
                  </div>
                </div>
                <span className="text-lg">🏪</span>
              </label>

              {/* Customer Udhaar Khata Ordering */}
              <div
                className={`p-3 rounded-xl border transition ${
                  paymentMethod === 'UDHAAR'
                    ? 'border-amber-500 bg-amber-50/80 shadow-md'
                    : 'border-slate-200 bg-white'
                }`}
              >
                <label className="flex items-start justify-between cursor-pointer">
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      name="payment"
                      disabled={!isUdhaarAllowed}
                      checked={paymentMethod === 'UDHAAR'}
                      onChange={() => setPaymentMethod('UDHAAR')}
                      className="text-amber-600 focus:ring-amber-500"
                    />
                    <div>
                      <div className="flex items-center gap-1.5">
                        <span className="font-bold text-slate-900">{getTranslation(language, 'udhaar')}</span>
                        {isUdhaarAllowed ? (
                          <span className="bg-emerald-600 text-white text-[10px] font-extrabold px-1.5 py-0.2 rounded">
                            Approved Customer
                          </span>
                        ) : (
                          <span className="bg-slate-200 text-slate-600 text-[10px] font-bold px-1.5 py-0.2 rounded">
                            Approval Needed
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-slate-600 mt-0.5">
                        Add order amount directly to digital Udhaar Khata
                      </p>
                    </div>
                  </div>
                  <BookOpen className="w-5 h-5 text-amber-600 shrink-0" />
                </label>

                {/* Udhaar Breakdown if selected */}
                {paymentMethod === 'UDHAAR' && (
                  <div className="mt-3 pt-2 border-t border-amber-200/80 text-xs space-y-1.5 text-slate-800 bg-white p-2.5 rounded-lg border border-amber-300">
                    <div className="flex justify-between">
                      <span>Customer Current Udhaar Balance:</span>
                      <span className="font-bold text-red-600">₹{customer.udhaarBalance}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>New Order Amount:</span>
                      <span className="font-bold text-emerald-800">+₹{cartTotal}</span>
                    </div>
                    <div className="flex justify-between pt-1 border-t font-black text-slate-900">
                      <span>New Udhaar Total if Approved:</span>
                      <span className="text-amber-700">₹{projectedUdhaarTotal}</span>
                    </div>

                    <p className="text-[11px] text-amber-800 font-semibold pt-1 flex items-center gap-1">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0 text-amber-600" />
                      <span>{getTranslation(language, 'udhaarWarning')}</span>
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 bg-slate-50 border-t border-slate-200 shrink-0 flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-500 font-medium">Total Payable:</p>
            <p className="text-xl font-black text-emerald-950">₹{cartTotal}</p>
          </div>

          <button
            onClick={handlePlaceOrder}
            disabled={isSubmitting}
            className="bg-emerald-800 hover:bg-emerald-700 text-white font-black px-6 py-3 rounded-xl text-sm shadow-lg flex items-center gap-2 transition disabled:opacity-50"
          >
            {isSubmitting ? (
              <span>Placing Order...</span>
            ) : (
              <>
                <CheckCircle2 className="w-4 h-4 text-amber-300" />
                <span>Confirm & Place Order</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
