import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import 'developer_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final GameStorage storage;
  final AuthService auth;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.auth,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: Coins + Player Profile / Cloud Sync + Creator Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Coins
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '${widget.storage.coins}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      // Player Profile Cloud Button
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(
                                auth: widget.auth,
                                storage: widget.storage,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                user != null ? Icons.cloud_done_rounded : Icons.cloud_outlined,
                                color: const Color(0xFF10B981),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user != null ? user.name.split(' ').first : 'Save',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Creator Profile Pill
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DeveloperScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundImage: NetworkImage('https://github.com/srkamd.png'),
                                backgroundColor: Color(0xFF334155),
                              ),
                              SizedBox(width: 5),
                              Text(
                                '@srkamd',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                        onPressed: _showSettingsDialog,
                      ),
                    ],
                  ),
                ],
              ),

              // Hero Center
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF1E293B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                          blurRadius: 28,
                        )
                      ],
                    ),
                    child: const Text('🎯', style: TextStyle(fontSize: 54)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Arrow Puzzle Pro',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Warp Portals • Dynamic Mazes • Cloud Record',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),

              // Menu Buttons
              Column(
                children: [
                  _buildMenuButton(
                    title: 'Play Campaign (Level ${widget.storage.unlockedLevel})',
                    icon: Icons.play_arrow_rounded,
                    isPrimary: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            initialLevel: widget.storage.unlockedLevel,
                            storage: widget.storage,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMenuButton(
                    title: 'Level Map (30 Levels)',
                    icon: Icons.map_rounded,
                    isPrimary: false,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LevelSelectScreen(storage: widget.storage),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMenuButton(
                    title: 'Zen Mode (Infinite Relax)',
                    icon: Icons.self_improvement_rounded,
                    isPrimary: false,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            initialLevel: 1,
                            isZen: true,
                            storage: widget.storage,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMenuButton(
                    title: 'Player Profile & Cloud Save',
                    icon: Icons.cloud_sync_rounded,
                    isPrimary: false,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            auth: widget.auth,
                            storage: widget.storage,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),

              // Stats Footer
              Text(
                'Levels: ${widget.storage.levelStars.length} Cleared | ⭐ Stars: ${widget.storage.levelStars.values.fold(0, (a, b) => a + b)}',
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: isPrimary ? 6 : 0,
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Sound Effects', style: TextStyle(color: Colors.white)),
                value: SoundService().sfxEnabled,
                onChanged: (val) {
                  setDialogState(() {
                    SoundService().sfxEnabled = val;
                    widget.storage.soundEnabled = val;
                    widget.storage.save();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
