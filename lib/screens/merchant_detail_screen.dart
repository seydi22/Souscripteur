// lib/screens/merchant_detail_screen.dart

import 'package:flutter/material.dart';

class MerchantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> merchant;

  MerchantDetailScreen({required this.merchant});

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFF36E21), size: 26),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002F6C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, dynamic value, IconData icon) {
    String displayValue = (value ?? 'Non spécifié').toString();
    if (value is Map && value.isEmpty) {
      displayValue = 'Non spécifié';
    }

    if (label == 'Coordonnées GPS') {
      displayValue =
          'Latitude: ${merchant['latitude'] ?? 'N/A'}\nLongitude: ${merchant['longitude'] ?? 'N/A'}';
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(0xFFF36E21), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, String? imageUrl) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            if (imageUrl == null || imageUrl.isEmpty)
              Center(
                child: Text(
                  'Image non disponible',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey[400]),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Color(0xFFF36E21),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Image non disponible.');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pieceIdentite =
        merchant['pieceIdentite'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          merchant['nom'] ?? 'Détails du marchand',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF36E21),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Informations Générales', Icons.business),
            _buildDetailCard('Nom de l\'enseigne', merchant['nom'], Icons.store),
            _buildDetailCard('Secteur d\'activité', merchant['secteur'], Icons.category),
            _buildDetailCard('Type de commerce', merchant['typeCommerce'], Icons.shopping_cart),

            _buildSectionTitle('Contact et Localisation', Icons.location_on),
            _buildDetailCard('Adresse', merchant['adresse'], Icons.map),
            _buildDetailCard('Région', merchant['region'], Icons.public),
            _buildDetailCard('Ville', merchant['ville'], Icons.location_city),
            _buildDetailCard('Commune', merchant['commune'], Icons.location_on),
            _buildDetailCard('Coordonnées GPS',
                '${merchant['latitude']}, ${merchant['longitude']}', Icons.gps_fixed),
            _buildDetailCard('Contact', merchant['contact'], Icons.phone),

            _buildSectionTitle('Informations du Gérant', Icons.person),
            _buildDetailCard('Nom', merchant['nomGerant'], Icons.person),
            _buildDetailCard('Prénom', merchant['prenomGerant'], Icons.person_outline),
            _buildDetailCard('NIF', merchant['nif'], Icons.credit_card),
            _buildDetailCard('RC', merchant['rc'], Icons.receipt_long),

            _buildSectionTitle('Informations de l\'Opérateur', Icons.support_agent),
            _buildDetailCard('Nom de l\'opérateur', merchant['nomOperateur'], Icons.person),
            _buildDetailCard('Prénom de l\'opérateur', merchant['prenomOperateur'], Icons.person_outline),
            _buildDetailCard('NNI de l\'opérateur', merchant['nniOperateur'], Icons.credit_card),
            _buildDetailCard('Téléphone de l\'opérateur', merchant['telephoneOperateur'], Icons.phone),

            _buildSectionTitle('Documents', Icons.folder),
            _buildDetailCard('Statut', merchant['statut'], Icons.info),
            _buildDetailCard('Type de pièce d\'identité',
                pieceIdentite['type'], Icons.badge),

            _buildImageCard('Photo d\'enseigne', merchant['photoEnseigneUrl']),
            if (pieceIdentite['type'] == 'cni' ||
                pieceIdentite['type'] == 'carte de sejour') ...[
              _buildImageCard('CNI / Carte de séjour (Recto)',
                  pieceIdentite['cniRectoUrl']),
              _buildImageCard('CNI / Carte de séjour (Verso)',
                  pieceIdentite['cniVersoUrl']),
            ] else if (pieceIdentite['type'] == 'passeport') ...[
              _buildImageCard('Passeport', pieceIdentite['passeportUrl']),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
