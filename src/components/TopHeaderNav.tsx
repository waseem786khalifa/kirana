import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { i18n, getTranslation } from '../i18n';
import { Language, AppMode } from '../types';
import {
  ShoppingBag,
  Store,
  Truck,
  Volume2,
  VolumeX,
  Globe,
  QrCode,
  MapPin,
  CheckCircle2,
  Bell,
  X,
  Share2,
} from 'lucide-react';

export const TopHeaderNav: React.FC<{
  onOpenShopConnect: () => void;
  onOpenCart: () => void;
}> = ({ onOpenShopConnect, onOpenCart }) => {
  const {
    mode,
    setMode,
    language,
    setLanguage,
    activeStore,
    stores,
    selectStore,
    cart,
    soundAlertEnabled,
    setSoundAlertEnabled,
    newOrderNotification,
    clearNotification,
  } = useApp();

  const [showShareModal, setShowShareModal] = useState(false);

  const cartItemsCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  const whatsappMessageEn = `Namaskar 🙏\nNow order fresh grocery online from *${activeStore.name}* with home delivery!\nStore Code: *${activeStore.code}*\nOrder online here: https://kirana-saarthi.app/store/${activeStore.code}`;
  const whatsappMessageHi = `नमस्कार 🙏\nअब आप *${activeStore.name}* से घर बैठे किराना और राशन ऑनलाइन मंगा सकते हैं!\nस्टोर कोड: *${activeStore.code}*\nअभी ऑर्डर करें: https://kirana-saarthi.app/store/${activeStore.code}`;
  const whatsappMessageMrw = `राम राम सा 🙏\nअबे आप *${activeStore.name}* सूं घर बैठे राशन ऑनलाइन मंगा सको हो!\nदुकान रो कोड: *${activeStore.code}*\nअठे सूं सामान मंगाओ: https://kirana-saarthi.app/store/${activeStore.code}`;

  const currentWhatsappMsg =
    language === 'HI' ? whatsappMessageHi : language === 'MRW' ? whatsappMessageMrw : whatsappMessageEn;

  return (
    <header className="sticky top-0 z-40 bg-emerald-900 text-white shadow-md border-b border-emerald-800">
      {/* Top Bar: Mode Switcher & Controls */}
      <div className="max-w-7xl mx-auto px-3 py-2 flex flex-wrap items-center justify-between gap-2 text-sm">
        {/* App Title & Mode Switcher */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-emerald-800/80 px-2.5 py-1 rounded-lg border border-emerald-700">
            <ShoppingBag className="w-5 h-5 text-emerald-300" />
            <span className="font-bold text-base tracking-tight text-white">Kirana Saarthi</span>
          </div>

          {/* Mode Selector Tabs */}
          <div className="bg-emerald-950/70 p-0.5 rounded-lg flex items-center border border-emerald-700/60 text-xs font-medium">
            <button
              onClick={() => setMode('CUSTOMER')}
              className={`px-3 py-1 rounded-md transition-all flex items-center gap-1.5 ${
                mode === 'CUSTOMER'
                  ? 'bg-amber-500 text-slate-950 font-bold shadow'
                  : 'text-emerald-100 hover:text-white'
              }`}
            >
              <ShoppingBag className="w-3.5 h-3.5" />
              <span>{getTranslation(language, 'customerApp')}</span>
            </button>
            <button
              onClick={() => setMode('MERCHANT')}
              className={`px-3 py-1 rounded-md transition-all flex items-center gap-1.5 ${
                mode === 'MERCHANT'
                  ? 'bg-amber-500 text-slate-950 font-bold shadow'
                  : 'text-emerald-100 hover:text-white'
              }`}
            >
              <Store className="w-3.5 h-3.5" />
              <span>{getTranslation(language, 'merchantApp')}</span>
            </button>
            <button
              onClick={() => setMode('DELIVERY_BOY')}
              className={`px-3 py-1 rounded-md transition-all flex items-center gap-1.5 ${
                mode === 'DELIVERY_BOY'
                  ? 'bg-amber-500 text-slate-950 font-bold shadow'
                  : 'text-emerald-100 hover:text-white'
              }`}
            >
              <Truck className="w-3.5 h-3.5" />
              <span>{getTranslation(language, 'deliveryBoyApp')}</span>
            </button>
          </div>
        </div>

        {/* Right side controls: Store Selector, Language & Sound */}
        <div className="flex items-center gap-2">
          {/* Active Store Dropdown */}
          <div className="hidden sm:flex items-center gap-1 bg-emerald-800/60 px-2 py-1 rounded border border-emerald-700/50 text-xs">
            <Store className="w-3.5 h-3.5 text-emerald-300" />
            <select
              value={activeStore.id}
              onChange={(e) => selectStore(e.target.value)}
              className="bg-transparent text-white font-medium focus:outline-none cursor-pointer"
            >
              {stores.map((s) => (
                <option key={s.id} value={s.id} className="bg-emerald-900 text-white">
                  {s.name} ({s.code})
                </option>
              ))}
            </select>
          </div>

          {/* Connect Shop QR/Code Button (in customer mode) */}
          {mode === 'CUSTOMER' && (
            <button
              onClick={onOpenShopConnect}
              className="bg-emerald-800 hover:bg-emerald-700 text-emerald-100 px-2.5 py-1 rounded-md text-xs font-medium flex items-center gap-1 border border-emerald-600 transition"
              title="Connect Store via QR or Shop Code"
            >
              <QrCode className="w-3.5 h-3.5 text-amber-300" />
              <span className="hidden md:inline">{getTranslation(language, 'scanQr')}</span>
            </button>
          )}

          {/* Sound Alert Toggle */}
          <button
            onClick={() => setSoundAlertEnabled(!soundAlertEnabled)}
            className={`p-1.5 rounded-md border text-xs transition ${
              soundAlertEnabled
                ? 'bg-emerald-800 text-amber-300 border-emerald-600'
                : 'bg-emerald-950 text-emerald-400 border-emerald-800 opacity-60'
            }`}
            title="Toggle Sound Notifications"
          >
            {soundAlertEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
          </button>

          {/* Language Picker Toggle */}
          <div className="flex items-center bg-emerald-950 p-0.5 rounded-md border border-emerald-700 text-xs">
            <Globe className="w-3.5 h-3.5 text-emerald-300 ml-1.5 mr-1" />
            <button
              onClick={() => setLanguage('EN')}
              className={`px-1.5 py-0.5 rounded text-[11px] font-semibold ${
                language === 'EN' ? 'bg-amber-400 text-emerald-950' : 'text-emerald-200'
              }`}
            >
              EN
            </button>
            <button
              onClick={() => setLanguage('HI')}
              className={`px-1.5 py-0.5 rounded text-[11px] font-semibold ${
                language === 'HI' ? 'bg-amber-400 text-emerald-950' : 'text-emerald-200'
              }`}
            >
              हिंदी
            </button>
            <button
              onClick={() => setLanguage('MRW')}
              className={`px-1.5 py-0.5 rounded text-[11px] font-semibold ${
                language === 'MRW' ? 'bg-amber-400 text-emerald-950' : 'text-emerald-200'
              }`}
            >
              मारवाड़ी
            </button>
          </div>

          {/* Share Store Button */}
          <button
            onClick={() => setShowShareModal(true)}
            className="bg-amber-500 hover:bg-amber-400 text-slate-950 px-2.5 py-1 rounded-md text-xs font-bold flex items-center gap-1 transition"
          >
            <Share2 className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Share Store</span>
          </button>

          {/* Customer Cart Quick Button */}
          {mode === 'CUSTOMER' && (
            <button
              onClick={onOpenCart}
              className="relative bg-amber-400 hover:bg-amber-300 text-emerald-950 font-bold px-3 py-1 rounded-md text-xs flex items-center gap-1.5 transition shadow"
            >
              <ShoppingBag className="w-4 h-4" />
              <span>Basket</span>
              {cartItemsCount > 0 && (
                <span className="bg-red-600 text-white text-[11px] font-extrabold px-1.5 py-0.2 rounded-full ml-0.5">
                  {cartItemsCount}
                </span>
              )}
            </button>
          )}
        </div>
      </div>

      {/* New Order Alert Pop-up Notification Banner */}
      {newOrderNotification && (
        <div className="bg-amber-400 text-slate-950 px-4 py-2.5 flex items-center justify-between border-b border-amber-500 animate-pulse">
          <div className="flex items-center gap-3">
            <div className="bg-red-600 text-white p-1.5 rounded-full">
              <Bell className="w-5 h-5 animate-bounce" />
            </div>
            <div>
              <p className="font-extrabold text-sm">
                🚨 NEW ORDER RECEIVED! Order #{newOrderNotification.id} – ₹{newOrderNotification.totalAmount}
              </p>
              <p className="text-xs font-medium text-slate-800">
                Customer: {newOrderNotification.customerName} ({newOrderNotification.customerPhone}) •{' '}
                {newOrderNotification.items.length} items
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {mode !== 'MERCHANT' && (
              <button
                onClick={() => {
                  setMode('MERCHANT');
                  clearNotification();
                }}
                className="bg-emerald-900 text-white hover:bg-emerald-800 px-3 py-1 rounded text-xs font-bold"
              >
                View in Merchant Dashboard
              </button>
            )}
            <button
              onClick={clearNotification}
              className="text-slate-800 hover:text-slate-950 p-1"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>
      )}

      {/* Share Store Modal */}
      {showShareModal && (
        <div className="fixed inset-0 bg-slate-950/70 z-50 flex items-center justify-center p-4">
          <div className="bg-white text-slate-900 rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
            <div className="flex justify-between items-center pb-3 border-b">
              <h3 className="font-bold text-lg text-emerald-900 flex items-center gap-2">
                <Share2 className="w-5 h-5 text-amber-500" />
                {getTranslation(language, 'shareStore')}
              </h3>
              <button onClick={() => setShowShareModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="my-4 space-y-3">
              <div className="bg-emerald-50 p-3 rounded-xl border border-emerald-200">
                <p className="text-xs text-emerald-800 font-semibold mb-1">Dukan Code (Shop Code):</p>
                <p className="text-2xl font-black text-emerald-900 tracking-wider">{activeStore.code}</p>
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">
                  WhatsApp Message Template ({language}):
                </label>
                <textarea
                  readOnly
                  rows={4}
                  value={currentWhatsappMsg}
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-300 rounded-lg text-slate-800 font-mono"
                />
              </div>
            </div>

            <div className="flex gap-2 pt-2">
              <a
                href={`https://wa.me/?text=${encodeURIComponent(currentWhatsappMsg)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex-1 bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-2.5 rounded-xl text-center text-sm flex items-center justify-center gap-2 shadow"
              >
                <span>Share via WhatsApp</span>
              </a>
              <button
                onClick={() => {
                  navigator.clipboard.writeText(currentWhatsappMsg);
                  alert('Message copied to clipboard!');
                }}
                className="bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold px-4 py-2.5 rounded-xl text-sm"
              >
                Copy
              </button>
            </div>
          </div>
        </div>
      )}
    </header>
  );
};
