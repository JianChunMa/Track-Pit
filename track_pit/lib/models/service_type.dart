class ServiceType {
  final int id;
  final String name;

  ServiceType({required this.id, required this.name});

  factory ServiceType.fromMap(Map<String, dynamic> map) {
    return ServiceType(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}
