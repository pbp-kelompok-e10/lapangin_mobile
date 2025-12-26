import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import 'review_add_page.dart';
import 'review_edit_page.dart';
import 'package:lapangin/services/review_service.dart';
import 'package:lapangin/models/review/review.dart';
import 'package:lapangin/widgets/review/review_card.dart';

class ReviewListPage extends StatefulWidget {
  final String venueId;

  const ReviewListPage({
    super.key,
    required this.venueId,
  });

  @override
  State<ReviewListPage> createState() => _ReviewListPageState();
}

class _ReviewListPageState extends State<ReviewListPage> {
  late Future<List<Review>> futureReviews;

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    futureReviews = ReviewService.getVenueReviews(request, widget.venueId);
  }

  void refreshReviews() {
    final request = context.read<CookieRequest>();
    setState(() {
      futureReviews = ReviewService.getVenueReviews(request, widget.venueId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text("Reviews")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewAddPage(venueId: widget.venueId),
            ),
          );
          refreshReviews();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: futureReviews,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data!;

          if (reviews.isEmpty) {
            return const Center(child: Text("Belum ada review."));
          }

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final isOwner = request.jsonData['user_id'] == review.userId;

              return ReviewCard(
                review: review,
                isOwner: isOwner,
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewEditPage(review: review),
                    ),
                  );
                  refreshReviews();
                },
                onDelete: () async {
                  await ReviewService.deleteReview(request, review.id);
                  refreshReviews();
                },
              );
            },
          );
        },
      ),
    );
  }
}
