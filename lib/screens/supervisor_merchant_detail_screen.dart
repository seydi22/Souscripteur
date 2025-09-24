// lib/screens/supervisor_merchant_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorMerchantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> merchant;

  const SupervisorMerchantDetailScreen({super.key, required this.merchant});

  @override
  State<SupervisorMerchantDetailScreen> createState() => _SupervisorMerchantDetailScreenState();
}

class _SupervisorMerchantDetailScreenState extends State<SupervisorMerchantDetailScreen> {
  final _rejectionReasonController = TextEditingController();

  final Color primaryColor = const Color(0xFFF36E21); // Orange
  final Color accentColor = const Color(0xFF0056A8);  // Bleu
  final Color backgroundColor = const Color(0xFFF5F5F5); // Gris clair
  final Color textColor = const Color(0xFF333333);    // Gris foncé
  final Color buttonTextColor = Colors.white;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en attente':
        return 'En attente de validation Superviseur';
      case 'validé_par_superviseur':
        return 'En attente de validation Admin';
      case 'validé':
        return 'Validé';
      case 'rejeté':
        return 'Rejeté';
      default:
        return statut;
    }
  }

  Future<void> _updateMerchantStatus(BuildContext context, String action, {String? rejectionReason}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showSnackbar(context, 'Veuillez vous reconnecter.', isError: true);
      return;
    }

    String url;
    Map<String, dynamic> body = {};

    if (action == 'supervisor-validate') {
      url = 'https://backend-vercel-one-kappa.vercel.app/api/merchants/supervisor-validate/${widget.merchant['_id']}';
    } else if (action == 'reject') {
      url = 'https://backend-vercel-one-kappa.vercel.app/api/merchants/reject/${widget.merchant['_id']}';
      body['rejectionReason'] = rejectionReason;
    } else {
      _showSnackbar(context, 'Action non valide.', isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        _showSnackbar(context, 'Statut du marchand mis à jour avec succès !');
        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        _showSnackbar(context, errorData['msg'] ?? 'Erreur de mise à jour du statut.', isError: true);
      }
    } catch (e) {
      _showSnackbar(context, 'Impossible de se connecter au serveur.', isError: true);
    }
  }

  void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Raison du rejet', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _rejectionReasonController,
          decoration: InputDecoration(
            hintText: 'Entrez la raison du rejet',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectionReasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _updateMerchantStatus(context, 'reject', rejectionReason: _rejectionReasonController.text);
              } else {
                _showSnackbar(context, 'La raison du rejet ne peut pas être vide.', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, dynamic value, {IconData? icon}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: accentColor.withOpacity(0.3))),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: primaryColor, size: 48),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value?.toString() ?? 'Non spécifié', style: TextStyle(fontSize: 16, color: textColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay(String? imageUrl, String label) {
    if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.red.shade400, size: 50),
                    const SizedBox(height: 8),
                    const Text('Impossible de charger l\'image.', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor)),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 10),
        const Divider(height: 40, color: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pieceIdentite = widget.merchant['pieceIdentite'] as Map<String, dynamic>? ?? {};
    final statut = widget.merchant['statut'] as String? ?? 'Inconnu';
    final rejectionReason = widget.merchant['rejectionReason'] as String?;
    final enroller = widget.merchant['agentRecruteurId'];
    String enrollerName = 'Non spécifié';
    if (enroller is Map) enrollerName = enroller['nom'] ?? enrollerName;
    else if (enroller is String) enrollerName = enroller;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.merchant['nom'] ?? 'Détails du marchand', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailSection('Informations du Marchand', [
              _buildDetailCard('Nom de l\'enseigne', widget.merchant['nom'], icon: Icons.store_rounded),
              _buildDetailCard('Secteur d\'activité', widget.merchant['secteur'], icon: Icons.category_rounded),
              _buildDetailCard('Type de commerce', widget.merchant['typeCommerce'], icon: Icons.shopping_cart),
              _buildDetailCard('Adresse', widget.merchant['adresse'], icon: Icons.location_on_rounded),
            ]),

            _buildDetailSection('Contact et Localisation', [
              _buildDetailCard('Contact', widget.merchant['contact'], icon: Icons.phone),
              _buildDetailCard('Région', widget.merchant['region'], icon: Icons.public),
              _buildDetailCard('Ville', widget.merchant['ville'], icon: Icons.location_city),
              _buildDetailCard('Commune', widget.merchant['commune'], icon: Icons.location_on),
              _buildDetailCard('Coordonnées GPS', 'Latitude: ${widget.merchant['latitude'] ?? 'N/A'}\nLongitude: ${widget.merchant['longitude'] ?? 'N/A'}', icon: Icons.gps_fixed),
            ]),

            _buildDetailSection('Informations du Gérant', [
              _buildDetailCard('Nom du gérant', widget.merchant['nomGerant'], icon: Icons.person),
              _buildDetailCard('Prénom du gérant', widget.merchant['prenomGerant'], icon: Icons.person_outline),
              _buildDetailCard('NIF', widget.merchant['nif'], icon: Icons.credit_card),
              _buildDetailCard('RC', widget.merchant['rc'], icon: Icons.receipt_long),
            ]),

            _buildDetailSection('Informations de l\'Opérateur', [
              _buildDetailCard('Nom de l\'opérateur', widget.merchant['nomOperateur'], icon: Icons.person),
              _buildDetailCard('Prénom de l\'opérateur', widget.merchant['prenomOperateur'], icon: Icons.person_outline),
              _buildDetailCard('NNI de l\'opérateur', widget.merchant['nniOperateur'], icon: Icons.credit_card),
              _buildDetailCard('Téléphone de l\'opérateur', widget.merchant['telephoneOperateur'], icon: Icons.phone),
            ]),

            _buildDetailSection('Statut et Documents', [
              _buildDetailCard('Statut', _getStatutText(statut), icon: Icons.info_outline_rounded),
              if (rejectionReason != null && rejectionReason.isNotEmpty)
                _buildDetailCard('Motif du rejet', rejectionReason, icon: Icons.comment_bank_outlined),
              _buildDetailCard('Enrôlé par', enrollerName, icon: Icons.person_add_alt_rounded),
              _buildDetailCard('Type de pièce d\'identité', pieceIdentite['type'], icon: Icons.badge_rounded),
            ]),
            _buildImageDisplay(widget.merchant['photoEnseigneUrl'], 'Photo de l\'enseigne'),
            if (pieceIdentite['type'] == 'cni' || pieceIdentite['type'] == 'carte de sejour') ...[
              _buildImageDisplay(pieceIdentite['cniRectoUrl'], 'CNI / Carte de séjour (Recto)'),
              _buildImageDisplay(pieceIdentite['cniVersoUrl'], 'CNI / Carte de séjour (Verso)'),
            ],
            if (pieceIdentite['type'] == 'passeport')
              _buildImageDisplay(pieceIdentite['passeportUrl'], 'Passeport'),
            const SizedBox(height: 30),
            if (statut == 'en attente')
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _updateMerchantStatus(context, 'supervisor-validate'),
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        label: const Text('Pré-valider', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: _showRejectionDialog,
                        icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                        label: const Text('Rejeter', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}