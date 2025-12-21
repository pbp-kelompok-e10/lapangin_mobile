class Review {
  final int id;
  final String username;
  final double rating;
  final String comment;
  final String createdAt;
  final bool isOwner;

  Review({
    required this.id,
    required this.username,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isOwner,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      username: json['username'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'],
      isOwner: json['is_owner'],
    );
  }
}
