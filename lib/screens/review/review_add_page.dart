import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import 'package:lapangin/services/review_service.dart';

class ReviewAddPage extends StatefulWidget {
  final String venueId;

  const ReviewAddPage({
    super.key,
    required this.venueId,
  });

  @override
  State<ReviewAddPage> createState() => _ReviewAddPageState();
}

class _ReviewAddPageState extends State<ReviewAddPage> {
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Review")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: ratingController,
              decoration: const InputDecoration(labelText: "Rating (0 - 5)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: "Komentar"),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await ReviewService.addReview(
                  request,
                  widget.venueId,
                  ratingController.text,
                  commentController.text,
                );
                Navigator.pop(context);
              },
              child: const Text("Kirim"),
            ),
          ],
        ),
      ),
    );
  }
}
