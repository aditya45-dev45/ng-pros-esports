import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../widgets/clean_card.dart';
import '../widgets/stat_box.dart';
class TournamentDetailScreen extends StatelessWidget {
  final String tournamentName;
  final List<Map<String, dynamic>> dailyMatchesData;
  final bool isCSMode;
  final Color themeColor;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentName,
    required this.dailyMatchesData,
    required this.isCSMode,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    int overallKills = 0;
    int overallPts = 0;
    int totalMatches = 0;

    Map<String, Map<String, int>> mapStats = {
      'BERMUDA': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
      'PURGATORY': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
      'KALAHARI': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
      'ALPINE': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
      'NEXTERRA': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
      'SOLARA': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
    };

    // 🔥 Naya Map: Player ke overall kills store karne ke liye
    Map<String, int> overallPlayerKills = {};

    for (var day in dailyMatchesData) {
      List matches = day['matches'] ?? [];
      totalMatches += matches.length;
      for (var m in matches) {
        int mKills = m['matchKills'] ?? 0;
        int mSec = isCSMode ? (m['rounds'] ?? 0) : (m['posPts'] ?? 0);
        int mTotal = m['matchTotal'] ?? (mKills + mSec);
        overallKills += mKills;
        overallPts += mTotal;
        String mName = (m['matchName'] ?? '').toString().toUpperCase();

        // 🔥 Naya Code: Har match ke player kills ko total me add karna
        Map<String, dynamic> pKills = m['playerKills'] ?? {};
        pKills.forEach((p, k) {
          String cleanName = p.toString().toUpperCase().replaceAll('GDR ', '').replaceAll('NG ', '').trim();
          overallPlayerKills[cleanName] = (overallPlayerKills[cleanName] ?? 0) + (k as int);
        });  for (String mapKey in mapStats.keys) {
          if (mName.contains(mapKey)) {
            mapStats[mapKey]!['matches'] = (mapStats[mapKey]!['matches']!) + 1;
            mapStats[mapKey]!['kills'] = (mapStats[mapKey]!['kills']!) + mKills;
            mapStats[mapKey]!['pos'] = (mapStats[mapKey]!['pos']!) + mSec;
            mapStats[mapKey]!['total'] = (mapStats[mapKey]!['total']!) + mTotal;
            break;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(tournamentName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text:
                  '🏆 $tournamentName\nTotal Pts: $overallPts | Kills: $overallKills\n#NGPROS'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Stats copied to clipboard! 📋'),
                  backgroundColor: AppTheme.secondary));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CleanCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatBox(label: 'MATCHES', value: '$totalMatches'),
                  StatBox(
                      label: 'TOTAL PTS',
                      value: '$overallPts',
                      valueColor: AppTheme.primary),
                  StatBox(
                      label: 'TEAM KILLS',
                      value: '$overallKills',
                      valueColor: AppTheme.danger),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🔥 Naya Code: Player-wise Overall Kills Banner
            if (overallPlayerKills.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('OVERALL SQUAD KILLS',
                        style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: overallPlayerKills.entries.map((e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${e.key}: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          Text('${e.value}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      )).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            const Text('MAP-WISE PERFORMANCE',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 14)),
            const SizedBox(height: 12),
            ...mapStats.entries.where((e) => e.value['matches']! > 0).map((entry) {
              var stats = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(11))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text('Matches: ${stats['matches']}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('K.P: ${stats['kills']}',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          Text(
                              isCSMode
                                  ? 'RND: ${stats['pos']}'
                                  : 'P.P: ${stats['pos']}',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          Text('TOTAL: ${stats['total']}',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text('DETAILED MATCH HISTORY',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 14)),
            const SizedBox(height: 12),
            ...dailyMatchesData.map((dayData) {
              List matches = dayData['matches'] ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('${dayData['name']} (${dayData['date']})',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...matches.map((m) {
                    Map<String, dynamic> pKills = m['playerKills'] ?? {};
                    return CleanCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(m['matchName'] ?? 'Match',
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text('T.P: ${m['matchTotal']}',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Kills: ${m['matchKills']}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                              const SizedBox(width: 16),
                              Text(
                                  isCSMode
                                      ? 'Rounds: ${m['rounds']}'
                                      : 'Pos Pts: ${m['posPts']}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                          const Divider(color: AppTheme.divider, height: 20),
                          LayoutBuilder(builder: (context, constraints) {
                            return Wrap(
                              runSpacing: 8,
                              children: pKills.keys.map((pName) {
                                String cleanName = pName
                                    .toUpperCase()
                                    .replaceAll('GDR ', '')
                                    .replaceAll('NG ', '')
                                    .trim();
                                return SizedBox(
                                  width: constraints.maxWidth / 2,
                                  child: Row(children: [
                                    Text('$cleanName - ',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12)),
                                    Text('${pKills[pName]}',
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                                );
                              }).toList(),
                            );
                          })
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
