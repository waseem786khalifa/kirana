import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { Store, QrCode, Share2, Save, Printer, Truck, DollarSign, Clock, ShieldCheck } from 'lucide-react';

export const MerchantOnlineStoreSettings: React.FC = () => {
  const { activeStore, updateStoreSettings, language } = useApp();

  const [isOpen, setIsOpen] = useState(activeStore.isOpen);
  const [minOrder, setMinOrder] = useState(activeStore.deliverySettings.minOrder);
  const [freeDeliveryAbove, setFreeDeliveryAbove] = useState(activeStore.deliverySettings.freeDeliveryAbove);
  const [deliveryCharge, setDeliveryCharge] = useState(activeStore.deliverySettings.deliveryCharge);
  const [radiusKm, setRadiusKm] = useState(activeStore.deliverySettings.radiusKm);
  const [expectedTime, setExpectedTime] = useState(activeStore.deliverySettings.expectedDeliveryTime);

  const [codEnabled, setCodEnabled] = useState(activeStore.paymentSettings.codEnabled);
  const [upiEnabled, setUpiEnabled] = useState(activeStore.paymentSettings.upiEnabled);
  const [udhaarEnabled, setUdhaarEnabled] = useState(activeStore.paymentSettings.onlineUdhaarEnabled);

  const [showQrPrintModal, setShowQrPrintModal] = useState(false);
  const [savedMsg, setSavedMsg] = useState(false);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    await updateStoreSettings({
      isOpen,
      deliverySettings: {
        ...activeStore.deliverySettings,
        minOrder: Number(minOrder),
        freeDeliveryAbove: Number(freeDeliveryAbove),
        deliveryCharge: Number(deliveryCharge),
        radiusKm: Number(radiusKm),
        expectedDeliveryTime: expectedTime,
      },
      paymentSettings: {
        ...activeStore.paymentSettings,
        codEnabled,
        upiEnabled,
        onlineUdhaarEnabled: udhaarEnabled,
      },
    });

    setSavedMsg(true);
    setTimeout(() => setSavedMsg(false), 2000);
  };

  return (
    <div className="space-y-6 pb-20">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h2 className="font-extrabold text-lg text-slate-900 tracking-tight flex items-center gap-2">
            <Store className="w-5 h-5 text-emerald-800" />
            <span>Kirana Store Online Configuration & Settings</span>
          </h2>
          <p className="text-xs text-slate-500">Customize delivery radius, min order, payment methods & shop QR</p>
        </div>

        <button
          onClick={() => setShowQrPrintModal(true)}
          className="bg-amber-400 hover:bg-amber-300 text-slate-950 font-extrabold px-4 py-2.5 rounded-xl text-xs flex items-center gap-1.5 shadow"
        >
          <QrCode className="w-4 h-4" />
          <span>Print Shop Display QR</span>
        </button>
      </div>

      {savedMsg && (
        <div className="bg-emerald-100 text-emerald-900 p-3 rounded-xl text-xs font-bold border border-emerald-300">
          ✓ Store settings updated successfully!
        </div>
      )}

      <form onSubmit={handleSave} className="space-y-5">
        {/* Shop Open / Closed Toggle */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
          <h3 className="font-extrabold text-sm text-slate-900">1. Shop Availability Status</h3>
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={() => setIsOpen(!isOpen)}
              className={`px-4 py-2 rounded-xl text-xs font-black transition border ${
                isOpen
                  ? 'bg-emerald-600 text-white border-emerald-500 shadow'
                  : 'bg-red-600 text-white border-red-500 shadow'
              }`}
            >
              STORE STATUS: {isOpen ? 'OPEN FOR ORDERS' : 'CLOSED'}
            </button>
            <span className="text-xs text-slate-500">
              When CLOSED, customers can browse items but cannot place new orders.
            </span>
          </div>
        </div>

        {/* Delivery Rules */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
          <h3 className="font-extrabold text-sm text-slate-900 flex items-center gap-2">
            <Truck className="w-4 h-4 text-emerald-700" />
            <span>2. Home Delivery Charges & Radius</span>
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 text-xs">
            <div>
              <label className="font-bold text-slate-700 block mb-1">Minimum Order Amount (₹):</label>
              <input
                type="number"
                value={minOrder}
                onChange={(e) => setMinOrder(Number(e.target.value))}
                className="w-full p-2.5 bg-slate-50 border rounded-xl font-bold text-slate-900"
              />
            </div>

            <div>
              <label className="font-bold text-slate-700 block mb-1">Free Delivery Above (₹):</label>
              <input
                type="number"
                value={freeDeliveryAbove}
                onChange={(e) => setFreeDeliveryAbove(Number(e.target.value))}
                className="w-full p-2.5 bg-slate-50 border rounded-xl font-bold text-slate-900"
              />
            </div>

            <div>
              <label className="font-bold text-slate-700 block mb-1">Standard Delivery Fee (₹):</label>
              <input
                type="number"
                value={deliveryCharge}
                onChange={(e) => setDeliveryCharge(Number(e.target.value))}
                className="w-full p-2.5 bg-slate-50 border rounded-xl font-bold text-slate-900"
              />
            </div>

            <div>
              <label className="font-bold text-slate-700 block mb-1">Delivery Radius (km):</label>
              <input
                type="number"
                value={radiusKm}
                onChange={(e) => setRadiusKm(Number(e.target.value))}
                className="w-full p-2.5 bg-slate-50 border rounded-xl font-bold text-slate-900"
              />
            </div>

            <div>
              <label className="font-bold text-slate-700 block mb-1">Expected Delivery Time:</label>
              <input
                type="text"
                value={expectedTime}
                onChange={(e) => setExpectedTime(e.target.value)}
                placeholder="e.g. 30-45 minutes"
                className="w-full p-2.5 bg-slate-50 border rounded-xl font-bold text-slate-900"
              />
            </div>
          </div>
        </div>

        {/* Allowed Payment Methods */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
          <h3 className="font-extrabold text-sm text-slate-900 flex items-center gap-2">
            <DollarSign className="w-4 h-4 text-emerald-700" />
            <span>3. Allowed Payment Methods</span>
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs font-bold">
            <label className="p-3 bg-slate-50 border rounded-xl flex items-center justify-between cursor-pointer">
              <span>Cash on Delivery (COD)</span>
              <input
                type="checkbox"
                checked={codEnabled}
                onChange={(e) => setCodEnabled(e.target.checked)}
                className="w-4 h-4 text-emerald-600 rounded"
              />
            </label>

            <label className="p-3 bg-slate-50 border rounded-xl flex items-center justify-between cursor-pointer">
              <span>UPI Payments</span>
              <input
                type="checkbox"
                checked={upiEnabled}
                onChange={(e) => setUpiEnabled(e.target.checked)}
                className="w-4 h-4 text-emerald-600 rounded"
              />
            </label>

            <label className="p-3 bg-slate-50 border rounded-xl flex items-center justify-between cursor-pointer">
              <span>Online Udhaar Khata</span>
              <input
                type="checkbox"
                checked={udhaarEnabled}
                onChange={(e) => setUdhaarEnabled(e.target.checked)}
                className="w-4 h-4 text-emerald-600 rounded"
              />
            </label>
          </div>
        </div>

        <button
          type="submit"
          className="bg-emerald-800 hover:bg-emerald-700 text-white font-black px-6 py-3 rounded-xl text-sm shadow-lg flex items-center gap-2"
        >
          <Save className="w-4 h-4 text-amber-300" />
          <span>Save Store Configuration</span>
        </button>
      </form>

      {/* Printable Shop Display QR Modal */}
      {showQrPrintModal && (
        <div className="fixed inset-0 bg-slate-950/80 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 text-center space-y-4 shadow-2xl border-4 border-emerald-800">
            <div className="bg-emerald-900 text-white p-3 rounded-xl">
              <h2 className="font-black text-lg">{activeStore.name}</h2>
              <p className="text-xs text-amber-300 font-bold">Online Kirana Store • QR Code</p>
            </div>

            <div className="p-4 bg-slate-50 border-2 border-dashed border-slate-300 rounded-2xl inline-block">
              <div className="w-48 h-48 bg-white border p-2 flex flex-col items-center justify-center rounded-xl shadow-inner mx-auto">
                <QrCode className="w-36 h-36 text-emerald-950" />
                <span className="font-mono font-black text-sm text-emerald-900 mt-1">
                  CODE: {activeStore.code}
                </span>
              </div>
            </div>

            <p className="text-xs text-slate-600 font-bold">
              Scan this QR code with mobile camera to open {activeStore.name} online store directly!
            </p>

            <div className="flex gap-2 pt-2">
              <button
                onClick={() => window.print()}
                className="flex-1 bg-emerald-800 text-white font-bold py-2.5 rounded-xl text-xs flex items-center justify-center gap-1.5 shadow"
              >
                <Printer className="w-4 h-4" />
                <span>Print QR Poster</span>
              </button>
              <button
                onClick={() => setShowQrPrintModal(false)}
                className="bg-slate-200 text-slate-800 font-bold px-4 py-2.5 rounded-xl text-xs"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
