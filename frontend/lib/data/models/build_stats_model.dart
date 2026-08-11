class BuildStats {
  final int conscienceOffensive;
  final int controleBalle;
  final int dribbles;
  final int tenueBalle;
  final int passeATerre;
  final int passeLobee;
  final int finition;
  final int tete;
  final int coupsDepiedArretes;
  final int effet;
  final int conscienceDefensive;
  final int tacles;
  final int engagementDefensif;
  final int agressivite;
  final int vitesse;
  final int acceleration;
  final int puissanceDeTir;
  final int detente;
  final int contactPhysique;
  final int equilibre;
  final int endurance;
  final int conscienceGardien;
  final int arretGardien;
  final int reflexesGardien;

  const BuildStats({
    this.conscienceOffensive = 0, this.controleBalle = 0,
    this.dribbles = 0,           this.tenueBalle = 0,
    this.passeATerre = 0,        this.passeLobee = 0,
    this.finition = 0,           this.tete = 0,
    this.coupsDepiedArretes = 0, this.effet = 0,
    this.conscienceDefensive = 0,this.tacles = 0,
    this.engagementDefensif = 0, this.agressivite = 0,
    this.vitesse = 0,            this.acceleration = 0,
    this.puissanceDeTir = 0,     this.detente = 0,
    this.contactPhysique = 0,    this.equilibre = 0,
    this.endurance = 0,          this.conscienceGardien = 0,
    this.arretGardien = 0,       this.reflexesGardien = 0,
  });

  factory BuildStats.fromMap(Map<String, dynamic> m) => BuildStats(
    conscienceOffensive: m['conscienceOffensive'] ?? 0,
    controleBalle:       m['controleBalle']       ?? 0,
    dribbles:            m['dribbles']            ?? 0,
    tenueBalle:          m['tenueBalle']          ?? 0,
    passeATerre:         m['passeATerre']         ?? 0,
    passeLobee:          m['passeLobee']          ?? 0,
    finition:            m['finition']            ?? 0,
    tete:                m['tete']                ?? 0,
    coupsDepiedArretes:  m['coupsDepiedArretes']  ?? 0,
    effet:               m['effet']               ?? 0,
    conscienceDefensive: m['conscienceDefensive'] ?? 0,
    tacles:              m['tacles']              ?? 0,
    engagementDefensif:  m['engagementDefensif']  ?? 0,
    agressivite:         m['agressivite']         ?? 0,
    vitesse:             m['vitesse']             ?? 0,
    acceleration:        m['acceleration']        ?? 0,
    puissanceDeTir:      m['puissanceDeTir']      ?? 0,
    detente:             m['detente']             ?? 0,
    contactPhysique:     m['contactPhysique']     ?? 0,
    equilibre:           m['equilibre']           ?? 0,
    endurance:           m['endurance']           ?? 0,
    conscienceGardien:   m['conscienceGardien']   ?? 0,
    arretGardien:        m['arretGardien']        ?? 0,
    reflexesGardien:     m['reflexesGardien']     ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'conscienceOffensive': conscienceOffensive, 'controleBalle': controleBalle,
    'dribbles': dribbles,    'tenueBalle': tenueBalle,
    'passeATerre': passeATerre, 'passeLobee': passeLobee,
    'finition': finition,    'tete': tete,
    'coupsDepiedArretes': coupsDepiedArretes, 'effet': effet,
    'conscienceDefensive': conscienceDefensive, 'tacles': tacles,
    'engagementDefensif': engagementDefensif, 'agressivite': agressivite,
    'vitesse': vitesse,      'acceleration': acceleration,
    'puissanceDeTir': puissanceDeTir, 'detente': detente,
    'contactPhysique': contactPhysique, 'equilibre': equilibre,
    'endurance': endurance,  'conscienceGardien': conscienceGardien,
    'arretGardien': arretGardien, 'reflexesGardien': reflexesGardien,
  };
}
