import 'package:flutter/material.dart';
import 'package:lapangin/config/api_config.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:lapangin/models/faq/faq_entry.dart';
import 'package:lapangin/widgets/faq/faq_card.dart';
import 'package:lapangin/screens/faq/faq_form.dart';

class FaqListPage extends StatefulWidget {
  const FaqListPage({super.key});

  @override
  State<FaqListPage> createState() => _FaqListPageState();
}

class _FaqListPageState extends State<FaqListPage> {
  String selectedCategory = 'Semua';

  final List<Map<String, String>> categories = [
    {'code': 'all', 'name': 'Semua'},
    {'code': 'umum', 'name': 'Umum'},
    {'code': 'booking', 'name': 'Booking'},
    {'code': 'pembayaran', 'name': 'Pembayaran'},
    {'code': 'venue', 'name': 'Venue'},
  ];

  // Fungsi untuk cek apakah user adalah admin (staff)
  bool isUserAdmin(CookieRequest request) {
    // Cek dari response login atau dari jsonData

    return request.loggedIn && request.jsonData['is_staff'] == true;
  }

  Future<List<FaqEntry>> fetchFaq(CookieRequest request) async {
    final String baseUrl = ApiConfig.baseUrl;

    String categoryCode = categories.firstWhere(
      (cat) => cat['name'] == selectedCategory,
      orElse: () => {'code': 'all'},
    )['code']!;

    String url = categoryCode == 'all'
        ? '$baseUrl/faq/json/'
        : '$baseUrl/faq/json/$categoryCode/';

    final response = await request.get(url);

    List<FaqEntry> listFaq = [];
    for (var d in response) {
      if (d != null) {
        listFaq.add(FaqEntry.fromJson(d));
      }
    }
    return listFaq;
  }

  Future<void> deleteFaq(CookieRequest request, String faqId) async {
    final String baseUrl = ApiConfig.baseUrl;

    final response = await request.post(
      '$baseUrl/faq/delete-flutter/$faqId/',
      {},
    );

    if (response['status'] == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FAQ berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    bool isAdmin = isUserAdmin(request);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'FAQs',
          style: TextStyle(
            color: Color(0xFF003C9C),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF003C9C)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Category Pil
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category['name'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category['name']!;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF003C9C),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF003C9C),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF003C9C)
                          : const Color(0xFFE5E7EB),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Add FAQ Button - HANYA MUNCUL KALAU ADMIN!
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaqFormPage(),
                      ),
                    ).then((_) => setState(() {})); // Refresh after adding
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Tambah Pertanyaan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003C9C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

          if (isAdmin) const SizedBox(height: 16),

          // FAQ List
          Expanded(
            child: FutureBuilder(
              future: fetchFaq(request),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF003C9C)),
                  );
                } else if (!snapshot.hasData || snapshot.data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada FAQ untuk kategori ini',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_, index) {
                      FaqEntry faq = snapshot.data![index];
                      return FaqCard(
                        faq: faq,
                        isAdmin: isAdmin, // Pass status admin ke card
                        onEdit: isAdmin
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FaqFormPage(faq: faq),
                                  ),
                                ).then((_) => setState(() {}));
                              }
                            : null,
                        onDelete: isAdmin
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi Hapus'),
                                    content: Text(
                                      'Apakah Anda yakin ingin menghapus FAQ:\n"${faq.fields.question}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deleteFaq(request, faq.pk);
                                        },
                                        child: const Text(
                                          'Hapus',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
