import 'package:flutter/material.dart';
import 'presentation/pages/login_page.dart'; // Importamos la vista extraída

void main() => runApp(const SitiEnergiaApp());

class SitiEnergiaApp extends StatelessWidget {
  const SitiEnergiaApp({super.key});
  
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SitiEnergia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b87)), 
          useMaterial3: true
        ),
        home: const LoginPage(),
      );
}