import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/models.dart';

/// Servizio di rete per gestire WebSocket Server (Banker) e Client (Player)
class NetworkService extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // STATO
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool _isServer = false;
  bool _isConnected = false;
  String? _localIp;
  int _port = 8080;
  
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  WebSocketChannel? _clientChannel;
  
  final StreamController<GameMessage> _messageController = 
      StreamController<GameMessage>.broadcast();

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool get isServer => _isServer;
  bool get isConnected => _isConnected;
  String? get localIp => _localIp;
  int get port => _port;
  String get serverAddress => '$_localIp:$_port';
  int get connectedClients => _clients.length;
  Stream<GameMessage> get messages => _messageController.stream;

  // ═══════════════════════════════════════════════════════════════════════════
  // INIZIALIZZAZIONE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    await _getLocalIp();
  }

  Future<void> _getLocalIp() async {
    try {
      // Su desktop (Linux/Windows/macOS), ottieni IP dalle interfacce di rete
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        
        for (final interface in interfaces) {
          // Cerca interfacce non loopback
          if (interface.name != 'lo' && interface.addresses.isNotEmpty) {
            _localIp = interface.addresses.first.address;
            debugPrint('🌐 Found IP on ${interface.name}: $_localIp');
            notifyListeners();
            return;
          }
        }
      }
      
      // Su mobile, usa network_info_plus per WiFi
      final info = NetworkInfo();
      _localIp = await info.getWifiIP();
      
      _localIp ??= '127.0.0.1'; // Fallback localhost
      debugPrint('🌐 Using IP: $_localIp');
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting local IP: $e');
      _localIp = '127.0.0.1';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVER (BANKER)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Avvia il server WebSocket (usato dal Banker)
  Future<bool> startServer({int port = 8080}) async {
    try {
      _port = port;
      await _getLocalIp();
      
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isServer = true;
      _isConnected = true;
      
      debugPrint('🎰 Server started at $_localIp:$port');
      
      _server!.transform(WebSocketTransformer()).listen(
        _handleClientConnection,
        onError: (error) {
          debugPrint('Server error: $error');
        },
        onDone: () {
          debugPrint('Server closed');
        },
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to start server: $e');
      return false;
    }
  }

  void _handleClientConnection(WebSocket client) {
    debugPrint('📱 New client connected');
    _clients.add(client);
    notifyListeners();
    
    client.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final message = GameMessage.fromJson(json);
          debugPrint('📨 Received: ${message.type}');
          _messageController.add(message);
          
          // Broadcast ai altri client (escluso il mittente)
          _broadcastToOthers(data, client);
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      },
      onDone: () {
        debugPrint('📱 Client disconnected');
        _clients.remove(client);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Client error: $error');
        _clients.remove(client);
        notifyListeners();
      },
    );
  }

  void _broadcastToOthers(String data, WebSocket sender) {
    for (final client in _clients) {
      if (client != sender && client.readyState == WebSocket.open) {
        client.add(data);
      }
    }
  }

  /// Invia un messaggio a tutti i client connessi
  void broadcast(GameMessage message) {
    final data = jsonEncode(message.toJson());
    for (final client in _clients) {
      if (client.readyState == WebSocket.open) {
        client.add(data);
      }
    }
  }

  /// Ferma il server
  Future<void> stopServer() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
    _isServer = false;
    _isConnected = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLIENT (PLAYER)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Connette al server WebSocket (usato dal Player)
  Future<bool> connectToServer(String address) async {
    try {
      // Rimuovi spazi e normalizza
      address = address.trim();
      
      // Aggiungi porta default se non presente
      if (!address.contains(':')) {
        address = '$address:8080';
      }
      
      final uri = Uri.parse('ws://$address');
      debugPrint('🔌 Connecting to $uri');
      
      _clientChannel = IOWebSocketChannel.connect(uri);
      
      // Attendi la connessione
      await _clientChannel!.ready;
      
      _isConnected = true;
      _isServer = false;
      
      debugPrint('✅ Connected to server');
      
      _clientChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final message = GameMessage.fromJson(json);
            debugPrint('📨 Received: ${message.type}');
            _messageController.add(message);
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        },
        onDone: () {
          debugPrint('🔌 Disconnected from server');
          _isConnected = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Connection error: $error');
          _isConnected = false;
          notifyListeners();
        },
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to connect: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Invia un messaggio al server
  void send(GameMessage message) {
    if (_clientChannel != null && _isConnected) {
      final data = jsonEncode(message.toJson());
      _clientChannel!.sink.add(data);
    }
  }

  /// Disconnette dal server
  Future<void> disconnect() async {
    await _clientChannel?.sink.close();
    _clientChannel = null;
    _isConnected = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    stopServer();
    disconnect();
    _messageController.close();
    super.dispose();
  }
}
