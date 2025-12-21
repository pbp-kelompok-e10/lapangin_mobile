import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class CreateBookingPage extends StatefulWidget {
  // We need to know which venue is being booked.
  final String venueId;
  const CreateBookingPage({super.key, required this.venueId});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  // A loading indicator state
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;

  @override
  void dispose() {
    // It's important to dispose of controllers to free up resources.
    // No controllers to dispose of anymore.
    super.dispose();
  }

  // A function to show the date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Users can't book in the past
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Booking'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(
                  child: Text(
                    'Buat Booking',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 36.0),
                // A text field that looks like a button for date picking
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Booking',
                    hintText: _selectedDate == null
                        ? 'Pilih tanggal'
                        : _selectedDate!.toIso8601String().split('T').first,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context),
                  validator: (_) {
                    if (_selectedDate == null) {
                      return 'Silakan pilih tanggal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;

                    setState(() => _isLoading = true);

                    // The API expects the date in 'YYYY-MM-DD' format.
                    final String dateStr = _selectedDate!.toIso8601String().split('T').first;

                    // Use the pbp_django_auth request to make a post request
                    final response = await request.postJson(
                      // Replace with your actual production URL
                      "http://localhost:8000/booking/create/", 
                      jsonEncode(<String, dynamic>{
                        'venue_id': widget.venueId,
                        'booking_date': dateStr,
                      }),
                    );

                    if (!context.mounted) return;

                    setState(() => _isLoading = false);

                    if (response['success']) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text(response['message'] ?? "Booking berhasil!")));
                      Navigator.pop(context); // Go back to the previous screen
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Booking Gagal'),
                          content: Text(response['message'] ?? "Terjadi kesalahan."),
                          actions: [
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 5,
                    // Show a disabled state when loading
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kirim Booking', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/*from django.db import models
from django.conf import settings
from modules.venue.models import Venue

class Booking(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='bookings')
    venue = models.ForeignKey('venue.Venue', on_delete=models.CASCADE, related_name='bookings')
    booking_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.venue.name} by {self.user.username} on {self.booking_date}"

    class Meta:
        ordering = ['-booking_date']
        unique_together = ('venue', 'booking_date')


@login_required
def booking_history_page(request):
    return render(request, 'booking_history.html')



@require_GET
def get_booked_dates_api(request, venue_id):
    if not Venue.objects.filter(pk=venue_id).exists():
        return JsonResponse({'error': 'Venue not found.'}, status=404)

    booked_dates = Booking.objects.filter(
        venue_id=venue_id,
        booking_date__gte=date.today()
    ).values_list('booking_date', flat=True)

    booked_date_strings = [d.isoformat() for d in booked_dates]

    return JsonResponse({'booked_dates': booked_date_strings})


@csrf_exempt # Disable CSRF for API endpoints consumed by non-browser clients
@require_POST
def create_booking_api(request):
    try:
        data = json.loads(request.body)
        venue_id = data.get('venue_id')
        date_str = data.get('booking_date')

        if not request.user.is_authenticated:
            return JsonResponse({
            'success': False,
            'message': 'Otentikasi diperlukan. Silakan login terlebih dahulu.'
        }, status=401)

        if not all([venue_id, date_str]):
            return JsonResponse({'success': False, 'message': 'Data tidak lengkap (venue_id, booking_date).'}, status=400)

        venue = get_object_or_404(Venue, pk=venue_id)
        booking_date = date.fromisoformat(date_str)

        # Validation
        if booking_date < date.today():
            return JsonResponse({'success': False, 'message': 'Tanggal booking tidak boleh di masa lalu.'}, status=400)

        # Check if already booked
        if Booking.objects.filter(venue=venue, booking_date=booking_date).exists():
            return JsonResponse({'success': False, 'message': 'Tanggal ini sudah dibooking.'}, status=400)

        # Create Booking
        booking = Booking.objects.create(
            user=request.user,
            venue=venue,
            booking_date=booking_date
        )

        return JsonResponse({
            'success': True,
            'message': 'Booking berhasil dibuat!',
            'booking_details': {
                'id': booking.id,
                'venue': booking.venue.name,
                'date': booking.booking_date.isoformat(),
            }
        })

    except json.JSONDecodeError:
        return JsonResponse({'success': False, 'message': 'Format data tidak valid.'}, status=400)
    except ValueError:
        return JsonResponse({'success': False, 'message': 'Format tanggal tidak valid (YYYY-MM-DD).'}, status=400)
    except Venue.DoesNotExist:
        return JsonResponse({'success': False, 'message': 'Venue tidak ditemukan.'}, status=404)
    except Exception as e:
        if 'UNIQUE constraint failed' in str(e):
            return JsonResponse({'success': False, 'message': 'Tanggal ini sudah dibooking.'}, status=400)
        return JsonResponse({'success': False, 'message': f'Terjadi kesalahan server: {str(e)}'}, status=500)


@csrf_exempt
def get_user_bookings_api(request):
    user_bookings = Booking.objects.filter(user=request.user).select_related('venue').order_by('-booking_date')
    bookings_data = []
    for booking in user_bookings:
        can_modify = booking.booking_date >= date.today()
        bookings_data.append({
            'booking_id': booking.id,
            'venue_id': booking.venue.id,
            'venue_name': booking.venue.name,
            'venue_thumbnail': booking.venue.thumbnail if booking.venue.thumbnail else '/static/img/default-thumbnail.jpg',
            'booking_date': booking.booking_date.isoformat(),
            'created_at': booking.created_at.isoformat(),
            'can_modify': can_modify,
            'url_detail': reverse('venue:venue_detail', args=[booking.venue.id]),
        })

    return JsonResponse({'bookings': bookings_data})


@csrf_exempt
@require_http_methods(["GET", "POST"])
def edit_booking_api(request, booking_id):
    if not request.user.is_authenticated:
        return JsonResponse({
            'success': False,
            'message': 'Authentication credentials were not provided.'
        }, status=401)
    booking = get_object_or_404(Booking, pk=booking_id, user=request.user)

    if booking.booking_date < date.today():
        return JsonResponse({'success': False, 'message': 'Booking yang sudah lewat tidak bisa diubah.'}, status=403)

    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            new_date_str = data.get('booking_date')
            if not new_date_str:
                return JsonResponse({'success': False, 'message': 'Tanggal baru diperlukan.'}, status=400)

            new_date = date.fromisoformat(new_date_str)

            if new_date < date.today():
                return JsonResponse({'success': False, 'message': 'Tanggal baru tidak boleh di masa lalu.'}, status=400)

            if Booking.objects.filter(
                venue=booking.venue,
                booking_date=new_date
            ).exclude(pk=booking.id).exists():
                return JsonResponse({'success': False, 'message': 'Tanggal baru tersebut sudah dibooking.'}, status=400)

            booking.booking_date = new_date
            booking.save(update_fields=['booking_date'])

            return JsonResponse({
                'success': True,
                'message': 'Tanggal booking berhasil diperbarui.',
                'updated_booking': {
                'booking_id': booking.id,
                'booking_date': booking.booking_date.isoformat(),
                }
            })

        except json.JSONDecodeError:
            return JsonResponse({'success': False, 'message': 'Format data tidak valid.'}, status=400)
        except ValueError:
            return JsonResponse({'success': False, 'message': 'Format tanggal baru tidak valid (YYYY-MM-DD).'}, status=400)
        except Exception as e:
            return JsonResponse({'success': False, 'message': f'Terjadi kesalahan: {str(e)}'}, status=500)

    else:
        return JsonResponse({'success': True, 'data': {'booking_date': booking.booking_date.isoformat()}})
*/