// lib/screens/supervisor_all_merchants_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supervisor_merchant_detail_screen.dart';

class SupervisorAllMerchantsScreen extends StatefulWidget {
  const SupervisorAllMerchantsScreen({super.key});

  @override
  State<SupervisorAllMerchantsScreen> createState() => _SupervisorAllMerchantsScreenState();
}

class _SupervisorAllMerchantsScreenState extends State<SupervisorAllMerchantsScreen> {
  List<dynamic> _allMerchants = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus = 'Tous';

  // Couleurs de la charte
  final Color primaryColor = const Color(0xFFF36E21); // Orange
  final Color accentColor = const Color(0xFF0056A8);  // Bleu
  final Color backgroundColor = const Color(0xFFF5F5F5); // Gris clair
  final Color textColor = const Color(0xFF333333);    // Gris foncé

  @override
  void initState() {
    super.initState();
    _fetchMerchants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Simple debounce mechanism
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fetchMerchants();
      }
    });
  }

  Future<void> _fetchMerchants() async {
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

    Uri url;
    final Map<String, String> queryParams = {};

    if (_selectedStatus == 'en attente') {
      url = Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/merchants/pending');
    } else {
      url = Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/merchants/superviseur-merchants');
      if (_selectedStatus != 'Tous') {
        queryParams['statut'] = _selectedStatus!;
      }
    }
    
    if (_searchController.text.isNotEmpty) {
      queryParams['search'] = _searchController.text;
    }
    
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      });

      if (response.statusCode == 200) {
        setState(() {
          _allMerchants = json.decode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _allMerchants = [];
          _errorMessage = 'Aucun marchand trouvé.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des marchands.';
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'validé':
        return Colors.green.shade600;
      case 'en attente':
        return Colors.amber.shade700;
      case 'validé_par_superviseur':
        return accentColor;
      case 'rejeté':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'validé':
        return Icons.check_circle_rounded;
      case 'en attente':
        return Icons.hourglass_top_rounded;
      case 'validé_par_superviseur':
        return Icons.gpp_good_rounded;
      case 'rejeté':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'validé':
        return 'Validé';
      case 'en attente':
        return 'En attente';
      case 'validé_par_superviseur':
        return 'Validé par Sup.';
      case 'rejeté':
        return 'Rejeté';
      default:
        return status ?? 'Non défini';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Marchands de mes agents',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, gérant...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: accentColor),
                      items: const [
                        DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                        DropdownMenuItem(value: 'en attente', child: Text('En attente')),
                        DropdownMenuItem(value: 'validé_par_superviseur', child: Text('Validé par Sup.')),
                        DropdownMenuItem(value: 'validé', child: Text('Validé')),
                        DropdownMenuItem(value: 'rejeté', child: Text('Rejeté')),
                      ],
                      onChanged: (String? newValue) {
                        setState(() => _selectedStatus = newValue);
                        _fetchMerchants();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _errorMessage.isNotEmpty && _allMerchants.isEmpty
                    ? Center(child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
                    ))
                    : _allMerchants.isEmpty
                        ? const Center(child: Text('Aucun marchand trouvé.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : RefreshIndicator(
                            onRefresh: _fetchMerchants,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                              itemCount: _allMerchants.length,
                              itemBuilder: (context, index) {
                                final merchant = _allMerchants[index];
                                final status = merchant['statut'] as String?;
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SupervisorMerchantDetailScreen(merchant: merchant),
                                      ),
                                    );
                                    if (result == true) _fetchMerchants();
                                  },
                                  child: Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: accentColor.withOpacity(0.2))),
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: _getStatusColor(status).withOpacity(0.1),
                                            radius: 28,
                                            child: Icon(
                                              _getStatusIcon(status),
                                              color: _getStatusColor(status),
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  merchant['nom'] ?? 'Nom inconnu',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Gérant: ${merchant['nomGerant'] ?? 'Non spécifié'}',
                                                  style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
                                                ),
                                                 const SizedBox(height: 4),
                                                Text(
                                                  _translateStatus(status),
                                                  style: TextStyle(
                                                    color: _getStatusColor(status),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}