import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'CORE/SERVICES/supabase_service.dart';
import 'router.dart';
import 'CORE/SERVICES/appTheme.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fuente Mario Admin',
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}