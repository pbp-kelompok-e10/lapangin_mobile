import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

// Renaming to BookingHistoryPage and converting to a StatefulWidget
// to manage state for loading and displaying bookings.
class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  late Future<List<dynamic>> _bookingHistoryFuture;

  @override
  void initState() {
    super.initState();
    _bookingHistoryFuture = _fetchBookingHistory();
  }

  Future<List<dynamic>> _fetchBookingHistory() async {
    final request = context.read<CookieRequest>();
    // Replace with your actual production URL
    final response = await request.get("http://localhost:8000/booking/history/api/");

    // The API returns a map with a 'bookings' key.
    if (response != null && response['bookings'] != null) {
      return response['bookings'];
    } else {
      // Handle cases where response is not as expected.
      throw Exception('Gagal memuat riwayat booking.');
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
      // The Django URL for deletion needs to be adapted.
      // Assuming a URL like /booking/delete/<id>/
      final response = await request.post(
        "http://localhost:8000/booking/delete/$bookingId/",
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
          ..showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text(response['message'] ?? 'Gagal membatalkan booking.')));
      }
    }
  }

  // Function to show the edit date dialog
  Future<void> _showEditDateDialog(BuildContext context, dynamic booking) async {
    final request = context.read<CookieRequest>();
    DateTime? newSelectedDate;
    List<DateTime> bookedDates = [];

    // Fetch already booked dates for this venue to disable them in the picker
    try {
      final url = "http://localhost:8000/booking/booked-dates/${booking['venue_id']}/";
      final response = await request.get(url);
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
                  Text('Pilih tanggal baru untuk venue "${booking['venue_name']}".'),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(newSelectedDate == null
                        ? 'Ketuk untuk memilih tanggal'
                        : 'Tanggal baru: ${newSelectedDate!.toIso8601String().split('T').first}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(booking['booking_date']),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                        selectableDayPredicate: (DateTime day) {
                          // Allow the original date to be selected
                          final originalDate = DateTime.parse(booking['booking_date']);
                          if (day.year == originalDate.year && day.month == originalDate.month && day.day == originalDate.day) {
                            return true;
                          }
                          // Disable other booked dates
                          return !bookedDates.any((bookedDate) =>
                              day.year == bookedDate.year &&
                              day.month == bookedDate.month &&
                              day.day == bookedDate.day);
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
                  onPressed: newSelectedDate == null ? null : () async {
                    // Call the edit API
                    await _submitEdit(booking['booking_id'], newSelectedDate!);
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
      "http://localhost:8000/booking/edit/$bookingId/",
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
        ..showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(response['message'] ?? 'Gagal memperbarui booking.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _bookingHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Anda belum memiliki riwayat booking.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final bool canModify = booking['can_modify'] ?? false;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            // Using a placeholder if thumbnail is not available
                            booking['venue_thumbnail'] ?? 'https://via.placeholder.com/150',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.sports_soccer, size: 50),
                          ),
                        ),
                        title: Text(booking['venue_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text('Tanggal: ${booking['booking_date']}', style: const TextStyle(fontSize: 16)),
                      ),
                      if (canModify) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _showEditDateDialog(context, booking);
                              },
                              child: const Text('Ubah Tanggal'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _cancelBooking(booking['booking_id'] as int),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Batalkan'),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/*
@csrf_exempt
@require_POST
def delete_booking_api(request, booking_id):
    """ Handles deleting a booking. """
    if not request.user.is_authenticated:
        return JsonResponse({
            'success': False,
            'message': 'Authentication credentials were not provided.'
        }, status=401)
    booking = get_object_or_404(Booking, pk=booking_id, user=request.user)

    if booking.booking_date < date.today():
        return JsonResponse({'success': False, 'message': 'Booking yang sudah lewat tidak bisa dihapus.'}, status=403)

    try:
        booking_id_deleted = booking.id
        venue_name = booking.venue.name
        booking_date = booking.booking_date
        booking.delete()
        return JsonResponse({
            'success': True,
            'message': f'Booking untuk {venue_name} pada tanggal {booking_date.isoformat()} berhasil dibatalkan.',
            'deleted_booking_id': booking_id_deleted
            })
    except Exception as e:
        return JsonResponse({'success': False, 'message': f'Gagal membatalkan booking: {str(e)}'}, status=500)
    */