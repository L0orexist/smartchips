import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import 'banker_screen.dart';
import 'player_screen.dart';
import 'qr_scanner_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CHIP DATA - Valori e colori delle fiches
// ═══════════════════════════════════════════════════════════════════════════════

class ChipData {
  final int value;
  final Color color;
  final Color borderColor;

  const ChipData({
    required this.value,
    required this.color,
    required this.borderColor,
  });
}

const List<ChipData> chipValues = [
  ChipData(value: 1, color: Color(0xFFFFFFFF), borderColor: Color(0xFFCCCCCC)),
  ChipData(value: 5, color: Color(0xFFFF0055), borderColor: Color(0xFFCC0044)),
  ChipData(value: 10, color: Color(0xFF0088FF), borderColor: Color(0xFF0066CC)),
  ChipData(value: 25, color: Color(0xFF00FF9D), borderColor: Color(0xFF00CC7D)),
  ChipData(value: 100, color: Color(0xFF000000), borderColor: Color(0xFF333333)),
  ChipData(value: 500, color: Color(0xFF8B00FF), borderColor: Color(0xFF6600CC)),
];

// ═══════════════════════════════════════════════════════════════════════════════
// HOME SCREEN - Role Selector
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _showNameInput = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  // Animazione glow del logo
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 20, end: 40).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _nameController.dispose();
    _ipController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo con glow
                _buildLogo(),

                const SizedBox(height: 40),

                // Selezione ruolo o input nome
                _showNameInput ? _buildNameInput() : _buildRoleSelection(),

                const SizedBox(height: 40),
                
                // Version tag
                Text(
                  'UI PROTOTYPE v1.0 • 2025 Casino Edition',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCasinoGridBackground() {
    return CustomPaint(
      painter: _GridPatternPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildFallingChips() {
    final screenSize = MediaQuery.of(context).size;
    final random = Random(42); // Seed fisso per consistenza

    return Stack(
      children: List.generate(chipValues.length, (index) {
        final chip = chipValues[index];
        final startX = random.nextDouble() * screenSize.width;
        final duration = 15 + random.nextDouble() * 10;
        final delay = index * 2.0;

        return _FallingChip(
          chip: chip,
          startX: startX,
          screenHeight: screenSize.height,
          duration: duration,
          delay: delay,
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLogo() {
    return Column(
      children: [
        // Titolo con sparkles
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: AppTheme.accentPrimary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SMARTCHIPS',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentPrimary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: AppTheme.accentPrimary,
                  ),
                ],
              ),
            );
          },
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, end: 0),

        const SizedBox(height: 16),

        // Sottotitolo
        Text(
          'LOCAL WIFI BLACKJACK MANAGER',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            letterSpacing: 6,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE SELECTION CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRoleSelection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 300.0 : screenWidth * 0.85;

    return Column(
      children: [
        // BANKER BUTTON
        _buildSimpleRoleButton(
          width: cardWidth,
          icon: Icons.workspace_premium,
          iconColor: const Color(0xFFFFD700),
          title: 'BANKER',
          description: 'Host the table.\nControl bets and payouts.',
          statusText: 'Creates the game server',
          onTap: () {
            debugPrint('BANKER TAPPED!');
            _handleBankerSelect();
          },
        ),
        
        const SizedBox(height: 20),
        
        // PLAYER BUTTON
        _buildSimpleRoleButton(
          width: cardWidth,
          icon: Icons.person,
          iconColor: AppTheme.accentPrimary,
          title: 'PLAYER',
          description: 'Join a table.\nPlace bets and win big.',
          statusText: 'Connects to banker',
          onTap: () {
            debugPrint('PLAYER TAPPED!');
            _handlePlayerSelect();
          },
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildSimpleRoleButton({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String statusText,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.backgroundCard,
          foregroundColor: AppTheme.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
          ),
          elevation: 8,
          shadowColor: iconColor.withValues(alpha: 0.3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.2),
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankerCard() {
    const goldColor = Color(0xFFFFD700);

    return _RoleCard(
      icon: Icons.workspace_premium,
      iconColor: goldColor,
      title: 'BANKER',
      description: 'Host the table. Control bets and payouts.',
      statusText: 'Creates the game server',
      statusColor: goldColor,
      gradientColor: goldColor,
      onTap: _handleBankerSelect,
    );
  }

  Widget _buildPlayerCard() {
    return _RoleCard(
      icon: Icons.person,
      iconColor: AppTheme.accentPrimary,
      title: 'PLAYER',
      description: 'Join a table. Place bets and win big.',
      statusText: 'Connects to banker',
      statusColor: AppTheme.accentPrimary,
      gradientColor: AppTheme.accentPrimary,
      onTap: _handlePlayerSelect,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYER JOIN PANEL
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNameInput() {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, color: AppTheme.accentPrimary, size: 24),
              const SizedBox(width: 8),
              Text(
                'JOIN TABLE',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Nome giocatore
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Your Name',
              labelStyle: GoogleFonts.roboto(color: AppTheme.textSecondary),
              hintText: 'Enter display name',
              hintStyle: GoogleFonts.roboto(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.accentPrimary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider con "OR"
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'CONNECT VIA',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.borderColor)),
            ],
          ),

          const SizedBox(height: 16),

          // Bottone Scan QR
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleScanQR,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.accentPrimary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: AppTheme.accentPrimary),
                    const SizedBox(width: 12),
                    Text(
                      'SCAN QR CODE',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Oppure inserisci IP
          Text(
            '— OR —',
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 12),

          // Input IP manuale
          TextField(
            controller: _ipController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppTheme.textPrimary,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              labelText: 'Server IP',
              labelStyle: GoogleFonts.roboto(color: AppTheme.textSecondary),
              hintText: '192.168.1.100:8080',
              hintStyle: GoogleFonts.roboto(
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
              ),
              prefixIcon: Icon(Icons.wifi, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.accentPrimary, width: 2),
              ),
            ),
            onSubmitted: (_) => _handleConnectWithIP(),
          ),

          const SizedBox(height: 20),

          // Bottoni azione
          Row(
            children: [
              // Back button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _showNameInput = false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'BACK',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Connect button
              Expanded(
                flex: 2,
                child: Material(
                  color: AppTheme.accentPrimary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _handleConnectWithIP,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'CONNECT',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.backgroundPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERSION TAG
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVersionTag() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'UI PROTOTYPE v1.0 • 2025 Casino Edition',
          style: GoogleFonts.orbitron(
            fontSize: 10,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
            letterSpacing: 1,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 1000.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleBankerSelect() {
    debugPrint('=== BANKER SELECT CALLED ===');
    // Naviga direttamente alla schermata Banker
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BankerScreen(),
      ),
    );
  }

  void _handlePlayerSelect() {
    setState(() => _showNameInput = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      _nameFocusNode.requestFocus();
    });
  }

  void _handleScanQR() async {
    final playerName = _nameController.text.trim().isEmpty
        ? 'Player'
        : _nameController.text.trim();

    // Apri scanner QR e ottieni l'indirizzo
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerScreen(),
      ),
    );
    
    if (result != null && result.isNotEmpty && mounted) {
      // Naviga alla schermata Player con l'indirizzo scansionato
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            serverAddress: result,
            playerName: playerName,
          ),
        ),
      );
    }
  }

  void _handleConnectWithIP() {
    final playerName = _nameController.text.trim().isEmpty
        ? 'Player'
        : _nameController.text.trim();
    final ip = _ipController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.accentSecondary),
              const SizedBox(width: 12),
              Text(
                'Please enter server IP or scan QR',
                style: GoogleFonts.roboto(color: AppTheme.textPrimary),
              ),
            ],
          ),
          backgroundColor: AppTheme.backgroundCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.accentSecondary.withValues(alpha: 0.5)),
          ),
        ),
      );
      return;
    }

    // Naviga alla schermata Player con IP inserito manualmente
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          serverAddress: ip,
          playerName: playerName,
        ),
      ),
    );
  }

  void _handlePlayerJoin() {
    _handleConnectWithIP();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ROLE CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String statusText;
  final Color statusColor;
  final Color gradientColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.statusText,
    required this.statusColor,
    required this.gradientColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: gradientColor.withValues(alpha: 0.3),
        highlightColor: gradientColor.withValues(alpha: 0.1),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.2),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PulsingDot(color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PULSING DOT
// ═══════════════════════════════════════════════════════════════════════════════

class _PulsingDot extends StatelessWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.3, 1.3),
          duration: 800.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 800.ms,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FALLING CHIP ANIMATION
// ═══════════════════════════════════════════════════════════════════════════════

class _FallingChip extends StatefulWidget {
  final ChipData chip;
  final double startX;
  final double screenHeight;
  final double duration;
  final double delay;

  const _FallingChip({
    required this.chip,
    required this.startX,
    required this.screenHeight,
    required this.duration,
    required this.delay,
  });

  @override
  State<_FallingChip> createState() => _FallingChipState();
}

class _FallingChipState extends State<_FallingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (widget.duration * 1000).toInt()),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: -100,
      end: widget.screenHeight + 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startX,
          top: _positionAnimation.value,
          child: Opacity(
            opacity: 0.3,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: _ChipWidget(chip: widget.chip),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHIP WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _ChipWidget extends StatelessWidget {
  final ChipData chip;

  const _ChipWidget({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: chip.color,
        border: Border.all(color: chip.borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: chip.color.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: chip.borderColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${chip.value}',
              style: GoogleFonts.orbitron(
                fontSize: chip.value >= 100 ? 10 : 14,
                fontWeight: FontWeight.bold,
                color: chip.color == const Color(0xFFFFFFFF) ||
                        chip.color == const Color(0xFF00FF9D)
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRID PATTERN PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const gridSize = 30.0;

    // Linee verticali
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Linee orizzontali
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
