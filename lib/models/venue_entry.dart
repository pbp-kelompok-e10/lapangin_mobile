class VenueEntry {
  final String id;
  final String name;
  final String city;
  final String homeTeams;
  final int capacity;
  final String country;
  final double price;
  final String thumbnail;
  final String description;
  final String? ownerId;
  final double rating;

  const VenueEntry({
    required this.id,
    required this.name,
    required this.city,
    required this.homeTeams,
    required this.capacity,
    required this.country,
    required this.price,
    required this.thumbnail,
    required this.description,
    this.ownerId,
    required this.rating,
  });

  // ----------------------------------------------------
  // FACTORY METHOD FOR JSON DESERIALIZATION (from JSON to Dart object)
  // ----------------------------------------------------

  factory VenueEntry.fromJson(Map<String, dynamic> json) {
    return VenueEntry(
      id: json['id'] as String,
      name: json['stadium'] as String,
      city: json['city'] as String,
      homeTeams: json['home_teams'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      country: json['country'] as String,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      thumbnail:
          json['thumbnail'] as String? ?? 'assets/images/venue_example.png',
      description: json['description'] as String? ?? '',
      ownerId: json['owner'] != null ? json['owner'] as String : null,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
    );
  }

  // ----------------------------------------------------
  // CONVENIENCE METHOD (Optional: to JSON for API POST/PUT)
  // ----------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'home_teams': homeTeams,
      'capacity': capacity,
      'country': country,
      'price': price,
      'thumbnail': thumbnail,
      'description': description,
      // Only include ownerId if it exists
      'owner': ownerId,
      'rating': rating,
    };
  }
}
