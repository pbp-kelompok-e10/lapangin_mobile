// Widget Kustom untuk Search Bar dan Filter Lokasi
import 'package:flutter/material.dart';

class CustomSearchBarAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final double height;

  // Constructor
  const CustomSearchBarAppBar({
    super.key,
    this.height = 125.0, // Tinggi yang cukup untuk Search Bar dan Lokasi
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(
        top: 40.0,
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),

      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.0),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Venue',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                      contentPadding: EdgeInsets.only(bottom: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.white),
                const SizedBox(width: 4),
                const Text(
                  'All Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
