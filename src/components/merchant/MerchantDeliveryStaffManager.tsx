import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Truck, Plus, Phone, CheckCircle2, X } from 'lucide-react';

export const MerchantDeliveryStaffManager: React.FC = () => {
  const { deliveryStaff, addDeliveryStaff } = useApp();

  const [showAddModal, setShowAddModal] = useState(false);
  const [name, setName] = useState('');
  const [mobile, setMobile] = useState('');
  const [pin, setPin] = useState('1234');

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !mobile) return;
    await addDeliveryStaff({ name, mobile, pin });
    setShowAddModal(false);
    setName('');
    setMobile('');
  };

  return (
    <div className="space-y-5 pb-20">
      <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h2 className="font-extrabold text-lg text-slate-900 tracking-tight flex items-center gap-2">
            <Truck className="w-5 h-5 text-emerald-800" />
            <span>Delivery Staff Management</span>
          </h2>
          <p className="text-xs text-slate-500">Manage delivery boys, assigned orders and cash collected</p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="bg-emerald-800 hover:bg-emerald-700 text-white font-extrabold px-4 py-2.5 rounded-xl text-xs flex items-center gap-1.5 shadow"
        >
          <Plus className="w-4 h-4 text-amber-300" />
          <span>Add Delivery Person</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {deliveryStaff.map((staff) => (
          <div key={staff.id} className="bg-white rounded-2xl border border-slate-200 p-4 shadow-sm space-y-3">
            <div className="flex items-center justify-between border-b pb-2">
              <div>
                <h3 className="font-extrabold text-slate-900 text-sm">{staff.name}</h3>
                <p className="text-xs text-slate-500 flex items-center gap-1 font-medium">
                  <Phone className="w-3.5 h-3.5 text-emerald-700" />
                  <a href={`tel:${staff.mobile}`} className="hover:underline text-emerald-900 font-bold">
                    {staff.mobile}
                  </a>
                </p>
              </div>

              <span className="bg-emerald-100 text-emerald-900 text-xs font-bold px-2.5 py-1 rounded-md">
                Active Staff
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2 text-xs">
              <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                <span className="text-slate-500 font-bold">Assigned Active Orders:</span>
                <p className="text-base font-black text-slate-900">{staff.assignedOrdersCount}</p>
              </div>

              <div className="bg-emerald-50 p-2.5 rounded-xl border border-emerald-200">
                <span className="text-emerald-800 font-bold">Cash Collected Today:</span>
                <p className="text-base font-black text-emerald-950">₹{staff.cashCollectedToday}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {showAddModal && (
        <div className="fixed inset-0 bg-slate-950/75 z-50 flex items-center justify-center p-4">
          <form onSubmit={handleAdd} className="bg-white rounded-2xl max-w-sm w-full p-5 space-y-3 shadow-2xl border border-slate-200">
            <div className="flex justify-between items-center border-b pb-2">
              <h3 className="font-extrabold text-slate-900 text-sm">Add New Delivery Person</h3>
              <button type="button" onClick={() => setShowAddModal(false)} className="text-slate-400">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2 text-xs">
              <input
                type="text"
                placeholder="Staff Name (e.g. Mukesh Saini)"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border rounded-xl text-slate-900"
              />
              <input
                type="tel"
                placeholder="Mobile Number"
                required
                value={mobile}
                onChange={(e) => setMobile(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border rounded-xl text-slate-900"
              />
              <input
                type="password"
                placeholder="Login PIN"
                value={pin}
                onChange={(e) => setPin(e.target.value)}
                className="w-full p-2.5 bg-slate-50 border rounded-xl text-slate-900"
              />
            </div>

            <div className="pt-2 border-t flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="bg-slate-100 text-slate-700 font-bold px-3 py-1.5 rounded-lg text-xs"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="bg-emerald-800 text-white font-bold px-4 py-1.5 rounded-lg text-xs"
              >
                Save Delivery Staff
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
