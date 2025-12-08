import 'package:flutter/material.dart';
import 'package:lapangin/models/venue_entry.dart';
import 'package:lapangin/screens/venue/edit_venue_form.dart';
import 'package:lapangin/screens/booking/create_booking_page.dart';
import 'package:lapangin/widgets/venue/venue_list_card.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:lapangin/screens/venue/venue_detail.dart';
import 'package:lapangin/screens/venue/create_venue_form.dart';

Future<List<VenueEntry>> fetchAllVenues(CookieRequest request) async {
  final response = await request.get('http://localhost:8000/venues/api/venues');

  if (response is Map<String, dynamic>) {
    // Cek apakah ada error
    if (response.containsKey('success') && response['success'] == false) {
      throw Exception('API Error: ${response['message']}');
    }

    // Ambil list venues
    final venueListJson = response['venues'];
    if (venueListJson is List) {
      List<VenueEntry> venues = [];
      for (var data in venueListJson) {
        if (data is Map<String, dynamic>) {
          venues.add(VenueEntry.fromJson(data));
        }
      }
      return venues;
    } else {
      throw Exception('Failed to load venues: "venues" key not found');
    }
  } else if (response is List) {
    List<VenueEntry> venues = [];
    for (var data in response) {
      if (data is Map<String, dynamic>) {
        venues.add(VenueEntry.fromJson(data));
      }
    }
    return venues;
  } else {
    throw Exception('Failed to load venues: Unexpected response format');
  }
}

class VenuesPage extends StatefulWidget {
  final String? initialQuery;
  const VenuesPage({super.key, this.initialQuery});

  @override
  State<VenuesPage> createState() => _VenuesPageState();
}

class _VenuesPageState extends State<VenuesPage> {
  String selectedLocation = 'Semua Lokasi';
  String searchQuery = '';
  String sortBy = 'Harga Terendah';

  late TextEditingController _searchController;

  final List<String> locations = [
    'Semua Lokasi',
    'Kota Jakarta Pusat',
    'Kota Jakarta Utara',
    'Kota Jakarta Selatan',
    'Kota Jakarta Barat',
    'Kota Jakarta Timur',
  ];

  final List<String> sortOptions = [
    'Harga Terendah',
    'Harga Tertinggi',
    'Rating Terendah',
    'Rating Tertinggi',
    'Kapasitas Terendah',
    'Kapasitas Tertinggi',
  ];

  bool _canCreateVenue = false;

  final GlobalKey<State<FutureBuilder<List<VenueEntry>>>> _futureBuilderKey =
      GlobalKey();

  void _refreshVenueList() {
    setState(() {
      _futureBuilderKey.currentState?.setState(() {});
    });
  }

  void _navigateToCreateVenue() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateVenuePage()),
    ).then((result) {
      if (result == true) {
        // Jika navigasi berhasil (venue dibuat/diedit)
        _refreshVenueList();
      }
    });
  }

  void _navigateToEditVenue(VenueEntry venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditVenuePage(venueId: venue.id, initialVenue: venue),
      ),
    ).then((result) {
      if (result == true) {
        _refreshVenueList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue berhasil diperbarui!')),
        );
      }
    });
  }

  void _removeVenue(VenueEntry venue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Anda yakin ingin menghapus venue "${venue.name}"? Aksi ini tidak dapat dibatalkan.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();

                _deleteVenueApi(venue);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVenueApi(VenueEntry venue) async {
    final request = context.read<CookieRequest>();
    final url = 'http://localhost:8000/venues/api/delete/${venue.id}/';

    try {
      final response = await request.post(url, {});

      if (response is Map<String, dynamic> && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Venue berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshVenueList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal menghapus venue.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error koneksi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kesalahan koneksi saat menghapus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchPermissionStatus();

    searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: searchQuery);
  }

  @override
  void didUpdateWidget(covariant VenuesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cek apakah query dari parent berubah
    if (widget.initialQuery != oldWidget.initialQuery) {
      setState(() {
        searchQuery = widget.initialQuery ?? '';
        _searchController.text = searchQuery;

        // Opsional: Pindahkan kursor ke akhir teks agar user bisa langsung lanjut ketik
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      });
    }
  }

  Future<void> _fetchPermissionStatus() async {
    final request = context.read<CookieRequest>();
    const url = 'http://localhost:8000/venues/api/permission/create/';

    try {
      final response = await request.get(url);

      if (response is Map<String, dynamic> &&
          response.containsKey('can_create_venue')) {
        if (mounted) {
          setState(() {
            _canCreateVenue = response['can_create_venue'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error fetching permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOCATION SELECTOR
            const Text(
              'Lokasi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const ImageIcon(
                    AssetImage("assets/images/icon/location_icon.png"),
                    size: 24.0,
                    color: const Color(0xFF0062FF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLocation,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        items: locations.map((String location) {
                          return DropdownMenuItem<String>(
                            value: location,
                            child: Text(location),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedLocation = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // search bar aseli
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari Stadion',
                        hintStyle: TextStyle(color: Color(0xFFA1A1A1)),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Color(0xFFA1A1A1)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SORT BY & CREATE VENUE BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ImageIcon(
                        AssetImage("assets/images/icon/venue_sort_icon.png"),
                        size: 24.0,
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: sortBy,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: const Color(0xFF737373),
                          ),
                          items: sortOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                sortBy = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. CREATE VENUE BUTTON
                if (_canCreateVenue)
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateVenue,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'Tambah Venue',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // VENUE LIST
            FutureBuilder<List<VenueEntry>>(
              future: fetchAllVenues(request),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Tidak ada venue tersedia.'),
                    ),
                  );
                } else {
                  List<VenueEntry> venues = snapshot.data!;

                  // Filter by location (skip jika "Semua Lokasi")
                  if (selectedLocation != 'Semua Lokasi') {
                    venues = venues.where((venue) {
                      return venue.city.toLowerCase().contains(
                        selectedLocation.toLowerCase().replaceAll('kota ', ''),
                      );
                    }).toList();
                  }

                  // Filter by search query
                  if (searchQuery.isNotEmpty) {
                    venues = venues.where((venue) {
                      return venue.name.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      );
                    }).toList();
                  }

                  // Sort venues
                  if (sortBy == 'Harga Terendah') {
                    venues.sort((a, b) => a.price.compareTo(b.price));
                  } else if (sortBy == 'Harga Tertinggi') {
                    venues.sort((a, b) => b.price.compareTo(a.price));
                  } else if (sortBy == 'Rating Tertinggi') {
                    venues.sort((a, b) => b.rating.compareTo(a.rating));
                  } else if (sortBy == 'Rating Terendah') {
                    venues.sort((a, b) => a.rating.compareTo(b.rating));
                  } else if (sortBy == 'Kapasitas Terendah') {
                    venues.sort((a, b) => a.capacity.compareTo(b.capacity));
                  } else if (sortBy == 'Kapasitas Tertinggi') {
                    venues.sort((a, b) => b.capacity.compareTo(b.capacity));
                  }

                  if (venues.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Tidak ada venue yang sesuai dengan filter.',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: venues.length,
                    itemBuilder: (context, index) {
                      final venue = venues[index];
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VenueDetailPage(venueId: venue.id),
                                ),
                              );
                            },
                            child: VenueListCard(
                              venue: venue,
                              canManage: _canCreateVenue,
                              onEdit: () => _navigateToEditVenue(venue),
                              onRemove: () => _removeVenue(venue),
                            ),
                          ),
                          // Adding the "Sewa" button below the card
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CreateBookingPage(venueId: venue.id)),
                                );
                              },
                              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                              child: const Text('Sewa Sekarang', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
