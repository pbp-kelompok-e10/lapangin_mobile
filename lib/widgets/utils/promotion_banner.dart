import 'package:flutter/material.dart';

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
