/// Modello rappresentante un giocatore nel tavolo
class PlayerModel {
  final String id;
  final String name;
  final int balance;
  final int currentBet;
  final bool isConnected;
  final DateTime joinedAt;
  
  // Stato mano Blackjack
  final bool hasDoubled;      // Ha raddoppiato
  final bool hasSplit;        // Ha splittato
  final bool hasInsurance;    // Ha assicurazione
  final int splitBet;         // Puntata sulla seconda mano (split)
  final String? handResult;   // Risultato mano principale
  final String? splitResult;  // Risultato mano split

  const PlayerModel({
    required this.id,
    required this.name,
    this.balance = 1000,
    this.currentBet = 0,
    this.isConnected = true,
    required this.joinedAt,
    this.hasDoubled = false,
    this.hasSplit = false,
    this.hasInsurance = false,
    this.splitBet = 0,
    this.handResult,
    this.splitResult,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    int? balance,
    int? currentBet,
    bool? isConnected,
    DateTime? joinedAt,
    bool? hasDoubled,
    bool? hasSplit,
    bool? hasInsurance,
    int? splitBet,
    String? handResult,
    String? splitResult,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currentBet: currentBet ?? this.currentBet,
      isConnected: isConnected ?? this.isConnected,
      joinedAt: joinedAt ?? this.joinedAt,
      hasDoubled: hasDoubled ?? this.hasDoubled,
      hasSplit: hasSplit ?? this.hasSplit,
      hasInsurance: hasInsurance ?? this.hasInsurance,
      splitBet: splitBet ?? this.splitBet,
      handResult: handResult ?? this.handResult,
      splitResult: splitResult ?? this.splitResult,
    );
  }
  
  /// Resetta lo stato per una nuova mano
  PlayerModel resetHand() {
    return PlayerModel(
      id: id,
      name: name,
      balance: balance,
      currentBet: 0,
      isConnected: isConnected,
      joinedAt: joinedAt,
      hasDoubled: false,
      hasSplit: false,
      hasInsurance: false,
      splitBet: 0,
      handResult: null,
      splitResult: null,
    );
  }
  
  /// Calcola la puntata totale (incluso double/split/insurance)
  int get totalBet {
    int total = currentBet;
    if (hasDoubled) total += currentBet;
    if (hasSplit) total += splitBet;
    if (hasInsurance) total += (currentBet / 2).round();
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currentBet': currentBet,
      'isConnected': isConnected,
      'joinedAt': joinedAt.toIso8601String(),
      'hasDoubled': hasDoubled,
      'hasSplit': hasSplit,
      'hasInsurance': hasInsurance,
      'splitBet': splitBet,
      'handResult': handResult,
      'splitResult': splitResult,
    };
  }

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: json['balance'] as int? ?? 1000,
      currentBet: json['currentBet'] as int? ?? 0,
      isConnected: json['isConnected'] as bool? ?? true,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      hasDoubled: json['hasDoubled'] as bool? ?? false,
      hasSplit: json['hasSplit'] as bool? ?? false,
      hasInsurance: json['hasInsurance'] as bool? ?? false,
      splitBet: json['splitBet'] as int? ?? 0,
      handResult: json['handResult'] as String?,
      splitResult: json['splitResult'] as String?,
    );
  }

  @override
  String toString() => 'PlayerModel(id: $id, name: $name, balance: $balance)';
}
