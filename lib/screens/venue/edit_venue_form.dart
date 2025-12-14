import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lapangin/models/venue_entry.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class EditVenuePage extends StatefulWidget {
  final String venueId;
  final VenueEntry? initialVenue;

  const EditVenuePage({super.key, required this.venueId, this.initialVenue});

  @override
  State<EditVenuePage> createState() => _EditVenuePageState();
}

class _EditVenuePageState extends State<EditVenuePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _thumbnailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _name = '';
  String _city = '';
  String _country = '';
  int _capacity = 0;
  double _price = 0.0;
  String _thumbnail = '';
  String _description = '';

  // Status loading
  bool _isLoading = false;
  bool _isDataLoading = true;
  VenueEntry? _currentVenue;

  static const Color _primaryColor = Color(0xFF0062FF);
  static const Color _secondaryColor = Color(0xFF003C9C);

  @override
  void initState() {
    super.initState();
    if (widget.initialVenue != null) {
      _currentVenue = widget.initialVenue;
      _initializeControllers();
      _isDataLoading = false;
    }
  }

  void _initializeControllers() {
    final venue = _currentVenue!;
    _nameController.text = venue.name;
    _cityController.text = venue.city;
    _countryController.text = venue.country;
    _capacityController.text = venue.capacity.toString();
    _priceController.text = venue.price.toString();
    _thumbnailController.text = venue.thumbnail;
    _descriptionController.text = venue.description;
  }

  // Mengirim pembaruan venue ke server
  Future<void> _submitEditVenue(BuildContext context) async {
    final request = context.read<CookieRequest>();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        // Endpoint edit venue di Django
        final url =
            "https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id/venues/api/edit/${widget.venueId}";

        final response = await request.postJson(
          url,
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
                response['message'] ??
                    'Venue ID ${widget.venueId} berhasil diperbarui!',
              ),
              backgroundColor: _primaryColor,
            ),
          );
          Navigator.pop(context, true);
        } else if (response is Map<String, dynamic> &&
            response.containsKey('errors')) {
          final errors = response['errors'];
          String errorMessage = 'Gagal memperbarui venue.';
          try {
            final errorMap = jsonDecode(errors);
            errorMessage = _formatErrors(errorMap);
          } catch (e) {
            errorMessage =
                'Gagal memperbarui venue: Data yang dikirimkan tidak valid.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Venue diperbarui, tetapi format respons tidak terduga: ${response.toString()}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (!mounted) return;
        String errorMsg = 'Kesalahan Koneksi: Gagal terhubung ke server.';
        if (e.toString().contains('403')) {
          errorMsg =
              'Akses Ditolak (403): Harap login terlebih dahulu atau periksa izin.';
        } else if (e.toString().contains('400')) {
          errorMsg = 'Data Invalid (400): Periksa input Anda.';
        } else {
          errorMsg = 'Kesalahan Koneksi: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi utilitas untuk memformat pesan error (konsisten)
  String _formatErrors(Map<String, dynamic> errors) {
    String formatted = 'Mohon perbaiki kesalahan berikut:\n';
    errors.forEach((key, value) {
      formatted += '- ${key.toUpperCase()}: ${(value as List).join(', ')}\n';
    });
    return formatted.trim();
  }

  // Widget _buildModernTextFormField (konsisten)
  Widget _buildModernTextFormField({
    required String labelText,
    required TextEditingController controller, // Wajib ada controller
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
          controller: controller, // Tetapkan controller
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
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _thumbnailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Venue',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Name Field
                    _buildModernTextFormField(
                      labelText: 'Nama Stadion',
                      controller: _nameController,
                      hintText: 'Masukkan nama stadion...',
                      validator: (value) => value!.isEmpty
                          ? 'Nama stadion tidak boleh kosong.'
                          : null,
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 16),

                    // City Field
                    _buildModernTextFormField(
                      labelText: 'Kota',
                      controller: _cityController,
                      hintText: 'Contoh: Jakarta Selatan',
                      validator: (value) =>
                          value!.isEmpty ? 'Kota tidak boleh kosong.' : null,
                      onSaved: (value) => _city = value!,
                    ),
                    const SizedBox(height: 16),

                    // Country Field
                    _buildModernTextFormField(
                      labelText: 'Negara',
                      controller: _countryController,
                      hintText: 'Contoh: Indonesia',
                      validator: (value) =>
                          value!.isEmpty ? 'Negara tidak boleh kosong.' : null,
                      onSaved: (value) => _country = value!,
                    ),
                    const SizedBox(height: 16),

                    // Capacity Field (Input Type Number)
                    _buildModernTextFormField(
                      labelText: 'Kapasitas Penonton',
                      controller: _capacityController,
                      hintText: 'Masukkan jumlah kapasitas...',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Kapasitas tidak boleh kosong.';
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0)
                          return 'Masukkan angka kapasitas yang valid (> 0).';
                        return null;
                      },
                      onSaved: (value) => _capacity = int.parse(value!),
                    ),

                    const SizedBox(height: 16),

                    // Price Field (Input Type Decimal)
                    _buildModernTextFormField(
                      labelText: 'Harga Sewa (Per Hari, dalam IDR)',
                      controller: _priceController,
                      hintText: 'Contoh: 3500000',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Harga sewa tidak boleh kosong.';
                        if (double.tryParse(value) == null ||
                            double.parse(value) < 0)
                          return 'Masukkan harga sewa yang valid.';
                        return null;
                      },
                      onSaved: (value) => _price = double.parse(value!),
                    ),
                    const SizedBox(height: 16),

                    // Thumbnail URL Field
                    _buildModernTextFormField(
                      labelText: 'URL Gambar Thumbnail',
                      controller: _thumbnailController,
                      hintText: 'URL gambar utama venue (opsional)',
                      onSaved: (value) => _thumbnail = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    _buildModernTextFormField(
                      labelText: 'Deskripsi Venue',
                      controller: _descriptionController,
                      hintText: 'Jelaskan fasilitas dan keunggulan venue...',
                      maxLines: 5,
                      onSaved: (value) => _description = value ?? '',
                    ),
                    const SizedBox(height: 32),

                    // Submit Button (Edit Button)
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _submitEditVenue(context),
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
                          : const Icon(Icons.edit_note_rounded, size: 24),
                      label: Text(
                        _isLoading ? 'Sedang Menyimpan...' : 'Simpan Perubahan',
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
