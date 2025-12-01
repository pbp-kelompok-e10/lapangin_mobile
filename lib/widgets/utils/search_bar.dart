import 'package:flutter/material.dart';

class CustomSearchBarAppBar extends StatelessWidget {
  const CustomSearchBarAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get system padding (Status Bar Height)

    // 2. We use SafeArea to push content below the status bar.
    // The top padding is applied automatically by SafeArea.
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center, // Center contents vertically
          children: <Widget>[
            // Search Bar Row
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
                    child: const TextField(
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
          ],
        ),
      ),
    );
  }
}
