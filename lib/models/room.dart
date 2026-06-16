class Room {
  final String id;
  final String name;
  final String description;
  final int capacity;

  const Room({
    required this.id,
    required this.name,
    required this.description,
    required this.capacity,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: _stringValue(json['id']),
      name: _stringValue(json['name'], fallback: 'Room'),
      description: _stringValue(json['description']),
      capacity: _intValue(json['capacity']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  final stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? fallback : stringValue;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
