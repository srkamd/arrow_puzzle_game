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

  @override
  void initState() {
    super.initState();
    // 1. Recoil & Shake Animation for Blocked Moves
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    // 2. Rocket Fly-Out Animation for Correct Moves
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _flyTranslateAnim = Tween<double>(begin: 0.0, end: 320.0).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.fastOutSlowIn),
    );
    _flyScaleAnim = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeIn),
    );
    _flyOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _flyController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  // Triggered when move is blocked
  void triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  // Triggered when move is correct
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

    // 2. WARP PORTAL (Blue or Orange Gate)
    if (widget.tile.type == TileType.portal) {
      final isPortalA = widget.tile.portalPairId == 1;
      final portalColor = isPortalA ? const Color(0xFF06B6D4) : const Color(0xFFF97316);

      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              portalColor.withValues(alpha: 0.9),
              portalColor.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
          border: Border.all(color: portalColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: portalColor.withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            isPortalA ? '🌀' : '🪐',
            style: const TextStyle(fontSize: 22),
          ),
        ),
      );
    }

    // 3. OBSTACLE ROCK
    if (widget.tile.type == TileType.obstacle) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF64748B), Color(0xFF334155)],
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

    // 4. ARROW TILE (With Elastic Shake and Rocket Zoom Fly-Out)
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnim, _flyController]),
      builder: (context, child) {
        // Forward impact + recoil offset for blocked
        double offsetX = 0.0;
        double offsetY = 0.0;

        if (_shakeController.isAnimating) {
          final progress = _shakeAnim.value;
          // Impact forward along heading vector, then elastic spring bounce
          final shakeDisplacement = (1.0 - progress) * 10.0 * sin(progress * pi * 5);
          offsetX = widget.tile.direction.dc * shakeDisplacement;
          offsetY = widget.tile.direction.dr * shakeDisplacement;
        }

        if (_isExiting) {
          offsetX = widget.tile.direction.dc * _flyTranslateAnim.value;
          offsetY = widget.tile.direction.dr * _flyTranslateAnim.value;
        }

        final currentScale = _isExiting ? _flyScaleAnim.value : 1.0;
        final currentOpacity = _isExiting ? _flyOpacityAnim.value : 1.0;

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.scale(
            scale: currentScale,
            child: Opacity(
              opacity: currentOpacity.clamp(0.0, 1.0),
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    gradient: widget.isHint
                        ? const LinearGradient(
                            colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.isHint
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      width: widget.isHint ? 2.5 : 1.2,
                    ),
                    boxShadow: widget.isHint
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                              blurRadius: 16,
                              spreadRadius: 2,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: widget.tile.direction.angleRadians / (2 * 3.14159265),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutBack,
                      child: Icon(
                        Icons.navigation_rounded,
                        size: 26,
                        color: widget.isHint
                            ? const Color(0xFF451A03)
                            : const Color(0xFF38BDF8),
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
