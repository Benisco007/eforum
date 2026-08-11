class PhysicalData {
  final double rayonJambes;
  final double rayonBras;
  final double hauteurSaut;
  final double collisionTorse;
  final double legLengthHeight;

  const PhysicalData({
    this.rayonJambes   = 0, this.rayonBras    = 0,
    this.hauteurSaut   = 0, this.collisionTorse = 0,
    this.legLengthHeight = 0,
  });

  factory PhysicalData.fromMap(Map<String, dynamic> m) => PhysicalData(
    rayonJambes:    (m['rayonJambes']    ?? 0).toDouble(),
    rayonBras:      (m['rayonBras']      ?? 0).toDouble(),
    hauteurSaut:    (m['hauteurSaut']    ?? 0).toDouble(),
    collisionTorse: (m['collisionTorse'] ?? 0).toDouble(),
    legLengthHeight:(m['legLengthHeight']?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'rayonJambes': rayonJambes, 'rayonBras': rayonBras,
    'hauteurSaut': hauteurSaut, 'collisionTorse': collisionTorse,
    'legLengthHeight': legLengthHeight,
  };
}
