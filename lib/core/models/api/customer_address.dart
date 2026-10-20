import 'zone_models.dart';

/// A customer address from `GET /users/me/addresses`.
///
/// `latitude` / `longitude` are what H3 dispatch matches on: the backend
/// drops a booking into the hexagon that contains the address, so an
/// address without coordinates falls straight through to "open to all
/// vendors". They stay nullable because an address saved before the pin
/// existed has no position.
class CustomerAddress {
  const CustomerAddress({
    required this.id,
    this.label = 'HOME',
    this.line1 = '',
    this.line2,
    this.landmark,
    this.city,
    this.zone,
    this.state = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.contactName,
    this.contactPhone,
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String? landmark;
  final City? city;
  final Zone? zone;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String? contactName;
  final String? contactPhone;

  /// True when the address carries a position, so H3 dispatch can
  /// match it against nearby vendors.
  bool get hasLocation => latitude != null && longitude != null;

  /// 'Andheri West, Andheri East' style summary used in lists.
  String get shortLabel {
    final parts = <String?>[
      line1,
      line2 ?? zone?.name,
      city?.name,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    final cityJson = json['city'];
    final zoneJson = json['zone'];
    return CustomerAddress(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      label: (json['label'] ?? 'HOME').toString(),
      line1: (json['line1'] ?? '').toString(),
      line2: json['line2']?.toString(),
      landmark: json['landmark']?.toString(),
      city: cityJson is Map<String, dynamic> ? City.fromJson(cityJson) : null,
      zone: zoneJson is Map<String, dynamic> ? Zone.fromJson(zoneJson) : null,
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isDefault: json['isDefault'] == true,
      contactName: json['contactName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
    );
  }

  /// Body for `POST /users/me/addresses` and
  /// `PATCH /users/me/addresses/{id}`.
  ///
  /// Latitude and longitude are always sent together — the API rejects a
  /// latitude without a longitude.
  Map<String, dynamic> toRequestBody() {
    return <String, dynamic>{
      'label': label,
      if (line1.trim().isNotEmpty) 'line1': line1.trim(),
      if (line2 != null && line2!.trim().isNotEmpty) 'line2': line2!.trim(),
      if (landmark != null && landmark!.trim().isNotEmpty)
        'landmark': landmark!.trim(),
      if (city != null) 'cityId': city!.id,
      if (zone != null) 'zoneId': zone!.id,
      if (state.trim().isNotEmpty) 'state': state.trim(),
      if (pincode.trim().isNotEmpty) 'pincode': pincode.trim(),
      if (hasLocation) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
      if (contactName != null && contactName!.trim().isNotEmpty)
        'contactName': contactName!.trim(),
      if (contactPhone != null && contactPhone!.trim().isNotEmpty)
        'contactPhone': contactPhone!.trim(),
      'isDefault': isDefault,
    };
  }

  CustomerAddress copyWith({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? landmark,
    City? city,
    Zone? zone,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
    String? contactName,
    String? contactPhone,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      zone: zone ?? this.zone,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
