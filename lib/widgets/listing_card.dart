// lib/widgets/listing_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cumpar_auto/listing_detail_screen.dart';
import 'package:flutter/material.dart';

class ListingCard extends StatelessWidget {
  final QueryDocumentSnapshot listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final data = listing.data() as Map<String, dynamic>;

    final List<dynamic> images = data['imageUrls'] ?? [];
    final String firstImage = images.isNotEmpty
        ? images[0]
        : 'https://via.placeholder.com/150'; // O imagine placeholder

    return Card(
      margin: const EdgeInsets.all(10.0),
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailScreen(listingId: listing.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'listingImage${listing.id}',
              child: Image.network(
                firstImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/carimg.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data['marca']} ${data['model']}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['pret'] != null ? '${data['pret']} €': 'Contactează vânzătorul',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text('${data['anFabricatie']}'),
                      const SizedBox(width: 16),
                      Icon(Icons.speed, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text('${data['kilometri']} km'),
                    ],
                  ),
                  // Vom ascunde vânzătorul de aici pentru un look mai curat
                  // Păstrăm detaliile pentru pagina de detalii
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}