import 'dart:math';
import '../models/arrow_model.dart';

class RaycastResult {
  final bool isClear;
  final GameTile? blockedBy;
  final List<GameTile> portalsUsed;

  RaycastResult({
    required this.isClear,
    this.blockedBy,
    this.portalsUsed = const [],
  });
}

class HistoryEntry {
  final String action;
  final GameTile tile;
  final ArrowDirection? prevDir;
  final int livesBefore;

  HistoryEntry({
    required this.action,
    required this.tile,
    this.prevDir,
    required this.livesBefore,
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

  // Portals
  GameTile? portalA;
  GameTile? portalB;

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
        // Exclude 4 corners of size 1 or 2
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
    bool withPortals = false,
  }) {
    size = levelSize;
    currentShape = shape;
    lives = maxLives;
    moves = 0;
    history.clear();
    hintTileId = null;
    portalA = null;
    portalB = null;
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

    // 2. Generate Paired Portals if requested
    if (withPortals && size >= 5) {
      final validCoords = <Point<int>>[];
      for (int r = 1; r < size - 1; r++) {
        for (int c = 1; c < size - 1; c++) {
          if (grid[r][c] == null) {
            validCoords.add(Point(r, c));
          }
        }
      }

      if (validCoords.length >= 2) {
        validCoords.shuffle(rand);
        final p1 = validCoords[0];
        final p2 = validCoords[1];

        portalA = GameTile(
          id: 'portal_1',
          type: TileType.portal,
          row: p1.x,
          col: p1.y,
          portalPairId: 1,
        );
        portalB = GameTile(
          id: 'portal_2',
          type: TileType.portal,
          row: p2.x,
          col: p2.y,
          portalPairId: 2,
        );

        grid[p1.x][p1.y] = portalA;
        grid[p2.x][p2.y] = portalB;
      }
    }

    // 3. Place Obstacles
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

  // --- Raycast Path Checking with Portal Warping ---
  RaycastResult checkPath(GameTile tile) {
    if (tile.type != TileType.arrow) {
      return RaycastResult(isClear: false);
    }

    int r = tile.row + tile.direction.dr;
    int c = tile.col + tile.direction.dc;
    final portalsUsed = <GameTile>[];
    int warpSafety = 0;

    while (r >= 0 && r < size && c >= 0 && c < size) {
      final cell = grid[r][c];

      if (cell != null) {
        if (cell.type == TileType.voidCell) {
          // Arrow escapes through the void cutout border!
          break;
        } else if (cell.type == TileType.portal && warpSafety < 2) {
          // WARP TO PAIRED PORTAL!
          warpSafety++;
          portalsUsed.add(cell);
          final otherPortal = (cell.id == portalA?.id) ? portalB : portalA;

          if (otherPortal != null) {
            // Emerge on the other side of portal in same direction
            r = otherPortal.row + tile.direction.dr;
            c = otherPortal.col + tile.direction.dc;
            continue;
          } else {
            return RaycastResult(isClear: false, blockedBy: cell);
          }
        } else {
          // Blocking arrow or obstacle found
          return RaycastResult(isClear: false, blockedBy: cell);
        }
      }

      r += tile.direction.dr;
      c += tile.direction.dc;
    }

    return RaycastResult(isClear: true, portalsUsed: portalsUsed);
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

  void removeTile(GameTile tile) {
    history.add(HistoryEntry(
      action: 'REMOVE',
      tile: tile.clone(),
      livesBefore: lives,
    ));
    grid[tile.row][tile.col] = null;
    moves++;
  }

  bool smashTile(int r, int c) {
    final item = grid[r][c];
    if (item == null || item.type == TileType.voidCell || item.type == TileType.portal) {
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
