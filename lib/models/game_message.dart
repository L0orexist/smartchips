/// Tipi di messaggi WebSocket
enum MessageType {
  // Connessione
  playerJoin,
  playerLeave,
  playerList,
  
  // Gioco
  placeBet,
  clearBet,
  confirmBets,
  gameResult,
  
  // Azioni Blackjack
  playerDouble,     // Raddoppio
  playerSplit,      // Split
  playerInsurance,  // Assicurazione
  setHandResult,    // Imposta risultato mano
  
  // Stato
  syncState,
  ping,
  pong,
  error,
}

/// Risultati possibili per una mano di Blackjack
class HandResult {
  static const String win = 'win';           // Vince 1:1
  static const String lose = 'lose';         // Perde
  static const String push = 'push';         // Pareggio
  static const String blackjack = 'blackjack'; // Blackjack 3:2
  static const String surrender = 'surrender'; // Resa (perde metà)
  
  static const List<String> all = [win, lose, push, blackjack, surrender];
  
  static String getDisplayName(String result) {
    switch (result) {
      case win: return 'WIN';
      case lose: return 'LOSE';
      case push: return 'PUSH';
      case blackjack: return 'BLACKJACK';
      case surrender: return 'SURRENDER';
      default: return result.toUpperCase();
    }
  }
  
  static double getMultiplier(String result) {
    switch (result) {
      case win: return 2.0;        // Vince: puntata * 2
      case blackjack: return 2.5;  // Blackjack: puntata * 2.5
      case push: return 1.0;       // Pareggio: restituisce puntata
      case surrender: return 0.5;  // Resa: restituisce metà
      case lose: return 0.0;       // Perde: 0
      default: return 0.0;
    }
  }
}

/// Messaggio scambiato via WebSocket tra Banker e Player
class GameMessage {
  final MessageType type;
  final String? playerId;
  final String? playerName;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  GameMessage({
    required this.type,
    this.playerId,
    this.playerName,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'playerId': playerId,
      'playerName': playerName,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameMessage.fromJson(Map<String, dynamic> json) {
    return GameMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.error,
      ),
      playerId: json['playerId'] as String?,
      playerName: json['playerName'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  // Factory methods per messaggi comuni
  factory GameMessage.playerJoin(String playerId, String playerName) {
    return GameMessage(
      type: MessageType.playerJoin,
      playerId: playerId,
      playerName: playerName,
    );
  }

  factory GameMessage.playerLeave(String playerId) {
    return GameMessage(
      type: MessageType.playerLeave,
      playerId: playerId,
    );
  }

  factory GameMessage.placeBet(String playerId, int amount) {
    return GameMessage(
      type: MessageType.placeBet,
      playerId: playerId,
      data: {'amount': amount},
    );
  }

  factory GameMessage.clearBet(String playerId) {
    return GameMessage(
      type: MessageType.clearBet,
      playerId: playerId,
    );
  }

  factory GameMessage.playerList(List<Map<String, dynamic>> players) {
    return GameMessage(
      type: MessageType.playerList,
      data: {'players': players},
    );
  }

  factory GameMessage.gameResult(String result, Map<String, int> payouts) {
    return GameMessage(
      type: MessageType.gameResult,
      data: {
        'result': result,
        'payouts': payouts,
      },
    );
  }
  
  // Azioni Blackjack
  factory GameMessage.playerDouble(String playerId) {
    return GameMessage(
      type: MessageType.playerDouble,
      playerId: playerId,
    );
  }
  
  factory GameMessage.playerSplit(String playerId, int splitBet) {
    return GameMessage(
      type: MessageType.playerSplit,
      playerId: playerId,
      data: {'splitBet': splitBet},
    );
  }
  
  factory GameMessage.playerInsurance(String playerId) {
    return GameMessage(
      type: MessageType.playerInsurance,
      playerId: playerId,
    );
  }
  
  factory GameMessage.setHandResult(String playerId, String result, {String? splitResult}) {
    return GameMessage(
      type: MessageType.setHandResult,
      playerId: playerId,
      data: {
        'result': result,
        'splitResult': splitResult,
      },
    );
  }

  factory GameMessage.error(String message) {
    return GameMessage(
      type: MessageType.error,
      data: {'message': message},
    );
  }
}
