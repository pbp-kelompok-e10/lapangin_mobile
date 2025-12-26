import 'dart:convert';

class Review {
  final int id;
  final String userName;
  final int userId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userName,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userName: json['user_name'],
      userId: json['user_id'],
      rating: double.parse(json['rating'].toString()),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
