//eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndneWlsaG1qYnp1Z3BjZ2FpanFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMjMyNzQsImV4cCI6MjA4Njg5OTI3NH0.jnirDsc5pqynGUf4OkDNpXu7n8xrVvz77fBwML0yVKc


//https://wgyilhmjbzugpcgaijqs.supabase.co

import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseService{
    static final SupabaseClient client = Supabase.instance.client;

    static Future<void> initialize() async {
        await Supabase.initialize(
            url: 'https://wgyilhmjbzugpcgaijqs.supabase.co',
            anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndneWlsaG1qYnp1Z3BjZ2FpanFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMjMyNzQsImV4cCI6MjA4Njg5OTI3NH0.jnirDsc5pqynGUf4OkDNpXu7n8xrVvz77fBwML0yVKc'
        );
    }
}