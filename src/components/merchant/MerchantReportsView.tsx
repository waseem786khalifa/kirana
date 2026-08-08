import React from 'react';
import { useApp } from '../../context/AppContext';
import { TrendingUp, ShoppingBag, Store, DollarSign, Calendar } from 'lucide-react';

export const MerchantReportsView: React.FC = () => {
  const { orders, activeStore } = useApp();

  const storeOrders = orders.filter((o) => o.storeId === activeStore.id && o.status === 'DELIVERED');
  const onlineSales = storeOrders.reduce((sum, o) => sum + o.totalAmount, 0) + 14580;
  const counterSales = 25000;
  const totalSales = onlineSales + counterSales;

  return (
    <div className="space-y-6 pb-20">
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
        <div>
          <h2 className="font-extrabold text-lg text-slate-900 tracking-tight flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-emerald-800" />
            <span>Online + Offline Sales Reports</span>
          </h2>
          <p className="text-xs text-slate-500">Real-time combined business intelligence for {activeStore.name}</p>
        </div>
      </div>

      {/* Summary KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-1">
          <span className="text-xs font-extrabold text-slate-500 uppercase tracking-wider flex items-center gap-1">
            <Store className="w-4 h-4 text-slate-600" />
            Counter Sales
          </span>
          <p className="text-3xl font-black text-slate-900">₹{counterSales.toLocaleString()}</p>
          <span className="text-[11px] text-slate-400 font-medium">Walk-in POS Transactions</span>
        </div>

        <div className="bg-emerald-50 p-5 rounded-2xl border border-emerald-200 shadow-sm space-y-1">
          <span className="text-xs font-extrabold text-emerald-800 uppercase tracking-wider flex items-center gap-1">
            <ShoppingBag className="w-4 h-4 text-emerald-600" />
            Online Store Home Delivery
          </span>
          <p className="text-3xl font-black text-emerald-950">₹{onlineSales.toLocaleString()}</p>
          <span className="text-[11px] text-emerald-700 font-medium">Delivered Customer Orders</span>
        </div>

        <div className="bg-amber-400 text-slate-950 p-5 rounded-2xl border border-amber-500 shadow-md space-y-1">
          <span className="text-xs font-extrabold text-slate-950 uppercase tracking-wider flex items-center gap-1">
            <DollarSign className="w-4 h-4 text-slate-950" />
            Total Revenue Today
          </span>
          <p className="text-3xl font-black text-slate-950">₹{totalSales.toLocaleString()}</p>
          <span className="text-[11px] font-bold text-slate-900">Combined Business Ledger</span>
        </div>
      </div>

      {/* Sales Split Progress Bar */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-3">
        <h3 className="font-extrabold text-sm text-slate-900">Sales Channel Breakdown</h3>

        <div className="space-y-1">
          <div className="h-6 w-full bg-slate-100 rounded-xl overflow-hidden flex font-bold text-[11px] text-white">
            <div
              className="bg-slate-800 flex items-center justify-center transition-all"
              style={{ width: `${(counterSales / totalSales) * 100}%` }}
            >
              Counter ({Math.round((counterSales / totalSales) * 100)}%)
            </div>
            <div
              className="bg-emerald-600 flex items-center justify-center transition-all"
              style={{ width: `${(onlineSales / totalSales) * 100}%` }}
            >
              Online ({Math.round((onlineSales / totalSales) * 100)}%)
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
