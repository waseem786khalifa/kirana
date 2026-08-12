import { useEffect, useState } from 'react';
import { AdminDashboard } from './AdminDashboard';
import { AdminLogin } from './AdminLogin';
import { adminApi, type AdminSession } from './api';

const sessionKey = 'kirana_super_admin_session';

function readSession(): AdminSession | null {
  try {
    const raw = sessionStorage.getItem(sessionKey);
    if (!raw) return null;
    const session = JSON.parse(raw) as AdminSession;
    if (!session.token || !session.user?.email || new Date(session.expires_at).getTime() <= Date.now()) {
      sessionStorage.removeItem(sessionKey);
      return null;
    }
    return session;
  } catch {
    sessionStorage.removeItem(sessionKey);
    return null;
  }
}

export default function AdminApp() {
  const [session, setSession] = useState<AdminSession | null>(() => readSession());
  const [checking, setChecking] = useState(Boolean(session));

  useEffect(() => {
    if (!session) return;
    let active = true;
    adminApi.me(session.token).then((user) => {
      if (active) {
        const verified = { ...session, user };
        sessionStorage.setItem(sessionKey, JSON.stringify(verified));
        setSession(verified);
      }
    }).catch(() => {
      if (active) {
        sessionStorage.removeItem(sessionKey);
        setSession(null);
      }
    }).finally(() => { if (active) setChecking(false); });
    return () => { active = false; };
  }, []);

  function login(next: AdminSession) {
    sessionStorage.setItem(sessionKey, JSON.stringify(next));
    setSession(next);
  }

  async function logout() {
    const token = session?.token;
    sessionStorage.removeItem(sessionKey);
    setSession(null);
    if (token) await adminApi.logout(token).catch(() => undefined);
  }

  if (checking) return <div className="min-h-screen grid place-items-center bg-[#f4f6f3] text-sm font-bold text-emerald-800">Secure session verify ho rahi hai…</div>;
  return session ? <AdminDashboard session={session} onLogout={logout} /> : <AdminLogin onLogin={login} />;
}
