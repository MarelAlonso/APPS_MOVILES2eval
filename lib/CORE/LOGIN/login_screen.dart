import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<bool> _guardarPerfilSeguro({
    required String userId,
    required String username,
    required String? email,
    void Function(String errorDetalle)? onError,
  }) async {
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'username': username,
        'email': email,
      }, onConflict: 'id');
      return true;
    } on PostgrestException catch (error) {
      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'username': username,
        }, onConflict: 'id');
        return true;
      } on PostgrestException catch (error2) {
        onError?.call('upsert(username): ${error2.message} [${error2.code}]');
      } catch (_) {}
      onError?.call('upsert(email+username): ${error.message} [${error.code}]');
      return false;
    } catch (_) {
      onError?.call('Error desconocido sincronizando perfil');
      return false;
    }
  }

  Future<(bool, String?)> _sincronizarPerfilTrasLogin(String accesoUsado) async {
    final usuario = Supabase.instance.client.auth.currentUser;
    if (usuario == null) return (false, 'No hay usuario autenticado');

    String? usernameProfiles;
    try {
      final perfilActual = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', usuario.id)
          .maybeSingle();
      usernameProfiles = perfilActual?['username']?.toString();
    } catch (_) {}

    final metadataUsername = usuario.userMetadata?['username']?.toString() ??
        usuario.userMetadata?['display_name']?.toString();
    final email = usuario.email;
    final usernameInferido =
        (usernameProfiles != null && usernameProfiles.isNotEmpty)
        ? usernameProfiles
        : (metadataUsername != null && metadataUsername.isNotEmpty
              ? metadataUsername
              : (accesoUsado.contains('@')
                    ? accesoUsado.split('@').first
                    : accesoUsado));

    String? detalleError;
    final ok = await _guardarPerfilSeguro(
      userId: usuario.id,
      username: usernameInferido,
      email: email,
      onError: (detalle) => detalleError = detalle,
    );
    return (ok, detalleError);
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final acceso = _emailOrUsernameController.text.trim();
      final password = _passwordController.text.trim();
      if (acceso.isEmpty || password.isEmpty) {
        const msg = 'Introduce usuario/email y contraseña';
        print(msg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(msg)),
          );
        }
        return;
      }

      Future<bool> intentarLoginConEmail(String email) async {
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: password,
          );
          return true;
        } on AuthException {
          return false;
        }
      }

      var autenticado = false;

      if (acceso.contains('@')) {
        autenticado = await intentarLoginConEmail(acceso);
      } else {
        // Login por username: buscar el email asociado en profiles
        final usernameInput = acceso.trim();
        print('Buscando username: "$usernameInput"');
        try {
          final perfil = await Supabase.instance.client
              .from('profiles')
              .select('email')
              .ilike('username', usernameInput)
              .maybeSingle();
          print('Perfil encontrado: $perfil');
          String? emailPerfil = perfil?['email']?.toString();
          print('Email encontrado para login: $emailPerfil');
          if (emailPerfil != null && emailPerfil.isNotEmpty) {
            autenticado = await intentarLoginConEmail(emailPerfil);
          } else {
            const msg = 'No existe ese nombre de usuario.';
            print(msg);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(msg)),
              );
            }
            return;
          }
        } catch (e) {
          final msg = 'Error buscando el usuario: ' + e.toString();
          print(msg);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
          return;
        }
      }

      if (autenticado) {
        // Forzar actualización de perfil en profiles tras cualquier login exitoso
        final usuario = Supabase.instance.client.auth.currentUser;
        if (usuario != null) {
          String? username;
          // Intentar obtener el username desde los metadatos o desde el acceso
          username = usuario.userMetadata?['username']?.toString() ?? usuario.userMetadata?['display_name']?.toString();
          if (username == null || username.isEmpty) {
            username = usuario.email?.split('@').first ?? acceso;
          }
          try {
            await Supabase.instance.client.from('profiles').upsert({
              'id': usuario.id,
              'username': username,
              'email': usuario.email,
            }, onConflict: 'id');
          } catch (e) {
            print('Error forzando upsert de perfil tras login: ' + e.toString());
          }
        }
        final (perfilOk, detallePerfilError) = await _sincronizarPerfilTrasLogin(acceso);
        if (mounted && !perfilOk) {
          final msg = 'Sesión iniciada, pero no se pudo guardar el nombre en profiles. ${detallePerfilError ?? ''}';
          print(msg);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
            ),
          );
        }
        if (mounted) context.go('/inicio');
        return;
      }

      if (mounted) {
        const msg = 'No se pudo iniciar sesión. Revisa tus credenciales.';
        print(msg);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(msg),
          ),
        );
      }
    } on PostgrestException catch (error) {
      final mensaje = error.code == 'PGRST204'
          ? 'Falta la columna email en profiles. Debes añadirla para login por username.'
          : error.message;
      print(mensaje);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } on AuthException catch (error) {
      print(error.message);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      const msg = 'Se ha producido un error inesperado';
      print(msg);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(msg)),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Inicio de sesión del propietario')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_person,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bienvenido',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailOrUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Crear una cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
