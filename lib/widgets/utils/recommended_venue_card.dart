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

  // Tinggi Gambar Ditetapkan Secara Konstan
  static const double imageDisplayHeight = 120.0;

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
            height: imageDisplayHeight, // Menggunakan konstanta
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
        height: imageDisplayHeight, // Menggunakan konstanta
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
        height: imageDisplayHeight, // Menggunakan konstanta
        width: double.infinity,
        errorBuilder: (c, o, s) => const Center(child: Icon(Icons.error)),
      );
    }

    return Container(height: imageDisplayHeight, color: Colors.grey.shade300);
  }

  @override
  Widget build(BuildContext context) {
    // Tinggi yang tersisa untuk Detail setelah Gambar & Padding Gambar:
    // Total Height (246) - Padding Atas/Bawah Gambar (8*2) - Tinggi Gambar (120)
    // = 246 - 16 - 120 = 110.0 piksel yang tersedia untuk Detail.

    return SizedBox(
      width: 160,
      height: 246, // Tinggi tetap 246px
      child: Container(
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
          // Menggunakan MainAxisSize.max untuk memastikan Column mengambil seluruh tinggi SizedBox
          mainAxisSize: MainAxisSize.max,
          children: [
            // Kontainer Gambar (120px + Padding 8 atas/bawah)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Container(
                  height: imageDisplayHeight, // 120px
                  width: double.infinity,
                  child: _buildVenueImage(imageUrl),
                ),
              ),
            ),

            // Detail Venue (Memanfaatkan seluruh sisa ruang yang tersedia)
            // Menggunakan Expanded dan Spacer untuk memastikan tidak ada overflow,
            // tetapi ini bisa mengubah tata letak detail Anda.
            // Alternatif termudah: Kurangi padding vertikal.

            // Kita akan mengurangi padding vertikal di sini:
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                // **Mengurangi Vertical Padding agar total tidak melebihi batas**
                vertical: 2.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lokasi
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
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 10,
                      ),
                    ),
                  ),
                  // **Mengurangi Spasi Vertikal**
                  const SizedBox(height: 4),

                  // Nama Venue (Memungkinkan 2 baris)
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  // **Mengurangi Spasi Vertikal**
                  const SizedBox(height: 2),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('$rating', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  // **Mengurangi Spasi Vertikal**
                  const SizedBox(height: 4),

                  // Harga
                  Text(
                    "Rp" +
                        (price != null
                            ? formatRupiah(price).toString()
                            : 'N/A'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // **Hapus SizedBox(height: 8) di bagian bawah**
            // Hapus atau ganti dengan Spacer() jika Anda ingin mendorong konten ke atas.
            // const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
