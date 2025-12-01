import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:lapangin/models/faq/faq_entry.dart';
import 'package:lapangin/widgets/faq/faq_card.dart';
// import 'package:lapangin/screens/faq_form.dart'; // nanti kita buat

class FaqListPage extends StatefulWidget {
  const FaqListPage({super.key});

  @override
  State<FaqListPage> createState() => _FaqListPageState();
}

class _FaqListPageState extends State<FaqListPage> {
  String selectedCategory = 'all';
  
  final List<Map<String, String>> categories = [
    {'code': 'all', 'name': 'Semua'},
    {'code': 'umum', 'name': 'Umum'},
    {'code': 'booking', 'name': 'Booking'},
    {'code': 'pembayaran', 'name': 'Pembayaran'},
    {'code': 'venue', 'name': 'Venue'},
  ];

  Future<List<FaqEntry>> fetchFaq(CookieRequest request) async {
    // TODO: Ganti dengan URL aplikasi kamu
    String url = selectedCategory == 'all'
        ? 'http://localhost:8000/faq/json/'
        : 'http://localhost:8000/faq/json/$selectedCategory/';
    
    final response = await request.get(url);
    
    List<FaqEntry> listFaq = [];
    for (var d in response) {
      if (d != null) {
        listFaq.add(FaqEntry.fromJson(d));
      }
    }
    return listFaq;
  }

  Future<void> deleteFaq(CookieRequest request, int faqId) async {
    // TODO: Ganti dengan URL aplikasi kamu
    final response = await request.post(
      'http://localhost:8000/faq/delete-flutter/$faqId/',
      {},
    );
    
    if (response['status'] == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FAQ berhasil dihapus!')),
        );
        setState(() {}); // Refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    // Cek apakah user adalah admin (staff)
    bool isAdmin = request.loggedIn; // Sesuaikan dengan logika admin kamu

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(
            color: Color(0xFF003C9C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF003C9C)),
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  bool isSelected = selectedCategory == category['code'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category['name']!),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedCategory = category['code']!;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF003C9C),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF003C9C),
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF003C9C)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Add FAQ Button (untuk admin)
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate ke form add FAQ
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => const FaqFormPage()),
                    // );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Form FAQ akan dibuat nanti')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Pertanyaan'),
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
          
          const SizedBox(height: 16),
          
          // FAQ List
          Expanded(
            child: FutureBuilder(
              future: fetchFaq(request),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                    padding: const EdgeInsets.all(16.0),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (_, index) {
                      FaqEntry faq = snapshot.data![index];
                      return FaqCard(
                        faq: faq,
                        isAdmin: isAdmin,
                        onEdit: () {
                          // TODO: Navigate ke edit form
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit form akan dibuat nanti')),
                          );
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Hapus'),
                              content: Text(
                                'Apakah Anda yakin ingin menghapus FAQ: "${faq.fields.question}"?',
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
                        },
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