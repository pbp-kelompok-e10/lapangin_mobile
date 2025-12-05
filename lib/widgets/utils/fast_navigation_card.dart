import 'package:flutter/material.dart';

class FastNavigationCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  // 1. Tambahkan parameter imageUrl
  final String imageUrl;

  const FastNavigationCard({
    Key? key,
    required this.title,
    required this.icon,
    this.iconBackgroundColor = const Color(0xFF003C9C),
    this.onTap,
    // 2. Wajibkan parameter ini (atau buat opsional dengan default value)
    required this.imageUrl,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: grayAreaHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: AssetImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
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
