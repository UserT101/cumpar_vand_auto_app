import 'package:cumpar_auto/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, 
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent, 
    systemNavigationBarIconBrightness: Brightness.light, 
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity, 
  );
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    const Color appBarColor = Color.fromRGBO(48, 48, 48, 1);

    return MaterialApp(
      title: 'Cumpar Auto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: appBarColor, 
          
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          type: BottomNavigationBarType.fixed, 
        ),

      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}