import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../info/info_screen.dart';
import 'models/falling_word.dart';
import 'widgets/falling_word_chip.dart';
import 'widgets/neon_orb.dart';

class TypingGameScreen extends StatefulWidget {
  const TypingGameScreen({super.key});

  @override
  State<TypingGameScreen> createState() => _TypingGameScreenState();
}

class _TypingGameScreenState extends State<TypingGameScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  final List<FallingWord> _words = [];
  final Random _random = Random();

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _score = 0;
  int _lives = 3;
  int _level = 1;
  double _speedMultiplier = 1.0;
  int _bestScore = 0;
  int _bestLevel = 1;
  double _spawnAccumulator = 0;
  bool _isRunning = false;
  bool _isGameOver = false;
  String _lastHitWord = '';

  static const List<String> _wordPool = [
    'flow',
    'swift',
    'neon',
    'pulse',
    'pixel',
    'laser',
    'shadow',
    'orbit',
    'flare',
    'nova',
    'spark',
    'shift',
    'fusion',
    'hyper',
    'ghost',
    'blink',
    'cyber',
    'focus',
    'rapid',
    'speed',
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadBestStats();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBestStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('best_score') ?? 0;
      _bestLevel = prefs.getInt('best_level') ?? 1;
    });
  }

  Future<void> _saveBestStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', _bestScore);
    await prefs.setInt('best_level', _bestLevel);
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _lives = 3;
      _level = 1;
      _speedMultiplier = 1.0;
      _words.clear();
      _spawnAccumulator = 0;
      _lastElapsed = Duration.zero;
      _isRunning = true;
      _isGameOver = false;
      _lastHitWord = '';
      _controller.clear();
    });
    _ticker.start();
    _focusNode.requestFocus();
  }

  void _endGame() {
    setState(() {
      _isRunning = false;
      _isGameOver = true;
      _words.clear();
    });
    _ticker.stop();
  }

  void _onTick(Duration elapsed) {
    if (!_isRunning) return;

    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;

    setState(() {
      // Update positions.
      for (final word in _words) {
        word.y += word.speed * dt;
      }

      // Handle words that reached the bottom.
      _words.removeWhere((word) {
        if (word.y >= 1.0) {
          _lives -= 1;
          if (_lives <= 0) {
            _endGame();
          }
          return true;
        }
        return false;
      });

      // Spawn new words based on time and level.
      _spawnAccumulator += dt;
      final spawnInterval = _currentSpawnInterval();
      while (_spawnAccumulator >= spawnInterval && _words.length < 6) {
        _spawnAccumulator -= spawnInterval;
        _spawnWord();
      }
    });
  }

  double _currentSpawnInterval() {
    // Faster spawning with higher levels.
    // Clamp to reasonable range.
    final base = 1.2;
    final factor = 0.12 * (_level - 1);
    return (base - factor).clamp(0.45, 1.2);
  }

  double _wordSpeed() {
    // Start fairly slow and scale up with level and per-word multiplier.
    final base = 0.08; // very slow at level 1
    final levelBoost = (_level - 1) * 0.018;
    final randomJitter = _random.nextDouble() * 0.03;
    final speed = (base + levelBoost + randomJitter) * _speedMultiplier;
    return speed.clamp(0.06, 0.8);
  }

  void _spawnWord() {
    final text = _wordPool[_random.nextInt(_wordPool.length)];
    final x = _random.nextDouble().clamp(0.1, 0.9);
    _words.add(FallingWord(text: text, x: x, y: -0.1, speed: _wordSpeed()));
  }

  void _onInputChanged(String value) {
    if (value.isEmpty || !_isRunning) return;

    final matchIndex = _words.indexWhere((w) => w.text.toLowerCase() == value.toLowerCase());
    if (matchIndex != -1) {
      final hitWord = _words[matchIndex];
      setState(() {
        _score += 10 + hitWord.text.length;
        _lastHitWord = hitWord.text;
        _words.removeAt(matchIndex);

        // Level up every 150 points.
        final newLevel = (_score ~/ 150) + 1;
        if (newLevel != _level) {
          _level = newLevel.clamp(1, 9);
        }

        // Update best stats if beaten.
        if (_score > _bestScore) {
          _bestScore = _score;
        }
        if (_level > _bestLevel) {
          _bestLevel = _level;
        }

        // Gradually increase falling speed with each successful word.
        _speedMultiplier = (_speedMultiplier + 0.05).clamp(1.0, 2.5);
        _saveBestStats();
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        _buildGlowOrbs(),
                        _buildPlayfield(),
                        if (!_isRunning) _buildOverlay(),
                      ],
                    ),
                  ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TypeRush',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'React fast. Stay in the zone.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatChip(label: 'Score', value: '$_score', color: const Color(0xFF22D3EE)),
                  const SizedBox(width: 8),
                  _buildStatChip(label: 'Lvl', value: '$_level', color: const Color(0xFF34D399)),
                  IconButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const InfoScreen()));
                    },
                    icon: const Icon(Icons.info_outline_rounded),
                    color: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                    tooltip: 'Info & Policies',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Best: $_bestScore  ·  L$_bestLevel',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0.06)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 1.1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 0.6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label.toLowerCase().startsWith('score')
                ? Icons.bolt_rounded
                : Icons.stacked_bar_chart_rounded,
            size: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLives() {
    return Row(
      children: List.generate(3, (index) {
        final active = index < _lives;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
          child: Icon(
            Icons.favorite_rounded,
            size: 18,
            color: active ? const Color(0xFFFB7185) : Colors.white24,
          ),
        );
      }),
    );
  }

  double _wordAlignX(double x) {
    final mapped = x * 2 - 1; // 0..1 -> -1..1
    return mapped.clamp(-0.8, 0.8).toDouble();
  }

  Widget _buildHealthPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.32),
        border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.9), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFB7185).withValues(alpha: 0.5),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'HP',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _buildLives(),
        ],
      ),
    );
  }

  Widget _buildGlowOrbs() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: NeonOrb(size: 220, color: const Color(0xFF22D3EE).withValues(alpha: 0.7)),
          ),
          Positioned(
            bottom: -120,
            right: -80,
            child: NeonOrb(size: 300, color: const Color(0xFF7C3AED).withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayfield() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.02), Colors.white.withValues(alpha: 0.04)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x88000000), blurRadius: 30, offset: Offset(0, 20)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(top: 10, right: 12, child: _buildHealthPanel()),
                // Subtle scanline / divider at bottom (fail line).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: height * 0.02,
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: 0.0),
                          Colors.red.withValues(alpha: 0.5),
                          Colors.red.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Falling words.
                ..._words.map((w) {
                  final top = w.y * height;
                  return Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment(_wordAlignX(w.x), 0),
                      child: FallingWordChip(text: w.text),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlay() {
    final title = _isGameOver ? 'Game Over' : 'TypeRush';
    final subtitle = _isGameOver
        ? 'Final score: $_score'
        : 'Words will start falling. Type them fully to clear them before they land.';

    return Container(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF020617).withValues(alpha: 0.92),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            if (_lastHitWord.isNotEmpty && _isGameOver) ...[
              const SizedBox(height: 8),
              Text(
                'Last word: $_lastHitWord',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  elevation: 10,
                  shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.7),
                ),
                child: Text(
                  _isGameOver ? 'Play Again' : 'Start',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isActive = _isRunning && !_isGameOver;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastHitWord.isNotEmpty && isActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: Colors.yellow.shade400),
                  const SizedBox(width: 6),
                  Text(
                    'Nice! "$_lastHitWord"',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF22D3EE).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.3,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.keyboard_rounded, size: 22, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onInputChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: _isRunning ? 'Type a word...' : 'Tap Start, then type what you see',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                    ),
                    textInputAction: TextInputAction.none,
                    enabled: _isRunning,
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _isRunning
                      ? Container(
                          key: const ValueKey('live'),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : IconButton(
                          key: const ValueKey('play'),
                          onPressed: _startGame,
                          icon: const Icon(Icons.play_arrow_rounded),
                          color: Colors.white,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
