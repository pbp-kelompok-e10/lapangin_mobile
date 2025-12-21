import 'package:flutter/material.dart';

class FastNavigationCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  final String imageUrl;

  const FastNavigationCard({
    Key? key,
    required this.title,
    required this.icon,
    this.iconBackgroundColor = const Color(0xFF003C9C),
    this.onTap,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 107.0;
    const double iconSize = 32.0;
    const double imageAreaHeight = 70.0;
    const double iconOverlap = iconSize / 2;

    return Padding(
      padding: EdgeInsets.all(0),
      child: SizedBox(
        width: cardWidth,
        child: GestureDetector(
          onTap: onTap,
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Area Gambar
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: imageAreaHeight,
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

                    // Area Teks
                    Padding(
                      padding: EdgeInsets.only(
                        top: iconOverlap,
                        left: 8.0,
                        right: 8.0,
                        bottom: 8.0, // Padding bawah
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.left,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
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
                  top: 8.0 + imageAreaHeight - iconOverlap,
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
                    child: Center(child: icon),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
