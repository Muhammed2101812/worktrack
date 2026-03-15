import 'package:uuid/uuid.dart';

class Client {
  final String id;
  final String name;
  final String color;

  Client({String? id, required this.name, required this.color})
      : id = id ?? const Uuid().v4();

  Client copyWith({String? name, String? color}) =>
      Client(id: id, name: name ?? this.name, color: color ?? this.color);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color};

  factory Client.fromMap(Map<String, dynamic> m) =>
      Client(id: m['id'], name: m['name'], color: m['color']);
}