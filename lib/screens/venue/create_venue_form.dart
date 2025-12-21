import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:lapangin/config/api_config.dart';

class CreateVenuePage extends StatefulWidget {
  const CreateVenuePage({super.key});

  @override
  State<CreateVenuePage> createState() => _CreateVenuePageState();
}

class _CreateVenuePageState extends State<CreateVenuePage> {
  final _formKey = GlobalKey<FormState>();

  // State Variables
  String _name = '';
  String _city = '';
  String _country = '';
  int _capacity = 0;
  double _price = 0.0;
  String _thumbnail = '';
  String _description = '';
  String _facilities = '';
  String _rules = '';

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
            'facilities': _facilities,
            'rules': _rules,
          }),
        );

        if (!mounted) return;

        if (response is Map<String, dynamic> &&
            response.containsKey('status') &&
            response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venue berhasil dibuat!'),
              backgroundColor: _primaryColor,
            ),
          );
          Navigator.pop(context, true);
        } else {
          String errorMessage = response['message'] ?? 'Gagal membuat venue.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _noConnection = true;
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildModernTextFormField({
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    int maxLines = 1,
    String? hintText,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: TextStyle(
              color: Colors.blueGrey.shade600,
              fontSize: 11,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: _secondaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_noConnection) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const Text("Koneksi Terputus"),
              ElevatedButton(
                onPressed: () => setState(() => _noConnection = false),
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Venue Baru',
          style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildModernTextFormField(
                labelText: 'Nama Stadion',
                hintText: 'Contoh: Gelora Bung Karno',
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextFormField(
                      labelText: 'Kota',
                      onSaved: (v) => _city = v!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernTextFormField(
                      labelText: 'Negara',
                      onSaved: (v) => _country = v!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModernTextFormField(
                labelText: 'Kapasitas & Harga',
                keyboardType: TextInputType.number,
                hintText: 'Kapasitas penonton...',
                onSaved: (v) => _capacity = int.parse(v!),
              ),
              const SizedBox(height: 16),
              _buildModernTextFormField(
                labelText: 'Harga Sewa (IDR)',
                keyboardType: TextInputType.number,
                onSaved: (v) => _price = double.parse(v!),
              ),
              const SizedBox(height: 16),
              _buildModernTextFormField(
                labelText: 'Deskripsi Singkat',
                maxLines: 3,
                onSaved: (v) => _description = v!,
              ),
              const SizedBox(height: 16),

              _buildModernTextFormField(
                labelText: 'Fasilitas Venue',
                hintText: 'Contoh:\nLampu Malam\nRuang Ganti\nWiFi',
                maxLines: 4,
                helperText:
                    '💡 Gunakan baris baru (Enter) untuk memisahkan setiap fasilitas.',
                onSaved: (v) => _facilities = v!,
              ),
              const SizedBox(height: 16),

              _buildModernTextFormField(
                labelText: 'Aturan Pakai',
                hintText: 'Contoh:\nDilarang merokok\nGunakan sepatu olahraga',
                maxLines: 4,
                helperText:
                    '💡 Gunakan baris baru (Enter) untuk memisahkan setiap aturan.',
                onSaved: (v) => _rules = v!,
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _submitVenue(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _secondaryColor,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Venue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
