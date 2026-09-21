import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:html' as html; // Only for Web
import '../core/theme.dart';

// 📸 8-IN-1 MULTI-TEMPLATE ESPORTS STORY GENERATOR
class StoryShareDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Map<String, dynamic> stats;
  final Map<String, int> playerKills;
  final Map<String, String>? playerAvatars;

  const StoryShareDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.playerKills,
    this.playerAvatars,
  });

  @override
  State<StoryShareDialog> createState() => _StoryShareDialogState();
}

class _StoryShareDialogState extends State<StoryShareDialog> {
  final GlobalKey _globalKey = GlobalKey();
  int _selectedThemeIndex = 0;
  final List<String> _themeNames = [
    'Classic Pro',
    'Minimalist',
    'Cyberpunk',
    'MVP Spotlight',
    'Bloodbath',
    'Tactical HUD',
    'Royal Champ',
    'Synthwave'
  ];

  Future<void> _downloadStory() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final blob = html.Blob([buffer]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
              "download",
              "NG_PROS_${widget.title.replaceAll(' ', '_')}_Theme${_selectedThemeIndex + 1}.png")
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🔥 Poster Downloaded!'),
              backgroundColor: AppTheme.secondary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  // 🎨 MASTER THEME BUILDER
  Widget _buildTemplate() {
    String mvpName = 'UNKNOWN';
    int mvpKills = 0;

    if (widget.playerKills.isNotEmpty) {
      var best = widget.playerKills.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      mvpName = best.key;
      mvpKills = best.value;
    }

    String mvpAvatarUrl = (widget.playerAvatars != null &&
        widget.playerAvatars!.containsKey(mvpName))
        ? widget.playerAvatars![mvpName]!
        : 'https://i.ibb.co/gbX7mcvm/gdr.jpg';

    if (_selectedThemeIndex == 0) {
      return _baseCardLayout(
        bgGradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderColor: const Color(0xFFF39C12),
        textColor: Colors.white,
        accentColor: const Color(0xFFF39C12),
        showWatermark: true,
      );
    } else if (_selectedThemeIndex == 1) {
      return _baseCardLayout(
        bgColor: Colors.white,
        borderColor: const Color(0xFFD4AF37),
        textColor: const Color(0xFF2C3E50),
        accentColor: const Color(0xFFD4AF37),
        showWatermark: false,
        isLight: true,
      );
    } else if (_selectedThemeIndex == 2) {
      return _baseCardLayout(
        bgColor: const Color(0xFF090916),
        borderColor: const Color(0xFF00FFCC),
        textColor: Colors.white,
        accentColor: const Color(0xFFFF007F),
        showWatermark: true,
        boxShadow: const BoxShadow(
            color: Color(0xFF00FFCC), blurRadius: 15, spreadRadius: -5),
      );
    } else if (_selectedThemeIndex == 3) {
      return Container(
        width: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 3),
                  image: DecorationImage(
                      image: NetworkImage(mvpAvatarUrl), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              const Text('🌟 MATCH MVP 🌟',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              Text(mvpName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              Text('$mvpKills KILLS',
                  style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.stats.entries
                    .map((e) => Column(
                  children: [
                    Text(e.value.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text(e.key,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    } else if (_selectedThemeIndex == 4) {
      return _baseCardLayout(
        bgGradient: const LinearGradient(
            colors: [Color(0xFF450a0a), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        borderColor: Colors.redAccent,
        textColor: Colors.white,
        accentColor: Colors.redAccent,
        showWatermark: true,
      );
    } else if (_selectedThemeIndex == 5) {
      return _baseCardLayout(
        bgColor: const Color(0xFF021703),
        borderColor: const Color(0xFF00FF41),
        textColor: const Color(0xFF00FF41),
        accentColor: Colors.white,
        showWatermark: false,
        fontFamily: 'Courier',
      );
    } else if (_selectedThemeIndex == 6) {
      return _baseCardLayout(
        bgGradient: const LinearGradient(
            colors: [Color(0xFF3B0764), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderColor: const Color(0xFFFBBF24),
        textColor: Colors.white,
        accentColor: const Color(0xFFFBBF24),
        showWatermark: true,
      );
    } else {
      return _baseCardLayout(
        bgGradient: const LinearGradient(
            colors: [Color(0xFF4338ca), Color(0xFFdb2777), Color(0xFFf97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderColor: Colors.white,
        textColor: Colors.white,
        accentColor: const Color(0xFFFef08a),
        showWatermark: false,
        boxShadow: const BoxShadow(
            color: Color(0xFFdb2777), blurRadius: 20, spreadRadius: 2),
      );
    }
  }

  Widget _baseCardLayout({
    Color? bgColor,
    LinearGradient? bgGradient,
    required Color borderColor,
    required Color textColor,
    required Color accentColor,
    required bool showWatermark,
    bool isLight = false,
    BoxShadow? boxShadow,
    String? fontFamily,
  }) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: boxShadow != null ? [boxShadow] : [],
      ),
      child: Stack(
        children: [
          if (showWatermark)
            Positioned.fill(
                child: Opacity(
                    opacity: 0.1,
                    child: Image.asset('assets/ng_logo.jpg',
                        fit: BoxFit.cover))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor),
                            image: const DecorationImage(
                                image: AssetImage('assets/ng_logo.jpg'),
                                fit: BoxFit.cover))),
                    const SizedBox(width: 10),
                    Text('NG PROS ESPORTS',
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily)),
                  ],
                ),
                const SizedBox(height: 15),
                Container(height: 1.5, width: 120, color: accentColor),
                const SizedBox(height: 25),
                Text(widget.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: fontFamily)),
                Text(widget.subtitle.toUpperCase(),
                    style: TextStyle(
                        color: isLight ? Colors.black54 : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: fontFamily)),
                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: widget.stats.entries
                      .map((e) => Column(
                    children: [
                      Text(e.value.toString(),
                          style: TextStyle(
                              color: textColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              fontFamily: fontFamily)),
                      Text(e.key,
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily)),
                    ],
                  ))
                      .toList(),
                ),
                const SizedBox(height: 35),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.03)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('SQUAD KILLS',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontFamily: fontFamily)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: widget.playerKills.entries
                            .map((e) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${e.key}: ',
                                  style: TextStyle(
                                      color: isLight
                                          ? Colors.black54
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontFamily: fontFamily)),
                              Text('${e.value}',
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: fontFamily))
                            ]))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _globalKey,
              child: _buildTemplate(),
            ),
            const SizedBox(height: 20),
            Container(
              height: 45,
              width: 360,
              alignment: Alignment.center,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _themeNames.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedThemeIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_themeNames[index],
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedThemeIndex = index);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('SAVE TO GALLERY',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              onPressed: _downloadStory,
            )
          ],
        ),
      ),
    );
  }
}