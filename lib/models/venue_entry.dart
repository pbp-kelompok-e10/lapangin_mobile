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
  final String facilities;
  final String rules;

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
    required this.facilities,
    required this.rules,
  });

  // ----------------------------------------------------
  // FACTORY METHOD FOR JSON DESERIALIZATION (from JSON to Dart object)
  // ----------------------------------------------------

  factory VenueEntry.fromJson(Map<String, dynamic> json) {
    return VenueEntry(
      id: json['id'],
      name: json['stadium'],
      city: json['city'],
      homeTeams: json['home_teams'] ?? '',
      capacity: json['capacity'] ?? 0,
      country: json['country'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      thumbnail: json['thumbnail'] ?? 'assets/images/venue_example.png',
      description: json['description'] ?? '',
      ownerId: json['owner'],
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      facilities: json['facilities'] ?? '',
      rules: json['rules'] ?? '',
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
