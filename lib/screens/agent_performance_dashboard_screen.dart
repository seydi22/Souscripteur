// lib/screens/agent_performance_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AgentPerformanceDashboardScreen extends StatefulWidget {
  @override
  _AgentPerformanceDashboardScreenState createState() => _AgentPerformanceDashboardScreenState();
}

class _AgentPerformanceDashboardScreenState extends State<AgentPerformanceDashboardScreen> {
  Map<String, dynamic> _performanceData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _errorMessage = 'Veuillez vous reconnecter.';
        _isLoading = false;
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/agents/my-performance'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> fetchedData = json.decode(response.body);
        setState(() {
          _performanceData = fetchedData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des données.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de se connecter au serveur.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fond gris clair
      appBar: AppBar(
        backgroundColor: const Color(0xFFF36E21), // Orange Mobile Money
        title: const Text(
          'Ma performance أدائي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF36E21)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPerformanceCard(
                        title: 'Total des enrôlements  إجمالي التسجيلات',
                        value: '${_performanceData['enrôlements'] ?? 0}',
                        color: const Color(0xFFF36E21), // Orange pour cohérence
                      ),
                      const SizedBox(height: 16),
                      _buildPerformanceCard(
                        title: 'Marchands validés التجار المُعتمدون',
                        value: '${_performanceData['validations'] ?? 0}',
                        color: const Color(0xFF002F6C), // Bleu foncé
                      ),
                      const SizedBox(height: 16),
                      // Ajout possible d'autres indicateurs ici
                    ],
                  ),
                ),
    );
  }

  Widget _buildPerformanceCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002F6C), // Bleu foncé
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
