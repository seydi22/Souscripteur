// lib/screens/merchant_list_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'merchant_detail_screen.dart';

class MerchantListScreen extends StatefulWidget {
  const MerchantListScreen({super.key});

  @override
  _MerchantListScreenState createState() => _MerchantListScreenState();
}

class _MerchantListScreenState extends State<MerchantListScreen> {
  List<dynamic> _merchants = [];
  List<dynamic> _filteredMerchants = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMyMerchants();
    _searchController.addListener(_filterMerchants);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyMerchants() async {
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
        Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/merchants/my-merchants'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedMerchants = json.decode(response.body);
        setState(() {
          _merchants = fetchedMerchants;
          _filteredMerchants = fetchedMerchants;
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

  void _filterMerchants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMerchants = _merchants.where((merchant) {
        final nameLower = merchant['nom']?.toLowerCase() ?? '';
        final contactLower = merchant['contact']?.toLowerCase() ?? '';
        final nomGerantLower = merchant['nomGerant']?.toLowerCase() ?? '';
        final statutLower = merchant['statut']?.toLowerCase() ?? '';

        return nameLower.contains(query) ||
            contactLower.contains(query) ||
            nomGerantLower.contains(query) ||
            statutLower.contains(query);
      }).toList();
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'validé':
        return Colors.green;
      case 'en attente':
        return Color(0xFFF36E21); // Orange Moov Money
      case 'rejeté':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF36E21),
        title: const Text(
          'Mes marchands enrôlés تجّاري المسجّلون',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un marchand ابحث عن تاجر',
                hintText: 'Nom, contact, gérant ou statut...  الاسم، جهة الاتصال، المدير أو الحالة...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0056A8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF36E21)))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMyMerchants,
                        color: const Color(0xFFF36E21),
                        child: _filteredMerchants.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun marchand trouvé pour cette recherche.  لم يتم العثور على أي تاجر لهذا البحث.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredMerchants.length,
                                itemBuilder: (context, index) {
                                  final merchant = _filteredMerchants[index];
                                  final statut = merchant['statut'] ?? 'Non défini';
                                  final statusColor = _getStatusColor(statut);

                                  return Card(
                                    elevation: 4.0,
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MerchantDetailScreen(merchant: merchant),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(15),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.storefront, color: Color(0xFF0056A8), size: 40),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    merchant['nom'] ?? 'Nom inconnu',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Color(0xFF0056A8),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Gérant: ${merchant['nomGerant'] ?? 'Non spécifié'}',
                                                    style: TextStyle(color: Colors.grey[700]),
                                                  ),
                                                  Text(
                                                    'Contact: ${merchant['contact'] ?? 'Non spécifié'}',
                                                    style: TextStyle(color: Colors.grey[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Chip(
                                              label: Text(
                                                statut,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              backgroundColor: statusColor,
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
