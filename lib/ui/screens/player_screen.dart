import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_theme.dart';
import '../../services/services.dart';
import '../../models/models.dart';

/// Schermata del Player - Giocatore al tavolo
class PlayerScreen extends StatefulWidget {
  final String serverAddress;
  final String playerName;

  const PlayerScreen({
    super.key,
    required this.serverAddress,
    required this.playerName,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isConnecting = true;
  String? _error;
  int _currentBet = 0;
  int? _selectedChip;
  bool _hasSubmittedResult = false;
  String? _splitHandResult; // Per tracciare il risultato della seconda mano

  @override
  void initState() {
    super.initState();
    _connectToServer();
    
    // Ascolta se il player viene espulso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().addListener(_checkIfKicked);
    });
  }
  
  @override
  void dispose() {
    context.read<GameProvider>().removeListener(_checkIfKicked);
    super.dispose();
  }
  
  void _checkIfKicked() {
    final game = context.read<GameProvider>();
    if (game.wasKicked && mounted) {
      game.clearKickedFlag();
      // Torna alla home e mostra messaggio
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.exit_to_app, color: AppTheme.accentSecondary),
              const SizedBox(width: 12),
              Text(
                'You have been removed from the table',
                style: GoogleFonts.roboto(color: AppTheme.textPrimary),
              ),
            ],
          ),
          backgroundColor: AppTheme.backgroundCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _connectToServer() async {
    final gameProvider = context.read<GameProvider>();
    
    try {
      final success = await gameProvider.setupAsPlayer(
        widget.serverAddress,
        widget.playerName,
      );
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
          if (!success) {
            _error = 'Failed to connect to server';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }

  void _addChip(int value) {
    final game = context.read<GameProvider>();
    if (game.myBalance >= _currentBet + value && game.gamePhase == 'betting') {
      setState(() {
        _currentBet += value;
        _selectedChip = value;
      });
      
      // Animate feedback
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _selectedChip = null;
          });
        }
      });
    }
  }

  void _clearBet() {
    setState(() {
      _currentBet = 0;
    });
  }

  void _placeBet() {
    if (_currentBet > 0) {
      context.read<GameProvider>().placeBet(_currentBet);
      setState(() {
        _currentBet = 0;
      });
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
            Icon(Icons.casino, color: AppTheme.accentPrimary),
            const SizedBox(width: 8),
            Text(
              widget.playerName.toUpperCase(),
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
      body: _isConnecting
          ? _buildConnecting()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildConnecting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.accentPrimary),
          const SizedBox(height: 24),
          Text(
            'Connecting to table...',
            style: GoogleFonts.roboto(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.serverAddress,
            style: GoogleFonts.roboto(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
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
            'Connection Failed',
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
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        return Column(
          children: [
            // Status bar
            _buildStatusBar(game),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Balance display
                    _buildBalanceCard(game),
                    
                    const SizedBox(height: 20),
                    
                    // Betting area
                    _buildBettingArea(game),
                    
                    const SizedBox(height: 20),
                    
                    // Fase playing: mostra azioni o loading
                    if (game.gamePhase == 'playing')
                      game.hasSubmittedResult && (!game.myHasSplit || game.mySplitResult != null)
                          ? _buildWaitingForNextRound(game)
                          : _buildBlackjackActions(game),
                    
                    // Chips selection - solo in fase betting
                    if (game.gamePhase == 'betting') ...[
                      _buildChipsSelection(game),
                      const SizedBox(height: 20),
                      _buildActionButtons(game),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBar(GameProvider game) {
    Color phaseColor;
    String phaseText;
    IconData phaseIcon;
    
    switch (game.gamePhase) {
      case 'betting':
        phaseColor = AppTheme.accentPrimary;
        phaseText = 'PLACE YOUR BETS';
        phaseIcon = Icons.casino;
        break;
      case 'playing':
        phaseColor = const Color(0xFFFFD700);
        phaseText = 'BETS LOCKED';
        phaseIcon = Icons.lock;
        break;
      case 'payout':
        phaseColor = Colors.purple;
        phaseText = 'PAYOUT';
        phaseIcon = Icons.attach_money;
        break;
      default:
        phaseColor = AppTheme.textSecondary;
        phaseText = 'WAITING...';
        phaseIcon = Icons.hourglass_empty;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: phaseColor.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(phaseIcon, color: phaseColor, size: 20)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: phaseColor.withValues(alpha: 0.3)),
          const SizedBox(width: 8),
          Text(
            phaseText,
            style: GoogleFonts.orbitron(
              color: phaseColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(GameProvider game) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.backgroundCard,
            AppTheme.backgroundCard.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'YOUR BALANCE',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppTheme.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${game.myBalance}',
            style: GoogleFonts.orbitron(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentPrimary,
            ),
          ).animate().fadeIn().scale(delay: 200.ms),
          
          if (game.myCurrentBet > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Active Bet: \$${game.myCurrentBet}',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  color: AppTheme.accentSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBettingArea(GameProvider game) {
    // Usa il bet locale durante la selezione, altrimenti il bet confermato dal provider
    final displayBet = _currentBet > 0 ? _currentBet : game.myCurrentBet;
    final hasBet = displayBet > 0;
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasBet 
              ? AppTheme.accentPrimary 
              : AppTheme.borderColor,
          width: hasBet ? 2 : 1,
        ),
      ),
      child: Center(
        child: hasBet
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    game.gamePhase == 'playing' ? 'YOUR BET' : 'BETTING',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$$displayBet',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ).animate().fadeIn().scale(),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 32,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.gamePhase == 'betting' 
                        ? 'Tap chips to bet' 
                        : 'Waiting for next round...',
                    style: GoogleFonts.roboto(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChipsSelection(GameProvider game) {
    final canBet = game.gamePhase == 'betting';
    
    return Column(
      children: [
        Text(
          'SELECT CHIPS',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: AppTheme.textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: GameChips.values.map((chip) {
            final canAfford = game.myBalance >= _currentBet + chip.value;
            final isEnabled = canBet && canAfford;
            final isSelected = _selectedChip == chip.value;
            
            return _buildChip(chip, isEnabled, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(ChipModel chip, bool isEnabled, bool isSelected) {
    // Calcola se il colore è chiaro per usare testo scuro
    final isLightColor = chip.color.computeLuminance() > 0.5;
    final textColor = isLightColor ? Colors.black : Colors.white;
    final disabledTextColor = isLightColor ? Colors.black45 : Colors.white54;
    
    return GestureDetector(
      onTap: isEnabled ? () => _addChip(chip.value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? chip.color : chip.color.withValues(alpha: 0.3),
          border: Border.all(
            color: isEnabled 
                ? chip.borderColor 
                : chip.borderColor.withValues(alpha: 0.3),
            width: 4,
          ),
          boxShadow: isEnabled && !isSelected
              ? [
                  BoxShadow(
                    color: chip.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        transform: isSelected 
            ? (Matrix4.identity()..scale(1.1)) 
            : Matrix4.identity(),
        child: Center(
          child: Text(
            chip.label,
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEnabled ? textColor : disabledTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(GameProvider game) {
    final canBet = game.gamePhase == 'betting';
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canBet && _currentBet > 0 ? _clearBet : null,
            icon: const Icon(Icons.clear),
            label: Text('CLEAR', style: GoogleFonts.orbitron(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentSecondary,
              side: BorderSide(color: AppTheme.accentSecondary),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: canBet && _currentBet > 0 ? _placeBet : null,
            icon: const Icon(Icons.check),
            label: Text('PLACE BET', style: GoogleFonts.orbitron()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.backgroundPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Widget per le azioni Blackjack (Double, Split, Insurance)
  Widget _buildBlackjackActions(GameProvider game) {
    final canDouble = game.myBalance >= game.myCurrentBet;
    final canSplit = game.myBalance >= game.myCurrentBet; // Semplificato
    final canInsurance = game.myBalance >= (game.myCurrentBet / 2).round();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: const Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text(
                'BLACKJACK ACTIONS',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Pulsanti azioni
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'DOUBLE',
                  icon: Icons.add_circle,
                  color: Colors.orange,
                  cost: game.myCurrentBet,
                  enabled: canDouble,
                  onTap: () {
                    game.doubleDown();
                    _showActionConfirmation('Double Down! Bet doubled.');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'SPLIT',
                  icon: Icons.call_split,
                  color: Colors.purple,
                  cost: game.myCurrentBet,
                  enabled: canSplit,
                  onTap: () {
                    game.split();
                    _showActionConfirmation('Cards Split! Playing two hands.');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: 'INSURANCE',
                  icon: Icons.shield,
                  color: Colors.blue,
                  cost: (game.myCurrentBet / 2).round(),
                  enabled: canInsurance,
                  onTap: () {
                    game.insurance();
                    _showActionConfirmation('Insurance taken!');
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Info attuale
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Your Bet', '\$${game.myCurrentBet}'),
                Container(width: 1, height: 30, color: AppTheme.borderColor),
                _buildInfoItem('Balance', '\$${game.myBalance}'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 12),
          
          // Sezione risultati
          Row(
            children: [
              Icon(Icons.emoji_events, color: AppTheme.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'DECLARE RESULT',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Pulsanti risultati
          _buildResultButtons(game),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required int cost,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? color : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: enabled ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: enabled ? color : Colors.grey,
              ),
            ),
            Text(
              '\$$cost',
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: enabled ? color.withValues(alpha: 0.7) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Widget con i pulsanti per dichiarare il risultato
  Widget _buildResultButtons(GameProvider game) {
    // Se ha fatto split, mostra due sezioni separate
    if (game.myHasSplit) {
      return Column(
        children: [
          // MANO 1
          _buildHandResultSection(
            game: game,
            title: 'HAND 1 (Main)',
            currentResult: game.myHandResult,
            onResultSelected: (result) => game.setMyResult(result),
            isCompleted: game.myHandResult != null,
          ),
          const SizedBox(height: 16),
          // MANO 2 (Split)
          _buildHandResultSection(
            game: game,
            title: 'HAND 2 (Split)',
            currentResult: game.mySplitResult,
            onResultSelected: (result) => game.setMySplitResult(result),
            isCompleted: game.mySplitResult != null,
            isSplit: true,
          ),
        ],
      );
    }
    
    // Senza split, mostra i pulsanti normali
    return Column(
      children: [
        // Prima riga: WIN, BLACKJACK, PUSH
        Row(
          children: [
            Expanded(
              child: _buildResultButton(
                label: 'WIN',
                color: AppTheme.accentPrimary,
                icon: Icons.check_circle,
                onTap: () => game.setMyResult('win'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResultButton(
                label: 'BLACKJACK',
                color: const Color(0xFFFFD700),
                icon: Icons.star,
                onTap: () => game.setMyResult('blackjack'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResultButton(
                label: 'PUSH',
                color: Colors.grey,
                icon: Icons.horizontal_rule,
                onTap: () => game.setMyResult('push'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Seconda riga: LOSE, SURRENDER
        Row(
          children: [
            Expanded(
              child: _buildResultButton(
                label: 'LOSE',
                color: AppTheme.accentSecondary,
                icon: Icons.cancel,
                onTap: () => game.setMyResult('lose'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResultButton(
                label: 'SURRENDER',
                color: Colors.orange,
                icon: Icons.flag,
                onTap: () => game.setMyResult('surrender'),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()), // Spacer
          ],
        ),
      ],
    );
  }
  
  Widget _buildHandResultSection({
    required GameProvider game,
    required String title,
    required String? currentResult,
    required Function(String) onResultSelected,
    required bool isCompleted,
    bool isSplit = false,
  }) {
    final borderColor = isSplit ? Colors.purple : const Color(0xFFFFD700);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppTheme.accentPrimary : borderColor.withValues(alpha: 0.5),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSplit ? Icons.call_split : Icons.style,
                color: borderColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentResult!.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentPrimary,
                    ),
                  ),
                ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildSmallResultButton('WIN', AppTheme.accentPrimary, () => onResultSelected('win')),
                _buildSmallResultButton('BJ', const Color(0xFFFFD700), () => onResultSelected('blackjack')),
                _buildSmallResultButton('PUSH', Colors.grey, () => onResultSelected('push')),
                _buildSmallResultButton('LOSE', AppTheme.accentSecondary, () => onResultSelected('lose')),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSmallResultButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
  
  /// Widget di attesa per il prossimo round
  Widget _buildWaitingForNextRound(GameProvider game) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: AppTheme.accentPrimary,
            strokeWidth: 3,
          ).animate(onPlay: (c) => c.repeat()).fadeIn(),
          const SizedBox(height: 20),
          Text(
            'RESULT SUBMITTED',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for the dealer to start a new round...',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Mostra i risultati dichiarati
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildResultChip('Main: ${game.myHandResult?.toUpperCase() ?? "-"}'),
              if (game.myHasSplit) ...[
                const SizedBox(width: 12),
                _buildResultChip('Split: ${game.mySplitResult?.toUpperCase() ?? "-"}', isSplit: true),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultChip(String text, {bool isSplit = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isSplit ? Colors.purple : AppTheme.accentPrimary).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.orbitron(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSplit ? Colors.purple : AppTheme.accentPrimary,
        ),
      ),
    );
  }
  
  Widget _buildResultButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
  
  void _showActionConfirmation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.accentPrimary),
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.roboto(color: AppTheme.textPrimary),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
          'You will disconnect from the table.',
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
              context.read<NetworkService>().disconnect();
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
