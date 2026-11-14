import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static const String _keySave = 'arrow_puzzle_flutter_save';

  int coins = 200;
  int unlockedLevel = 1;
  Map<int, int> levelStars = {}; // level -> stars
  Map<String, int> boosters = {
    'hammer': 2,
    'hint': 3,
    'undo': 5,
  };
  bool soundEnabled = true;
  bool musicEnabled = false;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySave);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        coins = data['coins'] ?? 200;
        unlockedLevel = data['unlockedLevel'] ?? 1;
        
        if (data['levelStars'] != null) {
          levelStars = (data['levelStars'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(int.parse(k), v as int),
          );
        }
        
        if (data['boosters'] != null) {
          boosters = (data['boosters'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as int),
          );
        }

        soundEnabled = data['soundEnabled'] ?? true;
        musicEnabled = data['musicEnabled'] ?? false;
      }
    } catch (e) {
      // Fallback to default
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'coins': coins,
        'unlockedLevel': unlockedLevel,
        'levelStars': levelStars.map((k, v) => MapEntry(k.toString(), v)),
        'boosters': boosters,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
      };
      await prefs.setString(_keySave, jsonEncode(data));
    } catch (e) {
      // Ignore
    }
  }

  void completeLevel(int level, int stars, int rewardCoins) {
    if (level >= unlockedLevel) {
      unlockedLevel = level + 1;
    }
    final prev = levelStars[level] ?? 0;
    if (stars > prev) {
      levelStars[level] = stars;
    }
    coins += rewardCoins;
    save();
  }

  bool useBooster(String type) {
    if ((boosters[type] ?? 0) > 0) {
      boosters[type] = boosters[type]! - 1;
      save();
      return true;
    }
    final costs = {'hammer': 50, 'hint': 30, 'undo': 20};
    final cost = costs[type] ?? 50;
    if (coins >= cost) {
      coins -= cost;
      save();
      return true;
    }
    return false;
  }
}
