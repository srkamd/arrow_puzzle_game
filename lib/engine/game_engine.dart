import 'dart:math';
import '../models/arrow_model.dart';

class RaycastResult {
  final bool isClear;
  final GameTile? blockedBy;
  final List<GameTile> collectedStars;

  RaycastResult({
    required this.isClear,
    this.blockedBy,
    this.collectedStars = const [],
  });
}

class HistoryEntry {
  final String action;
  final GameTile tile;
  final ArrowDirection? prevDir;
  final int livesBefore;
  final List<GameTile> restoredStars;

  HistoryEntry({
    required this.action,
    required this.tile,
    this.prevDir,
    required this.livesBefore,
    this.restoredStars = const [],
  });
}

class GameEngine {
  int size;
  final int maxLives;
  int lives;
  int moves;
  MapShape currentShape;
  late List<List<GameTile?>> grid;
  final List<HistoryEntry> history = [];
  String? hintTileId;

  GameEngine({
    this.size = 5,
    this.maxLives = 3,
    this.currentShape = MapShape.square,
  })  : lives = maxLives,
        moves = 0 {
    initEmptyGrid();
  }

  void initEmptyGrid() {
    grid = List.generate(size, (_) => List.generate(size, (_) => null));
  }

  bool isCellInShape(int r, int c, MapShape shape) {
    switch (shape) {
      case MapShape.square:
        return true;
      case MapShape.cross:
        final corner = size >= 6 ? 2 : 1;
        final isTopLeft = r < corner && c < corner;
        final isTopRight = r < corner && c >= size - corner;
        final isBottomLeft = r >= size - corner && c < corner;
        final isBottomRight = r >= size - corner && c >= size - corner;
        return !(isTopLeft || isTopRight || isBottomLeft || isBottomRight);
      case MapShape.diamond:
        final mid = (size - 1) / 2.0;
        final dist = (r - mid).abs() + (c - mid).abs();
        return dist <= mid + 0.5;
      case MapShape.donut:
        final mid = size ~/ 2;
        return !(r == mid && c == mid);
    }
  }

  void generateLevel({
    required int levelSize,
    required MapShape shape,
    int obstacleCount = 1,
    bool withBonusStars = false,
  }) {
    size = levelSize;
    currentShape = shape;
    lives = maxLives;
    moves = 0;
    history.clear();
    hintTileId = null;
    initEmptyGrid();

    // 1. Mark void cells for non-square map shapes
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!isCellInShape(r, c, shape)) {
          grid[r][c] = GameTile(
            id: 'void_${r}_$c',
            type: TileType.voidCell,
            row: r,
            col: c,
          );
        }
      }
    }

    final rand = Random();
    int idCounter = 1;

    // 2. Generate Collectible Bonus Stars (Reward items that arrows can fly through!)
    if (withBonusStars && size >= 5) {
      final validCoords = <Point<int>>[];
      for (int r = 1; r < size - 1; r++) {
        for (int c = 1; c < size - 1; c++) {
          if (grid[r][c] == null) {
            validCoords.add(Point(r, c));
          }
        }
      }

      if (validCoords.isNotEmpty) {
        validCoords.shuffle(rand);
        final starCount = min(2, validCoords.length);
        for (int i = 0; i < starCount; i++) {
          final pt = validCoords[i];
          grid[pt.x][pt.y] = GameTile(
            id: 'star_$i',
            type: TileType.bonusStar,
            row: pt.x,
            col: pt.y,
          );
        }
      }
    }

    // 3. Place Obstacles (Rocks)
    for (int i = 0; i < obstacleCount; i++) {
      if (size > 3) {
        final r = rand.nextInt(size - 2) + 1;
        final c = rand.nextInt(size - 2) + 1;
        if (grid[r][c] == null) {
          grid[r][c] = GameTile(
            id: 'obs_$i',
            type: TileType.obstacle,
            row: r,
            col: c,
          );
        }
      }
    }

    // 4. Reverse Simulation: Place arrows that can exit to edge cleanly
    int playableCells = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == null) playableCells++;
      }
    }

    final targetArrows = (playableCells * 0.65).floor();
    int placed = 0;
    int safety = 0;

    const allDirs = ArrowDirection.values;

    while (placed < targetArrows && safety < 800) {
      safety++;
      final r = rand.nextInt(size);
      final c = rand.nextInt(size);
      if (grid[r][c] != null) continue;

      final validDirs = <ArrowDirection>[];
      for (final dir in allDirs) {
        final testArrow = GameTile(
          id: 'temp',
          type: TileType.arrow,
          row: r,
          col: c,
          direction: dir,
        );

        if (checkPath(testArrow).isClear) {
          validDirs.add(dir);
        }
      }

      if (validDirs.isNotEmpty) {
        final chosenDir = validDirs[rand.nextInt(validDirs.length)];
        final arrow = GameTile(
          id: 'arr_${idCounter++}',
          type: TileType.arrow,
          row: r,
          col: c,
          direction: chosenDir,
        );
        grid[r][c] = arrow;
        placed++;
      }
    }
  }

  // --- Raycast Path Checking (Stars are collected, obstacles block!) ---
  RaycastResult checkPath(GameTile tile) {
    if (tile.type != TileType.arrow) {
      return RaycastResult(isClear: false);
    }

    int r = tile.row + tile.direction.dr;
    int c = tile.col + tile.direction.dc;
    final collectedStars = <GameTile>[];

    while (r >= 0 && r < size && c >= 0 && c < size) {
      final cell = grid[r][c];

      if (cell != null) {
        if (cell.type == TileType.voidCell) {
          // Arrow escapes through natural cutout border!
          break;
        } else if (cell.type == TileType.bonusStar) {
          // Stars DO NOT block! Arrow passes through and collects them!
          collectedStars.add(cell);
        } else {
          // Blocking arrow or rock obstacle found
          return RaycastResult(isClear: false, blockedBy: cell);
        }
      }

      r += tile.direction.dr;
      c += tile.direction.dc;
    }

    return RaycastResult(isClear: true, collectedStars: collectedStars);
  }

  GameTile? findFreeArrow() {
    final candidates = <GameTile>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final item = grid[r][c];
        if (item != null && item.type == TileType.arrow) {
          if (checkPath(item).isClear) {
            candidates.add(item);
          }
        }
      }
    }
    if (candidates.isEmpty) return null;
    return candidates[Random().nextInt(candidates.length)];
  }

  void removeTile(GameTile tile, {List<GameTile> collectedStars = const []}) {
    // Clear collected stars along the path
    for (final star in collectedStars) {
      grid[star.row][star.col] = null;
    }

    history.add(HistoryEntry(
      action: 'REMOVE',
      tile: tile.clone(),
      livesBefore: lives,
      restoredStars: collectedStars,
    ));
    grid[tile.row][tile.col] = null;
    moves++;
  }

  bool smashTile(int r, int c) {
    final item = grid[r][c];
    if (item == null || item.type == TileType.voidCell) {
      return false;
    }

    history.add(HistoryEntry(
      action: 'HAMMER',
      tile: item.clone(),
      livesBefore: lives,
    ));
    grid[r][c] = null;
    return true;
  }

  void rotateTile(GameTile tile) {
    final prev = tile.direction;
    tile.direction = tile.direction.nextClockwise;

    history.add(HistoryEntry(
      action: 'ROTATE',
      tile: tile,
      prevDir: prev,
      livesBefore: lives,
    ));
  }

  bool undo() {
    if (history.isEmpty) return false;
    final entry = history.removeLast();
    lives = entry.livesBefore;

    if (entry.action == 'REMOVE' || entry.action == 'HAMMER') {
      grid[entry.tile.row][entry.tile.col] = entry.tile;
      // Restore collected stars
      for (final star in entry.restoredStars) {
        grid[star.row][star.col] = star;
      }
    } else if (entry.action == 'ROTATE') {
      entry.tile.direction = entry.prevDir!;
    }
    hintTileId = null;
    return true;
  }

  int get remainingArrows {
    int count = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c]?.type == TileType.arrow) count++;
      }
    }
    return count;
  }

  bool get isLevelComplete => remainingArrows == 0;

  int calculateStars() {
    final lost = maxLives - lives;
    if (lost <= 0) return 3;
    if (lost == 1) return 2;
    return 1;
  }
}
