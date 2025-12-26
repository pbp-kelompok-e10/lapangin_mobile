import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isOwner;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    required this.isOwner,
    this.canDelete = false,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final int rating = () {
      final r = review["rating"];
      if (r is int) return r;
      if (r is double) return r.round();
      if (r is String) return double.tryParse(r)?.round() ?? 0;
      return 0;
    }();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Username + Rating
            Row(
              children: [
                const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review["user_name"] ?? "-",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: rating == 5 ? Colors.green : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 18,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Comment
            Text(
              review["comment"] ?? "",
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),

            // Edit/Delete buttons jika owner atau admin
            if (isOwner || canDelete)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isOwner)
                    TextButton(
                      onPressed: onEdit,
                      child: const Text(
                        "Edit",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: onDelete,
                    child: const Text(
                      "Hapus",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
