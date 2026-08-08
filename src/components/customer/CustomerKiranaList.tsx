import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { ListOrdered, Plus, Trash2, ShoppingBag, CheckCircle2, Sparkles } from 'lucide-react';

export const CustomerKiranaList: React.FC<{
  onOpenCart: () => void;
}> = ({ onOpenCart }) => {
  const { kiranaList, updateKiranaList, addAllKiranaListToCart, language } = useApp();

  const [newItemName, setNewItemName] = useState('');
  const [newItemQty, setNewItemQty] = useState('');

  const handleAddItem = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newItemName.trim()) return;

    const newItem = {
      id: `li_${Date.now()}`,
      name: newItemName.trim(),
      quantity: newItemQty.trim() || '1 pack',
      category: 'Grocery',
    };

    updateKiranaList({
      ...kiranaList,
      items: [...kiranaList.items, newItem],
    });

    setNewItemName('');
    setNewItemQty('');
  };

  const handleRemoveItem = (id: string) => {
    updateKiranaList({
      ...kiranaList,
      items: kiranaList.items.filter((item) => item.id !== id),
    });
  };

  return (
    <div className="space-y-5 pb-20">
      {/* Header */}
      <div className="bg-gradient-to-r from-emerald-900 to-emerald-800 text-white p-5 rounded-2xl shadow-md border border-emerald-700 space-y-2">
        <div className="flex items-center gap-2">
          <ListOrdered className="w-6 h-6 text-amber-400" />
          <h2 className="font-black text-lg md:text-xl">{getTranslation(language, 'kiranaListTitle')}</h2>
        </div>
        <p className="text-xs text-emerald-100 max-w-lg">
          Create your monthly grocery list here. Tap <strong className="text-amber-300">"ADD ALL TO CART"</strong> to automatically match products from shop inventory and add to basket!
        </p>

        <button
          onClick={() => {
            addAllKiranaListToCart();
            onOpenCart();
          }}
          className="mt-3 bg-amber-400 hover:bg-amber-300 text-slate-950 font-black px-4 py-2.5 rounded-xl text-xs flex items-center gap-2 shadow-lg transition"
        >
          <ShoppingBag className="w-4 h-4" />
          <span>{getTranslation(language, 'addAllToCart')}</span>
        </button>
      </div>

      {/* Add Item Form */}
      <form onSubmit={handleAddItem} className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-2">
        <input
          type="text"
          placeholder="Product Name (e.g., Atta, Mustard Oil, Tea, Sugar)"
          value={newItemName}
          onChange={(e) => setNewItemName(e.target.value)}
          required
          className="flex-1 p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-emerald-600"
        />
        <input
          type="text"
          placeholder="Quantity (e.g., 5 kg, 2 L)"
          value={newItemQty}
          onChange={(e) => setNewItemQty(e.target.value)}
          className="w-full sm:w-32 p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs text-slate-900 font-medium focus:outline-none focus:ring-2 focus:ring-emerald-600"
        />
        <button
          type="submit"
          className="bg-emerald-800 hover:bg-emerald-700 text-white font-bold px-4 py-2.5 rounded-xl text-xs flex items-center justify-center gap-1 shrink-0 shadow"
        >
          <Plus className="w-4 h-4 text-amber-300" />
          <span>{getTranslation(language, 'addToList')}</span>
        </button>
      </form>

      {/* List Items */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden divide-y divide-slate-100">
        <div className="p-3 bg-slate-50 border-b border-slate-200 font-bold text-xs text-slate-700 flex justify-between">
          <span>Item Description</span>
          <span>Pack Quantity</span>
        </div>

        {kiranaList.items.length === 0 ? (
          <div className="p-8 text-center text-slate-400 text-xs font-medium">
            {getTranslation(language, 'emptyList')}
          </div>
        ) : (
          kiranaList.items.map((item) => (
            <div key={item.id} className="p-3.5 flex items-center justify-between text-xs hover:bg-emerald-50/50 transition">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-bold text-slate-900">{item.name}</span>
              </div>

              <div className="flex items-center gap-3">
                <span className="bg-emerald-100 text-emerald-950 font-bold px-2.5 py-1 rounded-md text-[11px]">
                  {item.quantity}
                </span>
                <button
                  onClick={() => handleRemoveItem(item.id)}
                  className="text-slate-400 hover:text-red-600 p-1"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
