import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arrow_model.dart';

class ArrowTileWidget extends StatefulWidget {
  final GameTile tile;
  final bool isHint;
  final VoidCallback onTap;

  const ArrowTileWidget({
    super.key,
    required this.tile,
    required this.isHint,
    required this.onTap,
  });

  @override
  State<ArrowTileWidget> createState() => ArrowTileWidgetState();
}

class ArrowTileWidgetState extends State<ArrowTileWidget>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  late AnimationController _flyController;
  late Animation<double> _flyTranslateAnim;
  late Animation<double> _flyScaleAnim;
  late Animation<double> _flyOpacityAnim;

  bool _isExiting = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // 1. Elastic Recoil Animation for Blocked Moves
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    // 2. Juicy Rocket Fly-Out Animation for Correct Moves
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _flyTranslateAnim = Tween<double>(begin: 0.0, end: 340.0).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.fastOutSlowIn),
    );
    _flyScaleAnim = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeIn),
    );
    _flyOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _flyController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  // Triggered when move is blocked: Flashes RED and shakes!
  void triggerShake() {
    setState(() {
      _isError = true;
    });

    _shakeController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isError = false;
        });
      }
    });
  }

  // Triggered when move is correct: Rocket Zoom!
  Future<void> triggerFlyOut() async {
    setState(() {
      _isExiting = true;
    });
    await _flyController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // 1. VOID CUT-OUT (For Diamond, Cross, Donut shapes)
    if (widget.tile.type == TileType.voidCell) {
      return const SizedBox.shrink();
    }

    // 2. BONUS STAR ITEM (Arrows fly through to collect bonus coins!)
    if (widget.tile.type == TileType.bonusStar) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFF59E0B).withValues(alpha: 0.45),
              Colors.transparent,
            ],
          ),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '⭐',
            style: TextStyle(fontSize: 22),
          ),
        ),
      );
    }

    // 3. OBSTACLE ROCK (Blocks arrows until smashed with hammer)
    if (widget.tile.type == TileType.obstacle) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF475569), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🪨',
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      );
    }

    // 4. ARROW TILE (Vibrant Red on Error Shake, Cyan/Indigo on Normal)
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnim, _flyController]),
      builder: (context, child) {
        // Forward impact + recoil offset for blocked moves
        double offsetX = 0.0;
        double offsetY = 0.0;

        if (_shakeController.isAnimating) {
          final progress = _shakeAnim.value;
          final shakeDisplacement = (1.0 - progress) * 10.0 * sin(progress * pi * 4);
          offsetX = widget.tile.direction.dc * shakeDisplacement;
          offsetY = widget.tile.direction.dr * shakeDisplacement;
        }

        if (_isExiting) {
          offsetX = widget.tile.direction.dc * _flyTranslateAnim.value;
          offsetY = widget.tile.direction.dr * _flyTranslateAnim.value;
        }

        final currentScale = _isExiting ? _flyScaleAnim.value : 1.0;
        final currentOpacity = _isExiting ? _flyOpacityAnim.value : 1.0;

        // Decoration colors: Error Red vs Hint Gold vs Sleek Cyan/Indigo
        final Gradient gradient;
        final Color borderColor;
        final Color iconColor;
        final List<BoxShadow> shadows;

        if (_isError) {
          // RED FLASH WHILE SHAKING
          gradient = const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          borderColor = const Color(0xFFF87171);
          iconColor = Colors.white;
          shadows = [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.7),
              blurRadius: 16,
              spreadRadius: 2,
            )
          ];
        } else if (widget.isHint) {
          gradient = const LinearGradient(
            colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          borderColor = const Color(0xFFF59E0B);
          iconColor = const Color(0xFF451A03);
          shadows = [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
              blurRadius: 16,
              spreadRadius: 2,
            )
          ];
        } else {
          gradient = const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          borderColor = const Color(0xFF38BDF8).withValues(alpha: 0.45);
          iconColor = const Color(0xFF38BDF8);
          shadows = [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ];
        }

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.scale(
            scale: currentScale,
            child: Opacity(
              opacity: currentOpacity.clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: _isError ? 2.2 : (widget.isHint ? 2.5 : 1.4),
                    ),
                    boxShadow: shadows,
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: widget.tile.direction.angleRadians / (2 * 3.14159265),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutBack,
                      child: Icon(
                        Icons.navigation_rounded,
                        size: 26,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
