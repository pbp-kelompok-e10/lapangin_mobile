import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:lapangin/models/faq/faq_entry.dart';

class FaqFormPage extends StatefulWidget {
  final FaqEntry? faq; // Kalau edit, akan ada data FAQ. Kalau add, null.

  const FaqFormPage({super.key, this.faq});

  @override
  State<FaqFormPage> createState() => _FaqFormPageState();
}

class _FaqFormPageState extends State<FaqFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _question = "";
  String _answer = "";
  String _category = "umum";

  final List<Map<String, String>> categories = [
    {'code': 'umum', 'name': 'Umum'},
    {'code': 'booking', 'name': 'Booking'},
    {'code': 'pembayaran', 'name': 'Pembayaran'},
    {'code': 'venue', 'name': 'Venue'},
  ];

  @override
  void initState() {
    super.initState();
    // Kalau edit, isi form dengan data yang ada
    if (widget.faq != null) {
      _question = widget.faq!.fields.question;
      _answer = widget.faq!.fields.answer;
      _category = widget.faq!.fields.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isEdit = widget.faq != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit FAQ' : 'Tambah FAQ Baru',
          style: const TextStyle(
            color: Color(0xFF003C9C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF003C9C)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Text
              Text(
                isEdit
                    ? 'Perbarui informasi FAQ yang sudah ada'
                    : 'Tambahkan pertanyaan yang sering ditanyakan',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Question Field
              const Text(
                'Pertanyaan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _question,
                decoration: InputDecoration(
                  hintText: 'Masukkan pertanyaan FAQ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF003C9C),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _question = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Pertanyaan tidak boleh kosong!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Answer Field
              const Text(
                'Jawaban',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _answer,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Masukkan jawaban lengkap',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF003C9C),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _answer = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Jawaban tidak boleh kosong!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              const Text(
                'Gunakan enter untuk membuat paragraf baru',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Category Field
              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF003C9C),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['code'],
                    child: Text(category['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Batal',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String url = isEdit
                              ? 'https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id/faq/update-flutter/${widget.faq!.pk}/'
                              : 'https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id/faq/create-flutter/';

                          final response = await request.postJson(
                            url,
                            jsonEncode({
                              "question": _question,
                              "answer": _answer,
                              "category": _category,
                            }),
                          );

                          if (context.mounted) {
                            if (response['status'] == 'success') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? "FAQ berhasil diupdate!"
                                        : "FAQ berhasil disimpan!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Terjadi kesalahan, silakan coba lagi.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003C9C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEdit ? 'Update FAQ' : 'Simpan FAQ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Tips Box
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Buat pertanyaan yang jelas dan mudah dipahami\n'
                            '• Berikan jawaban yang lengkap dan informatif\n'
                            '• Pilih kategori yang sesuai untuk memudahkan pencarian',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
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
