import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/arrow_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/arrow_tile.dart';

class GameScreen extends StatefulWidget {
  final int initialLevel;
  final bool isZen;
  final GameStorage storage;

  const GameScreen({
    super.key,
    required this.initialLevel,
    this.isZen = false,
    required this.storage,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _engine;
  late int _currentLevel;
  String? _activeBooster;
  final Map<String, GlobalKey<ArrowTileWidgetState>> _tileKeys = {};

  int _comboCount = 0;
  String? _floatingComboText;
  bool _isAnimatingMove = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel;
    SoundService().init();
    _startLevel(_currentLevel);
  }

  MapShape _getShapeForLevel(int level) {
    if (widget.isZen) {
      const shapes = MapShape.values;
      return shapes[level % shapes.length];
    }
    final group = ((level - 1) ~/ 5) % 4;
    switch (group) {
      case 0:
        return MapShape.square;
      case 1:
        return MapShape.cross;
      case 2:
        return MapShape.diamond;
      case 3:
        return MapShape.donut;
      default:
        return MapShape.square;
    }
  }

  String _getShapeLabel(MapShape shape) {
    switch (shape) {
      case MapShape.square:
        return 'Square Grid ⏹️';
      case MapShape.cross:
        return 'Cross Maze ✝️';
      case MapShape.diamond:
        return 'Diamond Arena 💎';
      case MapShape.donut:
        return 'Hollow Donut 🍩';
    }
  }

  // --- Refined Modern Atmosphere Gradients ---
  LinearGradient _getWorldGradient(int level) {
    final world = ((level - 1) ~/ 8) % 4;
    switch (world) {
      case 0: // Midnight Obsidian
        return const LinearGradient(
          colors: [Color(0xFF0B0F19), Color(0xFF111827), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 1: // Royal Indigo
        return const LinearGradient(
          colors: [Color(0xFF0A0F24), Color(0xFF141B3B), Color(0xFF1E1B4B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 2: // Nordic Ice
        return const LinearGradient(
          colors: [Color(0xFF071B2F), Color(0xFF0C2D48), Color(0xFF145DA0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 3: // Cyber Jade
        return const LinearGradient(
          colors: [Color(0xFF021B16), Color(0xFF042E25), Color(0xFF064E3B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF0B0F19), Color(0xFF111827)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  void _startLevel(int level) {
    _tileKeys.clear();
    _activeBooster = null;
    _comboCount = 0;
    _floatingComboText = null;
    _isAnimatingMove = false;

    final shape = _getShapeForLevel(level);
    final size = level < 6 ? 5 : (level < 14 ? 6 : 7);
    final obstacles = (level / 6).floor().clamp(0, 3);
    // Collectible Bonus Stars appear every 3rd level!
    final withBonusStars = (level >= 3 && level % 3 == 0);

    _engine = GameEngine(size: size, maxLives: 3, currentShape: shape);
    _engine.generateLevel(
      levelSize: size,
      shape: shape,
      obstacleCount: obstacles,
      withBonusStars: withBonusStars,
    );

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final item = _engine.grid[r][c];
        if (item != null) {
          _tileKeys[item.id] = GlobalKey<ArrowTileWidgetState>();
        }
      }
    }
    setState(() {});
  }

  void _showFloatingMessage(String text) {
    setState(() {
      _floatingComboText = text;
    });

    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) {
        setState(() {
          _floatingComboText = null;
        });
      }
    });
  }

  Future<void> _handleCellTap(int r, int c) async {
    if (_isAnimatingMove) return;
    if (_engine.lives <= 0 && !widget.isZen) return;

    final item = _engine.grid[r][c];
    if (item == null || item.type == TileType.voidCell || item.type == TileType.bonusStar) return;

    // BOOSTER: HAMMER
    if (_activeBooster == 'hammer') {
      if (widget.storage.useBooster('hammer')) {
        SoundService().playHammer();
        setState(() {
          _engine.smashTile(r, c);
          _activeBooster = null;
        });
        _checkWin();
      } else {
        _showToast('Need 50 Coins for Hammer!');
      }
      return;
    }

    // BOOSTER: ROTATE
    if (_activeBooster == 'rotate') {
      if (item.type == TileType.arrow) {
        SoundService().playSuccess(0);
        setState(() {
          _engine.rotateTile(item);
          _activeBooster = null;
        });
      }
      return;
    }

    // NORMAL ARROW TAP
    if (item.type == TileType.arrow) {
      _engine.hintTileId = null;
      final check = _engine.checkPath(item);

      if (check.isClear) {
        // --- 1. CORRECT MOVE (JUICY & SATISFYING) ---
        _isAnimatingMove = true;
        _comboCount++;

        // Bonus Star Collected along flight path!
        if (check.collectedStars.isNotEmpty) {
          final bonusCoins = check.collectedStars.length * 10;
          widget.storage.coins += bonusCoins;
          widget.storage.save();
          SoundService().playStarCollect();
          _showFloatingMessage('⭐ STAR BONUS! +$bonusCoins 🪙');
        } else {
          // Melodic Pentatonic Combo Pop!
          SoundService().playSuccess(_comboCount);
          if (_comboCount >= 2) {
            String tag = 'GREAT! x$_comboCount';
            if (_comboCount == 3) tag = 'AWESOME! x3 🔥';
            if (_comboCount == 4) tag = 'BRILLIANT! x4 ⚡';
            if (_comboCount >= 5) tag = 'UNSTOPPABLE! x$_comboCount 🚀';
            _showFloatingMessage(tag);
          }
        }

        // Rocket zoom animation
        await _tileKeys[item.id]?.currentState?.triggerFlyOut();

        setState(() {
          _engine.removeTile(item, collectedStars: check.collectedStars);
          _isAnimatingMove = false;
        });
        _checkWin();

      } else {
        // --- 2. BLOCKED MOVE (NO RED COLOR - SOFT TACTILE RECOIL) ---
        _comboCount = 0; // Reset streak
        SoundService().playBlocked(); // Soft wooden tap

        // Trigger spring recoil shake without any red tint!
        _tileKeys[item.id]?.currentState?.triggerShake();

        if (!widget.isZen) {
          setState(() {
            _engine.lives--;
          });

          if (_engine.lives <= 0) {
            _showGameOverDialog();
          }
        }
      }
    }
  }

  void _checkWin() {
    if (_engine.isLevelComplete) {
      SoundService().playWin();
      final stars = _engine.calculateStars();
      final reward = stars * 15;

      if (!widget.isZen) {
        widget.storage.completeLevel(_currentLevel, stars, reward);
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Text('🎉 Level Cleared!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⭐' * stars + '☆' * (3 - stars), style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text('+$reward Coins Earned!', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentLevel++;
                  _startLevel(_currentLevel);
                });
              },
              child: const Text('Next Level ➔', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text('💔 Out of Lives!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        content: const Text(
          'Blocked path collisions cost lives. Plan ahead!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: () {
              if (widget.storage.coins >= 50) {
                widget.storage.coins -= 50;
                widget.storage.save();
                setState(() {
                  _engine.lives = _engine.maxLives;
                });
                Navigator.pop(context);
              } else {
                _showToast('Need 50 coins to revive!');
              }
            },
            child: const Text('❤️ Revive (50 🪙)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _startLevel(_currentLevel);
              });
            },
            child: const Text('Retry Level', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1F2937),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shapeLabel = _getShapeLabel(_engine.currentShape);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _getWorldGradient(_currentLevel),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              children: [
                // Top HUD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          widget.isZen ? 'Zen #$_currentLevel' : 'Level $_currentLevel',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        Text(
                          shapeLabel,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    widget.isZen
                        ? const Text('🧘 Zen', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold))
                        : Row(
                            children: List.generate(
                              _engine.maxLives,
                              (i) => Text(
                                i < _engine.lives ? '❤️' : '🖤',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                  ],
                ),

                // Floating Banner for Combos & Star Bonuses
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _floatingComboText != null ? 36 : 8,
                  alignment: Alignment.center,
                  child: _floatingComboText != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                blurRadius: 12,
                              )
                            ],
                          ),
                          child: Text(
                            _floatingComboText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const Spacer(),

                // Board Arena
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
                          blurRadius: 24,
                        )
                      ],
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _engine.size,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _engine.size * _engine.size,
                      itemBuilder: (context, index) {
                        final r = index ~/ _engine.size;
                        final c = index % _engine.size;
                        final tile = _engine.grid[r][c];

                        if (tile == null) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }

                        return ArrowTileWidget(
                          key: _tileKeys[tile.id],
                          tile: tile,
                          isHint: tile.id == _engine.hintTileId,
                          onTap: () => _handleCellTap(r, c),
                        );
                      },
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Boosters Tray
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBoosterBtn(
                        icon: '🔨',
                        label: 'Smash',
                        count: widget.storage.boosters['hammer'] ?? 0,
                        isActive: _activeBooster == 'hammer',
                        onTap: () {
                          setState(() {
                            _activeBooster = _activeBooster == 'hammer' ? null : 'hammer';
                          });
                        },
                      ),
                      _buildBoosterBtn(
                        icon: '🔄',
                        label: 'Rotate',
                        count: 99,
                        isActive: _activeBooster == 'rotate',
                        onTap: () {
                          setState(() {
                            _activeBooster = _activeBooster == 'rotate' ? null : 'rotate';
                          });
                        },
                      ),
                      _buildBoosterBtn(
                        icon: '💡',
                        label: 'Hint',
                        count: widget.storage.boosters['hint'] ?? 0,
                        isActive: false,
                        onTap: () {
                          final free = _engine.findFreeArrow();
                          if (free != null) {
                            if (widget.storage.useBooster('hint')) {
                              SoundService().playSuccess(0);
                              setState(() {
                                _engine.hintTileId = free.id;
                              });
                            } else {
                              _showToast('Need 30 Coins for Hint!');
                            }
                          }
                        },
                      ),
                      _buildBoosterBtn(
                        icon: '↩️',
                        label: 'Undo',
                        count: widget.storage.boosters['undo'] ?? 0,
                        isActive: false,
                        onTap: () {
                          if (widget.storage.useBooster('undo')) {
                            setState(() {
                              _engine.undo();
                            });
                          } else {
                            _showToast('Need 20 Coins to Undo!');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoosterBtn({
    required String icon,
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF59E0B).withValues(alpha: 0.25) : const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? const Color(0xFFF59E0B) : Colors.white12,
                width: isActive ? 2.0 : 1.0,
              ),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }
}
