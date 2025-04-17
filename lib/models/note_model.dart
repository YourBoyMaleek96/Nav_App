class Note {
  final int? id;
  final String text;
  final List<String> imagePaths;
  final DateTime dateTime;
  final double? latitude;
  final double? longitude;

  Note({this.id, required this.text, required this.imagePaths, required this.dateTime, this.latitude, this.longitude});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imagePaths': imagePaths.join(','),
      'dateTime': dateTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    final pathsString = map['imagePaths'] as String;
    final List<String> paths =
    pathsString.isNotEmpty ? pathsString.split(',') : <String>[];

    return Note(
      id: map['id'] as int?,
      text: map['text'] as String,
      imagePaths: paths,
      dateTime: DateTime.parse(map['dateTime'] as String),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }
}