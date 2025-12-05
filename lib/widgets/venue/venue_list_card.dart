import 'package:lapangin/models/venue_entry.dart';
import 'package:lapangin/helper/price_formatter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class VenueListCard extends StatelessWidget {
  final VenueEntry venue;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const VenueListCard({
    super.key,
    required this.venue,
    this.canManage = false,
    required this.onEdit,
    required this.onRemove,
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
            height: 160,
            width: double.infinity,
          );
        } catch (e) {
          return Container(
            height: 160,
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.broken_image)),
          );
        }
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 160,
        width: double.infinity,
        loadingBuilder: (c, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 160,
            color: Colors.grey.shade300,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (c, o, s) => Container(
          height: 160,
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.broken_image)),
        ),
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        height: 160,
        width: double.infinity,
        errorBuilder: (c, o, s) => Container(
          height: 160,
          color: Colors.grey.shade300,
          child: const Center(child: Icon(Icons.error)),
        ),
      );
    }

    return Container(height: 160, color: Colors.grey.shade300);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: _buildVenueImage(venue.thumbnail),
          ),

          // DETAILS
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VENUE NAME
                Text(
                  venue.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // RATING & LOCATION
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${venue.rating}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),

                    const SizedBox(width: 8),
                    const Icon(Icons.location_on, color: Colors.grey, size: 14),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        venue.city,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // PRICE
                Text(
                  'Rp${formatRupiah(venue.price)},-',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // TOMBOL REMOVE
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Remove',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // TOMBOL EDIT
                      ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0062FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
