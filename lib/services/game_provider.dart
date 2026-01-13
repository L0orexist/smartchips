import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'network_service.dart';

/// Provider per gestire lo stato del gioco Blackjack
class GameProvider extends ChangeNotifier {
  NetworkService? _networkService;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STATO
  // ═══════════════════════════════════════════════════════════════════════════
  
  String _role = ''; // 'banker' o 'player'
  String _playerId = '';
  String _playerName = '';
  int _balance = 1000;
  int _currentBet = 0;
  int _bankerBalance = 10000; // Cassa del banco
  
  // Stato azioni player
  bool _myHasDoubled = false;
  bool _myHasSplit = false;
  bool _myHasInsurance = false;
  String? _myHandResult;
  String? _mySplitResult;
  
  final Map<String, PlayerModel> _players = {};
  String _gamePhase = 'waiting'; // waiting, betting, playing, payout
  
  StreamSubscription<GameMessage>? _messageSubscription;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════════════════

  GameProvider();
  
  void updateNetworkService(NetworkService network) {
    if (_networkService != network) {
      _messageSubscription?.cancel();
      _networkService = network;
      _messageSubscription = network.messages.listen(_handleMessage);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  String get role => _role;
  bool get isBanker => _role == 'banker';
  bool get isPlayer => _role == 'player';
  String get playerId => _playerId;
  String get playerName => _playerName;
  int get balance => _balance;
  int get currentBet => _currentBet;
  int get myBalance => _balance;
  int get myCurrentBet => _currentBet;
  String get gamePhase => _gamePhase;
  List<PlayerModel> get players => _players.values.toList();
  int get playerCount => _players.length;
  int get totalBets => _players.values.fold(0, (sum, p) => sum + p.currentBet);
  
  // Getters per economia del banco
  int get bankerBalance => _bankerBalance;
  
  /// Calcola quanto il banco guadagnerà/perderà con i risultati attuali
  int get bankerNetProfit {
    int profit = 0;
    for (final player in _players.values) {
      if (player.handResult != null) {
        final totalBet = player.totalBet;
        final payout = calculatePayout(player);
        // Profitto = soldi incassati - soldi pagati
        profit += totalBet - payout;
      }
    }
    return profit;
  }
  
  // Getters per stato azioni player
  bool get myHasDoubled => _myHasDoubled;
  bool get myHasSplit => _myHasSplit;
  bool get myHasInsurance => _myHasInsurance;
  String? get myHandResult => _myHandResult;
  String? get mySplitResult => _mySplitResult;
  bool get hasSubmittedResult => _myHandResult != null;

  // ═══════════════════════════════════════════════════════════════════════════
  // SETUP RUOLI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Imposta il ruolo come Banker e avvia il server
  Future<bool> setupAsBanker() async {
    if (_networkService == null) return false;
    
    _role = 'banker';
    _playerId = const Uuid().v4();
    _playerName = 'Banker';
    
    await _networkService!.init();
    final success = await _networkService!.startServer();
    
    if (success) {
      _gamePhase = 'waiting';
      notifyListeners();
    }
    
    return success;
  }

  /// Imposta il ruolo come Player e connette al server
  Future<bool> setupAsPlayer(String serverAddress, String name) async {
    if (_networkService == null) return false;
    
    _role = 'player';
    _playerId = const Uuid().v4();
    _playerName = name.isEmpty ? 'Player' : name;
    _balance = 1000;
    _currentBet = 0;
    
    final success = await _networkService!.connectToServer(serverAddress);
    
    if (success) {
      // Invia messaggio di join
      _networkService!.send(GameMessage.playerJoin(_playerId, _playerName));
      notifyListeners();
    }
    
    return success;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AZIONI PLAYER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Piazza una puntata
  void placeBet(int amount) {
    if (_balance >= amount) {
      _currentBet += amount;
      _balance -= amount;
      
      if (isPlayer && _networkService != null) {
        _networkService!.send(GameMessage.placeBet(_playerId, _currentBet));
      }
      
      notifyListeners();
    }
  }

  /// Rimuove una chip dalla puntata
  void removeBet(int amount) {
    if (_currentBet >= amount) {
      _currentBet -= amount;
      _balance += amount;
      
      if (isPlayer && _networkService != null) {
        _networkService!.send(GameMessage.placeBet(_playerId, _currentBet));
      }
      
      notifyListeners();
    }
  }

  /// Pulisce la puntata corrente
  void clearBet() {
    _balance += _currentBet;
    _currentBet = 0;
    
    if (isPlayer && _networkService != null) {
      _networkService!.send(GameMessage.clearBet(_playerId));
    }
    
    notifyListeners();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // AZIONI BLACKJACK PLAYER
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Raddoppia la puntata (Double Down)
  void doubleDown() {
    if (!isPlayer || _networkService == null) return;
    if (_balance < _currentBet) return; // Non abbastanza soldi
    
    _balance -= _currentBet; // Raddoppia
    _myHasDoubled = true;
    _networkService!.send(GameMessage.playerDouble(_playerId));
    notifyListeners();
  }
  
  /// Split delle carte
  void split() {
    if (!isPlayer || _networkService == null) return;
    if (_balance < _currentBet) return;
    
    _balance -= _currentBet; // Puntata per la seconda mano
    _myHasSplit = true;
    _networkService!.send(GameMessage.playerSplit(_playerId, _currentBet));
    notifyListeners();
  }
  
  /// Assicurazione (quando il dealer mostra un Asso)
  void insurance() {
    if (!isPlayer || _networkService == null) return;
    final insuranceCost = (_currentBet / 2).round();
    if (_balance < insuranceCost) return;
    
    _balance -= insuranceCost;
    _myHasInsurance = true;
    _networkService!.send(GameMessage.playerInsurance(_playerId));
    notifyListeners();
  }
  
  /// Imposta il risultato della propria mano (Player)
  void setMyResult(String result, {String? splitResult}) {
    if (!isPlayer || _networkService == null) return;
    
    _myHandResult = result;
    _mySplitResult = splitResult;
    _networkService!.send(GameMessage.setHandResult(_playerId, result, splitResult: splitResult));
    notifyListeners();
  }
  
  /// Imposta solo il risultato della mano split
  void setMySplitResult(String splitResult) {
    if (!isPlayer || _networkService == null) return;
    
    _mySplitResult = splitResult;
    // Invia il risultato completo (mano principale + split)
    _networkService!.send(GameMessage.setHandResult(_playerId, _myHandResult ?? 'lose', splitResult: splitResult));
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AZIONI BANKER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Avvia la fase di puntate
  void startBettingPhase() {
    if (!isBanker || _networkService == null) return;
    
    _gamePhase = 'betting';
    _networkService!.broadcast(GameMessage(
      type: MessageType.syncState,
      data: {'phase': 'betting'},
    ));
    notifyListeners();
  }

  /// Conferma le puntate e passa alla fase di gioco
  void confirmBets() {
    if (!isBanker || _networkService == null) return;
    
    _gamePhase = 'playing';
    _networkService!.broadcast(GameMessage(
      type: MessageType.confirmBets,
    ));
    notifyListeners();
  }
  
  /// Imposta il risultato di un singolo giocatore
  void setPlayerResult(String playerId, String result, {String? splitResult}) {
    if (!isBanker || _networkService == null) return;
    
    final player = _players[playerId];
    if (player == null) return;
    
    _players[playerId] = player.copyWith(
      handResult: result,
      splitResult: splitResult,
    );
    
    _networkService!.broadcast(GameMessage.setHandResult(playerId, result, splitResult: splitResult));
    notifyListeners();
  }
  
  /// Calcola il payout per un giocatore
  int calculatePayout(PlayerModel player) {
    int payout = 0;
    
    // Mano principale
    if (player.handResult != null) {
      double mult = HandResult.getMultiplier(player.handResult!);
      int bet = player.currentBet;
      if (player.hasDoubled) bet *= 2;
      payout += (bet * mult).round();
    }
    
    // Mano split
    if (player.hasSplit && player.splitResult != null) {
      double mult = HandResult.getMultiplier(player.splitResult!);
      payout += (player.splitBet * mult).round();
    }
    
    // Assicurazione (vince solo se dealer ha blackjack e player perde)
    if (player.hasInsurance && player.handResult == HandResult.lose) {
      // L'assicurazione paga 2:1 se il dealer ha blackjack
      // Per semplicità, assumiamo che se il player ha assicurazione e perde = dealer aveva BJ
      payout += player.currentBet; // Restituisce la puntata originale via assicurazione
    }
    
    return payout;
  }

  /// Distribuisce le vincite a tutti i giocatori
  void distributeAllPayouts() {
    if (!isBanker || _networkService == null) return;
    
    final payouts = <String, int>{};
    int totalPaidOut = 0;
    int totalCollected = 0;
    
    for (final player in _players.values) {
      if (player.handResult != null) {
        final payout = calculatePayout(player);
        final totalBet = player.totalBet;
        
        payouts[player.id] = payout;
        totalPaidOut += payout;
        totalCollected += totalBet;
      }
    }
    
    // Aggiorna il saldo del banco: incassa le puntate, paga le vincite
    _bankerBalance += totalCollected - totalPaidOut;
    
    _networkService!.broadcast(GameMessage.gameResult('complete', payouts));
    
    // Reset per nuova mano
    _gamePhase = 'waiting';
    for (final id in _players.keys) {
      _players[id] = _players[id]!.resetHand();
    }
    
    notifyListeners();
  }

  /// Distribuisce le vincite (result: 'win', 'lose', 'push', 'blackjack') - LEGACY
  void distributePayouts(Map<String, String> results) {
    if (!isBanker || _networkService == null) return;
    
    final payouts = <String, int>{};
    
    for (final entry in results.entries) {
      final playerId = entry.key;
      final result = entry.value;
      final player = _players[playerId];
      
      if (player != null) {
        int payout = 0;
        switch (result) {
          case 'win':
            payout = player.currentBet * 2;
            break;
          case 'blackjack':
            payout = (player.currentBet * 2.5).round();
            break;
          case 'push':
            payout = player.currentBet;
            break;
          case 'lose':
          default:
            payout = 0;
        }
        payouts[playerId] = payout;
      }
    }
    
    _networkService!.broadcast(GameMessage.gameResult('complete', payouts));
    
    // Reset per nuova mano
    _gamePhase = 'waiting';
    for (final id in _players.keys) {
      _players[id] = _players[id]!.copyWith(currentBet: 0);
    }
    
    notifyListeners();
  }

  /// Rimuove un giocatore dal tavolo
  void removePlayer(String playerId) {
    if (!isBanker || _networkService == null) return;
    
    _players.remove(playerId);
    _networkService!.broadcast(GameMessage.playerLeave(playerId));
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTIONE MESSAGGI
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleMessage(GameMessage message) {
    debugPrint('🎮 GameProvider received: ${message.type}');
    
    switch (message.type) {
      case MessageType.playerJoin:
        _onPlayerJoin(message);
        break;
      case MessageType.playerLeave:
        _onPlayerLeave(message);
        break;
      case MessageType.placeBet:
        _onPlaceBet(message);
        break;
      case MessageType.clearBet:
        _onClearBet(message);
        break;
      case MessageType.gameResult:
        _onGameResult(message);
        break;
      case MessageType.syncState:
        _onSyncState(message);
        break;
      case MessageType.playerList:
        _onPlayerList(message);
        break;
      case MessageType.playerDouble:
        _onPlayerDouble(message);
        break;
      case MessageType.playerSplit:
        _onPlayerSplit(message);
        break;
      case MessageType.playerInsurance:
        _onPlayerInsurance(message);
        break;
      case MessageType.setHandResult:
        _onSetHandResult(message);
        break;
      case MessageType.confirmBets:
        _onConfirmBets(message);
        break;
      default:
        break;
    }
  }
  
  void _onConfirmBets(GameMessage message) {
    // Quando il banker conferma le bets, passa alla fase playing
    _gamePhase = 'playing';
    notifyListeners();
  }

  void _onPlayerJoin(GameMessage message) {
    if (message.playerId != null && message.playerName != null) {
      _players[message.playerId!] = PlayerModel(
        id: message.playerId!,
        name: message.playerName!,
        joinedAt: DateTime.now(),
      );
      
      // Se siamo il banker, invia la lista aggiornata
      if (isBanker && _networkService != null) {
        _networkService!.broadcast(GameMessage.playerList(
          _players.values.map((p) => p.toJson()).toList(),
        ));
      }
      
      notifyListeners();
    }
  }

  void _onPlayerLeave(GameMessage message) {
    if (message.playerId != null) {
      // Se il giocatore rimosso sono io (Player), devo disconnettermi
      if (message.playerId == _playerId && isPlayer) {
        _wasKicked = true;
        _networkService?.disconnect();
        reset();
        notifyListeners();
        return;
      }
      
      _players.remove(message.playerId);
      notifyListeners();
    }
  }
  
  // Flag per indicare se il player è stato espulso
  bool _wasKicked = false;
  bool get wasKicked => _wasKicked;
  
  void clearKickedFlag() {
    _wasKicked = false;
  }

  void _onPlaceBet(GameMessage message) {
    if (message.playerId != null && message.data != null) {
      final amount = message.data!['amount'] as int? ?? 0;
      final player = _players[message.playerId];
      
      if (player != null) {
        _players[message.playerId!] = player.copyWith(currentBet: amount);
        notifyListeners();
      }
    }
  }

  void _onClearBet(GameMessage message) {
    if (message.playerId != null) {
      final player = _players[message.playerId];
      
      if (player != null) {
        _players[message.playerId!] = player.copyWith(currentBet: 0);
        notifyListeners();
      }
    }
  }

  void _onGameResult(GameMessage message) {
    if (message.data != null) {
      final payouts = message.data!['payouts'] as Map<String, dynamic>?;
      
      if (payouts != null && payouts.containsKey(_playerId)) {
        final payout = payouts[_playerId] as int? ?? 0;
        _balance += payout;
        _currentBet = 0;
        notifyListeners();
      }
    }
  }

  void _onSyncState(GameMessage message) {
    if (message.data != null) {
      final phase = message.data!['phase'] as String?;
      if (phase != null) {
        // Se passa a betting, resetta lo stato della mano
        if (phase == 'betting' && _gamePhase != 'betting') {
          resetHandState();
        }
        _gamePhase = phase;
        notifyListeners();
      }
    }
  }

  void _onPlayerList(GameMessage message) {
    if (message.data != null) {
      final playersList = message.data!['players'] as List<dynamic>?;
      
      if (playersList != null) {
        _players.clear();
        for (final p in playersList) {
          final player = PlayerModel.fromJson(p as Map<String, dynamic>);
          _players[player.id] = player;
        }
        notifyListeners();
      }
    }
  }
  
  void _onPlayerDouble(GameMessage message) {
    if (message.playerId != null) {
      final player = _players[message.playerId];
      if (player != null) {
        _players[message.playerId!] = player.copyWith(hasDoubled: true);
        notifyListeners();
      }
    }
  }
  
  void _onPlayerSplit(GameMessage message) {
    if (message.playerId != null && message.data != null) {
      final splitBet = message.data!['splitBet'] as int? ?? 0;
      final player = _players[message.playerId];
      if (player != null) {
        _players[message.playerId!] = player.copyWith(
          hasSplit: true,
          splitBet: splitBet,
        );
        notifyListeners();
      }
    }
  }
  
  void _onPlayerInsurance(GameMessage message) {
    if (message.playerId != null) {
      final player = _players[message.playerId];
      if (player != null) {
        _players[message.playerId!] = player.copyWith(hasInsurance: true);
        notifyListeners();
      }
    }
  }
  
  void _onSetHandResult(GameMessage message) {
    if (message.playerId != null && message.data != null) {
      final result = message.data!['result'] as String?;
      final splitResult = message.data!['splitResult'] as String?;
      
      // Se sono il player interessato, aggiorno il mio stato
      if (message.playerId == _playerId && isPlayer) {
        // Il payout verrà gestito da gameResult
      }
      
      final player = _players[message.playerId];
      if (player != null) {
        _players[message.playerId!] = player.copyWith(
          handResult: result,
          splitResult: splitResult,
        );
        notifyListeners();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resetta lo stato per una nuova mano
  void resetHandState() {
    _currentBet = 0;
    _myHasDoubled = false;
    _myHasSplit = false;
    _myHasInsurance = false;
    _myHandResult = null;
    _mySplitResult = null;
    notifyListeners();
  }

  void reset() {
    _role = '';
    _playerId = '';
    _playerName = '';
    _balance = 1000;
    _currentBet = 0;
    _bankerBalance = 10000;
    _myHasDoubled = false;
    _myHasSplit = false;
    _myHasInsurance = false;
    _myHandResult = null;
    _mySplitResult = null;
    _players.clear();
    _gamePhase = 'waiting';
    notifyListeners();
  }
  
  /// Imposta il saldo iniziale del banco
  void setBankerBalance(int amount) {
    if (isBanker) {
      _bankerBalance = amount;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
