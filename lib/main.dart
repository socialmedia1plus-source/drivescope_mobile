import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; // استدعاء صفحة تسجيل الدخول مباشرة من نفس المجلد
import 'home_screen.dart';  // استدعاء الصفحة الرئيسية لفتحها بعد نجاح التحقق

void main() async {
  // التأكد من تهيئة كل خدمات الـ Widgets قبل بدء الفايربيز
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // التهيئة اليدوية المباشرة لخدمات فايربيز لضمان استقرار التشغيل السحابي
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAs-YOUR-ACTUAL-API-KEY",
        appId: "1:999999999999:web:9999999999999999",
        messagingSenderId: "999999999999",
        projectId: "drivescope-47f3c",
        storageBucket: "drivescope-47f3c.appspot.com",
      ),
    );
    print("Firebase initialized successfully manually!");
  } catch (e) {
    print("Firebase initialization info: $e");
  }

  runApp(const DriveScopeApp());
}

class DriveScopeApp extends StatelessWidget {
  const DriveScopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveScope',
      debugShowCheckedModeBanner: false,
      
      // إعدادات الثيم المضيء (Minimal & Clean)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
      ),
      
      // إعدادات الثيم المظلم (Dark Mode) لراحة عين الكابتن أثناء القيادة ليلاً
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
      ),
      
      // التحويل التلقائي للثيم بناءً على إعدادات نظام الهاتف
      themeMode: ThemeMode.system,
      
      // فتح صفحة تسجيل الدخول والتحقق برقم الهاتف أولاً كشاشة رئيسية للتطبيق
      home: const LoginScreen(), 
    );
  }
}