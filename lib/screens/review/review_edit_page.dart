import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

import 'package:lapangin/models/review/review.dart';
import 'package:lapangin/services/review_service.dart';

class ReviewEditPage extends StatefulWidget {
  final Review review;

  const ReviewEditPage({
    super.key,
    required this.review,
  });

  @override
  State<ReviewEditPage> createState() => _ReviewEditPageState();
}

class _ReviewEditPageState extends State<ReviewEditPage> {
  late TextEditingController ratingController;
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    ratingController =
        TextEditingController(text: widget.review.rating.toString());
    commentController =
        TextEditingController(text: widget.review.comment);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Review")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: ratingController,
              decoration: const InputDecoration(labelText: "Rating"),
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
                await ReviewService.editReview(
                  request,
                  widget.review.id,
                  ratingController.text,
                  commentController.text,
                );
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}
