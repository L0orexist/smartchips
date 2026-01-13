import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../theme/app_theme.dart';
import '../../services/services.dart';
import '../../models/models.dart';

/// Schermata del Banker - Host del tavolo
class BankerScreen extends StatefulWidget {
  const BankerScreen({super.key});

  @override
  State<BankerScreen> createState() => _BankerScreenState();
}

class _BankerScreenState extends State<BankerScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initServer();
  }

  Future<void> _initServer() async {
    final gameProvider = context.read<GameProvider>();
    
    try {
      final success = await gameProvider.setupAsBanker();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!success) {
            _error = 'Failed to start server';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, color: const Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text(
              'BANKER',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.accentPrimary),
          const SizedBox(height: 24),
          Text(
            'Starting server...',
            style: GoogleFonts.roboto(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.accentSecondary),
          const SizedBox(height: 24),
          Text(
            'Error',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              color: AppTheme.accentSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.roboto(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer2<NetworkService, GameProvider>(
      builder: (context, network, game, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bank Balance section
              _buildBankBalanceSection(game),
              
              const SizedBox(height: 24),
              
              // QR Code section
              _buildQRSection(network),
              
              const SizedBox(height: 24),
              
              // Connection info
              _buildConnectionInfo(network),
              
              const SizedBox(height: 24),
              
              // Connected players
              _buildPlayersSection(game),
              
              const SizedBox(height: 24),
              
              // Game controls
              _buildGameControls(game),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildBankBalanceSection(GameProvider game) {
    final netProfit = game.bankerNetProfit;
    final isPositive = netProfit >= 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFF16213e),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance,
                color: const Color(0xFFFFD700),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'BANK',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BALANCE',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '\$${game.bankerBalance}',
                    style: GoogleFonts.orbitron(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (game.gamePhase == 'playing' && game.players.any((p) => p.handResult != null))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'THIS ROUND',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: isPositive ? AppTheme.accentPrimary : AppTheme.accentSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}\$$netProfit',
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppTheme.accentPrimary : AppTheme.accentSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra di progresso visiva
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (game.bankerBalance / 20000).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accentPrimary, const Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(NetworkService network) {
    final qrData = network.serverAddress;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            'SCAN TO JOIN',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0a0a0a),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0a0a0a),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, color: AppTheme.accentPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  qrData,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionInfo(NetworkService network) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: network.isConnected ? AppTheme.accentPrimary : AppTheme.accentSecondary,
              boxShadow: [
                BoxShadow(
                  color: (network.isConnected ? AppTheme.accentPrimary : AppTheme.accentSecondary)
                      .withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server Status',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  network.isConnected ? 'Online - Waiting for players' : 'Offline',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, size: 16, color: AppTheme.accentPrimary),
                const SizedBox(width: 4),
                Text(
                  '${network.connectedClients}',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersSection(GameProvider game) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'PLAYERS',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'Total Bets: \$${game.totalBets}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (game.players.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for players to join...',
                      style: GoogleFonts.roboto(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...game.players.map((player) => _buildPlayerTile(player, game)),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(PlayerModel player, GameProvider game) {
    final isPlaying = game.gamePhase == 'playing';
    final hasResult = player.handResult != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasResult 
              ? _getResultColor(player.handResult!)
              : player.currentBet > 0 
                  ? AppTheme.accentPrimary.withValues(alpha: 0.5)
                  : AppTheme.borderColor,
          width: hasResult ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Riga principale con info giocatore
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.accentPrimary.withValues(alpha: 0.2),
                child: Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  style: GoogleFonts.orbitron(
                    color: AppTheme.accentPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.orbitron(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Mostra stato speciale (double/split/insurance)
                    if (player.hasDoubled || player.hasSplit || player.hasInsurance)
                      Row(
                        children: [
                          if (player.hasDoubled) _buildStatusChip('2X', Colors.orange),
                          if (player.hasSplit) _buildStatusChip('SPLIT', Colors.purple),
                          if (player.hasInsurance) _buildStatusChip('INS', Colors.blue),
                        ],
                      ),
                  ],
                ),
              ),
              // Puntata totale
              if (player.currentBet > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${player.totalBet}',
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.backgroundPrimary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.accentSecondary),
                onPressed: () => game.removePlayer(player.id),
                tooltip: 'Remove player',
              ),
            ],
          ),
          
          // Mostra risultato se impostato (solo visualizzazione, il player lo seleziona)
          if (hasResult) ...[
            const SizedBox(height: 8),
            _buildResultDisplay(player, game),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.orbitron(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildResultDisplay(PlayerModel player, GameProvider game) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getResultColor(player.handResult!).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            player.handResult!.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getResultColor(player.handResult!),
            ),
          ),
        ),
        if (player.hasSplit && player.splitResult != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getResultColor(player.splitResult!).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
            ),
            child: Text(
              'SPLIT: ${player.splitResult!.toUpperCase()}',
              style: GoogleFonts.orbitron(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getResultColor(player.splitResult!),
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          'Payout: \$${game.calculatePayout(player)}',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: AppTheme.accentPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Color _getResultColor(String result) {
    switch (result) {
      case 'win': return AppTheme.accentPrimary;
      case 'blackjack': return const Color(0xFFFFD700);
      case 'push': return Colors.grey;
      case 'lose': return AppTheme.accentSecondary;
      case 'surrender': return Colors.orange;
      default: return AppTheme.textSecondary;
    }
  }

  Widget _buildGameControls(GameProvider game) {
    // Controlla se tutti i giocatori con puntata hanno un risultato
    final playersWithBets = game.players.where((p) => p.currentBet > 0).toList();
    final allHaveResults = playersWithBets.isNotEmpty && 
        playersWithBets.every((p) => p.handResult != null);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'GAME CONTROLS',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          
          // Phase indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Phase: ${game.gamePhase.toUpperCase()}',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Fasi del gioco
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: game.gamePhase == 'waiting' ? () => game.startBettingPhase() : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('START BETS', style: GoogleFonts.orbitron(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: AppTheme.backgroundPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: game.gamePhase == 'betting' && playersWithBets.isNotEmpty
                      ? () => game.confirmBets() 
                      : null,
                  icon: const Icon(Icons.lock),
                  label: Text('LOCK BETS', style: GoogleFonts.orbitron(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: AppTheme.backgroundPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Pulsante payout finale
          ElevatedButton.icon(
            onPressed: game.gamePhase == 'playing' && allHaveResults
                ? () => _confirmAndDistribute(game)
                : null,
            icon: const Icon(Icons.payments),
            label: Text(
              allHaveResults ? 'DISTRIBUTE PAYOUTS' : 'SET ALL RESULTS FIRST',
              style: GoogleFonts.orbitron(fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: allHaveResults ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          // Nuovo round
          if (game.gamePhase == 'waiting' && game.players.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ready for new round',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _setAllResults(GameProvider game, String result) {
    for (final player in game.players) {
      if (player.currentBet > 0) {
        game.setPlayerResult(player.id, result);
      }
    }
  }
  
  void _confirmAndDistribute(GameProvider game) {
    // Calcola il totale dei payout
    int totalPayout = 0;
    for (final player in game.players) {
      if (player.handResult != null) {
        totalPayout += game.calculatePayout(player);
      }
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.payments, color: AppTheme.accentPrimary),
            const SizedBox(width: 8),
            Text(
              'Confirm Payouts',
              style: GoogleFonts.orbitron(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total payout to players:',
              style: GoogleFonts.roboto(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '\$$totalPayout',
              style: GoogleFonts.orbitron(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...game.players.where((p) => p.handResult != null).map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.name, style: GoogleFonts.roboto(color: AppTheme.textPrimary)),
                  Text(
                    '${p.handResult!.toUpperCase()} → \$${game.calculatePayout(p)}',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      color: _getResultColor(p.handResult!),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              game.distributeAllPayouts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
            ),
            child: Text('DISTRIBUTE', style: GoogleFonts.orbitron()),
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(GameProvider game, String defaultResult) {
    // Per semplicità, applica lo stesso risultato a tutti i giocatori
    final results = <String, String>{};
    for (final player in game.players) {
      results[player.id] = defaultResult;
    }
    game.distributePayouts(results);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Leave Table?',
          style: GoogleFonts.orbitron(color: AppTheme.textPrimary),
        ),
        content: Text(
          'This will disconnect all players and close the table.',
          style: GoogleFonts.roboto(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<NetworkService>().stopServer();
              context.read<GameProvider>().reset();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentSecondary,
            ),
            child: Text('Leave', style: GoogleFonts.orbitron()),
          ),
        ],
      ),
    );
  }
}
