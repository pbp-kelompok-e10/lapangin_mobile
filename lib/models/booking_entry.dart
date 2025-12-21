class BookingEntry {
  final int id;
  final String venueId;
  final String venueName;
  final String venueCity;
  final String venueThumbnail;
  final double venuePrice;
  final DateTime bookingDate;
  final DateTime createdAt;
  final bool canModify;
  final String status;
  final String statusDisplay;

  const BookingEntry({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.venueCity,
    required this.venueThumbnail,
    required this.venuePrice,
    required this.bookingDate,
    required this.createdAt,
    required this.canModify,
    required this.status,
    required this.statusDisplay,
  });

  // ----------------------------------------------------
  // FACTORY METHOD FOR JSON DESERIALIZATION
  // From flutter_get_user_bookings API response
  // ----------------------------------------------------

  factory BookingEntry.fromJson(Map<String, dynamic> json) {
    return BookingEntry(
      id: json['booking_id'],
      venueId: json['venue_id'] ?? '',
      venueName: json['venue_name'] ?? '',
      venueCity: json['venue_city'] ?? '',
      venueThumbnail: json['venue_thumbnail'] ?? '',
      venuePrice: double.tryParse(json['venue_price'].toString()) ?? 0.0,
      bookingDate: DateTime.parse(json['booking_date']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      canModify: json['can_modify'] ?? false,
      status: json['status'] ?? 'upcoming',
      statusDisplay: json['status_display'] ?? 'Akan Datang',
    );
  }

  // ----------------------------------------------------
  // FACTORY METHOD FOR CREATE BOOKING RESPONSE
  // From flutter_create_booking API response
  // ----------------------------------------------------

  factory BookingEntry.fromCreateResponse(Map<String, dynamic> json) {
    return BookingEntry(
      id: json['booking_id'],
      venueId: json['venue_id'] ?? '',
      venueName: json['venue_name'] ?? '',
      venueCity: '',
      venueThumbnail: json['venue_thumbnail'] ?? '',
      venuePrice: 0.0,
      bookingDate: DateTime.parse(json['booking_date']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      canModify: true,
      status: 'upcoming',
      statusDisplay: 'Akan Datang',
    );
  }

  // ----------------------------------------------------
  // CONVENIENCE METHOD (to JSON for API POST)
  // ----------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'booking_id': id,
      'venue_id': venueId,
      'venue_name': venueName,
      'venue_city': venueCity,
      'venue_thumbnail': venueThumbnail,
      'venue_price': venuePrice,
      'booking_date': bookingDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'can_modify': canModify,
      'status': status,
      'status_display': statusDisplay,
    };
  }

  // ----------------------------------------------------
  // STATUS HELPERS
  // ----------------------------------------------------

  bool get isCompleted => status == 'completed';
  bool get isToday => status == 'today';
  bool get isUpcoming => status == 'upcoming';

  // ----------------------------------------------------
  // FORMATTED DATE HELPERS
  // ----------------------------------------------------

  String get formattedBookingDate {
    return '${bookingDate.day.toString().padLeft(2, '0')}/'
        '${bookingDate.month.toString().padLeft(2, '0')}/'
        '${bookingDate.year}';
  }

  String get formattedCreatedAt {
    return '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }

  // Format: "Senin, 21 Desember 2025"
  String get formattedBookingDateLong {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = days[bookingDate.weekday - 1];
    final monthName = months[bookingDate.month - 1];

    return '$dayName, ${bookingDate.day} $monthName ${bookingDate.year}';
  }
}
