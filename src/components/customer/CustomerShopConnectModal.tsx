import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { QrCode, Search, MapPin, Truck, Check, X, Camera, AlertCircle } from 'lucide-react';

export const CustomerShopConnectModal: React.FC<{ isOpen: boolean; onClose: () => void }> = ({
  isOpen,
  onClose,
}) => {
  const { stores, selectStore, connectShopByCode, activeStore, language } = useApp();

  const [method, setMethod] = useState<'CODE' | 'QR' | 'NEARBY'>('CODE');
  const [inputCode, setInputCode] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [scanning, setScanning] = useState(false);

  if (!isOpen) return null;

  const handleConnectByCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    setSuccessMsg('');

    if (!inputCode.trim()) {
      setErrorMsg('Please enter a valid Shop Code');
      return;
    }

    const ok = await connectShopByCode(inputCode.trim());
    if (ok) {
      setSuccessMsg(`Successfully connected to Kirana store!`);
      setTimeout(() => {
        onClose();
        setSuccessMsg('');
        setInputCode('');
      }, 1000);
    } else {
      setErrorMsg(`Shop Code "${inputCode}" not found. Try BALAJI123, MAHALAXMI456, or GUPTA789`);
    }
  };

  const handleSimulateQRScan = (storeCode: string) => {
    setScanning(true);
    setTimeout(async () => {
      setScanning(false);
      await connectShopByCode(storeCode);
      setSuccessMsg(`Scanned QR Code for ${storeCode}! Connected.`);
      setTimeout(() => {
        onClose();
        setSuccessMsg('');
      }, 1000);
    }, 1200);
  };

  return (
    <div className="fixed inset-0 bg-slate-950/75 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-lg w-full overflow-hidden shadow-2xl border border-slate-200">
        {/* Header */}
        <div className="bg-emerald-900 text-white p-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <QrCode className="w-6 h-6 text-amber-400" />
            <div>
              <h2 className="font-bold text-base">Connect to Your Kirana Dukan</h2>
              <p className="text-xs text-emerald-200">Select store to view live inventory & place order</p>
            </div>
          </div>
          <button onClick={onClose} className="text-emerald-200 hover:text-white p-1">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex border-b text-xs font-bold text-slate-700 bg-slate-50">
          <button
            onClick={() => { setMethod('CODE'); setErrorMsg(''); }}
            className={`flex-1 py-3 text-center border-b-2 transition ${
              method === 'CODE'
                ? 'border-emerald-600 text-emerald-900 bg-white font-extrabold'
                : 'border-transparent text-slate-500 hover:text-slate-900'
            }`}
          >
            1. Shop Code
          </button>
          <button
            onClick={() => { setMethod('QR'); setErrorMsg(''); }}
            className={`flex-1 py-3 text-center border-b-2 transition ${
              method === 'QR'
                ? 'border-emerald-600 text-emerald-900 bg-white font-extrabold'
                : 'border-transparent text-slate-500 hover:text-slate-900'
            }`}
          >
            2. Shop QR Code
          </button>
          <button
            onClick={() => { setMethod('NEARBY'); setErrorMsg(''); }}
            className={`flex-1 py-3 text-center border-b-2 transition ${
              method === 'NEARBY'
                ? 'border-emerald-600 text-emerald-900 bg-white font-extrabold'
                : 'border-transparent text-slate-500 hover:text-slate-900'
            }`}
          >
            3. Nearby Stores
          </button>
        </div>

        {/* Content */}
        <div className="p-5">
          {errorMsg && (
            <div className="mb-4 bg-red-50 text-red-700 p-3 rounded-xl text-xs font-semibold flex items-center gap-2 border border-red-200">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {successMsg && (
            <div className="mb-4 bg-emerald-50 text-emerald-800 p-3 rounded-xl text-xs font-semibold flex items-center gap-2 border border-emerald-200">
              <Check className="w-4 h-4 text-emerald-600 shrink-0" />
              <span>{successMsg}</span>
            </div>
          )}

          {/* Method 1: Shop Code Input */}
          {method === 'CODE' && (
            <form onSubmit={handleConnectByCode} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-800 mb-1">
                  Enter Unique Shop Code (दुकान कोड):
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={inputCode}
                    onChange={(e) => setInputCode(e.target.value.toUpperCase())}
                    placeholder="e.g. BALAJI123, MAHALAXMI456"
                    className="w-full pl-3 pr-20 py-3 bg-slate-50 border border-slate-300 rounded-xl font-mono text-base font-extrabold uppercase tracking-widest text-emerald-950 focus:outline-none focus:ring-2 focus:ring-emerald-600"
                  />
                  <button
                    type="submit"
                    className="absolute right-1.5 top-1.5 bottom-1.5 bg-emerald-700 hover:bg-emerald-800 text-white px-4 rounded-lg text-xs font-bold transition shadow"
                  >
                    Connect
                  </button>
                </div>
                <p className="text-[11px] text-slate-500 mt-1.5">
                  Sample Codes: <span className="font-mono font-bold text-emerald-800">BALAJI123</span>,{' '}
                  <span className="font-mono font-bold text-emerald-800">MAHALAXMI456</span>,{' '}
                  <span className="font-mono font-bold text-emerald-800">GUPTA789</span>
                </p>
              </div>
            </form>
          )}

          {/* Method 2: Shop QR Code Scanner */}
          {method === 'QR' && (
            <div className="text-center space-y-4">
              <div className="border-2 border-dashed border-emerald-300 rounded-2xl p-6 bg-emerald-50/50 flex flex-col items-center justify-center">
                {scanning ? (
                  <div className="py-8 space-y-3">
                    <div className="w-12 h-12 border-4 border-emerald-600 border-t-transparent rounded-full animate-spin mx-auto" />
                    <p className="text-xs font-bold text-emerald-900">Scanning Shop QR Code...</p>
                  </div>
                ) : (
                  <>
                    <Camera className="w-12 h-12 text-emerald-700 mb-2 animate-pulse" />
                    <p className="font-bold text-sm text-slate-800">Scan Display QR at Kirana Counter</p>
                    <p className="text-xs text-slate-500 max-w-xs mt-1">
                      Point camera at the printed Kirana Saarthi QR code outside or inside the shop.
                    </p>

                    <div className="mt-4 pt-4 border-t border-emerald-200/60 w-full flex flex-wrap justify-center gap-2">
                      {stores.map((s) => (
                        <button
                          key={s.id}
                          type="button"
                          onClick={() => handleSimulateQRScan(s.code)}
                          className="bg-white hover:bg-emerald-100 text-emerald-950 font-bold px-3 py-1.5 rounded-xl border border-emerald-300 text-xs shadow-sm flex items-center gap-1.5"
                        >
                          <QrCode className="w-3.5 h-3.5 text-amber-500" />
                          <span>Simulate Scan: {s.name}</span>
                        </button>
                      ))}
                    </div>
                  </>
                )}
              </div>
            </div>
          )}

          {/* Method 3: Nearby Stores Discovery */}
          {method === 'NEARBY' && (
            <div className="space-y-3 max-h-80 overflow-y-auto pr-1">
              <p className="text-xs font-bold text-slate-600 mb-2">
                Showing Kirana Saarthi stores within 5 km:
              </p>

              {stores
                .filter((s) => s.allowNearbyDiscovery)
                .map((s) => (
                  <div
                    key={s.id}
                    className={`p-3.5 rounded-xl border transition flex items-center justify-between gap-3 ${
                      activeStore.id === s.id
                        ? 'border-emerald-500 bg-emerald-50/80'
                        : 'border-slate-200 hover:border-emerald-300 bg-white'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <img
                        src={s.logo}
                        alt={s.name}
                        className="w-12 h-12 rounded-xl object-cover border border-slate-200 shrink-0"
                      />
                      <div>
                        <div className="flex items-center gap-1.5">
                          <h4 className="font-bold text-sm text-slate-900">{s.name}</h4>
                          <span className="text-[10px] bg-slate-100 text-slate-700 px-1.5 py-0.2 rounded font-mono font-bold">
                            {s.code}
                          </span>
                        </div>
                        <p className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
                          <MapPin className="w-3 h-3 text-amber-500" />
                          <span>{s.distanceKm} km away • {s.landmark}</span>
                        </p>
                        <div className="flex items-center gap-2 mt-1 text-[11px] text-emerald-900 font-semibold">
                          <span>Min: ₹{s.deliverySettings.minOrder}</span>
                          <span>•</span>
                          <span>Delivery: ₹{s.deliverySettings.deliveryCharge}</span>
                          <span>•</span>
                          <span>{s.deliverySettings.expectedDeliveryTime}</span>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => {
                        selectStore(s.id);
                        onClose();
                      }}
                      className={`px-3 py-1.5 rounded-lg text-xs font-bold transition shrink-0 ${
                        activeStore.id === s.id
                          ? 'bg-emerald-700 text-white'
                          : 'bg-emerald-100 hover:bg-emerald-200 text-emerald-900'
                      }`}
                    >
                      {activeStore.id === s.id ? 'Connected' : 'Select'}
                    </button>
                  </div>
                ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
