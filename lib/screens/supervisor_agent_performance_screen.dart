// lib/screens/supervisor_agent_performance_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorAgentPerformanceScreen extends StatefulWidget {
  const SupervisorAgentPerformanceScreen({super.key});

  @override
  _SupervisorAgentPerformanceScreenState createState() =>
      _SupervisorAgentPerformanceScreenState();
}

class _SupervisorAgentPerformanceScreenState
    extends State<SupervisorAgentPerformanceScreen> {
  List<dynamic> _agentsPerformance = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Couleurs de la charte
  final Color primaryColor = const Color(0xFFF36E21); // Orange
  final Color accentColor = const Color(0xFF0056A8); // Bleu
  final Color backgroundColor = const Color(0xFFF5F5F5); // Gris clair
  final Color textColor = const Color(0xFF333333); // Gris foncé
  final Color buttonTextColor = const Color(0xFF002F6C); // Bleu foncé

  @override
  void initState() {
    super.initState();
    _fetchAllAgentsPerformance();
  }

  Future<void> _fetchAllAgentsPerformance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

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
        Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/agents/all-performance'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = json.decode(response.body);
        setState(() {
          _agentsPerformance = fetchedData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des performances des agents.';
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Performance des Agents',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _fetchAllAgentsPerformance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _agentsPerformance.isEmpty
                  ? const Center(
                      child: Text('Aucun agent trouvé.',
                          style: TextStyle(fontSize: 16)),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListView.builder(
                        itemCount: _agentsPerformance.length,
                        itemBuilder: (context, index) {
                          final agent = _agentsPerformance[index];
                          final performance = agent['performance'] ?? {};
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: accentColor, width: 1),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Matricule: ${agent['matricule']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: buttonTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Rôle: ${agent['role']}',
                                          style: TextStyle(color: textColor),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              'Enrôlements: ${performance['enrôlements'] ?? 0}',
                                              style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Validations: ${performance['validations'] ?? 0}',
                                              style: TextStyle(
                                                  color: accentColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
