//eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndneWlsaG1qYnp1Z3BjZ2FpanFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMjMyNzQsImV4cCI6MjA4Njg5OTI3NH0.jnirDsc5pqynGUf4OkDNpXu7n8xrVvz77fBwML0yVKc


//https://wgyilhmjbzugpcgaijqs.supabase.co

import 'package:supabase_flutter/supabase_flutter.dart';


// Servicio para conectar con supabase, inicializa y guarda cliente
class SupabaseService{
    // Cliente supabase, para hacer consultas
    static final SupabaseClient client = Supabase.instance.client;

    // Inicializa supabase, mete url y clave
    static Future<void> initialize() async {
        await Supabase.initialize(
            url: 'https://wgyilhmjbzugpcgaijqs.supabase.co',
            anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndneWlsaG1qYnp1Z3BjZ2FpanFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMjMyNzQsImV4cCI6MjA4Njg5OTI3NH0.jnirDsc5pqynGUf4OkDNpXu7n8xrVvz77fBwML0yVKc'
        );
    }
}