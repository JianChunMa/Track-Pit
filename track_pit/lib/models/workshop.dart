class Workshop {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;

  Workshop({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory Workshop.fromMap(Map<String, dynamic> map) {
    return Workshop(
      id: map['id'] as int,
      name: map['name'] as String,
      address: map['address'] as String,
      lat: map['lat'] as double,
      lng: map['lng'] as double,
    );
  }
}
