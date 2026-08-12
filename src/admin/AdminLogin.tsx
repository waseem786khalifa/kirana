import { FormEvent, useState } from 'react';
import { Eye, EyeOff, LockKeyhole, ShieldCheck, ShoppingBag } from 'lucide-react';
import { AdminApiError, adminApi, type AdminSession } from './api';

type Props = { onLogin: (session: AdminSession) => void };

export function AdminLogin({ onLogin }: Props) {
  const [email, setEmail] = useState('wasim786khalifa@gmail.com');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (busy) return;
    setError('');
    setBusy(true);
    try {
      onLogin(await adminApi.login(email.trim().toLowerCase(), password));
    } catch (reason) {
      setError(reason instanceof AdminApiError ? reason.message : 'Login complete nahi hua. Dobara try karein.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="min-h-screen bg-[#f3f6f2] grid lg:grid-cols-[1.12fr_0.88fr]">
      <section className="hidden lg:flex relative overflow-hidden bg-[#073d2b] px-14 py-12 text-white flex-col justify-between">
        <div className="absolute -top-32 -right-24 w-96 h-96 rounded-full bg-emerald-500/15" />
        <div className="absolute -bottom-48 -left-36 w-[34rem] h-[34rem] rounded-full border-[80px] border-emerald-500/10" />
        <div className="relative flex items-center gap-3">
          <span className="grid place-items-center w-11 h-11 rounded-2xl bg-emerald-400 text-emerald-950">
            <ShoppingBag className="w-6 h-6" strokeWidth={2.5} />
          </span>
          <div>
            <p className="text-xl font-black tracking-tight">Kirana Saarthi</p>
            <p className="text-xs text-emerald-200">Platform command centre</p>
          </div>
        </div>

        <div className="relative max-w-xl">
          <span className="inline-flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.18em] text-emerald-300 mb-5">
            <ShieldCheck className="w-4 h-4" /> Secure operations
          </span>
          <h1 className="text-5xl xl:text-6xl leading-[1.06] font-black tracking-[-0.04em]">
            Teen apps.<br />Ek control room.
          </h1>
          <p className="mt-6 text-lg leading-8 text-emerald-100/80 max-w-lg">
            Stores, customers, orders, catalogue aur delivery team ko live backend data ke saath manage karein.
          </p>
          <div className="mt-10 grid grid-cols-3 gap-3 text-sm">
            {['Customer App', 'Store Manager', 'Delivery Staff'].map((app, index) => (
              <div key={app} className="rounded-2xl border border-white/10 bg-white/5 p-4">
                <p className="text-emerald-300 font-black">0{index + 1}</p>
                <p className="mt-1 font-bold">{app}</p>
              </div>
            ))}
          </div>
        </div>

        <p className="relative text-xs text-emerald-200/60">Authorized administrators only · All changes are audited</p>
      </section>

      <section className="flex items-center justify-center px-5 py-12 sm:px-10">
        <form onSubmit={submit} className="w-full max-w-md">
          <div className="lg:hidden flex items-center gap-3 mb-12">
            <span className="grid place-items-center w-11 h-11 rounded-2xl bg-emerald-800 text-white"><ShoppingBag className="w-6 h-6" /></span>
            <div><p className="font-black text-lg">Kirana Saarthi</p><p className="text-xs text-slate-500">Super Admin</p></div>
          </div>
          <div className="w-14 h-14 grid place-items-center rounded-2xl bg-emerald-100 text-emerald-800 mb-6">
            <LockKeyhole className="w-7 h-7" />
          </div>
          <p className="text-xs font-black text-emerald-700 uppercase tracking-[0.18em]">Super Admin</p>
          <h2 className="mt-2 text-4xl font-black tracking-tight text-slate-950">Welcome back</h2>
          <p className="mt-3 text-sm leading-6 text-slate-500">Platform dashboard access karne ke liye secure credentials enter karein.</p>

          <label className="block mt-9 text-sm font-bold text-slate-700">
            Email address
            <input
              autoComplete="username"
              type="email"
              required
              value={email}
              onChange={(event) => { setEmail(event.target.value); setError(''); }}
              className="mt-2 w-full h-13 px-4 rounded-xl border border-slate-300 bg-white outline-none focus:ring-4 focus:ring-emerald-100 focus:border-emerald-700"
            />
          </label>
          <label className="block mt-5 text-sm font-bold text-slate-700">
            Password
            <span className="relative block mt-2">
              <input
                autoComplete="current-password"
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(event) => { setPassword(event.target.value); setError(''); }}
                className="w-full h-13 px-4 pr-12 rounded-xl border border-slate-300 bg-white outline-none focus:ring-4 focus:ring-emerald-100 focus:border-emerald-700"
              />
              <button type="button" onClick={() => setShowPassword((value) => !value)} className="absolute right-1 top-1 w-11 h-11 grid place-items-center rounded-lg text-slate-500 hover:bg-slate-100" aria-label={showPassword ? 'Hide password' : 'Show password'}>
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </span>
          </label>

          {error && <div role="alert" className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700">{error}</div>}

          <button disabled={busy} className="mt-6 w-full h-13 rounded-xl bg-emerald-800 text-white font-black shadow-lg shadow-emerald-900/15 hover:bg-emerald-700 disabled:opacity-60">
            {busy ? 'Secure login ho raha hai…' : 'Login to dashboard'}
          </button>
          <p className="mt-5 flex gap-2 text-xs leading-5 text-slate-500"><ShieldCheck className="w-4 h-4 shrink-0 text-emerald-700" /> Password server par hash ke against verify hota hai; browser mein plaintext credential save nahi hota.</p>
        </form>
      </section>
    </main>
  );
}
