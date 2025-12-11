import 'package:flutter/material.dart';
import 'package:lapangin/screens/auth/login.dart';
import 'package:lapangin/screens/venue/venue_list.dart';
import 'package:lapangin/widgets/utils/fast_navigation_card.dart';
import 'package:lapangin/widgets/utils/promotion_banner.dart';
import 'package:lapangin/widgets/utils/recommended_venue_card.dart';
import 'package:lapangin/widgets/utils/search_bar.dart';
import 'package:lapangin/models/venue_entry.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:lapangin/screens/venue/venue_detail.dart';
import 'package:lapangin/screens/faq/faq_list.dart';

Future<List<VenueEntry>> fetchRecommendedVenues(CookieRequest request) async {
  final response = await request.get(
    'http://localhost:8000/venues/api/recommended',
  );

  if (response is Map<String, dynamic>) {
    if (response.containsKey('success') && response['success'] == false) {
      throw Exception('API Error: ${response['message']}');
    }

    final venueListJson = response['venues'];

    if (venueListJson is List) {
      List<VenueEntry> recommendedVenues = [];

      for (var data in venueListJson) {
        if (data is Map<String, dynamic>) {
          recommendedVenues.add(VenueEntry.fromJson(data));
        }
      }
      return recommendedVenues;
    } else {
      throw Exception(
        'Failed to load recommended venues: "venues" key not found or is not a list.',
      );
    }
  } else {
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

  String _searchQuery = '';

  void _onItemTapped(int index) async {
    if (index == 4) {
      await _handleSignOut(context);
    } else {
      setState(() {
        _selectedIndex = index;
        if (index != 1) _searchQuery = '';
      });
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.logout(
        "http://10.0.2.2:8000/auth/logout/",
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
            ImageIcon(AssetImage(assetPath), color: color, size: 41.0),
            const SizedBox(height: 2.0),
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
    // 2. Tentukan widget body secara manual
    Widget currentBody;

    switch (_selectedIndex) {
      case 0:
        currentBody = CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              floating: false,
              pinned: false,
              toolbarHeight: 0.0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(85.0),
                child: CustomSearchBarAppBar(
                  onSubmitted: (String value) {
                    setState(() {
                      _searchQuery = value;
                      _selectedIndex = 1;
                    });
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: const HomePage()),
          ],
        );
        break;
      case 1:
        currentBody = VenuesPage(initialQuery: _searchQuery);
        break;
      case 2:
        currentBody = const SignOutPlaceholder(); // TODO: History
        break;
      case 3:
        currentBody = const SignOutPlaceholder(); // TODO: Profile
        break;
      default:
        currentBody = const HomePage();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: currentBody,
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<VenueEntry>>? _recommendedVenuesFuture;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _recommendedVenuesFuture = fetchRecommendedVenues(request);
  }

  void _navigateToVenueList() {
    final mainState = context.findAncestorStateOfType<_MyHomePageState>();

    if (mainState != null) {
      mainState._onItemTapped(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BANNER CAROUSEL
          BannerCarousel(),

          const SizedBox(height: 12.0),

          // KARTU KATEGORI (Sewa Venue, FAQ, Review)
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FastNavigationCard(
                    imageUrl: "assets/images/menu1.jpg",
                    icon: ImageIcon(
                      AssetImage("assets/images/icon/ball_icon.png"),
                      color: Colors.white,
                      size: 41.0,
                    ),
                    title: 'Sewa Venue',
                    onTap: _navigateToVenueList,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: FastNavigationCard(
                    imageUrl: "assets/images/menu2.jpg",
                    icon: ImageIcon(
                      AssetImage("assets/images/icon/faq_home_icon.png"),
                      color: Colors.white,
                      size: 41.0,
                    ),
                    title: 'Frequently Asked Questions',
                    onTap: 
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FaqListPage(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: FastNavigationCard(
                    imageUrl: "assets/images/menu3.jpg",
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

          // JUDUL REKOMENDASI
          const Text(
            'Rekomendasi Venue',
            style: TextStyle(
              fontFamily: "Poppins",
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16.0),

          // LIST REKOMENDASI
          FutureBuilder<List<VenueEntry>>(
            future: _recommendedVenuesFuture,
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VenueDetailPage(venueId: venues[0].id),
                            ),
                          );
                        },
                        child: VenueCard(
                          location: venues[0].city,
                          name: venues[0].name,
                          rating: venues[0].rating,
                          price: venues[0].price,
                          imageUrl: venues[0].thumbnail,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    if (venues.length > 1)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VenueDetailPage(venueId: venues[1].id),
                              ),
                            );
                          },
                          child: VenueCard(
                            location: venues[1].city,
                            name: venues[1].name,
                            rating: venues[1].rating,
                            price: venues[1].price,
                            imageUrl: venues[1].thumbnail,
                          ),
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

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentBannerPage = 0;
  Timer? _autoScrollTimer;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Temukan & Booking dalam Sekejap',
      'imageUrl': 'assets/images/cta_1.png',
      'isPrimary': true,
    },
    {
      'title': 'Jangkau Lebih Banyak Pengguna',
      'imageUrl': 'assets/images/cta_2.png',
      'isPrimary': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentBannerPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentBannerPage = page;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: PromotionBanner(
                  title: banner['title'],
                  imageUrl: banner['imageUrl'],
                  isPrimary: banner['isPrimary'],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12.0),
        // DOT INDICATOR
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: _currentBannerPage == index
                    ? const Color(0xFF003C9C)
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
