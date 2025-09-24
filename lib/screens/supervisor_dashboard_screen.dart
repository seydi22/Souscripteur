// lib/screens/supervisor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supervisor_merchant_detail_screen.dart';
import 'supervisor_agent_performance_screen.dart';
import 'supervisor_all_merchants_screen.dart';
import 'supervisor_agent_management_screen.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  _SupervisorDashboardScreenState createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  Map<String, dynamic> _dashboardData = {
    'stats': {'en attente': 0, 'validé': 0, 'rejeté': 0, 'validé_par_superviseur': 0},
    'pendingMerchants': []
  };
  bool _isLoading = true;
  String _errorMessage = '';
  String? _userRole; // Ajout pour stocker le rôle de l'utilisateur

  // Charte de couleurs
  final Color primaryColor = const Color(0xFFF36E21); // Orange
  final Color accentColor = const Color(0xFF0056A8);  // Bleu
  final Color backgroundColor = const Color(0xFFF5F5F5); // Gris clair
  final Color textColor = const Color(0xFF333333);    // Gris foncé
  final Color buttonTextColor = const Color(0xFF002F6C); // Bleu foncé

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userRole');
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userRole = prefs.getString('userRole'); // Récupérer le rôle

    if (token == null) {
      setState(() {
        _errorMessage = 'Veuillez vous reconnecter.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://backend-vercel-one-kappa.vercel.app/api/merchants/dashboard-stats'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> fetchedData = json.decode(response.body);
        setState(() {
          _userRole = userRole; // Stocker le rôle
          _dashboardData = fetchedData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userRole = userRole;
          _errorMessage = 'Erreur lors du chargement des données. Statut: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userRole = userRole;
        _errorMessage = 'Impossible de se connecter au serveur.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _userRole == 'admin';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _buildStatsSection(),
                            const SizedBox(height: 20),
                            if (isAdmin) ...[
                              _buildAdminExtraStats(),
                              const SizedBox(height: 20),
                            ],
                            _buildNavigationLinks(),
                            const SizedBox(height: 20),
                            if (!isAdmin) ...[
                              const Text(
                                'Derniers dossiers en attente',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildPendingMerchantsTable(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      floating: true,
      centerTitle: false,
      title: const Text(
        'Tableau de bord',
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _fetchDashboardData,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _logout(context),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = _dashboardData['stats'] as Map<String, dynamic>? ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'En attente',
          (stats['en attente'] ?? 0).toString(),
          primaryColor,
          Icons.pending_actions_rounded,
        ),
        _buildStatCard(
          'Validé par Superviseur',
          (stats['validé_par_superviseur'] ?? 0).toString(),
          accentColor,
          Icons.gpp_good_rounded,
        ),
        _buildStatCard(
          'Validés',
          (stats['validé'] ?? 0).toString(),
          Colors.green.shade700,
          Icons.check_circle_rounded,
        ),
        _buildStatCard(
          'Rejetés',
          (stats['rejeté'] ?? 0).toString(),
          Colors.red.shade700,
          Icons.cancel_rounded,
        ),
      ],
    );
  }

  Widget _buildAdminExtraStats() {
    final stats = _dashboardData['stats'] as Map<String, dynamic>? ?? {};
    final totalMerchants = stats['total'] ?? 0;
    final totalAgents = _dashboardData['totalAgents'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Marchands',
          totalMerchants.toString(),
          Colors.purple.shade700,
          Icons.store_mall_directory,
        ),
        _buildStatCard(
          'Total Agents',
          totalAgents.toString(),
          Colors.blue.shade700,
          Icons.groups,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationLinks() {
    return Column(
      children: [
        _buildNavigationCard(
          'Gestion des agents',
          Icons.people_alt_outlined,
          const SupervisorAgentManagementScreen(),
        ),
        const SizedBox(height: 12),
        _buildNavigationCard(
          'Performance des agents',
          Icons.bar_chart_outlined,
          const SupervisorAgentPerformanceScreen(),
        ),
        const SizedBox(height: 12),
        _buildNavigationCard(
          'Tous les marchands',
          Icons.storefront_outlined,
          const SupervisorAllMerchantsScreen(),
        ),
      ],
    );
  }

  Widget _buildNavigationCard(String title, IconData icon, Widget targetScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: accentColor.withOpacity(0.3))),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 48),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingMerchantsTable() {
    final pendingMerchants = _dashboardData['pendingMerchants'] as List<dynamic>? ?? [];

    if (pendingMerchants.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Aucun dossier en attente de validation.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
          child: DataTable(
            columnSpacing: 24,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            columns: const [
              DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Secteur', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Agent', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: pendingMerchants.map((merchant) {
              final agent = merchant['agentRecruteurId'];
              String agentMatricule = 'N/A';
              if (agent is Map) {
                agentMatricule = agent['matricule'] ?? 'N/A';
              }

              return DataRow(
                cells: [
                  DataCell(Text(merchant['nom'] ?? 'N/A')),
                  DataCell(Text(merchant['secteur'] ?? 'N/A')),
                  DataCell(Text(agentMatricule)),
                  DataCell(
                    ElevatedButton(
                      onPressed: () async {
                        final shouldRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SupervisorMerchantDetailScreen(merchant: merchant)),
                        );
                        if (shouldRefresh == true) _fetchDashboardData();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white),
                      child: const Text('Traiter'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
