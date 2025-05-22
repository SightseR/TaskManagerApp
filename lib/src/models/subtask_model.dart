class SubtaskModel {
  final String name;
  final Duration duration;
  final DateTime startDate;

  SubtaskModel({
    required this.name,
    required this.duration,
    required this.startDate,
  });

  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      name: map['name'] as String,
      duration: Duration(milliseconds: map['duration'] as int),
      startDate: DateTime.parse(map['startDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      // store duration in milliseconds
      'duration': duration.inMilliseconds,
      // store startDate as ISO8601 string
      'startDate': startDate.toIso8601String(),
    };
  }
}
