import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lapangin/config/api_config.dart';
import 'package:lapangin/screens/booking/create_booking_page.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:lapangin/helper/price_formatter.dart';
import 'package:lapangin/models/venue_entry.dart';
import 'package:lapangin/models/review.dart';
import 'package:lapangin/widgets/review/review_card.dart';

Future<VenueEntry> fetchVenueDetail(
  CookieRequest request,
  String venueId,
) async {
  final response = await request.get(ApiConfig.venueDetailUrl(venueId));

  if (response is Map<String, dynamic> &&
      response.containsKey('success') &&
      response['success'] == true) {
    if (response['venue'] is Map<String, dynamic>) {
      return VenueEntry.fromJson(response['venue']);
    } else {
      throw Exception('Format data venue tidak valid.');
    }
  } else if (response is Map<String, dynamic> &&
      response.containsKey('message')) {
    throw Exception('Gagal memuat detail venue: ${response['message']}');
  } else {
    throw Exception(
      'Gagal memuat detail venue: Kesalahan respons tak terduga.',
    );
  }
}

class VenueDetailPage extends StatefulWidget {
  final String venueId;

  const VenueDetailPage({super.key, required this.venueId});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  VenueEntry? _venue;
  bool _isLoading = true;
  String? _error;
  bool _noConnection = false;
  bool _reviewChanged = false;

  void _onReviewChanged() {
    _reviewChanged = true;
  }

  @override
  void initState() {
    super.initState();
    _loadVenueDetail();
  }

  void _loadVenueDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _noConnection = false;
    });

    try {
      final request = context.read<CookieRequest>();
      final venueData = await fetchVenueDetail(request, widget.venueId);
      setState(() {
        _venue = venueData;
        _isLoading = false;
      });
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('handshakeexception') ||
          errorString.contains('connection') ||
          errorString.contains('network') ||
          errorString.contains('failed host lookup')) {
        setState(() {
          _noConnection = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = e.toString().contains('Exception:')
              ? e.toString().split('Exception: ')[1]
              : e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildVenueImage(String imageUrl, BuildContext context) {
    const base64Header = 'data:image';
    Widget imageWidget;
    final double imageHeight = MediaQuery.of(context).size.height * 0.35;

    if (imageUrl.startsWith(base64Header)) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          final bytes = base64Decode(parts[1].trim());
          imageWidget = Image.memory(bytes, fit: BoxFit.cover);
        } else {
          imageWidget = const Center(child: Icon(Icons.broken_image));
        }
      } catch (e) {
        imageWidget = const Center(child: Icon(Icons.broken_image));
      }
    } else if (imageUrl.startsWith('http')) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (c, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (c, o, s) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    } else {
      imageWidget = Image.asset(
        imageUrl.isNotEmpty ? imageUrl : 'assets/images/placeholder.png',
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) => const Center(child: Icon(Icons.error)),
      );
    }

    return Container(
      height: imageHeight,
      width: double.infinity,
      color: Colors.grey.shade300,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_noConnection || _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Venue')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _noConnection ? Icons.wifi_off : Icons.error,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(_noConnection ? "Tidak ada koneksi" : "Error: $_error"),
              ElevatedButton(
                onPressed: _loadVenueDetail,
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    final venue = _venue!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_reviewChanged);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(_reviewChanged),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVenueImage(venue.thumbnail, context),
                    VenueDetailBody(
                      venue: venue,
                      onReviewChanged: _onReviewChanged,
                    ),
                  ],
                ),
              ),
            ),
            VenueDetailFooter(venue: venue),
          ],
        ),
      ),
    );
  }
}

class VenueDetailBody extends StatelessWidget {
  final VenueEntry venue;
  final VoidCallback? onReviewChanged;

  const VenueDetailBody({super.key, required this.venue, this.onReviewChanged});

  // Fungsi Helper untuk mengubah string newline menjadi List Widget Bullet
  List<Widget> _buildBulletList(String text) {
    if (text.isEmpty) {
      return [
        const Text(
          "Data tidak tersedia",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ];
    }
    // Pisahkan string berdasarkan baris baru dan hapus baris kosong
    List<String> lines = text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return lines.map((line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "• ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0062FF),
              ),
            ),
            Expanded(
              child: Text(
                line.trim(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();
    final rawId = request.jsonData != null
        ? (request.jsonData['id'] ?? request.jsonData['user_id'])
        : null;
    final int currentUserId = rawId != null
        ? int.tryParse(rawId.toString()) ?? 0
        : 0;
    final bool loggedIn = request.loggedIn == true;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${venue.city}, ${venue.country}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    venue.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            venue.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Deskripsi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            venue.description.isEmpty
                ? "Deskripsi tidak tersedia."
                : venue.description,
            style: const TextStyle(color: Colors.black87, height: 1.5),
          ),
          const SizedBox(height: 24),

          // LIST FASILITAS
          _buildExpansionCard(
            title: 'Fasilitas Venue',
            icon: Icons.layers_outlined,
            content: _buildBulletList(venue.facilities),
          ),
          const SizedBox(height: 16),

          // ATURAN VENUE
          _buildExpansionCard(
            title: 'Aturan Venue',
            icon: Icons.rule_outlined,
            content: _buildBulletList(venue.rules),
            isWarning: true,
          ),
          const SizedBox(height: 24),

          // Bagian Ulasan (Review)
          ReviewSection(
            venueId: venue.id!,
            currentUserId: currentUserId,
            onReviewChanged: onReviewChanged,
          ),
          const SizedBox(height: 24),

          const SizedBox(
            height: 100,
          ), // Ruang agar konten tidak tertutup footer
        ],
      ),
    );
  }

  Widget _buildExpansionCard({
    required String title,
    required IconData icon,
    required List<Widget> content,
    bool isWarning = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(), // Hilangkan border default expansion tile
        leading: Icon(
          icon,
          color: isWarning ? Colors.orange : const Color(0xFF0062FF),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: content),
          ),
        ],
      ),
    );
  }
}

class VenueDetailFooter extends StatelessWidget {
  final VenueEntry venue;
  const VenueDetailFooter({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rp${formatRupiah(venue.price)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'per hari',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => CreateBookingPage(venueId: venue.id),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0062FF),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Sewa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewSection extends StatefulWidget {
  final String venueId;
  final int currentUserId;
  final VoidCallback? onReviewChanged;

  const ReviewSection({
    super.key,
    required this.venueId,
    required this.currentUserId,
    this.onReviewChanged,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  bool isLoading = true;
  List<Map<String, dynamic>> reviews = [];
  int currentUserId = 0;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final request = context.read<CookieRequest>();

    final response = await request.get(ApiConfig.reviewsUrl(widget.venueId));

    setState(() {
      reviews = List<Map<String, dynamic>>.from(response['reviews']);
      currentUserId = response['current_user_id'] ?? 0;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final request = context.read<CookieRequest>();
    final isAdmin =
        request.jsonData?['is_admin'] == true ||
        request.jsonData?['is_superuser'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Ulasan",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              onPressed: () => showReviewModal(
                context,
                venueId: widget.venueId,
                onSuccess: () {
                  fetchReviews();
                  widget.onReviewChanged?.call();
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0062FF),
              ),
              child: const Text(
                "Berikan Ulasan",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (reviews.isEmpty)
          const Text(
            "Belum ada ulasan.",
            style: TextStyle(fontFamily: 'Poppins'),
          ),

        ...reviews.map((review) {
          final isOwner = review["user_id"] == currentUserId;

          return ReviewCard(
            review: review,
            isOwner: isOwner,
            canDelete: isAdmin,

            onEdit: () {
              selectedRating.value = review["rating"] is int
                  ? review["rating"]
                  : double.tryParse(review["rating"].toString())?.round() ?? 0;

              showEditReviewModal(
                context,
                venueId: widget.venueId,
                initialComment: review["comment"] ?? "",
                onSuccess: () {
                  fetchReviews();
                  widget.onReviewChanged?.call();
                },
              );
            },

            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text(
                    "Hapus Review",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  content: const Text(
                    "Yakin ingin menghapus review ini?",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Batal",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Hapus",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await deleteReview(context: context, venueId: widget.venueId);
                fetchReviews();
                widget.onReviewChanged?.call();
              }
            },
          );
        }),
      ],
    );
  }
}

final selectedRating = ValueNotifier<int>(0);

void showReviewModal(
  BuildContext context, {
  required String venueId,
  required VoidCallback onSuccess,
}) {
  final TextEditingController reviewController = TextEditingController();
  final ValueNotifier<int> selectedRating = ValueNotifier<int>(0);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Berikan Ulasanmu",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // STAR RATING
                  ValueListenableBuilder<int>(
                    valueListenable: selectedRating,
                    builder: (context, value, _) {
                      return Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              index < value ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                            onPressed: () {
                              selectedRating.value = index + 1;
                            },
                          );
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // LABEL
                  const Text(
                    "Tulisan Ulasan",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // TEXTFIELD
                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    onChanged: (_) {
                      setState(() {}); // untuk enable/disable button
                    },
                    decoration: InputDecoration(
                      hintText: "Tulis disini...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF0062FF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BUTTON ACTIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<int>(
                        valueListenable: selectedRating,
                        builder: (context, value, _) {
                          return ElevatedButton(
                            onPressed:
                                value == 0 ||
                                    reviewController.text.trim().isEmpty
                                ? null
                                : () async {
                                    await submitReview(
                                      context: context,
                                      venueId: venueId,
                                      rating: value,
                                      comment: reviewController.text.trim(),
                                    );
                                    Navigator.pop(context);
                                    onSuccess();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0062FF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              "Kirim Review",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> submitReview({
  required BuildContext context,
  required String venueId,
  required int rating,
  required String comment,
}) async {
  final request = context.read<CookieRequest>();

  final response = await request.post(ApiConfig.addReviewUrl, {
    'venue_id': venueId,
    'rating': rating.toString(),
    'comment': comment,
  });

  if (response['success'] != true) {
    throw Exception(response['message'] ?? 'Gagal mengirim review');
  }
}

Future<void> deleteReview({
  required BuildContext context,
  required String venueId,
}) async {
  final request = context.read<CookieRequest>();

  final response = await request.post(ApiConfig.deleteReviewUrl, {
    'venue_id': venueId,
  });

  if (response['success'] != true) {
    throw Exception(response['message'] ?? 'Gagal menghapus review');
  }
}

Future<void> editReview({
  required BuildContext context,
  required String venueId,
  required int rating,
  required String comment,
}) async {
  final request = context.read<CookieRequest>();

  final response = await request.post(ApiConfig.editReviewUrl, {
    'venue_id': venueId,
    'rating': rating.toString(),
    'comment': comment,
  });

  if (response['success'] != true) {
    throw Exception(response['message'] ?? 'Gagal edit review');
  }
}

void showEditReviewModal(
  BuildContext context, {
  required String venueId,
  required String initialComment,
  required VoidCallback onSuccess,
}) {
  final TextEditingController controller = TextEditingController(
    text: initialComment,
  );
  final ValueNotifier<int> selectedRating = ValueNotifier<int>(0);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Edit Ulasan",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // STAR RATING
                  ValueListenableBuilder<int>(
                    valueListenable: selectedRating,
                    builder: (context, value, _) {
                      return Row(
                        children: List.generate(5, (i) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              i < value ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                            onPressed: () {
                              selectedRating.value = i + 1;
                            },
                          );
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // TEXTFIELD
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    onChanged: (_) {
                      setState(() {}); // untuk enable/disable button
                    },
                    decoration: InputDecoration(
                      hintText: "Tulis disini...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF0062FF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<int>(
                        valueListenable: selectedRating,
                        builder: (context, value, _) {
                          return ElevatedButton(
                            onPressed:
                                value == 0 || controller.text.trim().isEmpty
                                ? null
                                : () async {
                                    await editReview(
                                      context: context,
                                      venueId: venueId,
                                      rating: value,
                                      comment: controller.text.trim(),
                                    );
                                    Navigator.pop(context);
                                    onSuccess();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0062FF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              "Simpan",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
