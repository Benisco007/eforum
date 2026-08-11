class Coach {
  final String       name;
  final String?      photoURL;
  final List<String> bonuses;

  const Coach({required this.name, this.photoURL, this.bonuses = const []});

  factory Coach.fromMap(Map<String, dynamic> m) => Coach(
    name:     m['name']     ?? '',
    photoURL: m['photoURL'],
    bonuses:  List<String>.from(m['bonuses'] ?? []),
  );

  Map<String, dynamic> toMap() =>
      {'name': name, 'photoURL': photoURL, 'bonuses': bonuses};
}
