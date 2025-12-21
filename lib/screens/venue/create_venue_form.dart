import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lapangin/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class CreateVenuePage extends StatefulWidget {
  const CreateVenuePage({super.key});

  @override
  State<CreateVenuePage> createState() => _CreateVenuePageState();
}

class _CreateVenuePageState extends State<CreateVenuePage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _city = '';
  String _country = '';
  int _capacity = 0;
  double _price = 0.0;
  String _thumbnail = '';
  String _description = '';
  bool _isLoading = false;
  bool _noConnection = false;

  static const Color _primaryColor = Color(0xFF0062FF);
  static const Color _secondaryColor = Color(0xFF003C9C);

  Future<void> _submitVenue(BuildContext context) async {
    final request = context.read<CookieRequest>();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await request.postJson(
          ApiConfig.createVenueUrl,
          jsonEncode({
            'name': _name,
            'city': _city,
            'country': _country,
            'capacity': _capacity,
            'price': _price.toString(),
            'thumbnail': _thumbnail,
            'description': _description,
          }),
        );
        if (!mounted) return;

        if (response is Map<String, dynamic> &&
            response.containsKey('status') &&
            response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Venue created successfully!',
              ),
              backgroundColor: _primaryColor,
            ),
          );
          Navigator.pop(context, true);
        } else if (response is Map<String, dynamic> &&
            response.containsKey('errors')) {
          final errors = response['errors'];
          String errorMessage = 'Failed to create venue.';
          try {
            final errorMap = jsonDecode(errors);
            errorMessage = _formatErrors(errorMap);
          } catch (e) {
            errorMessage = 'Failed to create venue: Invalid data submitted.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Venue created, but response format was unexpected: ${response.toString()}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (!mounted) return;

        final errorString = e.toString().toLowerCase();
        if (errorString.contains('socketexception') ||
            errorString.contains('handshakeexception') ||
            errorString.contains('connection') ||
            errorString.contains('failed host lookup')) {
          setState(() {
            _noConnection = true;
          });
        } else {
          String errorMsg = 'Connection Error: Gagal terhubung ke server.';
          if (e.toString().contains('403')) {
            errorMsg =
                'Akses Ditolak (403): Harap login terlebih dahulu atau periksa izin.';
          } else if (e.toString().contains('400')) {
            errorMsg = 'Data Invalid (400): Periksa input Anda.';
          } else {
            errorMsg = 'Connection Error: ${e.toString()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatErrors(Map<String, dynamic> errors) {
    String formatted = 'Mohon perbaiki kesalahan berikut:\n';
    errors.forEach((key, value) {
      formatted += '- ${key.toUpperCase()}: ${(value as List).join(', ')}\n';
    });
    return formatted.trim();
  }

  Widget _buildModernTextFormField({
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onSaved: onSaved,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: _secondaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // No internet connection state
    if (_noConnection) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Tambah Venue Baru',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: _primaryColor,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: _primaryColor),
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
                  onPressed: () {
                    setState(() {
                      _noConnection = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Venue Baru',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Hapus bayangan AppBar
        iconTheme: const IconThemeData(color: _primaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Name Field
              _buildModernTextFormField(
                labelText: 'Nama Stadion',
                hintText: 'Masukkan nama stadion...',
                validator: (value) =>
                    value!.isEmpty ? 'Nama stadion tidak boleh kosong.' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),

              // City Field
              _buildModernTextFormField(
                labelText: 'Kota',
                hintText: 'Contoh: Jakarta Selatan',
                validator: (value) =>
                    value!.isEmpty ? 'Kota tidak boleh kosong.' : null,
                onSaved: (value) => _city = value!,
              ),
              const SizedBox(height: 16),

              // Country Field
              _buildModernTextFormField(
                labelText: 'Negara',
                hintText: 'Contoh: Indonesia',
                validator: (value) =>
                    value!.isEmpty ? 'Negara tidak boleh kosong.' : null,
                onSaved: (value) => _country = value!,
              ),
              const SizedBox(height: 16),

              // Capacity Field (Input Type Number)
              _buildModernTextFormField(
                labelText: 'Kapasitas Penonton',
                hintText: 'Masukkan jumlah kapasitas...',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Kapasitas tidak boleh kosong.';
                  if (int.tryParse(value) == null || int.parse(value) <= 0)
                    return 'Masukkan angka kapasitas yang valid (> 0).';
                  return null;
                },
                onSaved: (value) => _capacity = int.parse(value!),
              ),
              const SizedBox(height: 16),

              // Price Field (Input Type Decimal)
              _buildModernTextFormField(
                labelText: 'Harga Sewa (Per Hari, dalam IDR)',
                hintText: 'Contoh: 3500000',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Harga sewa tidak boleh kosong.';
                  if (double.tryParse(value) == null || double.parse(value) < 0)
                    return 'Masukkan harga sewa yang valid.';
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              const SizedBox(height: 16),

              // Thumbnail URL Field
              _buildModernTextFormField(
                labelText: 'URL Gambar Thumbnail',
                hintText: 'URL gambar utama venue (opsional)',
                onSaved: (value) => _thumbnail = value ?? '',
              ),
              const SizedBox(height: 16),

              // Description Field
              _buildModernTextFormField(
                labelText: 'Deskripsi Venue',
                hintText: 'Jelaskan fasilitas dan keunggulan venue...',
                maxLines: 5,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _submitVenue(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: _secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 24),
                label: Text(
                  _isLoading ? 'Sedang Menyimpan...' : 'Tambahkan Venue',
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
