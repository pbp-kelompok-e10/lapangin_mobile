import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lapangin/config/api_config.dart';
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
  final TextEditingController _facilitiesController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();

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
  bool _isDataLoading = true;
  bool _noConnection = false;
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
    _facilitiesController.text = venue.facilities;
    _rulesController.text = venue.rules;
  }

  Future<void> _submitEditVenue(BuildContext context) async {
    final request = context.read<CookieRequest>();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final url = ApiConfig.editVenueUrl(widget.venueId);

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
            'facilities': _facilities,
            'rules': _rules,
          }),
        );

        if (!mounted) return;

        if (response is Map<String, dynamic> &&
            response.containsKey('status') &&
            response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Venue berhasil diperbarui!',
              ),
              backgroundColor: _primaryColor,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui venue.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _noConnection = true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildModernTextFormField({
    required String labelText,
    required TextEditingController controller,
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
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onSaved: onSaved,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            helperStyle: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
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
    _facilitiesController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_noConnection) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
              const Text(
                'Tidak Ada Koneksi Internet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _noConnection = false),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Venue',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primaryColor),
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
                    _buildModernTextFormField(
                      labelText: 'Nama Stadion',
                      controller: _nameController,
                      validator: (value) =>
                          value!.isEmpty ? 'Nama tidak boleh kosong.' : null,
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextFormField(
                      labelText: 'Kota',
                      controller: _cityController,
                      onSaved: (value) => _city = value!,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextFormField(
                      labelText: 'Negara',
                      controller: _countryController,
                      onSaved: (value) => _country = value!,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextFormField(
                      labelText: 'Kapasitas',
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSaved: (value) => _capacity = int.parse(value!),
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextFormField(
                      labelText: 'Harga Sewa (IDR)',
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onSaved: (value) => _price = double.parse(value!),
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextFormField(
                      labelText: 'URL Gambar',
                      controller: _thumbnailController,
                      onSaved: (value) => _thumbnail = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextFormField(
                      labelText: 'Deskripsi',
                      controller: _descriptionController,
                      maxLines: 4,
                      onSaved: (value) => _description = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    _buildModernTextFormField(
                      labelText: 'Fasilitas',
                      controller: _facilitiesController,
                      hintText: 'Contoh: WiFi\nKamar Ganti',
                      maxLines: 4,
                      helperText:
                          '💡 Tekan Enter untuk membuat baris baru per fasilitas',
                      onSaved: (value) => _facilities = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    _buildModernTextFormField(
                      labelText: 'Aturan Venue',
                      controller: _rulesController,
                      hintText:
                          'Contoh: Gunakan sepatu olahraga\nDilarang merokok',
                      maxLines: 4,
                      helperText:
                          '💡 Tekan Enter untuk membuat baris baru per aturan',
                      onSaved: (value) => _rules = value ?? '',
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _submitEditVenue(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(55),
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
                          : const Icon(Icons.edit_note_rounded),
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
