// Supabase Edge Function: admin-signup
// Creates a user with phone+password using service_role and confirms phone immediately
// Request: { phone: string, password: string }
// Response: { ok: true, user_id: string } or { ok: false, error: string }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2?target=deno';

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

export default async function handler(req: Request): Promise<Response> {
  try {
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'content-type, authorization',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
        },
      });
    }
    if (req.method !== 'POST') {
      return json({ ok: false, error: 'Method not allowed' }, 405);
    }
    const { phone, email, password } = await req.json().catch(() => ({ phone: '', email: '', password: '' }));

    if (typeof password !== 'string' || password.length < 6) {
      return json({ ok: false, error: 'Password too short' }, 400);
    }
    const trimmedPhone = (phone ?? '').trim();
    const trimmedEmail = (email ?? '').trim();
    let usePhone = false;
    let normalizedPhone = '';
    if (trimmedPhone) {
      // Accept E.164 or CN 11-digit; normalize CN to +86
      if (!/^\+?\d{10,15}$/.test(trimmedPhone) && !/^1[3-9]\d{9}$/.test(trimmedPhone)) {
        return json({ ok: false, error: 'Invalid phone format' }, 400);
      }
      normalizedPhone =
        /^1[3-9]\d{9}$/.test(trimmedPhone)
          ? `+86${trimmedPhone}`
          : trimmedPhone.startsWith('+')
          ? trimmedPhone
          : `+${trimmedPhone}`;
      usePhone = true;
    } else if (trimmedEmail) {
      // Basic email check
      if (!/^\S+@\S+\.\S+$/.test(trimmedEmail)) {
        return json({ ok: false, error: 'Invalid email format' }, 400);
      }
      usePhone = false;
    } else {
      return json({ ok: false, error: 'Invalid request body' }, 400);
    }
    if (password.length < 6) {
      return json({ ok: false, error: 'Password too short' }, 400);
    }

    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      return json({ ok: false, error: 'Service role not configured' }, 500);
    }

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data, error } = await admin.auth.admin.createUser(
      usePhone
        ? { phone: normalizedPhone, password, phone_confirm: true }
        : { email: trimmedEmail, password, email_confirm: true }
    );
    if (error) {
      // Map common errors
      const msg = (error.message || '').toLowerCase();
      if (msg.includes('registered') || msg.includes('exists')) {
        return json({ ok: false, error: '该手机号已注册' }, 409);
      }
      if (msg.includes('signups') || msg.includes('disabled')) {
        return json({ ok: false, error: '已禁用注册或手机号注册，请在 Authentication → Providers 开启 Phone 并关闭禁用注册' }, 400);
      }
      if (msg.includes('database error creating new user')) {
        return json({ ok: false, error: '创建用户时数据库错误，请检查 Auth 配置与唯一约束' }, 400);
      }
      return json({ ok: false, error: error.message }, 400);
    }

    return json({ ok: true, user_id: data.user?.id }, 200);
  } catch (e) {
    return json({ ok: false, error: `Unhandled: ${e instanceof Error ? e.message : String(e)}` }, 500);
  }
}

// Deno entrypoint
Deno.serve(handler);
