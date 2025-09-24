// Fichier: splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Attend 3 secondes avant de naviguer vers l'écran de connexion
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // L'image de fond qui couvre tout l'écran
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Le contenu (indicateur et texte) centré par-dessus
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text('Chargement...', style: TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
