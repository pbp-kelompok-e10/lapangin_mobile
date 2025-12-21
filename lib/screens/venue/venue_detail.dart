import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lapangin/config/api_config.dart';
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

// Halaman Detail Venue
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

  // Helper untuk menampilkan gambar
  Widget _buildVenueImage(String imageUrl, BuildContext context) {
    const base64Header = 'data:image';
    Widget imageWidget;
    final double imageHeight = MediaQuery.of(context).size.height * 0.35;

    // Logika menampilkan gambar (base64, network, atau asset)
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

    if (_noConnection) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Detail Venue'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tidak Ada Koneksi Internet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Periksa koneksi internet Anda dan coba lagi.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadVenueDetail,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0062FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Venue')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Gagal memuat detail venue: $_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadVenueDetail,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final venue = _venue!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // AppBar transparan di atas gambar
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BAGIAN GAMBAR
                  _buildVenueImage(venue.thumbnail, context),
                  // BAGIAN DETAIL
                  VenueDetailBody(venue: venue),
                ],
              ),
            ),
          ),
          // BAGIAN FOOTER (HARGA & SEWA)
          VenueDetailFooter(venue: venue),
        ],
      ),
    );
  }
}

// Body utama halaman detail (Nama, Deskripsi, Fasilitas, Aturan)
class VenueDetailBody extends StatelessWidget {
  final VenueEntry venue;

  const VenueDetailBody({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // LOKASI dan RATING
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${venue.city}, ${venue.country}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    venue.rating.toStringAsFixed(2),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // NAMA VENUE
          Text(
            venue.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // DESKRIPSI
          Text(
            venue.description.isEmpty
                ? "Deskripsi tidak tersedia."
                : venue.description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 24),

          // FASILITAS VENUE
          _buildFacilitiesExpansionTile(),
          const SizedBox(height: 16),

          // ATURAN VENUE (Dummy)
          _buildRulesExpansionTile(),

          // Bagian Ulasan (Review) telah dihapus/ditunda.
          const SizedBox(
            height: 100,
          ), // Ruang agar konten tidak tertutup footer
        ],
      ),
    );
  }

  // Widget untuk menampilkan daftar fasilitas
  Widget _buildFacilitiesExpansionTile() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text(
          'Fasilitas Venue',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        children: [
          // Tambahkan divider di dalam children jika ExpansionTile terbuka
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Text(
            venue.description.isEmpty
                ? "Deskripsi tidak tersedia."
                : venue.description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Item Fasilitas
  Widget _buildFacilityItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan aturan venue
  Widget _buildRulesExpansionTile() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: const Text(
          'Aturan Venue',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        children: [
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              venue.description.isEmpty
                  ? 'Mohon baca aturan venue yang berlaku sebelum melakukan pemesanan.'
                  : venue.description,
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
  }
}

// Footer halaman detail (Harga dan Tombol Sewa)
class VenueDetailFooter extends StatefulWidget {
  final VenueEntry venue;

  const VenueDetailFooter({super.key, required this.venue});

  @override
  State<VenueDetailFooter> createState() => _VenueDetailFooterState();
}

class _VenueDetailFooterState extends State<VenueDetailFooter> {
  bool _isBooking = false;

  Future<List<DateTime>> _fetchBookedDates() async {
    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(
        ApiConfig.bookedDatesUrl(widget.venue.id),
      );

      if (response['status'] == true) {
        final dates = response['data']['booked_dates'] as List;
        return dates.map((d) => DateTime.parse(d)).toList();
      }
    } catch (e) {
      // Return empty list if error
    }
    return [];
  }

  Future<void> _showBookingDialog() async {
    // Fetch booked dates first
    final bookedDates = await _fetchBookedDates();

    if (!mounted) return;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Can't select already booked dates
        return !bookedDates.any(
          (booked) =>
              booked.year == date.year &&
              booked.month == date.month &&
              booked.day == date.day,
        );
      },
      helpText: 'Pilih Tanggal Booking',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0062FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Konfirmasi Booking',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Venue: ${widget.venue.name}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanggal: ${_formatDate(selectedDate)}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Harga: Rp${formatRupiah(widget.venue.price)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0062FF),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0062FF),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Submit booking
    await _submitBooking(selectedDate);
  }

  Future<void> _submitBooking(DateTime date) async {
    setState(() {
      _isBooking = true;
    });

    try {
      final request = context.read<CookieRequest>();
      final response = await request.postJson(
        ApiConfig.createBookingUrl,
        jsonEncode({
          'venue_id': widget.venue.id,
          'booking_date': date.toIso8601String().split('T')[0],
        }),
      );

      if (!mounted) return;

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Booking berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal melakukan booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Harga
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rp${formatRupiah(widget.venue.price)},-',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'per hari',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // Tombol Sewa
            ElevatedButton(
              onPressed: _isBooking ? null : _showBookingDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0062FF),
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sewa',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
