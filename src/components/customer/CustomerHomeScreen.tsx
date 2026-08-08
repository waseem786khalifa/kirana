import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { getTranslation } from '../../i18n';
import { Product } from '../../types';
import {
  Search,
  Plus,
  Minus,
  ShoppingBag,
  Sparkles,
  Zap,
  TrendingUp,
  Tag,
  CheckCircle2,
  ListOrdered,
} from 'lucide-react';

export const CATEGORIES_LIST = [
  { id: 'All', key: 'allCategories', icon: '🛒' },
  { id: 'Atta & Flour', key: 'catAtta', icon: '🌾' },
  { id: 'Rice', key: 'catRice', icon: '🍚' },
  { id: 'Dal', key: 'catDal', icon: '🫘' },
  { id: 'Oil & Ghee', key: 'catOil', icon: '🪔' },
  { id: 'Masala', key: 'catMasala', icon: '🌶️' },
  { id: 'Snacks', key: 'catSnacks', icon: '🥨' },
  { id: 'Biscuits', key: 'catBiscuits', icon: '🍪' },
  { id: 'Beverages', key: 'catBeverages', icon: '☕' },
  { id: 'Dairy', key: 'catDairy', icon: '🥛' },
  { id: 'Soap & Detergent', key: 'catSoap', icon: '🧼' },
  { id: 'Personal Care', key: 'catPersonal', icon: '🧴' },
  { id: 'Household', key: 'catHousehold', icon: '🧹' },
  { id: 'Other', key: 'catOther', icon: '📦' },
];

export const CustomerHomeScreen: React.FC<{
  onOpenKiranaList: () => void;
  onOpenCart: () => void;
}> = ({ onOpenKiranaList, onOpenCart }) => {
  const {
    products,
    language,
    cart,
    addToCart,
    updateCartQuantity,
    activeCategory,
    setActiveCategory,
    activeStore,
  } = useApp();

  const [searchQuery, setSearchQuery] = useState('');

  // Filter products by category, search query, hidden status
  const visibleProducts = products.filter((p) => {
    if (p.isHidden || !p.availableForOnline) return false;
    const matchesCategory = activeCategory === 'All' || p.category === activeCategory;
    const query = searchQuery.toLowerCase().trim();
    const matchesSearch =
      !query ||
      p.nameEn.toLowerCase().includes(query) ||
      p.nameHi.toLowerCase().includes(query) ||
      p.nameMrw.toLowerCase().includes(query) ||
      p.category.toLowerCase().includes(query);
    return matchesCategory && matchesSearch;
  });

  const getProductName = (p: Product) => {
    if (language === 'HI') return p.nameHi || p.nameEn;
    if (language === 'MRW') return p.nameMrw || p.nameHi || p.nameEn;
    return p.nameEn;
  };

  const getCartQuantity = (productId: string) => {
    const item = cart.find((i) => i.product.id === productId);
    return item ? item.quantity : 0;
  };

  return (
    <div className="space-y-6 pb-20">
      {/* Search & Kirana List Quick Trigger */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3.5 top-3 w-4 h-4 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={getTranslation(language, 'searchPlaceholder')}
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-300 rounded-2xl text-sm font-medium text-slate-900 shadow-sm focus:outline-none focus:ring-2 focus:ring-emerald-600"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-2.5 text-xs text-slate-400 hover:text-slate-600 bg-slate-100 rounded-full w-5 h-5 flex items-center justify-center font-bold"
            >
              ×
            </button>
          )}
        </div>

        <button
          onClick={onOpenKiranaList}
          className="bg-emerald-800 hover:bg-emerald-700 text-white font-bold px-3 py-2.5 rounded-2xl text-xs flex items-center gap-1.5 shadow border border-emerald-700 shrink-0"
          title="Open Monthly Grocery List"
        >
          <ListOrdered className="w-4 h-4 text-amber-400" />
          <span className="hidden sm:inline">{getTranslation(language, 'kiranaListTitle')}</span>
          <span className="sm:hidden">Grocery List</span>
        </button>
      </div>

      {/* Category Pills Slider */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <h3 className="font-extrabold text-sm text-slate-900 tracking-tight">
            {getTranslation(language, 'allCategories')}
          </h3>
          {activeCategory !== 'All' && (
            <button
              onClick={() => setActiveCategory('All')}
              className="text-xs font-bold text-emerald-700 hover:underline"
            >
              Reset Category
            </button>
          )}
        </div>

        <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none">
          {CATEGORIES_LIST.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-2xl text-xs font-bold whitespace-nowrap transition-all shadow-sm ${
                activeCategory === cat.id
                  ? 'bg-emerald-800 text-white shadow-md ring-2 ring-emerald-600'
                  : 'bg-white text-slate-700 hover:bg-emerald-50 border border-slate-200'
              }`}
            >
              <span className="text-sm">{cat.icon}</span>
              <span>{getTranslation(language, cat.key as any)}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Special Offer Banner (if All selected and no search) */}
      {activeCategory === 'All' && !searchQuery && (
        <div className="bg-gradient-to-r from-amber-500 via-amber-400 to-emerald-700 text-slate-950 p-4 rounded-2xl shadow-md flex items-center justify-between gap-4 border border-amber-300">
          <div className="space-y-1">
            <div className="inline-flex items-center gap-1 bg-slate-950 text-amber-400 text-[10px] font-black px-2 py-0.5 rounded-full uppercase">
              <Sparkles className="w-3 h-3" />
              <span>Ghar Rashan Bachat Special</span>
            </div>
            <h3 className="font-black text-lg md:text-xl text-slate-950 tracking-tight">
              FREE Delivery on Orders above ₹{activeStore.deliverySettings.freeDeliveryAbove}!
            </h3>
            <p className="text-xs text-slate-900 font-medium">
              Direct delivery from {activeStore.name} in {activeStore.deliverySettings.expectedDeliveryTime}.
            </p>
          </div>
          <button
            onClick={() => setActiveCategory('Atta & Flour')}
            className="bg-slate-950 hover:bg-slate-900 text-amber-400 font-bold px-4 py-2 rounded-xl text-xs shrink-0 shadow"
          >
            Shop Atta & Oils
          </button>
        </div>
      )}

      {/* Product Grid */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="font-extrabold text-base text-slate-900 flex items-center gap-2">
            <Zap className="w-4 h-4 text-amber-500" />
            <span>
              {activeCategory === 'All'
                ? getTranslation(language, 'popularProducts')
                : getTranslation(
                    language,
                    CATEGORIES_LIST.find((c) => c.id === activeCategory)?.key as any
                  )}
            </span>
          </h2>
          <span className="text-xs text-slate-500 font-medium">
            Showing {visibleProducts.length} items
          </span>
        </div>

        {visibleProducts.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-2xl border border-slate-200 space-y-2">
            <p className="text-2xl">🔍</p>
            <p className="font-bold text-slate-800 text-sm">No products found matching search</p>
            <p className="text-xs text-slate-500">Try searching for Atta, Rice, Oil, Dal, or Soap</p>
            <button
              onClick={() => {
                setSearchQuery('');
                setActiveCategory('All');
              }}
              className="mt-2 bg-emerald-800 text-white text-xs font-bold px-3 py-1.5 rounded-xl"
            >
              Clear Filters
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 md:gap-4">
            {visibleProducts.map((product) => {
              const qtyInCart = getCartQuantity(product.id);
              const savings = product.mrp - product.sellingPrice;
              const isOutOfStock = product.stock <= 0;

              return (
                <div
                  key={product.id}
                  className={`bg-white rounded-2xl border border-slate-200 p-3 flex flex-col justify-between shadow-sm hover:shadow-md transition relative group ${
                    isOutOfStock ? 'opacity-75 bg-slate-50' : ''
                  }`}
                >
                  {/* Savings Tag */}
                  {savings > 0 && !isOutOfStock && (
                    <div className="absolute top-2 left-2 z-10 bg-amber-500 text-slate-950 font-black text-[10px] px-2 py-0.5 rounded-full shadow-sm">
                      ₹{savings} OFF
                    </div>
                  )}

                  {/* Out of Stock Badge */}
                  {isOutOfStock && (
                    <div className="absolute top-2 left-2 z-10 bg-red-600 text-white font-extrabold text-[10px] px-2 py-0.5 rounded-full shadow-sm">
                      {getTranslation(language, 'outOfStock')}
                    </div>
                  )}

                  {/* Image */}
                  <div className="relative h-32 md:h-36 w-full mb-2 bg-slate-50 rounded-xl overflow-hidden flex items-center justify-center p-2">
                    <img
                      src={product.image}
                      alt={getProductName(product)}
                      className="max-h-full max-w-full object-contain group-hover:scale-105 transition duration-300"
                    />
                  </div>

                  {/* Details */}
                  <div className="space-y-1">
                    <span className="text-[10px] font-bold text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-100">
                      {product.packSize}
                    </span>
                    <h3 className="font-bold text-xs md:text-sm text-slate-900 line-clamp-2 min-h-[2rem] leading-snug">
                      {getProductName(product)}
                    </h3>

                    {/* Price & MRP */}
                    <div className="flex items-baseline gap-1.5 pt-1">
                      <span className="font-black text-sm md:text-base text-emerald-950">
                        ₹{product.sellingPrice}
                      </span>
                      {product.mrp > product.sellingPrice && (
                        <span className="text-xs text-slate-400 line-through font-medium">
                          ₹{product.mrp}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Add / Quantity Control Button */}
                  <div className="mt-3 pt-2 border-t border-slate-100">
                    {isOutOfStock ? (
                      <button
                        disabled
                        className="w-full bg-slate-200 text-slate-500 font-bold py-1.5 rounded-xl text-xs cursor-not-allowed"
                      >
                        Unavailable
                      </button>
                    ) : qtyInCart === 0 ? (
                      <button
                        onClick={() => addToCart(product, 1)}
                        className="w-full bg-emerald-800 hover:bg-emerald-700 text-white font-extrabold py-2 rounded-xl text-xs flex items-center justify-center gap-1 shadow-sm transition"
                      >
                        <Plus className="w-3.5 h-3.5 text-amber-300" />
                        <span>{getTranslation(language, 'add')}</span>
                      </button>
                    ) : (
                      <div className="flex items-center justify-between bg-emerald-900 text-white rounded-xl p-1 shadow">
                        <button
                          onClick={() => updateCartQuantity(product.id, qtyInCart - 1)}
                          className="w-7 h-7 flex items-center justify-center bg-emerald-800 hover:bg-emerald-700 rounded-lg text-white font-bold transition"
                        >
                          <Minus className="w-3.5 h-3.5" />
                        </button>
                        <span className="font-black text-xs px-2 text-amber-300">{qtyInCart}</span>
                        <button
                          onClick={() => updateCartQuantity(product.id, qtyInCart + 1)}
                          className="w-7 h-7 flex items-center justify-center bg-emerald-800 hover:bg-emerald-700 rounded-lg text-white font-bold transition"
                        >
                          <Plus className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
