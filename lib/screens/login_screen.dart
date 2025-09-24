// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/agents/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'matricule': _matriculeController.text.trim(),
          'motDePasse': _passwordController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userRole = responseData['agent']['role'];
        final userAffiliation = responseData['agent']['affiliation'];
        final userMatricule = responseData['agent']['matricule'];

        if (userRole == 'agent' || userRole == 'superviseur') {
          await prefs.setString('token', responseData['token']);
          await prefs.setString('userRole', userRole);
          if (userAffiliation != null) {
            await prefs.setString('affiliation', userAffiliation);
          }
          if (userMatricule != null) {
            await prefs.setString('matricule', userMatricule);
          }

          Navigator.pushReplacementNamed(
            context,
            userRole == 'superviseur' ? '/supervisor-dashboard' : '/agent-dashboard',
          );
        } else {
          _showSnackBar("Vous n'êtes pas autorisé à accéder à cette application.", isError: true);
        }
      } else {
        final errorMessage = responseData["msg"] ?? "Identifiants incorrects.";
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion : ${e.toString()}", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Gris clair Mobile Money
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  // Titre
                  const Text(
                    'Moov Money Agent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002F6C), // Bleu foncé
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour continuer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Matricule
                  TextField(
                    controller: _matriculeController,
                    decoration: InputDecoration(
                      labelText: 'Matricule',
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFF36E21)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mot de passe
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFFF36E21)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  // Bouton de connexion
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF36E21), // Orange Mobile Money
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'S\'authentifier',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
