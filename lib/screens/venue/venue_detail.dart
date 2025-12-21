import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lapangin/config/api_config.dart';
import 'package:lapangin/screens/booking/create_booking_page.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:lapangin/helper/price_formatter.dart';
import 'package:lapangin/models/venue_entry.dart';

Future<VenueEntry> fetchVenueDetail(
  CookieRequest request,
  String venueId,
) async {
  final response = await request.get(ApiConfig.venueDetailUrl(venueId));

  if (response is Map<String, dynamic> &&
      response.containsKey('success') &&
      response['success'] == true) {
    if (response['venue'] is Map<String, dynamic>) {
      return VenueEntry.fromJson(response['venue']);
    } else {
      throw Exception('Format data venue tidak valid.');
    }
  } else if (response is Map<String, dynamic> &&
      response.containsKey('message')) {
    throw Exception('Gagal memuat detail venue: ${response['message']}');
  } else {
    throw Exception(
      'Gagal memuat detail venue: Kesalahan respons tak terduga.',
    );
  }
}

class VenueDetailPage extends StatefulWidget {
  final String venueId;

  const VenueDetailPage({super.key, required this.venueId});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  VenueEntry? _venue;
  bool _isLoading = true;
  String? _error;
  bool _noConnection = false;

  @override
  void initState() {
    super.initState();
    _loadVenueDetail();
  }

  void _loadVenueDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _noConnection = false;
    });

    try {
      final request = context.read<CookieRequest>();
      final venueData = await fetchVenueDetail(request, widget.venueId);
      setState(() {
        _venue = venueData;
        _isLoading = false;
      });
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('handshakeexception') ||
          errorString.contains('connection') ||
          errorString.contains('network') ||
          errorString.contains('failed host lookup')) {
        setState(() {
          _noConnection = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = e.toString().contains('Exception:')
              ? e.toString().split('Exception: ')[1]
              : e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildVenueImage(String imageUrl, BuildContext context) {
    const base64Header = 'data:image';
    Widget imageWidget;
    final double imageHeight = MediaQuery.of(context).size.height * 0.35;

    if (imageUrl.startsWith(base64Header)) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          final bytes = base64Decode(parts[1].trim());
          imageWidget = Image.memory(bytes, fit: BoxFit.cover);
        } else {
          imageWidget = const Center(child: Icon(Icons.broken_image));
        }
      } catch (e) {
        imageWidget = const Center(child: Icon(Icons.broken_image));
      }
    } else if (imageUrl.startsWith('http')) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (c, o, s) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    } else {
      imageWidget = Image.asset(
        imageUrl.isNotEmpty ? imageUrl : 'assets/images/placeholder.png',
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) => const Center(child: Icon(Icons.error)),
      );
    }

    return Container(
      height: imageHeight,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_noConnection || _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Venue')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _noConnection ? Icons.wifi_off : Icons.error,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(_noConnection ? "Tidak ada koneksi" : "Error: $_error"),
              ElevatedButton(
                onPressed: _loadVenueDetail,
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    final venue = _venue!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVenueImage(venue.thumbnail, context),
                  VenueDetailBody(venue: venue),
                ],
              ),
            ),
          ),
          VenueDetailFooter(venue: venue),
        ],
      ),
    );
  }
}

class VenueDetailBody extends StatelessWidget {
  final VenueEntry venue;

  const VenueDetailBody({super.key, required this.venue});

  // Fungsi Helper untuk mengubah string newline menjadi List Widget Bullet
  List<Widget> _buildBulletList(String text) {
    if (text.isEmpty) {
      return [
        const Text(
          "Data tidak tersedia",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ];
    }
    // Pisahkan string berdasarkan baris baru dan hapus baris kosong
    List<String> lines = text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return lines.map((line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "• ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0062FF),
              ),
            ),
            Expanded(
              child: Text(
                line.trim(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${venue.city}, ${venue.country}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    venue.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            venue.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Deskripsi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            venue.description.isEmpty
                ? "Deskripsi tidak tersedia."
                : venue.description,
            style: const TextStyle(color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 24),

          // LIST FASILITAS
          _buildExpansionCard(
            title: 'Fasilitas Venue',
            icon: Icons.layers_outlined,
            content: _buildBulletList(venue.facilities),
          ),
          const SizedBox(height: 16),

          // LIST ATURAN
          _buildExpansionCard(
            title: 'Aturan Venue',
            icon: Icons.info_outline,
            content: _buildBulletList(venue.rules),
            isWarning: true,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildExpansionCard({
    required String title,
    required IconData icon,
    required List<Widget> content,
    bool isWarning = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(), // Hilangkan border default expansion tile
        leading: Icon(
          icon,
          color: isWarning ? Colors.orange : const Color(0xFF0062FF),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: content),
          ),
        ],
      ),
    );
  }
}

class VenueDetailFooter extends StatelessWidget {
  final VenueEntry venue;
  const VenueDetailFooter({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rp${formatRupiah(venue.price)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'per hari',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => CreateBookingPage(venueId: venue.id),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0062FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Sewa',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
