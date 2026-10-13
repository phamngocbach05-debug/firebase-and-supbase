import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo hệ sinh thái Firebase (Yêu cầu 01 & 02)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialize notice: $e');
  }

  // 2. Khởi tạo kết nối Supabase Cloud Database (Yêu cầu 03 & 05)
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey, // ignore: deprecated_member_use
    );
    debugPrint('Supabase initialized successfully with project: ${AppConfig.supabaseUrl}');
  } catch (e) {
    debugPrint('Supabase initialize notice: $e');
  }

  runApp(const CloudDocumentApp());
}

class CloudDocumentApp extends StatelessWidget {
  const CloudDocumentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Tài Liệu - Flutter & Cloud Ecosystem (BT6)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4E79),
          primary: const Color(0xFF1F4E79),
          secondary: const Color(0xFF008080),
          tertiary: const Color(0xFFE65100),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
