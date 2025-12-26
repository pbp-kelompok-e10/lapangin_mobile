import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:lapangin/models/review/review.dart';

class ReviewService {
  static const String baseUrl = "http://localhost:8000";

  static Future<List<Review>> getVenueReviews(
      CookieRequest request, String venueId) async {
    final response = await request.get("$baseUrl/review/reviews/$venueId");
    final List<dynamic> data = response['reviews'];

    return data.map((json) => Review.fromJson(json)).toList();
  }

  static Future<Map<String, dynamic>> addReview(
    CookieRequest request,
    String venueId,
    String rating,
    String comment,
  ) async {
    final response = await request.post(
      "$baseUrl/review/add/",
      {
        "venue_id": venueId,
        "rating": rating,
        "comment": comment,
      },
    );

    return response;
  }

  static Future<Map<String, dynamic>> editReview(
    CookieRequest request,
    int reviewId,
    String rating,
    String comment,
  ) async {
    final response = await request.post(
      "$baseUrl/review/edit/$reviewId",
      {
        "rating": rating,
        "comment": comment,
      },
    );

    return response;
  }

  static Future<Map<String, dynamic>> deleteReview(
    CookieRequest request,
    int reviewId,
  ) async {
    final response = await request.post(
      "$baseUrl/review/delete/$reviewId",
      {},
    );

    return response;
  }
}
