class Booster {
  final String name;
  final int    value;

  const Booster({required this.name, required this.value});

  factory Booster.fromMap(Map<String, dynamic> m) =>
      Booster(name: m['name'] ?? '', value: m['value'] ?? 0);

  Map<String, dynamic> toMap() => {'name': name, 'value': value};
}
