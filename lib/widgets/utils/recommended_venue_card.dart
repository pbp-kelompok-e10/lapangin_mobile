import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lapangin/helper/price_formatter.dart';

class VenueCard extends StatelessWidget {
  final String location;
  final String name;
  final double rating;
  final double price;
  final String imageUrl;

  const VenueCard({
    super.key,
    required this.location,
    required this.name,
    required this.rating,
    required this.price,
    required this.imageUrl,
  });

  Widget _buildVenueImage(String imageUrl) {
    const base64Header = 'data:image';

    if (imageUrl.startsWith(base64Header)) {
      final parts = imageUrl.split(',');
      if (parts.length > 1) {
        try {
          final bytes = base64Decode(parts[1].trim());
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            height: 120,
            width: double.infinity,
          );
        } catch (e) {
          return const Center(child: Text('Error decoding image'));
        }
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 180,
        width: double.infinity,
        loadingBuilder: (c, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (c, o, s) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        height: 180,
        width: double.infinity,
        errorBuilder: (c, o, s) => const Center(child: Icon(Icons.error)),
      );
    }

    return Container(height: 300, color: Colors.grey.shade300);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Container(
                height: 180,
                width: double.infinity,
                child: _buildVenueImage(imageUrl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '📍 $location',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: "Poppins",
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text('$rating', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Rp" + formatRupiah(price).toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
