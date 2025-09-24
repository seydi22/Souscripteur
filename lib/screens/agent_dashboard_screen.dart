// lib/screens/agent_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgentDashboardScreen extends StatelessWidget {
  // Fonction de déconnexion
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userRole');

    Navigator.pushReplacementNamed(context, '/');
  }

  // Bouton stylisé façon Mobile Money
  Widget _buildDashboardButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: SingleChildScrollView( // Empêche le débordement si le texte est trop long
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Color(0xFFF36E21)), // Orange principal
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002F6C), // Bleu foncé
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fond gris clair
      appBar: AppBar(
        backgroundColor: const Color(0xFFF36E21), // Orange Mobile Money
        title: const Text(
          'Tableau de bord  لوحة التحكم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView( // Remplacer Column par ListView pour rendre toute la page scrollable
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Bienvenue, Souscripteur Moov Money !',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002F6C),
                  ),
                ),
                subtitle: Text(
                  'Sélectionnez une option pour continuer.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true, // Important pour que GridView fonctionne dans un ListView
                physics: const NeverScrollableScrollPhysics(), // Le ListView gère le scroll
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildDashboardButton(
                    context: context,
                    icon: Icons.person_add,
                    label: 'Enrôler un marchand تسجيل تاجر',
                    onPressed: () => Navigator.pushNamed(context, '/merchant-form'),
                  ),
                  _buildDashboardButton(
                    context: context,
                    icon: Icons.list_alt,
                    label: 'Marchands enrôlés التجار المُسجَّلون',
                    onPressed: () => Navigator.pushNamed(context, '/merchant-list'),
                  ),
                  _buildDashboardButton(
                    context: context,
                    icon: Icons.show_chart,
                    label: 'Ma performance  أدائي',
                    onPressed: () => Navigator.pushNamed(context, '/agent-performance'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
