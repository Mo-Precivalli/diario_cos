import 'dart:convert';

class MonsterModel {
  String name;
  String size;
  String type;
  String alignment;

  int armorClass;
  int hitPoints;
  String hitPointsFormula;
  String speed;
  int initiative;

  int strength;
  int dexterity;
  int constitution;
  int intelligence;
  int wisdom;
  int charisma;

  String savingThrows;
  String skills;
  String damageVulnerabilities;
  String damageResistances;
  String damageImmunities;
  String conditionImmunities;
  String senses;
  String languages;
  double challengeRating;
  int xp;
  int proficiencyBonus;

  List<MonsterAbility> traits;
  List<MonsterAbility> actions;
  List<MonsterAbility> bonusActions;
  List<MonsterAbility> reactions;
  List<MonsterAbility> legendaryActions;
  String legendaryActionsDescription;

  Map<String, bool> saveProficiencies;

  MonsterModel({
    this.name = 'Monstro Sem Nome',
    this.size = 'Médio',
    this.type = 'Humanoide',
    this.alignment = 'Neutro',
    this.armorClass = 10,
    this.hitPoints = 10,
    this.hitPointsFormula = '2d8 + 2',
    this.speed = '30 ft.',
    this.initiative = 0,
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
    this.savingThrows = '',
    this.skills = '',
    this.damageVulnerabilities = '',
    this.damageResistances = '',
    this.damageImmunities = '',
    this.conditionImmunities = '',
    this.senses = 'passive Perception 10',
    this.languages = '-',
    this.challengeRating = 0,
    this.xp = 0,
    this.proficiencyBonus = 2,
    Map<String, bool>? saveProficiencies,
    List<MonsterAbility>? traits,
    List<MonsterAbility>? actions,
    List<MonsterAbility>? bonusActions,
    List<MonsterAbility>? reactions,
    List<MonsterAbility>? legendaryActions,
    this.legendaryActionsDescription = '',
  }) : traits = traits ?? [],
       actions = actions ?? [],
       bonusActions = bonusActions ?? [],
       reactions = reactions ?? [],
       legendaryActions = legendaryActions ?? [],
       saveProficiencies =
           saveProficiencies ??
           {
             'FOR': false,
             'DES': false,
             'CON': false,
             'INT': false,
             'SAB': false,
             'CAR': false,
           };

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'size': size,
      'type': type,
      'alignment': alignment,
      'armorClass': armorClass,
      'hitPoints': hitPoints,
      'hitPointsFormula': hitPointsFormula,
      'speed': speed,
      'initiative': initiative,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'savingThrows': savingThrows,
      'skills': skills,
      'damageVulnerabilities': damageVulnerabilities,
      'damageResistances': damageResistances,
      'damageImmunities': damageImmunities,
      'conditionImmunities': conditionImmunities,
      'senses': senses,
      'languages': languages,
      'challengeRating': challengeRating,
      'xp': xp,
      'proficiencyBonus': proficiencyBonus,
      'saveProficiencies': saveProficiencies,
      'traits': traits.map((x) => x.toMap()).toList(),
      'actions': actions.map((x) => x.toMap()).toList(),
      'bonusActions': bonusActions.map((x) => x.toMap()).toList(),
      'reactions': reactions.map((x) => x.toMap()).toList(),
      'legendaryActions': legendaryActions.map((x) => x.toMap()).toList(),
      'legendaryActionsDescription': legendaryActionsDescription,
    };
  }

  factory MonsterModel.fromMap(Map<String, dynamic> map) {
    return MonsterModel(
      name: map['name'] ?? 'Monstro Sem Nome',
      size: map['size'] ?? 'Médio',
      type: map['type'] ?? 'Humanoide',
      alignment: map['alignment'] ?? 'Neutro',
      armorClass: map['armorClass']?.toInt() ?? 10,
      hitPoints: map['hitPoints']?.toInt() ?? 10,
      hitPointsFormula: map['hitPointsFormula'] ?? '',
      speed: map['speed'] ?? '30 ft.',
      initiative: map['initiative']?.toInt() ?? 0,
      strength: map['strength']?.toInt() ?? 10,
      dexterity: map['dexterity']?.toInt() ?? 10,
      constitution: map['constitution']?.toInt() ?? 10,
      intelligence: map['intelligence']?.toInt() ?? 10,
      wisdom: map['wisdom']?.toInt() ?? 10,
      charisma: map['charisma']?.toInt() ?? 10,
      savingThrows: map['savingThrows'] ?? '',
      skills: map['skills'] ?? '',
      damageVulnerabilities: map['damageVulnerabilities'] ?? '',
      damageResistances: map['damageResistances'] ?? '',
      damageImmunities: map['damageImmunities'] ?? '',
      conditionImmunities: map['conditionImmunities'] ?? '',
      senses: map['senses'] ?? '',
      languages: map['languages'] ?? '',
      challengeRating: (map['challengeRating'] ?? 0).toDouble(),
      xp: map['xp']?.toInt() ?? 0,
      proficiencyBonus: map['proficiencyBonus']?.toInt() ?? 2,
      saveProficiencies: map['saveProficiencies'] != null
          ? Map<String, bool>.from(map['saveProficiencies'])
          : null,
      traits: map['traits'] != null
          ? List<MonsterAbility>.from(
              map['traits']?.map((x) => MonsterAbility.fromMap(x)),
            )
          : null,
      actions: map['actions'] != null
          ? List<MonsterAbility>.from(
              map['actions']?.map((x) => MonsterAbility.fromMap(x)),
            )
          : null,
      bonusActions: map['bonusActions'] != null
          ? List<MonsterAbility>.from(
              map['bonusActions']?.map((x) => MonsterAbility.fromMap(x)),
            )
          : null,
      reactions: map['reactions'] != null
          ? List<MonsterAbility>.from(
              map['reactions']?.map((x) => MonsterAbility.fromMap(x)),
            )
          : null,
      legendaryActions: map['legendaryActions'] != null
          ? List<MonsterAbility>.from(
              map['legendaryActions']?.map((x) => MonsterAbility.fromMap(x)),
            )
          : null,
      legendaryActionsDescription: map['legendaryActionsDescription'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MonsterModel.fromJson(String source) =>
      MonsterModel.fromMap(json.decode(source));

  // Helper para calcular modificador
  static int calculateModifier(int score) {
    return ((score - 10) / 2).floor();
  }
}

class MonsterAbility {
  String name;
  String description;

  MonsterAbility({required this.name, required this.description});

  Map<String, dynamic> toMap() {
    return {'name': name, 'description': description};
  }

  factory MonsterAbility.fromMap(Map<String, dynamic> map) {
    return MonsterAbility(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
