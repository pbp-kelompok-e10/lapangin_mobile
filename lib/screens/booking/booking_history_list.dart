import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lapangin/config/api_config.dart';
import 'package:lapangin/screens/booking/create_booking_page.dart';
import 'package:lapangin/screens/venue/venue_detail.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Renaming to BookingHistoryPage and converting to a StatefulWidget
// to manage state for loading and displaying bookings.
class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  late Future<List<dynamic>> _bookingHistoryFuture;
  bool _noConnection = false;

  @override
  void initState() {
    super.initState();
    _bookingHistoryFuture = _fetchBookingHistory();
  }

  Future<List<dynamic>> _fetchBookingHistory() async {
    setState(() {
      _noConnection = false;
    });

    try {
      final request = context.read<CookieRequest>();
      final response = await request.get(ApiConfig.myBookingsUrl);

      // The API returns a map with a 'bookings' key.
      if (response != null && response['bookings'] != null) {
        return response['bookings'];
      } else {
        // Handle cases where response is not as expected.
        throw Exception('Gagal memuat riwayat booking.');
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('handshakeexception') ||
          errorString.contains('connection') ||
          errorString.contains('network') ||
          errorString.contains('failed host lookup')) {
        setState(() {
          _noConnection = true;
        });
        return [];
      }
      rethrow;
    }
  }

  // Function to handle booking cancellation
  Future<void> _cancelBooking(int bookingId) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembatalan'),
        content: const Text('Anda yakin ingin membatalkan booking ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final request = context.read<CookieRequest>();
      final response = await request.post(
        ApiConfig.deleteBookingUrl(bookingId),
        jsonEncode({}), // Sending an empty body for a POST-based delete
      );

      if (!context.mounted) return;

      if (response['success']) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(response['message'])));
        // Refresh the list
        setState(() {
          _bookingHistoryFuture = _fetchBookingHistory();
        });
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                response['message'] ?? 'Gagal membatalkan booking.',
              ),
            ),
          );
      }
    }
  }

  // Function to show the edit date dialog
  Future<void> _showEditDateDialog(
    BuildContext context,
    dynamic booking,
  ) async {
    final request = context.read<CookieRequest>();
    DateTime? newSelectedDate;
    List<DateTime> bookedDates = [];

    // Fetch already booked dates for this venue to disable them in the picker
    try {
      final response = await request.get(
        ApiConfig.bookedDatesUrl(booking['venue_id'].toString()),
      );
      if (response != null && response['booked_dates'] != null) {
        bookedDates = (response['booked_dates'] as List)
            .map((dateStr) => DateTime.parse(dateStr))
            .toList();
      }
    } catch (e) {
      // Non-critical error, we can proceed without disabling dates
      print("Failed to load booked dates for editing: $e");
    }

    if (!context.mounted) return;

    // Show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ubah Tanggal Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih tanggal baru untuk venue "${booking['venue_name']}".',
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      newSelectedDate == null
                          ? 'Ketuk untuk memilih tanggal'
                          : 'Tanggal baru: ${newSelectedDate!.toIso8601String().split('T').first}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(booking['booking_date']),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                        selectableDayPredicate: (DateTime day) {
                          // Allow the original date to be selected
                          final originalDate = DateTime.parse(
                            booking['booking_date'],
                          );
                          if (day.year == originalDate.year &&
                              day.month == originalDate.month &&
                              day.day == originalDate.day) {
                            return true;
                          }
                          // Disable other booked dates
                          return !bookedDates.any(
                            (bookedDate) =>
                                day.year == bookedDate.year &&
                                day.month == bookedDate.month &&
                                day.day == bookedDate.day,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          newSelectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: newSelectedDate == null
                      ? null
                      : () async {
                          // Call the edit API
                          await _submitEdit(
                            booking['booking_id'],
                            newSelectedDate!,
                          );
                          if (context.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to submit the edit request
  Future<void> _submitEdit(int bookingId, DateTime newDate) async {
    final request = context.read<CookieRequest>();
    final String dateStr = newDate.toIso8601String().split('T').first;

    final response = await request.postJson(
      ApiConfig.editBookingUrl(bookingId),
      jsonEncode({'booking_date': dateStr}),
    );

    if (!context.mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response['message'])));
      // Refresh the list
      setState(() {
        _bookingHistoryFuture = _fetchBookingHistory();
      });
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(response['message'] ?? 'Gagal memperbarui booking.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _bookingHistoryFuture = _fetchBookingHistory();
            });
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Riwayat Booking',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: _noConnection
                    ? _buildNoConnectionState()
                    : FutureBuilder<List<dynamic>>(
                        future: _bookingHistoryFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return _buildErrorState(snapshot.error.toString());
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          }

                          final bookings = snapshot.data!;
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              return _buildBookingCard(booking);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoConnectionState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'Tidak Ada Koneksi Internet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Periksa koneksi internet Anda dan coba lagi.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _bookingHistoryFuture = _fetchBookingHistory();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Booking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda belum memiliki riwayat booking.\nAyo booking Stadion sekarang!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _bookingHistoryFuture = _fetchBookingHistory();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(dynamic booking) {
    // Try different possible field names for venue image
    String? imageUrl =
        booking['venue_thumbnail'] ??
        booking['thumbnail'] ??
        booking['venue_image'] ??
        booking['image'];

    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    return imageUrl;
  }

  Widget _buildVenueImage(dynamic booking) {
    final imageData = _getImageUrl(booking);

    // Placeholder widget for error/empty states
    Widget placeholder = Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 50, color: Colors.grey),
      ),
    );

    if (imageData.isEmpty) {
      return placeholder;
    }

    // Handle base64 data URI
    if (imageData.startsWith('data:image')) {
      try {
        // Extract base64 string from data URI
        final base64String = imageData.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } catch (e) {
        return placeholder;
      }
    }

    // Handle regular URL
    String url = imageData;
    if (!url.startsWith('http')) {
      url = url.startsWith('/')
          ? '${ApiConfig.baseUrl}$url'
          : '${ApiConfig.baseUrl}/$url';
    }

    return Image.network(
      url,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final bool canModify = booking['can_modify'] ?? false;
    final String venueId = booking['venue_id'].toString();
    final DateTime bookingDate = DateTime.parse(booking['booking_date']);

    // Determine booking status
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    final DateTime bookingDateOnly = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
    );

    final bool isToday = bookingDateOnly.isAtSameMomentAs(todayOnly);
    final bool isPast = bookingDateOnly.isBefore(todayOnly);
    final bool isUpcoming = bookingDateOnly.isAfter(todayOnly);

    // Badge properties
    final String badgeText;
    final Color badgeColor;
    final IconData badgeIcon;

    if (isPast) {
      badgeText = 'Selesai';
      badgeColor = Colors.grey;
      badgeIcon = Icons.check_circle;
    } else if (isToday) {
      badgeText = 'Hari Ini';
      badgeColor = Colors.green;
      badgeIcon = Icons.today;
    } else {
      badgeText = 'Akan Datang';
      badgeColor = Colors.blue;
      badgeIcon = Icons.event;
    }

    final String formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(bookingDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VenueDetailPage(venueId: venueId),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildVenueImage(booking),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Venue Name
                    Text(
                      booking['venue_name'] ?? 'Nama Venue',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Date Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Booking',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow Icon
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                    // Action Buttons
                    if (canModify && !isPast) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showEditDateDialog(context, booking),
                              icon: const Icon(Icons.edit_calendar, size: 18),
                              label: const Text('Ubah Tanggal'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _cancelBooking(booking['booking_id'] as int),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Batalkan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
      ),
    );
  }
}
