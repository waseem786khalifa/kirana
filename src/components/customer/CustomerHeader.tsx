import React from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { Store, MapPin, Phone, Clock, Truck, ShieldCheck, QrCode } from 'lucide-react';

export const CustomerHeader: React.FC<{ onOpenShopConnect: () => void }> = ({ onOpenShopConnect }) => {
  const { activeStore, language } = useApp();

  return (
    <div className="bg-white border-b border-slate-200 shadow-sm overflow-hidden mb-4">
      {/* Banner */}
      <div className="relative h-32 md:h-44 w-full bg-slate-900 overflow-hidden">
        <img
          src={activeStore.banner}
          alt={activeStore.name}
          className="w-full h-full object-cover opacity-80"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-slate-950/90 via-slate-900/30 to-transparent" />

        <div className="absolute bottom-3 left-4 right-4 flex items-end justify-between text-white">
          <div className="flex items-center gap-3">
            <img
              src={activeStore.logo}
              alt={activeStore.name}
              className="w-14 h-14 md:w-16 md:h-16 rounded-xl border-2 border-amber-400 object-cover shadow-md bg-white"
            />
            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-black text-lg md:text-2xl text-white tracking-tight">{activeStore.name}</h1>
                <span
                  className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full border ${
                    activeStore.isOpen
                      ? 'bg-emerald-500 text-white border-emerald-400'
                      : 'bg-red-500 text-white border-red-400'
                  }`}
                >
                  {activeStore.isOpen ? getTranslation(language, 'openShop') : getTranslation(language, 'closedShop')}
                </span>
              </div>
              <p className="text-xs text-slate-200 flex items-center gap-1 mt-0.5">
                <MapPin className="w-3.5 h-3.5 text-amber-400 shrink-0" />
                <span className="truncate max-w-xs md:max-w-md">{activeStore.address}</span>
              </p>
            </div>
          </div>

          <button
            onClick={onOpenShopConnect}
            className="hidden sm:flex items-center gap-1.5 bg-amber-400 text-slate-950 hover:bg-amber-300 font-bold px-3 py-1.5 rounded-xl text-xs shadow transition"
          >
            <QrCode className="w-4 h-4" />
            <span>Change Store ({activeStore.code})</span>
          </button>
        </div>
      </div>

      {/* Store Highlights Bar */}
      <div className="bg-emerald-50 px-4 py-2 text-xs text-slate-700 flex flex-wrap items-center justify-between gap-3 border-t border-emerald-100">
        <div className="flex flex-wrap items-center gap-4 text-emerald-950 font-medium">
          <span className="flex items-center gap-1">
            <Clock className="w-3.5 h-3.5 text-emerald-700" />
            Timings: {activeStore.openingTime} – {activeStore.closingTime}
          </span>
          <span className="flex items-center gap-1">
            <Truck className="w-3.5 h-3.5 text-emerald-700" />
            ETA: {activeStore.deliverySettings.expectedDeliveryTime}
          </span>
          <span className="flex items-center gap-1 font-semibold text-emerald-900">
            Min Order: ₹{activeStore.deliverySettings.minOrder} | FREE Delivery above ₹{activeStore.deliverySettings.freeDeliveryAbove}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <span className="bg-emerald-200/80 text-emerald-900 text-[11px] font-extrabold px-2 py-0.5 rounded border border-emerald-300">
            Shop Code: {activeStore.code}
          </span>
        </div>
      </div>
    </div>
  );
};
