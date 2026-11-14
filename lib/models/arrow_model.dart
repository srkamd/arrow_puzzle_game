import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ArrowDirection { up, right, down, left }

enum TileType { arrow, obstacle, portal, voidCell }

enum MapShape { square, cross, diamond, donut }

extension ArrowDirectionExt on ArrowDirection {
  int get dr {
    switch (this) {
      case ArrowDirection.up:
        return -1;
      case ArrowDirection.down:
        return 1;
      case ArrowDirection.left:
      case ArrowDirection.right:
        return 0;
    }
  }

  int get dc {
    switch (this) {
      case ArrowDirection.left:
        return -1;
      case ArrowDirection.right:
        return 1;
      case ArrowDirection.up:
      case ArrowDirection.down:
        return 0;
    }
  }

  double get angleRadians {
    switch (this) {
      case ArrowDirection.up:
        return 0.0;
      case ArrowDirection.right:
        return math.pi / 2;
      case ArrowDirection.down:
        return math.pi;
      case ArrowDirection.left:
        return 3 * math.pi / 2;
    }
  }

  ArrowDirection get nextClockwise {
    switch (this) {
      case ArrowDirection.up:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.left;
      case ArrowDirection.left:
        return ArrowDirection.up;
    }
  }
}

class GameTile {
  final String id;
  final TileType type;
  int row;
  int col;
  ArrowDirection direction;
  int portalPairId; // 1 for Portal A, 2 for Portal B
  Color? customColor;

  GameTile({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.direction = ArrowDirection.up,
    this.portalPairId = 0,
    this.customColor,
  });

  GameTile clone() {
    return GameTile(
      id: id,
      type: type,
      row: row,
      col: col,
      direction: direction,
      portalPairId: portalPairId,
      customColor: customColor,
    );
  }
}
