class EventModel {
  final int? id;
  final String title;
  final DateTime start;
  final DateTime end;

  EventModel({this.id, required this.title, required this.start, required this.end});

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      start: DateTime.parse(map['start'] as String),
      end: DateTime.parse(map['end'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }
}
