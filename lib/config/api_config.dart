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
      '$baseUrl/venues/api/edit/$venueId/';
  static String deleteVenueUrl(String venueId) =>
      '$baseUrl/venues/api/delete/$venueId/';

  // Booking endpoints
  static String get myBookingsUrl => '$baseUrl/booking/flutter/my-bookings/';
  static String bookedDatesUrl(String venueId) =>
      '$baseUrl/booking/flutter/booked-dates/$venueId/';
  static String get createBookingUrl => '$baseUrl/booking/flutter/create/';
  static String editBookingUrl(int bookingId) =>
      '$baseUrl/booking/flutter/edit/$bookingId/';
  static String deleteBookingUrl(int bookingId) =>
      '$baseUrl/booking/flutter/delete/$bookingId/';

  // FAQ endpoints
  static String get createFaqUrl => '$baseUrl/faq/create-flutter/';
  static String updateFaqUrl(String faqId) =>
      '$baseUrl/faq/update-flutter/$faqId/';
  static String deleteFaqUrl(String faqId) =>
      '$baseUrl/faq/delete-flutter/$faqId/';
  static String faqListUrl(String venueId) =>
      '$baseUrl/faq/list-flutter/$venueId/';
}
