import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Product } from '../../types';
import { CATEGORIES_LIST } from '../customer/CustomerHomeScreen';
import { Plus, Search, Eye, EyeOff, Edit3, Check, X, Tag, PackageCheck } from 'lucide-react';

export const MerchantInventoryManager: React.FC = () => {
  const { products, activeStore, addProduct, updateProduct } = useApp();

  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('All');

  // Add Product Modal
  const [showAddModal, setShowAddModal] = useState(false);
  const [nameEn, setNameEn] = useState('');
  const [nameHi, setNameHi] = useState('');
  const [nameMrw, setNameMrw] = useState('');
  const [category, setCategory] = useState('Atta & Flour');
  const [packSize, setPackSize] = useState('1 kg');
  const [mrp, setMrp] = useState(100);
  const [sellingPrice, setSellingPrice] = useState(90);
  const [stock, setStock] = useState(20);
  const [imageUrl, setImageUrl] = useState('');

  const storeProducts = products.filter((p) => p.storeId === activeStore.id);

  const filteredProducts = storeProducts.filter((p) => {
    const matchesCat = categoryFilter === 'All' || p.category === categoryFilter;
    const q = searchQuery.toLowerCase().trim();
    const matchesQuery =
      !q ||
      p.nameEn.toLowerCase().includes(q) ||
      p.nameHi.toLowerCase().includes(q) ||
      p.category.toLowerCase().includes(q);
    return matchesCat && matchesQuery;
  });

  const handleCreateProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nameEn) return;

    await addProduct({
      nameEn,
      nameHi: nameHi || nameEn,
      nameMrw: nameMrw || nameHi || nameEn,
      category,
      packSize,
      mrp: Number(mrp),
      sellingPrice: Number(sellingPrice),
      stock: Number(stock),
      image: imageUrl || 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400',
      availableForOnline: true,
      isHidden: false,
    });

    setShowAddModal(false);
    setNameEn('');
    setNameHi('');
    setNameMrw('');
  };

  return (
    <div className="space-y-5 pb-20">
      {/* Top Controls */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h2 className="font-extrabold text-lg text-slate-900 tracking-tight flex items-center gap-2">
            <PackageCheck className="w-5 h-5 text-emerald-800" />
            <span>Connected Inventory & Product Catalogue</span>
          </h2>
          <p className="text-xs text-slate-500">Updates here sync immediately to customer online store view</p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="bg-emerald-800 hover:bg-emerald-700 text-white font-extrabold px-4 py-2.5 rounded-xl text-xs flex items-center gap-1.5 shadow"
        >
          <Plus className="w-4 h-4 text-amber-300" />
          <span>Add New Product</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="flex flex-col sm:flex-row items-center gap-2">
        <div className="relative flex-1 w-full">
          <Search className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search items by name or category..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-2 bg-white border border-slate-300 rounded-xl text-xs font-medium text-slate-900"
          />
        </div>

        <select
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          className="w-full sm:w-48 p-2 bg-white border border-slate-300 rounded-xl text-xs font-bold text-slate-800"
        >
          {CATEGORIES_LIST.map((c) => (
            <option key={c.id} value={c.id}>
              {c.id}
            </option>
          ))}
        </select>
      </div>

      {/* Product Table / Cards */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden divide-y divide-slate-100">
        <div className="p-3 bg-slate-50 font-extrabold text-xs text-slate-700 grid grid-cols-12 gap-2 border-b">
          <span className="col-span-5 sm:col-span-4">Product Details</span>
          <span className="col-span-2">MRP / Price</span>
          <span className="col-span-2">Live Stock</span>
          <span className="col-span-3 sm:col-span-4 text-right">Online Toggle / Actions</span>
        </div>

        {filteredProducts.length === 0 ? (
          <div className="p-8 text-center text-slate-400 text-xs font-medium">
            No products found matching filters.
          </div>
        ) : (
          filteredProducts.map((p) => (
            <div key={p.id} className="p-3 grid grid-cols-12 gap-2 items-center text-xs hover:bg-slate-50 transition">
              {/* Product info */}
              <div className="col-span-5 sm:col-span-4 flex items-center gap-2.5">
                <img
                  src={p.image}
                  alt={p.nameEn}
                  className="w-10 h-10 object-contain bg-slate-50 rounded-lg border p-0.5 shrink-0"
                />
                <div>
                  <p className="font-bold text-slate-900 line-clamp-1">{p.nameEn}</p>
                  <p className="text-[11px] text-slate-500">{p.nameHi} • {p.packSize}</p>
                </div>
              </div>

              {/* Price */}
              <div className="col-span-2">
                <span className="font-black text-emerald-950">₹{p.sellingPrice}</span>
                <span className="text-[10px] text-slate-400 line-through block">₹{p.mrp}</span>
              </div>

              {/* Stock Editor */}
              <div className="col-span-2">
                <input
                  type="number"
                  value={p.stock}
                  onChange={(e) => updateProduct(p.id, { stock: Number(e.target.value) })}
                  className={`w-16 p-1 border rounded font-bold text-xs ${
                    p.stock <= 0 ? 'bg-red-50 border-red-300 text-red-700' : 'bg-slate-50 border-slate-300'
                  }`}
                />
              </div>

              {/* Online Toggle */}
              <div className="col-span-3 sm:col-span-4 flex items-center justify-end gap-2">
                <button
                  onClick={() => updateProduct(p.id, { availableForOnline: !p.availableForOnline })}
                  className={`px-2.5 py-1 rounded-lg text-[11px] font-extrabold flex items-center gap-1 transition ${
                    p.availableForOnline
                      ? 'bg-emerald-100 text-emerald-900 border border-emerald-300'
                      : 'bg-slate-100 text-slate-600 border border-slate-300'
                  }`}
                >
                  <span>Online: {p.availableForOnline ? 'ON' : 'OFF'}</span>
                </button>

                <button
                  onClick={() => updateProduct(p.id, { isHidden: !p.isHidden })}
                  className="p-1 text-slate-400 hover:text-slate-600"
                  title="Hide Product"
                >
                  {p.isHidden ? <EyeOff className="w-4 h-4 text-red-500" /> : <Eye className="w-4 h-4 text-slate-500" />}
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Add Product Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-slate-950/75 z-50 flex items-center justify-center p-4">
          <form onSubmit={handleCreateProduct} className="bg-white rounded-2xl max-w-lg w-full p-5 space-y-3 shadow-2xl border border-slate-200">
            <div className="flex justify-between items-center border-b pb-2">
              <h3 className="font-extrabold text-slate-900 text-sm">Add New Grocery Item</h3>
              <button type="button" onClick={() => setShowAddModal(false)} className="text-slate-400">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
              <div>
                <label className="font-bold text-slate-700 block mb-1">Name (English):</label>
                <input
                  type="text"
                  required
                  value={nameEn}
                  onChange={(e) => setNameEn(e.target.value)}
                  placeholder="e.g. Aashirvaad Atta"
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Name (Hindi):</label>
                <input
                  type="text"
                  value={nameHi}
                  onChange={(e) => setNameHi(e.target.value)}
                  placeholder="e.g. आशीर्वाद आटा"
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Category:</label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                >
                  {CATEGORIES_LIST.filter((c) => c.id !== 'All').map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.id}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Pack Size:</label>
                <input
                  type="text"
                  value={packSize}
                  onChange={(e) => setPackSize(e.target.value)}
                  placeholder="e.g. 5 kg, 1 L, 500 g"
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">MRP (₹):</label>
                <input
                  type="number"
                  value={mrp}
                  onChange={(e) => setMrp(Number(e.target.value))}
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Selling Price (₹):</label>
                <input
                  type="number"
                  value={sellingPrice}
                  onChange={(e) => setSellingPrice(Number(e.target.value))}
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Initial Stock:</label>
                <input
                  type="number"
                  value={stock}
                  onChange={(e) => setStock(Number(e.target.value))}
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Image URL:</label>
                <input
                  type="text"
                  value={imageUrl}
                  onChange={(e) => setImageUrl(e.target.value)}
                  placeholder="https://images.unsplash.com/..."
                  className="w-full p-2 bg-slate-50 border rounded-lg text-slate-900"
                />
              </div>
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
                Add Product
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
