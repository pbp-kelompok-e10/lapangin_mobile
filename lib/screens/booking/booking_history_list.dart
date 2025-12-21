import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lapangin/config/api_config.dart';
import 'package:lapangin/models/booking_entry.dart';
import 'package:lapangin/screens/venue/venue_detail.dart';
import 'package:lapangin/helper/price_formatter.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  List<BookingEntry>? _bookings;
  bool _isLoading = true;
  bool _noConnection = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _noConnection = false;
      _error = null;
    });

    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(ApiConfig.myBookingsUrl);
      print('Logged in: ${request.loggedIn}');
      print('Cookies: ${request.cookies}');

      if (response is Map<String, dynamic> && response['status'] == true) {
        final bookingsData = response['data']['bookings'] as List;
        setState(() {
          _bookings = bookingsData
              .map((json) => BookingEntry.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal memuat data booking';
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('handshakeexception') ||
          errorString.contains('connection') ||
          errorString.contains('failed host lookup')) {
        setState(() {
          _noConnection = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBooking(BookingEntry booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Batalkan Booking?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan booking di ${booking.venueName} pada ${booking.formattedBookingDateLong}?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final request = context.read<CookieRequest>();
      final response = await request.post(
        ApiConfig.deleteBookingUrl(booking.id),
        {},
      );

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Booking berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal membatalkan booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rescheduleBooking(BookingEntry booking) async {
    // Get booked dates for the venue first
    List<DateTime> bookedDates = [];
    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(
        ApiConfig.bookedDatesUrl(booking.venueId),
      );

      if (response['status'] == true) {
        final dates = response['data']['booked_dates'] as List;
        bookedDates = dates.map((d) => DateTime.parse(d)).toList();
      }
    } catch (e) {
      // Continue without booked dates info
    }

    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: booking.bookingDate.isAfter(DateTime.now())
          ? booking.bookingDate
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Can't select already booked dates (except current booking date)
        if (date.year == booking.bookingDate.year &&
            date.month == booking.bookingDate.month &&
            date.day == booking.bookingDate.day) {
          return true;
        }
        return !bookedDates.any(
          (booked) =>
              booked.year == date.year &&
              booked.month == date.month &&
              booked.day == date.day,
        );
      },
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

    if (newDate == null) return;

    // Check if same date selected
    if (newDate.year == booking.bookingDate.year &&
        newDate.month == booking.bookingDate.month &&
        newDate.day == booking.bookingDate.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal yang dipilih sama dengan tanggal sebelumnya'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final request = context.read<CookieRequest>();
      final response = await request.post(
        ApiConfig.editBookingUrl(booking.id),
        jsonEncode({'booking_date': newDate.toIso8601String().split('T')[0]}),
      );

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Jadwal berhasil diubah'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal mengubah jadwal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Riwayat Booking',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0062FF),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0062FF)),
      ),
      body: RefreshIndicator(onRefresh: _loadBookings, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_noConnection) {
      return _buildNoConnectionWidget();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookings == null || _bookings!.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings!.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(_bookings![index]);
      },
    );
  }

  Widget _buildNoConnectionWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Koneksi Internet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet Anda dan coba lagi',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0062FF),
                side: const BorderSide(color: Color(0xFF0062FF)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum memiliki riwayat booking.\nMulai booking venue favorit Anda!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingEntry booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailPage(venueId: booking.venueId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Image with Status Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: _buildVenueImage(booking.venueThumbnail),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(booking),
                ),
              ],
            ),

            // Booking Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue Name
                  Text(
                    booking.venueName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.venueCity,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Booking Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.formattedBookingDateLong,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rp${formatRupiah(booking.venuePrice)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0062FF),
                        ),
                      ),
                    ],
                  ),

                  // Action Buttons (only if can modify)
                  if (booking.canModify) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Delete Button
                        TextButton.icon(
                          onPressed: () => _deleteBooking(booking),
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Batalkan',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reschedule Button
                        ElevatedButton.icon(
                          onPressed: () => _rescheduleBooking(booking),
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text(
                            'Ubah Jadwal',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0062FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
      ),
    );
  }

  Widget _buildVenueImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Icon(Icons.stadium, size: 48, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          final bytes = base64Decode(parts[1].trim());
          return Image.memory(
            bytes,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        }
      } catch (e) {
        // Fall through to placeholder
      }
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 140,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: const Icon(Icons.stadium, size: 48, color: Colors.grey),
    );
  }

  Widget _buildStatusBadge(BookingEntry booking) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (booking.status) {
      case 'completed':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.check_circle;
        break;
      case 'today':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.today;
        break;
      case 'upcoming':
      default:
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            booking.statusDisplay,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
