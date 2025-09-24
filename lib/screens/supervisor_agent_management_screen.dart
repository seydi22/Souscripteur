// lib/screens/supervisor_agent_management_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorAgentManagementScreen extends StatefulWidget {
  const SupervisorAgentManagementScreen({super.key});

  @override
  State<SupervisorAgentManagementScreen> createState() =>
      _SupervisorAgentManagementScreenState();
}

class _SupervisorAgentManagementScreenState
    extends State<SupervisorAgentManagementScreen> {
  List<dynamic> _agents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final Color primaryColor = const Color(0xFFF36E21); // Orange
  final Color accentColor = const Color(0xFF0056A8); // Bleu
  final Color backgroundColor = const Color(0xFFF5F5F5); // Gris clair
  final Color textColor = const Color(0xFF333333); // Gris foncé
  final Color buttonTextColor = const Color(0xFF002F6C); // Bleu foncé

  @override
  void initState() {
    super.initState();
    _fetchAgents();
  }

  Future<void> _fetchAgents() async {
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
          _agents = fetchedData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des agents.';
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

  Future<void> _addAgent(
      String matricule, String password, String affiliation) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/agents'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: json.encode({
          'matricule': matricule,
          'motDePasse': password,
          'affiliation': affiliation,
          'role': 'agent',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Agent ajouté avec succès.'),
              backgroundColor: primaryColor),
        );
        _fetchAgents();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(errorData['msg'] ?? 'Erreur lors de l\'ajout de l\'agent.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Impossible de se connecter au serveur.'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateAgent(String id, String newPassword, String newRole) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final body = {};
    if (newPassword.isNotEmpty) {
      body['motDePasse'] = newPassword;
    }
    if (newRole.isNotEmpty) {
      body['role'] = newRole;
    }

    try {
      final response = await http.put(
        Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/agents/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Agent mis à jour avec succès.'),
              backgroundColor: primaryColor),
        );
        _fetchAgents();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  errorData['msg'] ?? 'Erreur lors de la mise à jour de l\'agent.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Impossible de se connecter au serveur.'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAgent(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/agents/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Agent supprimé avec succès.'),
              backgroundColor: primaryColor),
        );
        _fetchAgents();
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  errorData['msg'] ?? 'Erreur lors de la suppression de l\'agent.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Impossible de se connecter au serveur.'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showAddAgentDialog() async {
    final matriculeController = TextEditingController();
    final passwordController = TextEditingController();
    final affiliationController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    final supervisorAffiliation = prefs.getString('affiliation');

    if (supervisorAffiliation != null) {
      affiliationController.text = supervisorAffiliation;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Ajouter un nouvel agent',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matriculeController,
                decoration: const InputDecoration(
                  labelText: 'Matricule',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: affiliationController,
                decoration: const InputDecoration(
                  labelText: 'Affiliation',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                if (matriculeController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty &&
                    affiliationController.text.isNotEmpty) {
                  _addAgent(
                    matriculeController.text,
                    passwordController.text,
                    affiliationController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAgentDialog(dynamic agent) {
    final passwordController = TextEditingController();
    String? selectedRole = agent['role'];
    final originalRole = agent['role'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier ${agent['matricule']}',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Nouveau mot de passe'),
                controller: passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: ['agent', 'superviseur', 'admin'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  selectedRole = newValue;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                _updateAgent(
                  agent['_id'],
                  passwordController.text,
                  selectedRole ?? originalRole,
                );
                Navigator.pop(context);
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Gestion des Agents',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _fetchAgents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ))
              : _agents.isEmpty
                  ? const Center(child: Text('Aucun agent à gérer.'))
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        itemCount: _agents.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3, // plus compact
                        ),
                        itemBuilder: (context, index) {
                          final agent = _agents[index];
                          final performance = agent['performance'] ?? {};
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: accentColor, width: 1)),
                            elevation: 2,
                            child: Stack(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showEditAgentDialog(agent),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8), // plus compact
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person,
                                            size: 36, color: primaryColor),
                                        const SizedBox(height: 4),
                                        Text(
                                          agent['matricule'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: buttonTextColor),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Enrolement: ${performance['enrôlements'] ?? 0}     Validation: ${performance['validations'] ?? 0}',
                                          style: TextStyle(
                                              fontSize: 12, color: textColor),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Confirmer la suppression'),
                                          content: Text(
                                              'Voulez-vous vraiment supprimer ${agent['matricule']} ?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Annuler'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor),
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteAgent(agent['_id']);
                                              },
                                              child: const Text('Supprimer'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _showAddAgentDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
