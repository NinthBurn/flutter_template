
class Albatross {
  int id;
  DateTime date;
  String name;

  Albatross.full({
    required this.id,
    required this.date,
    required this.name,
  });

  Albatross({
    required this.date,
    required this.name,
  }) : id = -1;

  factory Albatross.fromJson(Map<String, dynamic> json) {
    return Albatross.full(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'name': name
    };
  }

  Map<String, dynamic> toJsonWithoutId() {
    return {
      'date': date.toIso8601String(),
      'name': name
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Albatross &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;


  @override
  String toString() {
    return 'Albatross{id: $id, date: $date, name: $name}';
  }
}