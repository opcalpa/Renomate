import { createClient } from '@supabase/supabase-js'

// Hämta dessa värden från din Supabase-projektinställningar
// Du hittar dem på: https://app.supabase.com/project/_/settings/api
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || ''
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || ''

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase URL eller Anon Key saknas. Kontrollera dina miljövariabler.')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
