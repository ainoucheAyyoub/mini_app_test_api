import 'dart:convert';

class Events {
  final int? id;
  final String? title;
  final DateTime? date;
  final Type? type;

  Events({this.id, this.title, this.date, this.type});

  factory Events.fromRawJson(String str) => Events.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Events.fromJson(Map<String, dynamic> json) => Events(
    id: json["id"],
    title: json["title"],
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    type: typeValues.map[json["type"]],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "date": date?.toIso8601String(),
    "type": typeValues.reverse[type],
  };
}

enum Type { ERROR, SUCCESS, WARNING }

final typeValues = EnumValues({
  "error": Type.ERROR,
  "success": Type.SUCCESS,
  "warning": Type.WARNING,
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
