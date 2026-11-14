import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  final GameStorage storage;

  const LevelSelectScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Level Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '🪙 ${storage.coins}',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 30,
          itemBuilder: (context, index) {
            final level = index + 1;
            final isLocked = level > storage.unlockedLevel;
            final stars = storage.levelStars[level] ?? 0;

            return GestureDetector(
              onTap: isLocked
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            initialLevel: level,
                            storage: storage,
                          ),
                        ),
                      );
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: isLocked ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLocked ? '🔒' : '$level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.white30 : Colors.white,
                      ),
                    ),
                    if (!isLocked)
                      Text(
                        '⭐' * stars + '☆' * (3 - stars),
                        style: const TextStyle(fontSize: 8),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
