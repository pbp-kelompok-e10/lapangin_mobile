/// API Configuration
/// Change this URL when switching between development and production
class ApiConfig {
  // Development (Android Emulator)
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Production (PWS)
  // static const String baseUrl = 'https://angga-ziaurrohchman-lapangin.pbp.cs.ui.ac.id';

  // Auth endpoints
  static String get loginUrl => '$baseUrl/auth/login/';
  static String get registerUrl => '$baseUrl/auth/register/';
  static String get logoutUrl => '$baseUrl/auth/logout/';

  // Venue endpoints
  static String get venuesUrl => '$baseUrl/venues/api/venues';
  static String get recommendedVenuesUrl => '$baseUrl/venues/api/recommended';
  static String get createVenueUrl => '$baseUrl/venues/api/create/';
  static String get createPermissionUrl =>
      '$baseUrl/venues/api/permission/create/';
  static String venueDetailUrl(String venueId) =>
      '$baseUrl/venues/api/detail/$venueId/';
  static String editVenueUrl(String venueId) =>
      '$baseUrl/venues/api/edit/$venueId';
  static String deleteVenueUrl(String venueId) =>
      '$baseUrl/venues/api/delete/$venueId/';

  // Booking endpoints (Web API)
  static String get myBookingsUrl => '$baseUrl/booking/api/history/';
  static String bookedDatesUrl(String venueId) =>
      '$baseUrl/booking/api/get_booked/$venueId/';
  static String get createBookingUrl => '$baseUrl/booking/api/create/';
  static String editBookingUrl(int bookingId) =>
      '$baseUrl/booking/api/edit/$bookingId/';
  static String deleteBookingUrl(int bookingId) =>
      '$baseUrl/booking/api/delete/$bookingId/';

  // FAQ endpoints
  static String get createFaqUrl => '$baseUrl/faq/create-flutter/';
  static String updateFaqUrl(String faqId) =>
      '$baseUrl/faq/update-flutter/$faqId/';
  static String deleteFaqUrl(String faqId) =>
      '$baseUrl/faq/delete-flutter/$faqId/';
  static String faqListUrl(String venueId) =>
      '$baseUrl/faq/list-flutter/$venueId/';

  // Profile endpoints
  static String get profileUrl => '$baseUrl/user/api/profile/';
  static String get updateProfileUrl => '$baseUrl/user/api/update-profile/';

  // User Admin endpoints
  static String userListUrl({String? search, String? status, int page = 1}) {
    String url = '$baseUrl/user/api/list/?page=$page';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    return url;
  }

  static String userDetailUrl(int userId) => '$baseUrl/user/detail/$userId/';
  static String get createUserUrl => '$baseUrl/user/create/';
  static String editUserUrl(int userId) => '$baseUrl/user/edit/$userId/';
  static String toggleUserStatusUrl(int userId) =>
      '$baseUrl/user/toggle-status/$userId/';
  static String deleteUserUrl(int userId) => '$baseUrl/user/delete/$userId/';

  // Review endpoints
  static String reviewsUrl(String venueId) =>
      '$baseUrl/review/reviews/$venueId';
  static String get addReviewUrl => '$baseUrl/review/api/add/';
  static String get deleteReviewUrl => '$baseUrl/review/api/delete/';
  static String get editReviewUrl => '$baseUrl/review/api/edit/';
}
