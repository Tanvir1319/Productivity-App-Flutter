import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'doc_editor_widget.dart';

class YearProgressDialog extends StatefulWidget {
  final StorageService store;

  const YearProgressDialog({super.key, required this.store});

  @override
  State<YearProgressDialog> createState() => _YearProgressDialogState();
}

class _YearProgressDialogState extends State<YearProgressDialog> {
  late DocTextEditingController _achController;
  late DocTextEditingController _tgtController;

  @override
  void initState() {
    super.initState();
    _achController = DocTextEditingController(text: widget.store.achievements);
    _tgtController = DocTextEditingController(text: widget.store.targets);
  }

  @override
  void dispose() {
    _achController.dispose();
    _tgtController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    widget.store.saveAchievements(_achController.text);
    widget.store.saveTargets(_tgtController.text);
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.store.yearStats;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 700),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF13162A), Color(0xFF0E1120), Color(0xFF111528)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.primary.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        '📅 Year Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      _saveChanges();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x18FFFFFF)),

            // Modal Body (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat Grid (2 or 3 columns responsive)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 480;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isNarrow ? 2 : 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.8,
                          children: [
                            _buildStatCard(
                              value: '${stats['passedDays']}',
                              label: 'Days Passed',
                              gradient: const [Color(0xFFC4B5FD), Color(0xFF818CF8)],
                            ),
                            _buildStatCard(
                              value: '${stats['leftDays']}',
                              label: 'Days Left',
                              gradient: const [Color(0xFF38BDF8), Color(0xFF22D3EE)],
                            ),
                            _buildStatCard(
                              value: '${stats['passedWeeks']}',
                              label: 'Weeks Passed',
                              gradient: const [Color(0xFFA78BFA), Color(0xFF818CF8)],
                            ),
                            _buildStatCard(
                              value: '${stats['leftWeeks']}',
                              label: 'Weeks Left',
                              gradient: const [Color(0xFF38BDF8), Color(0xFF67E8F9)],
                            ),
                            _buildStatCard(
                              value: '${stats['totalDays']}',
                              label: 'Total Days',
                              gradient: const [Color(0xFFC4B5FD), Color(0xFFA5B4FC)],
                            ),
                            _buildStatCard(
                              value: '${stats['yearPct']}%',
                              label: 'Year Progress',
                              gradient: const [Color(0xFF38BDF8), Color(0xFF22D3EE)],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Achievements Section with Doc-like Interface
                    DocEditorWidget(
                      label: 'Achievements',
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber,
                      controller: _achController,
                      hintText: 'Record your accomplishments, milestones, and wins this year...\nFormat with Bold, Italic, Headings, Bullets, and Colors above!',
                      onChanged: (_) => _saveChanges(),
                    ),

                    const SizedBox(height: 20),

                    // Targets Section with Doc-like Interface
                    DocEditorWidget(
                      label: 'Key Targets & Vision',
                      icon: Icons.track_changes,
                      iconColor: AppTheme.accent,
                      controller: _tgtController,
                      hintText: 'Define your main objectives, priorities, and roadmap...\nFormat with Bold, Italic, Headings, Bullets, and Colors above!',
                      onChanged: (_) => _saveChanges(),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0x18FFFFFF)),

            // Bottom action row with close button (as requested)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: BorderSide(color: AppTheme.danger.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      _saveChanges();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(colors: gradient).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

