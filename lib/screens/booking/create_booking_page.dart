import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lapangin/config/api_config.dart';
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
      firstDate: DateTime.now(),
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
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => _isLoading = true);

                          // The API expects the date in 'YYYY-MM-DD' format.
                          final String dateStr = _selectedDate!
                              .toIso8601String()
                              .split('T')
                              .first;

                          // Use the pbp_django_auth request to make a post request
                          final response = await request.postJson(
                            ApiConfig.createBookingUrl,
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
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response['message'] ?? "Booking berhasil!",
                                  ),
                                ),
                              );
                            Navigator.pop(
                              context,
                            ); // Go back to the previous screen
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Booking Gagal'),
                                content: Text(
                                  response['message'] ?? "Terjadi kesalahan.",
                                ),
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
                      : const Text(
                          'Kirim Booking',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
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
}
