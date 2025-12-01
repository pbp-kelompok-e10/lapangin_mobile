import 'package:flutter/material.dart';
import 'package:lapangin/helper/price_formatter.dart';
import 'package:lapangin/screens/auth/login.dart';
//import 'package:lapangin/screens/booking/booking_history_list.dart';
import 'package:lapangin/screens/venue/venue_list.dart';
import 'package:lapangin/widgets/utils/search_bar.dart';
import 'package:lapangin/models/venue_entry.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

Future<List<VenueEntry>> fetchRecommendedVenues(CookieRequest request) async {
  final response = await request.get(
    'http://localhost:8000/venues/api/recommended',
  );

  // 1. Cek apakah responsnya adalah Map (sesuai dengan output Django)
  if (response is Map<String, dynamic>) {
    // 1a. Cek apakah respons berisi error (untuk API side errors)
    if (response.containsKey('success') && response['success'] == false) {
      throw Exception('API Error: ${response['message']}');
    }

    // 1b. Ekstrak list venue dari kunci 'venues'
    final venueListJson = response['venues'];

    if (venueListJson is List) {
      List<VenueEntry> recommendedVenues = [];

      for (var data in venueListJson) {
        if (data is Map<String, dynamic>) {
          // PENTING: Anda mungkin perlu menyesuaikan kunci JSON di fromJson jika Django menggunakan 'stadium'
          // sementara model Dart Anda menggunakan 'name'. Lihat bagian *Catatan Khusus* di bawah.
          recommendedVenues.add(VenueEntry.fromJson(data));
        }
      }
      return recommendedVenues;
    } else {
      // Jika Map ada, tetapi kunci 'venues' hilang atau bukan List
      throw Exception(
        'Failed to load recommended venues: "venues" key not found or is not a list.',
      );
    }
  }
  // 2. Jika respons bukan Map sama sekali (misal: String/Integer tak terduga)
  else {
    throw Exception(
      'Failed to load recommended venues: Received unexpected top-level response format.',
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(), // Index 0: Beranda
    VenuesPage(), // Index 1: Explore
    //BookingHistoryListPage(), // Index 2: History (Asumsi DashboardPage/FAQ diubah menjadi History)
    SignOutPlaceholder(), // Index 3: Profil
  ];

  void _onItemTapped(int index) async {
    if (index == 3) {
      await _handleSignOut(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.logout(
        "http://localhost:8000/auth/logout/",
      );
      String message = response["message"];

      if (!context.mounted) return;

      if (response['status']) {
        String uname = response["username"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$message Sampai jumpa, $uname.")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Sign Out: ${e.toString()}")),
      );
    }
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 80.0,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, "Beranda", "assets/images/icon/home_icon.png"),
          _buildNavItem(1, "Explore", "assets/images/icon/explore_icon.png"),
          _buildNavItem(2, "History", "assets/images/icon/faq_icon.png"),
          _buildNavItem(3, "Profil", "assets/images/icon/profile_icon.png"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String assetPath) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.black;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        height: 80.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IKON
            ImageIcon(AssetImage(assetPath), color: color, size: 41.0),

            const SizedBox(height: 2.0),

            // LABEL
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: "Poppins",
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double searchBarHeight = 85.0;

    return Scaffold(
      backgroundColor: Colors.white,

      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            floating: false,
            pinned: false,
            toolbarHeight: 0.0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(searchBarHeight),
              child: const CustomSearchBarAppBar(),
            ),
          ),

          SliverToBoxAdapter(child: _widgetOptions.elementAt(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KARTU KATEGORI (Sewa Venue, FAQ, Review)
          IntrinsicHeight(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: VenueServiceCardWithOverlap(
                    icon: ImageIcon(
                      AssetImage("assets/images/icon/ball_icon.png"),
                      color: Colors.white,
                      size: 41.0,
                    ),
                    title: 'Sewa Venue',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: VenueServiceCardWithOverlap(
                    icon: ImageIcon(
                      AssetImage("assets/images/icon/faq_home_icon.png"),
                      color: Colors.white,
                      size: 41.0,
                    ),
                    title: 'Frequently Asked Questions',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: VenueServiceCardWithOverlap(
                    icon: ImageIcon(
                      AssetImage("assets/images/icon/review_home_icon.png"),
                      color: Colors.white,
                      size: 41.0,
                    ),
                    title: 'Leave a Review',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // 2. JUDUL REKOMENDASI
          const Text(
            'Rekomendasi Venue',
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16.0),

          // 3. LIST REKOMENDASI
          FutureBuilder<List<VenueEntry>>(
            future: fetchRecommendedVenues(request),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Tidak ada venue yang direkomendasikan.'),
                );
              } else {
                final venues = snapshot.data!;

                return Row(
                  children: [
                    // Kartu 1
                    Expanded(
                      child: VenueCard(
                        location: venues[0].city,
                        name: venues[0].name,
                        rating: venues[0].rating,
                        price: venues[0].price,
                        imageUrl: venues[0].thumbnail,
                      ),
                    ),
                    const SizedBox(width: 16.0),

                    if (venues.length > 1)
                      Expanded(
                        child: VenueCard(
                          location: venues[1].city,
                          name: venues[1].name,
                          rating: venues[1].rating,
                          price: venues[1].price,
                          imageUrl: venues[1].thumbnail,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox.shrink()),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24.0),

          // 4. PROMOSI BANNER 1
          const PromotionBanner(
            title: 'Temukan & Booking dalam Sekejap',
            imageUrl: 'assets/images/cta_1.png',
            isPrimary: true,
          ),
          const SizedBox(height: 16.0),

          // 5. PROMOSI BANNER 2
          const PromotionBanner(
            title: 'Jangkau Lebih Banyak Pengguna',
            imageUrl: 'assets/images/cta_2.png',
            isPrimary: false,
          ),
          const SizedBox(height: 30.0),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const CategoryCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8.0),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VenueCard extends StatelessWidget {
  final String location;
  final String name;
  final double rating;
  final double price;
  final String imageUrl;

  const VenueCard({
    super.key,
    required this.location,
    required this.name,
    required this.rating,
    required this.price,
    required this.imageUrl,
  });

  Widget _buildVenueImage(String imageUrl) {
    const base64Header = 'data:image';

    if (imageUrl.startsWith(base64Header)) {
      final parts = imageUrl.split(',');
      if (parts.length > 1) {
        try {
          final bytes = base64Decode(parts[1].trim());

          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            height: 120,
            width: double.infinity,
          );
        } catch (e) {
          return const Center(child: Text('Error decoding image'));
        }
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 120,
        width: double.infinity,
        loadingBuilder: (c, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (c, o, s) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        height: 120,
        width: double.infinity,
        errorBuilder: (c, o, s) => const Center(child: Icon(Icons.error)),
      );
    }

    // Placeholder jika string kosong
    return Container(height: 120, color: Colors.grey.shade300);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Container(
                height: 120,
                width: double.infinity,
                child: _buildVenueImage(imageUrl),
              ),
            ),
          ),

          // Detail Teks
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lokasi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.5,
                    ), // Latar belakang gelap transparan
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '📍 $location',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: "Poppins",
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Nama Venue
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),

                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text('$rating', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),

                // Harga
                Text(
                  "Rp" + formatRupiah(price).toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PromotionBanner extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isPrimary;

  const PromotionBanner({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF003C9C);

    return Container(
      height: 170,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isPrimary ? primaryColor : Color(0x80BED7FF),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teks Promosi
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : Color(0xFF003C9C),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Gambar Banner
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                height: double.infinity,
                errorBuilder: (c, o, s) => Container(
                  color: Colors.grey,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignOutPlaceholder extends StatelessWidget {
  const SignOutPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Proses Sign Out...', style: TextStyle(fontSize: 24)),
    );
  }
}

class VenueServiceCardWithOverlap extends StatelessWidget {
  final String title;
  final Widget icon;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  const VenueServiceCardWithOverlap({
    Key? key,
    required this.title,
    required this.icon,
    this.iconBackgroundColor = const Color(0xFF003C9C),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double iconSize = 35.5;
    const double grayAreaHeight = 74.0;
    const double iconOverlapFromBottom = iconSize / 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Card(
          margin: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 3.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Card Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gray area
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: grayAreaHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),

                  // Text area
                  Padding(
                    padding: const EdgeInsets.only(
                      top: iconOverlapFromBottom,
                      left: 8.0,
                      right: 8.0,
                      bottom: 16.0,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: "Poppins",
                      ),
                    ),
                  ),
                ],
              ),

              // Circular Icon
              Positioned(
                left: 8,
                top: 8.0 + grayAreaHeight - iconOverlapFromBottom,
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: icon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
