import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// These are auto-injected by Supabase for every deployed Edge Function.
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL')              ?? ''
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')         ?? ''
const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // ── 1. Authenticate + authorise the caller ─────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')

    // Use the caller's JWT to verify identity (anon key + their token = safe)
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) throw new Error('Unauthorized: ' + (userError?.message ?? 'no user'))

    const { data: profile, error: profileError } = await userClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError) throw new Error('Profile lookup failed: ' + profileError.message)

    if (profile?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden: caller is not an admin' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── 2. Parse action ────────────────────────────────────────────────────────
    const body   = await req.json()
    const action = body.action as string

    // Raw GoTrue admin headers — service_role key is accepted here because
    // this code runs on Supabase's Deno server, NOT in a browser.
    const adminHeaders = {
      'Content-Type' : 'application/json',
      'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
      'apikey'       : SERVICE_ROLE_KEY,
    }

    // ── 3a. Create user ─────────────────────────────────────────────────────────
    if (action === 'create_user') {
      const { email, password, role, full_name, department_id } = body

      if (!email || !password) throw new Error('email and password are required')
      if (password.length < 6)  throw new Error('Password must be at least 6 characters')

      // Raw fetch to GoTrue — bypasses the SDK's AdminApi which caused the
      // AuthRetryableFetchError (SDK was wrapping a 500 into an opaque error).
      const resp = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
        method : 'POST',
        headers: adminHeaders,
        body   : JSON.stringify({
          email          : email.trim().toLowerCase(),
          password       : password,
          email_confirm  : true,
          user_metadata  : { role, full_name, department_id },
        }),
      })

      const respData = await resp.json()

      if (!resp.ok) {
        // GoTrue puts the human-readable message in different fields depending
        // on the error type; try them all.
        const msg = respData.msg
               ?? respData.message
               ?? respData.error_description
               ?? respData.error
               ?? `GoTrue returned ${resp.status}`
        throw new Error(msg)
      }

      return new Response(JSON.stringify({ success: true, user_id: respData.id }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── 3b. Delete user ─────────────────────────────────────────────────────────
    if (action === 'delete_user') {
      const { target_user_id } = body
      if (!target_user_id) throw new Error('target_user_id is required')
      if (target_user_id === user.id) throw new Error('Admins cannot delete their own account')

      const resp = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${target_user_id}`, {
        method : 'DELETE',
        headers: adminHeaders,
      })

      if (!resp.ok) {
        const txt = await resp.text()
        throw new Error(`GoTrue delete failed (${resp.status}): ${txt}`)
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    throw new Error(`Unknown action: ${action}`)

  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : String(error)
    console.error('[admin_user_manager]', msg)

    return new Response(JSON.stringify({ error: msg }), {
      status : 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
