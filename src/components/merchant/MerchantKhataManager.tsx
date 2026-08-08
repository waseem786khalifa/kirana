import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { CustomerProfile } from '../../types';
import { BookOpen, UserCheck, ShieldAlert, Plus, Check, Search, Phone, History } from 'lucide-react';

export const MerchantKhataManager: React.FC = () => {
  const {
    savedCustomers,
    activeStore,
    toggleOnlineUdhaarPermission,
    addKhataPayment,
    khataEntries,
  } = useApp();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCust, setSelectedCust] = useState<CustomerProfile | null>(null);
  const [payAmount, setPayAmount] = useState('');
  const [payNote, setPayNote] = useState('');

  const storeCustomers = savedCustomers.filter((c) => c.storeId === activeStore.id);

  const filteredCustomers = storeCustomers.filter(
    (c) =>
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.mobile.includes(searchQuery)
  );

  const handleRecordPayment = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedCust || !payAmount) return;

    addKhataPayment(selectedCust.id, Number(payAmount), payNote || 'Khata Cash Payment Received');
    setPayAmount('');
    setPayNote('');
    setSelectedCust(null);
  };

  return (
    <div className="space-y-5 pb-20">
      {/* Header */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="font-extrabold text-lg text-slate-900 tracking-tight flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-amber-600" />
            <span>Digital Udhaar Khata & Customer Permissions</span>
          </h2>
          <p className="text-xs text-slate-500">Enable "Allow Online Udhaar" for trusted regular customers only</p>
        </div>

        <div className="relative w-full sm:w-64">
          <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search customer name or mobile..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-300 rounded-xl text-xs font-medium text-slate-900"
          />
        </div>
      </div>

      {/* Customer Udhaar Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden divide-y divide-slate-100">
        <div className="p-3 bg-slate-50 font-extrabold text-xs text-slate-700 grid grid-cols-12 gap-2 border-b">
          <span className="col-span-4">Customer Name & Phone</span>
          <span className="col-span-2">Udhaar Balance</span>
          <span className="col-span-2">Total Orders</span>
          <span className="col-span-4 text-right">Online Udhaar Permission</span>
        </div>

        {filteredCustomers.length === 0 ? (
          <div className="p-8 text-center text-slate-400 text-xs font-medium">
            No customers found.
          </div>
        ) : (
          filteredCustomers.map((cust) => (
            <div key={cust.id} className="p-3.5 grid grid-cols-12 gap-2 items-center text-xs hover:bg-slate-50 transition">
              <div className="col-span-4">
                <p className="font-bold text-slate-900">{cust.name}</p>
                <p className="text-[11px] text-slate-500 font-medium">{cust.mobile}</p>
              </div>

              <div className="col-span-2 font-black text-sm text-red-600">
                ₹{cust.udhaarBalance}
              </div>

              <div className="col-span-2 font-bold text-slate-700">
                {cust.totalOrders} orders (₹{cust.totalSpent})
              </div>

              <div className="col-span-4 flex items-center justify-end gap-2">
                <button
                  onClick={() => setSelectedCust(cust)}
                  className="bg-emerald-50 hover:bg-emerald-100 text-emerald-900 font-bold px-2.5 py-1 rounded-lg text-xs border border-emerald-200"
                >
                  Collect Cash
                </button>

                <button
                  onClick={() => toggleOnlineUdhaarPermission(cust.id, !cust.allowOnlineUdhaar)}
                  className={`px-3 py-1 rounded-lg text-[11px] font-black transition border ${
                    cust.allowOnlineUdhaar
                      ? 'bg-amber-400 text-slate-950 border-amber-500 shadow-sm'
                      : 'bg-slate-100 text-slate-600 border-slate-300'
                  }`}
                >
                  {cust.allowOnlineUdhaar ? 'Online Udhaar: ALLOWED' : 'Online Udhaar: OFF'}
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Collect Cash Modal */}
      {selectedCust && (
        <div className="fixed inset-0 bg-slate-950/75 z-50 flex items-center justify-center p-4">
          <form onSubmit={handleRecordPayment} className="bg-white rounded-2xl max-w-md w-full p-5 space-y-4 shadow-2xl border border-slate-200">
            <h3 className="font-extrabold text-slate-900 text-sm">
              Record Khata Payment – {selectedCust.name}
            </h3>
            <p className="text-xs text-slate-600">Current Balance: <strong className="text-red-600">₹{selectedCust.udhaarBalance}</strong></p>

            <div className="space-y-2 text-xs">
              <input
                type="number"
                placeholder="Payment Amount Received (₹)"
                required
                value={payAmount}
                onChange={(e) => setPayAmount(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border rounded-xl font-bold text-slate-900"
              />
              <input
                type="text"
                placeholder="Note / Receipt Details"
                value={payNote}
                onChange={(e) => setPayNote(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border rounded-xl text-slate-900"
              />
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t">
              <button
                type="button"
                onClick={() => setSelectedCust(null)}
                className="bg-slate-100 text-slate-700 font-bold px-4 py-2 rounded-xl text-xs"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="bg-emerald-800 text-white font-bold px-4 py-2 rounded-xl text-xs shadow"
              >
                Record Received Payment
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
