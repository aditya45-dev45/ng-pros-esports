import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../widgets/clean_card.dart';
import '../widgets/clean_avatar.dart';
import '../widgets/stat_box.dart';
import '../widgets/next_match_timer.dart';
import '../widgets/clean_chip_btn.dart';
import '../widgets/story_share_dialog.dart';
import '../models/achievements.dart';
import 'tournament_detail_screen.dart';
import 'admin_panel_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isOfficialMode = true;
  bool isCSMode = false;
  int _currentDashboardPage = 0;
  final PageController _pageController = PageController();
  int _dashboardTabIndex = 1;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  String _getMonthName(int m) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return m >= 1 && m <= 12 ? months[m - 1] : '';
  }

  String get playersCol => !isOfficialMode
      ? 'players'
      : (isCSMode ? 'players_official_cs' : 'players_official');
  String get tourneyCol => !isOfficialMode
      ? 'tournaments'
      : (isCSMode ? 'tournaments_official_cs' : 'tournaments_official');
  String get statsDoc => !isOfficialMode
      ? 'third_party'
      : (isCSMode ? 'official_cs' : 'official');
  Color get accentColor => !isOfficialMode ? AppTheme.accent : AppTheme.primary;

  @override
  void initState() {
    super.initState();
    _incrementWebsiteVisitCount();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _incrementWebsiteVisitCount() async {
    DocumentReference ref =
    FirebaseFirestore.instance.collection('stats').doc('visitors');
    FirebaseFirestore.instance.runTransaction((t) async {
      DocumentSnapshot s = await t.get(ref);
      if (!s.exists) {
        t.set(ref, {'count': 1});
      } else {
        int n = (s.data() as Map<String, dynamic>)['count'] + 1;
        t.update(ref, {'count': n});
      }
    });
  }

  void _promptAdminPin(BuildContext parentCtx) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: parentCtx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Admin Access', style: TextStyle(color: accentColor)),
        content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Enter Security PIN')),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor, foregroundColor: Colors.white),
            onPressed: () {
              if (pinCtrl.text == "8757") {
                Navigator.pop(dCtx);
                Navigator.push(
                    parentCtx,
                    MaterialPageRoute(
                        builder: (_) => const AdminPanelScreen()));
              } else {
                Navigator.pop(dCtx);
              }
            },
            child: const Text('ENTER'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternalURL(String? u) async {
    if (u == null || u.isEmpty) return;
    final uri = Uri.parse(u);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('fail $u');
    }
  }

  Widget _buildSmallStatBox(String label, String value,
      {Color? valueColor, Color? labelColor}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: labelColor ?? AppTheme.textSecondary,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ===== MAP-WISE ANALYSIS =====
  void _showMapWiseAnalysis(
      BuildContext context, List<Map<String, dynamic>> allMatches) {
    String selectedFilter = 'LAST 60 MATCHES';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          Set<String> filters = {'ALL TIME', 'LAST 60 MATCHES'};
          for (var m in allMatches) {
            var ts = m['timestamp'] as Timestamp?;
            if (ts != null) {
              DateTime dt = ts.toDate();
              filters.add('${_getMonthName(dt.month)} ${dt.year}');
            }
          }

          List<Map<String, dynamic>> filteredMatches = [];
          if (selectedFilter == 'LAST 60 MATCHES') {
            filteredMatches = allMatches.take(60).toList();
          } else if (selectedFilter != 'ALL TIME') {
            filteredMatches = allMatches.where((m) {
              var ts = m['timestamp'] as Timestamp?;
              if (ts == null) return false;
              DateTime dt = ts.toDate();
              return '${_getMonthName(dt.month)} ${dt.year}' == selectedFilter;
            }).toList();
          } else {
            filteredMatches = allMatches;
          }

          Map<String, Map<String, int>> mapData = {
            'BERMUDA': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
            'PURGATORY': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
            'KALAHARI': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
            'ALPINE': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
            'NEXTERRA': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
            'SOLARA': {'matches': 0, 'kills': 0, 'pos': 0, 'total': 0},
          };
          for (var match in filteredMatches) {
            String n = (match['name'] ?? '').toString().toUpperCase();
            int k = match['kills'] ?? 0;
            int p = match['secondary'] ?? 0;
            int tot = match['total'] ?? 0;
            for (String m in mapData.keys) {
              if (n.contains(m)) {
                mapData[m]!['matches'] = (mapData[m]!['matches']!) + 1;
                mapData[m]!['kills'] = (mapData[m]!['kills']!) + k;
                mapData[m]!['pos'] = (mapData[m]!['pos']!) + p;
                mapData[m]!['total'] = (mapData[m]!['total']!) + tot;
                break;
              }
            }
          }
          var sorted = mapData.entries.toList()
            ..sort((a, b) {
              double aa = a.value['matches']! > 0
                  ? a.value['total']! / a.value['matches']!
                  : 0;
              double bb = b.value['matches']! > 0
                  ? b.value['total']! / b.value['matches']!
                  : 0;
              return bb.compareTo(aa);
            });

          return Container(
            height: MediaQuery.of(context).size.height * 0.70,
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
            decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.map_outlined, color: accentColor, size: 22),
                      const SizedBox(width: 10),
                      Text('MAP ANALYSIS',
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: accentColor.withValues(alpha: 0.3))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedFilter,
                          icon: Icon(Icons.filter_list,
                              color: accentColor, size: 16),
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          items: filters
                              .map((v) =>
                              DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setS(() => selectedFilter = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ranked Best to Worst Average',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11))),
                const SizedBox(height: 15),
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border)),
                  child: const Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text('MAP',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('MATCH',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('K.P',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('P.P',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text('TOTAL',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)))),
                  ]),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      var s = sorted[i];
                      if (s.value['matches'] == 0) return const SizedBox();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: AppTheme.divider, width: 1))),
                        child: Row(children: [
                          Expanded(
                              flex: 3,
                              child: Row(children: [
                                Text('${i + 1}. ',
                                    style: const TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                Text(s.key,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13))
                              ])),
                          Expanded(
                              flex: 2,
                              child: Center(
                                  child: Text('${s.value['matches']}',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13)))),
                          Expanded(
                              flex: 2,
                              child: Center(
                                  child: Text('${s.value['kills']}',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13)))),
                          Expanded(
                              flex: 2,
                              child: Center(
                                  child: Text('${s.value['pos']}',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13)))),
                          Expanded(
                              flex: 2,
                              child: Center(
                                  child: Text('${s.value['total']}',
                                      style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)))),
                        ]),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== TOURNAMENT TIMELINE =====
  void _showTournamentTimeline(BuildContext context) {
    String selectedMonth = 'ALL TIME';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(tourneyCol)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return Center(
                        child: CircularProgressIndicator(color: accentColor));
                  }
                  final allDocs = snap.data!.docs;

                  Set<String> monthFilters = {'ALL TIME'};
                  for (var doc in allDocs) {
                    var ts = (doc.data() as Map<String, dynamic>)['timestamp']
                    as Timestamp?;
                    if (ts != null) {
                      DateTime dt = ts.toDate();
                      monthFilters.add('${_getMonthName(dt.month)} ${dt.year}');
                    }
                  }

                  List<QueryDocumentSnapshot> filteredDocs =
                  allDocs.where((doc) {
                    if (selectedMonth == 'ALL TIME') return true;
                    var ts = (doc.data() as Map<String, dynamic>)['timestamp']
                    as Timestamp?;
                    if (ts == null) return false;
                    DateTime dt = ts.toDate();
                    return '${_getMonthName(dt.month)} ${dt.year}' ==
                        selectedMonth;
                  }).toList();

                  Map<String, List<Map<String, dynamic>>> grouped = {};
                  for (var doc in filteredDocs) {
                    var d = doc.data() as Map<String, dynamic>;
                    String raw = (d['name'] ?? '').toString().toUpperCase();
                    // Koi hardcoding nahi, universal regex filter
                    String folder = '${raw.replaceAll(RegExp(r'\s*(LEAGUE|BONUS|GRAND|WAY TO|GRAND FINAL|GRAND FINALS|K.O STAGE|K. O STAGE|TOP 6|TOP 9|GROUP STAGE|PLAYINS|KNOCKOUT|PLAYOFF|POINT RUSH|FINALS|QT\.|MATCH|DAY|ROUND|GAME|WEEK|QUALIFIER|SEMI|FINAL)\s*\d*.*$'), '').trim()} (OVERALL)';
                    grouped.putIfAbsent(folder, () => []).add(d);
                  }

                  return Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Icon(Icons.emoji_events_outlined,
                                    color: accentColor, size: 22),
                                const SizedBox(width: 8),
                                Text('HISTORY',
                                    style: TextStyle(
                                        color: accentColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5)),
                              ]),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: accentColor.withValues(
                                            alpha: 0.3))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedMonth,
                                    icon: Icon(Icons.filter_list,
                                        color: accentColor, size: 16),
                                    style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                    items: monthFilters
                                        .map((m) => DropdownMenuItem(
                                        value: m, child: Text(m)))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setS(() => selectedMonth = v);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (grouped.isEmpty)
                          const Expanded(
                              child: Center(
                                  child: Text("No Timeline Data Found",
                                      style: TextStyle(
                                          color: AppTheme.textLight)))),
                        if (grouped.isNotEmpty)
                        // 🔥 Focus widget lagaya taaki Arrow keys automatic kaam karein
                          Expanded(
                            child: Focus(
                              autofocus: true,
                              child: ListView.builder(
                                itemCount: grouped.keys.length,
                                itemBuilder: (_, i) {
                                  String title = grouped.keys.elementAt(i);
                                  List<Map<String, dynamic>> daily =
                                  grouped[title]!;

                                  // 🔥 FFMIC hardcoding aur Trophy logic yahan se hata diya
                                  Color theme = accentColor;
                                  int kT = 0, pT = 0;

                                  for (var dd in daily) {
                                    kT += (dd['totalKills'] ?? 0) as int;
                                    pT += (dd['overallPts'] ?? 0) as int;
                                  }

                                  return CleanCard(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    borderColor: AppTheme.border, // Normal border
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  TournamentDetailScreen(
                                                    tournamentName: title,
                                                    dailyMatchesData: daily,
                                                    isCSMode: isCSMode,
                                                    themeColor: theme,
                                                  )));
                                    },
                                    child: Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(title,
                                                    style: const TextStyle(
                                                        color: AppTheme.textPrimary, // Normal text
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    isCSMode
                                                        ? 'Total Kills: $kT'
                                                        : 'Total Pts: $pT | Kills: $kT',
                                                    style: TextStyle(
                                                        color: theme,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12)),
                                              ])),
                                      Icon(Icons.arrow_forward_ios,
                                          color: theme, size: 16),
                                    ]),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== TROPHY CABINET =====
  void _showTrophyCabinet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: AppTheme.accent, size: 24),
                SizedBox(width: 8),
                Text('TROPHY CABINET',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(tourneyCol)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all = snap.data!.docs;

                  Map<String, int> podiumWinners = {};
                  for (var d in all) {
                    var data = d.data() as Map<String, dynamic>;
                    int pos = data['podiumPosition'] ?? 0;

                    if (pos >= 1 && pos <= 3) {
                      String n = data['name'] ?? '';
                      // Same universal filter yahan bhi
                      String cleanName = n.toUpperCase().replaceAll(RegExp(r'\s*(LEAGUE|BONUS|GROUP STAGE|PLAYINS|KNOCKOUT|PLAYOFF|POINT RUSH|FINALS|QT\.|MATCH|DAY|ROUND|GAME|WEEK|QUALIFIER|SEMI|FINAL)\s*\d*.*$'), '').trim();
                      if (!podiumWinners.containsKey(cleanName) ||
                          pos < podiumWinners[cleanName]!) {
                        podiumWinners[cleanName] = pos;
                      }
                    }
                  }

                  if (podiumWinners.isEmpty) {
                    return const Center(
                        child: Text(
                            "No podium finishes yet. Keep grinding! 💪",
                            style: TextStyle(color: AppTheme.textLight)));
                  }

                  final list = podiumWinners.entries.toList();
                  return GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.9),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      String tName = list[i].key;
                      int pos = list[i].value;

                      Color tColor = pos == 1
                          ? AppTheme.accent
                          : (pos == 2 ? AppTheme.textLight : const Color(0xFFCD7F32));
                      String pText = pos == 1
                          ? "1ST PLACE"
                          : (pos == 2 ? "2ND PLACE" : "3RD PLACE");

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: tColor.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                                color: tColor.withValues(alpha: 0.1),
                                blurRadius: 10)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, size: 60, color: tColor),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: tColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(pText,
                                  style: TextStyle(
                                      color: tColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(tName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== PLAYER COMPARISON =====
  void _showPlayerComparison(
      BuildContext context, List<QueryDocumentSnapshot> roster) {
    String? p1, p2;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        final p1Data = p1 != null
            ? roster.firstWhere((d) => d['name'] == p1).data()
        as Map<String, dynamic>?
            : null;
        final p2Data = p2 != null
            ? roster.firstWhere((d) => d['name'] == p2).data()
        as Map<String, dynamic>?
            : null;
        return Dialog(
          backgroundColor: AppTheme.surface,
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⚔️ COMPARE PLAYERS',
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: p1,
                          hint: const Text('Player 1',
                              style: TextStyle(color: AppTheme.textLight)),
                          items: roster
                              .map((d) => DropdownMenuItem(
                              value: d['name'].toString(),
                              child: Text(d['name'])))
                              .toList(),
                          onChanged: (v) => setS(() => p1 = v),
                        )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: p2,
                          hint: const Text('Player 2',
                              style: TextStyle(color: AppTheme.textLight)),
                          items: roster
                              .map((d) => DropdownMenuItem(
                              value: d['name'].toString(),
                              child: Text(d['name'])))
                              .toList(),
                          onChanged: (v) => setS(() => p2 = v),
                        )),
                  ]),
                  const SizedBox(height: 20),
                  if (p1Data != null && p2Data != null)
                    _buildComparisonView(p1Data, p2Data)
                  else
                    const Text('Select 2 players to compare',
                        style: TextStyle(color: AppTheme.textLight)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildComparisonView(Map<String, dynamic> a, Map<String, dynamic> b) {
    Widget row(String label, num va, num vb, {bool higher = true}) {
      bool aWins = higher ? va > vb : va < vb;
      bool bWins = higher ? vb > va : vb < va;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
              child: Text('$va',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: aWins ? AppTheme.secondary : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),
          Expanded(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('$vb',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: bWins ? AppTheme.secondary : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),
        ]),
      );
    }

    int aK = a['eliminations'] ?? 0, bK = b['eliminations'] ?? 0;
    int aM = a['matchesPlayed'] ?? 0, bM = b['matchesPlayed'] ?? 0;
    double aAvg = aM > 0 ? aK / aM : 0;
    double bAvg = bM > 0 ? bK / bM : 0;
    return Column(
      children: [
        Row(children: [
          Expanded(
              child: Column(children: [
                CleanAvatar(
                    imageUrl: a['imageUrl'] ?? '',
                    size: 70,
                    borderColor: accentColor),
                const SizedBox(height: 6),
                Text(a['name'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              ])),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('VS',
                  style: TextStyle(
                      color: AppTheme.danger,
                      fontSize: 20,
                      fontWeight: FontWeight.bold))),
          Expanded(
              child: Column(children: [
                CleanAvatar(
                    imageUrl: b['imageUrl'] ?? '',
                    size: 70,
                    borderColor: const Color(0xFF8B5CF6)),
                const SizedBox(height: 6),
                Text(b['name'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              ])),
        ]),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.divider),
        row('KILLS', aK, bK),
        row('MATCHES', aM, bM),
        row('AVG K/M', double.parse(aAvg.toStringAsFixed(1)),
            double.parse(bAvg.toStringAsFixed(1))),
        row('HIGHEST', a['highestKills'] ?? 0, b['highestKills'] ?? 0),
      ],
    );
  }

  // ===== PLAYER CARD =====
  Widget _buildSimplePlayerCard(Map<String, dynamic> playerData,
      Map<String, int> playerTournamentKills,
      List<Map<String, dynamic>> rawHistory) {
    String status = (playerData['status'] ?? 'ACTIVE').toString().toUpperCase();
    bool isActive = status == 'ACTIVE';
    int kills = playerData['eliminations'] ?? 0;
    int matches = playerData['matchesPlayed'] ?? 0;
    double kd = matches > 0 ? kills / matches : 0;

    String safe = (playerData['name'] ?? '')
        .toString()
        .toUpperCase()
        .replaceAll('GDR ', '')
        .replaceAll('NG ', '')
        .trim();
    int streak = 0;
    for (var m in rawHistory) {
      if ((m['secondary'] ?? 0) == 12) {
        streak++;
      } else {
        break;
      }
    }

    return CleanCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      borderColor: isActive
          ? accentColor.withValues(alpha: 0.3)
          : AppTheme.border,
      onTap: () => _showDetailedProfilePopup(
          context, playerData, playerTournamentKills, rawHistory, safe),
      child: Row(children: [
        CleanAvatar(
            imageUrl:
            playerData['imageUrl'] ?? 'https://via.placeholder.com/150',
            size: 60,
            borderColor: isActive ? accentColor : AppTheme.textLight),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                    child: Text(playerData['name'] ?? 'Unknown',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isActive
                                ? AppTheme.textPrimary
                                : AppTheme.textLight))),
                const SizedBox(width: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.secondary.withValues(alpha: 0.15)
                        : AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(isActive ? 'ACTIVE' : 'LEFT',
                      style: TextStyle(
                          color: isActive ? AppTheme.secondary : AppTheme.danger,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                )
              ]),
              const SizedBox(height: 2),
              Text(playerData['role'] ?? 'Player',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isActive ? accentColor : AppTheme.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                Text('K/D: ${kd.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                if (streak > 0)
                  Text('🔥 x$streak',
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$kills',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isActive ? accentColor : AppTheme.textLight)),
            const Text('OVERALL',
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ]),
    );
  }

  // ===== DETAILED PROFILE POPUP =====
  void _showDetailedProfilePopup(
      BuildContext context,
      Map<String, dynamic> p,
      Map<String, int> tKills,
      List<Map<String, dynamic>> rawHistory,
      String safeName) {
    int matches = p['matchesPlayed'] ?? 0;
    int kills = p['eliminations'] ?? 0;
    double avg = matches > 0 ? kills / matches : 0;
    int highest = p['highestKills'] ?? 0;
    double kd = matches > 0 ? kills / matches : 0;
    final badges = computeAchievements(p, tKills);

    List<int> last10 = [];
    for (var m in rawHistory.take(10)) {
      Map pk = m['playerKills'] ?? {};
      int v = 0;
      pk.forEach((k, val) {
        String sk = k
            .toString()
            .toUpperCase()
            .replaceAll('GDR ', '')
            .replaceAll('NG ', '')
            .trim();
        if (sk == safeName) v = val;
      });
      last10.add(v);
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surface,
        insetPadding: const EdgeInsets.all(12),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: DefaultTabController(
          length: 2,
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                CleanAvatar(
                    imageUrl:
                    p['imageUrl'] ?? 'https://via.placeholder.com/150',
                    size: 90,
                    borderColor: accentColor),
                const SizedBox(height: 10),
                Text(p['name'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5)),
                Text(p['role'] ?? 'Player',
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TabBar(
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: AppTheme.textLight,
                  tabs: const [
                    Tab(text: 'STATS'),
                    Tab(text: 'ACHIEVEMENTS'),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      _buildProfileStats(p, matches, kills, avg, highest, kd, tKills),
                      _buildProfileAchievements(badges, last10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStats(
      Map<String, dynamic> p,
      int matches,
      int kills,
      double avg,
      int highest,
      double kd,
      Map<String, int> tKills) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallStatBox('MATCHES', '$matches'),
              _buildSmallStatBox('KILLS', '$kills',
                  valueColor: AppTheme.primary),
              _buildSmallStatBox('AVG', avg.toStringAsFixed(1)),
              _buildSmallStatBox('K/D', kd.toStringAsFixed(2),
                  valueColor: AppTheme.accent),
              _buildSmallStatBox('HIGHEST', '$highest',
                  valueColor: AppTheme.danger),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOURNAMENT',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            Text('KILLS',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          if (tKills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No tournament data yet.',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
            )
          else
            ...tKills.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(e.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13))),
                    Text('${e.value}',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ]),
            )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42)),
            icon: const Icon(Icons.share, size: 16),
            label: const Text('SHARE STATS',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text:
                  '🎮 ${p['name']} | Kills: $kills | Matches: $matches | K/D: ${kd.toStringAsFixed(2)} | Highest: $highest\n#NGPROS'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Player stats copied! 📋'),
                  backgroundColor: AppTheme.secondary));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAchievements(
      List<Achievement> badges, List<int> last10) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Text('🏅 BADGES',
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1))),
          const SizedBox(height: 15),
          if (badges.isEmpty)
            const Center(
                child: Text('No badges unlocked yet.\nKeep grinding! 💪',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textLight)))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges
                  .map((b) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: b.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: b.color.withValues(alpha: 0.4),
                        width: 1)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(b.icon, style: const TextStyle(fontSize: 22)),
                  Text(b.name,
                      style: TextStyle(
                          color: b.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  Text(b.desc,
                      style: const TextStyle(
                          color: AppTheme.textLight, fontSize: 9)),
                ]),
              ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 10),
          Center(
              child: Text('🔥 LAST 10 MATCHES',
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: last10.map((k) {
              Color c;
              if (k >= 8) {
                c = AppTheme.secondary;
              } else if (k >= 4) {
                c = AppTheme.accent;
              } else if (k > 0) {
                c = const Color(0xFFF97316);
              } else {
                c = AppTheme.danger;
              }
              return Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.withValues(alpha: 0.5), width: 1),
                ),
                child: Center(
                    child: Text('$k',
                        style: TextStyle(
                            color: c,
                            fontWeight: FontWeight.bold,
                            fontSize: 14))),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===== ACTIVE TOURNAMENT CARD =====
  // ===== ACTIVE TOURNAMENT CARD =====
  Widget _buildActiveTournamentCard(Map<String, dynamic> tourneyData, List<QueryDocumentSnapshot> roster) {
    String tName = tourneyData['name'] ?? 'Unknown Tournament';
    String tDate = tourneyData['date'] ?? '';
    List matches = tourneyData['matches'] ?? [];
    int totalKills = 0, totalSec = 0;
    Map<String, int> agg = {};

    for (var m in matches) {
      int mK = m['matchKills'] ?? 0;
      int mS = isCSMode ? (m['rounds'] ?? 0) : (m['posPts'] ?? 0);
      totalKills += mK;
      totalSec += mS;
      Map<String, dynamic> pk = m['playerKills'] ?? {};
      pk.forEach((rk, v) {
        String sk = rk
            .toString()
            .toUpperCase()
            .replaceAll('GDR ', '')
            .replaceAll('NG ', '')
            .trim();
        agg[sk] = (agg[sk] ?? 0) + (v as int);
      });
    }
    int overall = totalKills + totalSec;

    double synergy = 0;
    if (agg.isNotEmpty && totalKills > 0) {
      double avgK = totalKills / agg.length;
      double variance = agg.values
          .map((v) => (v - avgK) * (v - avgK))
          .reduce((a, b) => a + b) /
          agg.length;
      double std = _sqrt(variance);
      synergy = (100 - (std / (avgK + 1)) * 50).clamp(0, 100);
    }

    // 🔥 FIREBASE SE SAB PLAYERS KI PHOTO NIKALNA
    Map<String, String> playerAvatars = {};
    for (var doc in roster) {
      var pd = doc.data() as Map<String, dynamic>;
      String cleanName = (pd['name'] ?? '').toString().toUpperCase().replaceAll('GDR ', '').replaceAll('NG ', '').trim();
      playerAvatars[cleanName] = pd['imageUrl'] ?? 'https://i.ibb.co/gbX7mcvm/gdr.jpg';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(11))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text('🟢 RECENT: $tName',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13))),
              Row(
                children: [
                  Text(tDate,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(width: 12),
                  // 📤 OVERALL SHARE BUTTON
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => StoryShareDialog(
                          title: tName,
                          subtitle: 'OVERALL PERFORMANCE ($tDate)',
                          stats: {
                            'T.P': overall,
                            isCSMode ? 'ROUNDS' : 'P.P': totalSec,
                            'KILLS': totalKills,
                          },
                          playerKills: agg,
                          playerAvatars: playerAvatars, // <--- FOTU YAHAN SE JAYEGI
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.ios_share, size: 16, color: accentColor),
                    ),
                  ),
                ],
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildSmallStatBox('T.P', '$overall'),
              _buildSmallStatBox(isCSMode ? 'ROUNDS' : 'P.P', '$totalSec'),
              _buildSmallStatBox('KILLS', '$totalKills', valueColor: accentColor),
              _buildSmallStatBox(
                  'SYNERGY', '${synergy.toStringAsFixed(0)}%',
                  valueColor: AppTheme.secondary),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: synergy / 100,
                minHeight: 6,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation<Color>(synergy > 70
                    ? AppTheme.secondary
                    : (synergy > 40 ? AppTheme.accent : AppTheme.danger)),
              ),
            ),
          ),
          const Divider(color: AppTheme.divider, height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SQUAD PERFORMANCE',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: agg.keys
                      .map((p) => SizedBox(
                    width: (MediaQuery.of(context).size.width / 2) - 30,
                    child: Row(children: [
                      Text('$p - ',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13)),
                      Text('${agg[p]}',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.divider, height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MATCHES',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                if (matches.isEmpty)
                  const Text('No matches played yet.',
                      style:
                      TextStyle(color: AppTheme.textLight, fontSize: 12))
                else
                  ...matches.map((m) {
                    int mK = m['matchKills'] ?? 0;
                    int mS = isCSMode ? (m['rounds'] ?? 0) : (m['posPts'] ?? 0);
                    int mT = mK + mS;

                    Map<String, int> pKills = {};
                    (m['playerKills'] ?? {}).forEach((k, v) {
                      String cleanName = k.toString().toUpperCase().replaceAll('GDR ', '').replaceAll('NG ', '').trim();
                      pKills[cleanName] = v as int;
                    });

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            flex: 2,
                            child: Text(m['matchName'] ?? 'Match',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            flex: 1,
                            child: Text('K: $mK',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12))),
                        Expanded(
                            flex: 1,
                            child: Text(isCSMode ? 'R: $mS' : 'P: $mS',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12))),
                        Expanded(
                            flex: 1,
                            child: Text('T: $mT',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        // 📤 PARTICULAR MATCH SHARE BUTTON
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => StoryShareDialog(
                                title: m['matchName'] ?? 'MATCH',
                                subtitle: tName,
                                stats: {
                                  'T.P': mT,
                                  isCSMode ? 'ROUNDS' : 'P.P': mS,
                                  'KILLS': mK,
                                },
                                playerKills: pKills,
                                playerAvatars: playerAvatars, // <--- FOTU YAHAN SE BHI JAYEGI
                              ),
                            );
                          },
                          child: const Icon(Icons.ios_share, size: 16, color: AppTheme.textLight),
                        ),
                      ]),
                    );
                  }),
              ],
            ),
          )
        ],
      ),
    );
  }
  double _sqrt(double val) {
    double x = val;
    double last = 0;
    for (int i = 0; i < 30 && x != last; i++) {
      last = x;
      x = (x + val / x) / 2;
    }
    return x;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.history, color: accentColor, size: 26),
            tooltip: 'Timeline',
            onPressed: () => _showTournamentTimeline(context)),
        title: Text(
            isOfficialMode
                ? (isCSMode ? 'NG PROS · CS' : 'NG PROS')
                : 'NG · 3RD PARTY',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        actions: [
          IconButton(
              icon: const Icon(Icons.emoji_events_outlined,
                  color: AppTheme.accent),
              tooltip: 'Trophy Cabinet',
              onPressed: () => _showTrophyCabinet(context)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(isOfficialMode ? 'OFFICIAL' : '3RD PARTY',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            Switch(
              value: isOfficialMode,
              activeColor: AppTheme.primary,
              inactiveThumbColor: AppTheme.accent,
              onChanged: (v) => setState(() {
                isOfficialMode = v;
                if (!isOfficialMode) isCSMode = false;
                _currentDashboardPage = 0;
              }),
            ),
          ]),
          IconButton(
              icon: Icon(Icons.admin_panel_settings_outlined,
                  color: accentColor),
              onPressed: () => _promptAdminPin(context)),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('settings')
                .doc('ticker')
                .snapshots(),
            builder: (ctx, snap) {
              Widget ticker = const SizedBox();
              Widget timer = const SizedBox();
              if (snap.hasData && snap.data!.exists) {
                var s = snap.data!.data() as Map<String, dynamic>;
                String t = s['text'] ?? '';
                String n = s['nextMatchTime'] ?? '';
                if (t.isNotEmpty) {
                  ticker = Container(
                    height: 28,
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    child: Marquee(
                        text: '🚨 $t 🚨',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.danger,
                            fontSize: 12),
                        velocity: 40),
                  );
                }
                if (n.isNotEmpty) {
                  DateTime? d = DateTime.tryParse(n);
                  if (d != null && d.isAfter(DateTime.now())) {
                    timer = NextMatchTimer(targetTime: d);
                  }
                }
              }
              return Column(children: [ticker, timer]);
            },
          ),
          if (isOfficialMode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                        label: Text('BR MODE',
                            style: TextStyle(
                                color:
                                !isCSMode ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold)),
                        selected: !isCSMode,
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        shape: StadiumBorder(
                            side: BorderSide(color: AppTheme.border)),
                        onSelected: (_) => setState(() => isCSMode = false)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                        label: Text('CS MODE',
                            style: TextStyle(
                                color:
                                isCSMode ? Colors.white : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold)),
                        selected: isCSMode,
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        shape: StadiumBorder(
                            side: BorderSide(color: AppTheme.border)),
                        onSelected: (_) => setState(() => isCSMode = true)),
                  ]),
            ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('team_stats')
                  .doc(statsDoc)
                  .snapshots(),
              builder: (ctx, baseSnap) {
                int mM = 0, mK = 0, mS = 0;
                if (baseSnap.hasData && baseSnap.data!.exists) {
                  var d = baseSnap.data!.data() as Map<String, dynamic>;
                  mM = d['matches'] ?? 0;
                  mK = d['kills'] ?? 0;
                  mS = d['secondary'] ?? 0;
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(tourneyCol)
                      .snapshots(),
                  builder: (ctx, tSnap) {
                    int totMatches = mM, totKills = mK, totSec = mS;
                    int featM = 0, featP = 0, featK = 0, featT = 0;
                    Map<String, int> featKills = {};
                    String featuredTourneyName = "NO TOURNAMENT";
                    List<Map<String, dynamic>> rawHistory = [];
                    Map<String, Map<String, int>> playerLifetimeT = {};
                    Map<String, dynamic>? activeT;

                    if (tSnap.hasData && tSnap.data!.docs.isNotEmpty) {
                      var docs = tSnap.data!.docs.toList()
                        ..sort((a, b) {
                          var ta = (a.data()
                          as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          var tb = (b.data()
                          as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          if (ta == null || tb == null) return 0;
                          return tb.compareTo(ta);
                        });
                      activeT = docs.first.data() as Map<String, dynamic>;

                      // 🔥 Naye tournament ka base name automatically nikalna
                      // 🔥 Universal filter (No hardcoding)
                      String rawActiveName = (activeT['name'] ?? '').toString().toUpperCase();
                      featuredTourneyName = rawActiveName.replaceAll(RegExp(r'\s*(LEAGUE|BONUS|GROUP STAGE|PLAYINS|KNOCKOUT|PLAYOFF|POINT RUSH|FINALS|QT\.|MATCH|DAY|ROUND|GAME|WEEK|QUALIFIER|SEMI|FINAL)\s*\d*.*$'), '').trim();

                      for (var doc in docs) {
                        var td = doc.data() as Map<String, dynamic>;
                        String rn = (td['name'] ?? 'Unknown').toString().toUpperCase();

                        // Current match ka base name nikalna
                        String currentMatchBaseName = rn.replaceAll(RegExp(r'\s*(LEAGUE|BONUS|GROUP STAGE|PLAYINS|KNOCKOUT|PLAYOFF|POINT RUSH|FINALS|QT\.|MATCH|DAY|ROUND|GAME|WEEK|QUALIFIER|SEMI|FINAL)\s*\d*.*$'), '').trim();
                        bool isFeat = currentMatchBaseName == featuredTourneyName;
                        List ms = td['matches'] ?? [];
                        totMatches += ms.length;
                        for (var sm in ms.reversed) {
                          int cmK = sm['matchKills'] ?? 0;
                          int cmS = isCSMode
                              ? (sm['rounds'] ?? 0)
                              : (sm['posPts'] ?? 0);
                          rawHistory.add({
                            'tourneyName': rn,
                            'name': sm['matchName'] ?? 'M',
                            'date': td['date'] ?? '',
                            'timestamp': td['timestamp'] as Timestamp?,
                            'kills': cmK,
                            'secondary': cmS,
                            'total': cmK + cmS,
                            'playerKills': sm['playerKills'] ?? {},
                          });
                          totKills += cmK;
                          if (isCSMode) {
                            totSec += cmS;
                          } else {
                            if (cmS == 12) totSec += 1;
                          }
                          Map<String, dynamic> mpk = sm['playerKills'] ?? {};
                          mpk.forEach((rp, kc) {
                            String sp = rp
                                .toString()
                                .toUpperCase()
                                .replaceAll('GDR ', '')
                                .replaceAll('NG ', '')
                                .trim();
                            playerLifetimeT.putIfAbsent(sp, () => {});
                            // Har stage ke kills seedha Base Name me hi plus honge
                            playerLifetimeT[sp]![currentMatchBaseName] =
                                (playerLifetimeT[sp]![currentMatchBaseName] ?? 0) + (kc as int);
                          });
                          if (isFeat && !isCSMode) {
                            featM += 1;
                            featK += cmK;
                            featP += cmS;
                            mpk.forEach((pn, kc) {
                              String sp = pn
                                  .toString()
                                  .toUpperCase()
                                  .replaceAll('GDR ', '')
                                  .replaceAll('NG ', '')
                                  .trim();
                              featKills[sp] =
                                  (featKills[sp] ?? 0) + (kc as int);
                            });
                          }
                        }
                      }
                      featT = featK + featP;
                    }

                    List<Map<String, dynamic>> last5Detailed =
                    rawHistory.take(5).toList();
                    List<Map<String, dynamic>> graph5 =
                    last5Detailed.reversed.toList();
                    double avg = totMatches > 0 ? totKills / totMatches : 0;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection(playersCol)
                          .orderBy('eliminations', descending: true)
                          .snapshots(),
                      builder: (ctx, pSnap) {
                        if (!pSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        List<QueryDocumentSnapshot> roster =
                        pSnap.data!.docs.toList()
                          ..sort((a, b) {
                            String sa = (a.data()
                            as Map<String, dynamic>)['status'] ??
                                'ACTIVE';
                            String sb = (b.data()
                            as Map<String, dynamic>)['status'] ??
                                'ACTIVE';
                            if (sa == 'ACTIVE' && sb != 'ACTIVE') return -1;
                            if (sa != 'ACTIVE' && sb == 'ACTIVE') return 1;
                            int ka = (a.data() as Map<String,
                                dynamic>)['eliminations'] ??
                                0;
                            int kb = (b.data() as Map<String,
                                dynamic>)['eliminations'] ??
                                0;
                            return kb.compareTo(ka);
                          });

                        String mvpName = 'No Data';
                        int mvpK = 0;
                        String mvpAvatar = 'https://via.placeholder.com/150';
                        featKills.forEach((p, k) {
                          if (k > mvpK) {
                            mvpK = k;
                            mvpName = p;
                            for (var pl in roster) {
                              var pd = pl.data() as Map<String, dynamic>;
                              String safeRosterName = (pd['name'] ?? '')
                                  .toString()
                                  .toUpperCase()
                                  .replaceAll('GDR ', '')
                                  .replaceAll('NG ', '')
                                  .trim();
                              if (safeRosterName == p) {
                                mvpAvatar = pd['imageUrl'] ?? mvpAvatar;
                              }
                            }
                          }
                        });

                        int pageCount = (isOfficialMode && !isCSMode) ? 3 : 2;

                        List<QueryDocumentSnapshot> filteredRoster =
                        _searchQuery.isEmpty
                            ? roster
                            : roster.where((d) {
                          String n = ((d.data()
                          as Map<String, dynamic>)[
                          'name'] ??
                              '')
                              .toString()
                              .toLowerCase();
                          return n
                              .contains(_searchQuery.toLowerCase());
                        }).toList();

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('DASHBOARD',
                                        style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            fontSize: 14)),
                                    Row(children: [
                                      CleanChipBtn(
                                          label: 'COMPARE',
                                          icon: Icons.compare_arrows,
                                          color: const Color(0xFF8B5CF6),
                                          onTap: () => _showPlayerComparison(
                                              context, roster)),
                                      const SizedBox(width: 8),
                                      CleanChipBtn(
                                          label: 'MAPS',
                                          icon: Icons.map_outlined,
                                          color: accentColor,
                                          onTap: () => _showMapWiseAnalysis(
                                              context, rawHistory)),
                                    ]),
                                  ]),
                            ),
                            SizedBox(
                              height: 200,
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (i) => setState(
                                        () => _currentDashboardPage = i),
                                children: [
                                  if (isOfficialMode && !isCSMode)
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 5),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFF59E0B),
                                              Color(0xFFEF4444)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppTheme.accent
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ],
                                      ),
                                      child: Column(children: [
                                        Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              Container(
                                                  height: 44,
                                                  width: 44,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: Colors.white,
                                                          width: 2),
                                                      image: const DecorationImage(
                                                          image: NetworkImage(
                                                              'https://i.ibb.co/NdC4V0PR/NG-PROS.jpg'),
                                                          fit: BoxFit.cover))),
                                              Text(featuredTourneyName,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      letterSpacing: 1.5)),
                                              const Icon(Icons.emoji_events,
                                                  size: 32,
                                                  color: Colors.white),
                                            ]),
                                        const SizedBox(height: 10),
                                        Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildSmallStatBox('MATCH', '$featM',
                                                  valueColor: Colors.white, labelColor: Colors.white70),
                                              _buildSmallStatBox('P.P', '$featP',
                                                  valueColor: Colors.white, labelColor: Colors.white70),
                                              _buildSmallStatBox('K.P', '$featK',
                                                  valueColor: Colors.white, labelColor: Colors.white70),
                                              _buildSmallStatBox('T.P', '$featT',
                                                  valueColor: Colors.white, labelColor: Colors.white70),
                                            ]),
                                        const Spacer(),
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 8),
                                          decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                              BorderRadius.circular(8)),
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                            children: featKills.keys
                                                .map((p) => Flexible(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                                child: Text('$p: ${featKills[p]}',
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                        color: Colors
                                                            .white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                        FontWeight
                                                            .bold)),
                                              ),
                                            ))
                                                .toList(),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: accentColor.withValues(
                                              alpha: 0.3)),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2))
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  Container(
                                                      height: 48,
                                                      width: 48,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                          BoxShape.circle,
                                                          border: Border.all(
                                                              color:
                                                              accentColor,
                                                              width: 2),
                                                          image: const DecorationImage(
                                                              image: NetworkImage(
                                                                  'https://i.ibb.co/gbX7mcvm/gdr.jpg'),
                                                              fit: BoxFit
                                                                  .cover))),
                                                  Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .end,
                                                      children: [
                                                        Text(
                                                            isOfficialMode
                                                                ? (isCSMode
                                                                ? 'OFFICIAL CS'
                                                                : 'OFFICIAL BR')
                                                                : '3RD PARTY',
                                                            style: TextStyle(
                                                                color:
                                                                AppTheme
                                                                    .textPrimary,
                                                                fontSize: 17,
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                                letterSpacing:
                                                                1)),
                                                        Text('OVERALL',
                                                            style: TextStyle(
                                                                color:
                                                                accentColor,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                                letterSpacing:
                                                                2)),
                                                      ]),
                                                ]),
                                            const SizedBox(height: 20),
                                            Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                                children: [
                                                  StatBox(
                                                      label: 'MATCHES',
                                                      value: '$totMatches'),
                                                  StatBox(
                                                      label: 'KILLS',
                                                      value: '$totKills',
                                                      valueColor: accentColor),
                                                  StatBox(
                                                      label: isCSMode
                                                          ? 'ROUNDS'
                                                          : 'BOOYAH',
                                                      value: '$totSec',
                                                      valueColor:
                                                      AppTheme.secondary),
                                                  StatBox(
                                                      label: 'AVG',
                                                      value: avg.toStringAsFixed(1)),
                                                ]),
                                          ]),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 5),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.border)),
                                    child: Column(children: [
                                      Text('RECENT PERFORMANCE (LAST 5)',
                                          style: TextStyle(
                                              color: accentColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 0.5)),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: graph5.isEmpty
                                            ? const Center(
                                            child: Text(
                                                'Play matches to see graph',
                                                style: TextStyle(
                                                    color: AppTheme.textLight)))
                                            : Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: graph5.map((md) {
                                            int mkv = md['kills'] as int;
                                            int hi = graph5
                                                .map((e) => e['kills'] as int)
                                                .reduce(
                                                    (a, b) => a > b ? a : b);
                                            double r =
                                            hi > 0 ? mkv / hi : 0;
                                            return Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.end,
                                                children: [
                                                  Text('$mkv',
                                                      style: const TextStyle(
                                                          color: AppTheme
                                                              .textPrimary,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          fontSize: 12)),
                                                  const SizedBox(height: 5),
                                                  Container(
                                                      width: 26,
                                                      height:
                                                      60 * r + 5,
                                                      decoration: BoxDecoration(
                                                          color:
                                                          accentColor,
                                                          borderRadius:
                                                          const BorderRadius
                                                              .vertical(
                                                              top: Radius
                                                                  .circular(
                                                                  6)))),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                      md['name']
                                                          .toString()
                                                          .length >
                                                          5
                                                          ? md['name']
                                                          .toString()
                                                          .substring(
                                                          0, 5)
                                                          : md['name'],
                                                      style: const TextStyle(
                                                          color: AppTheme
                                                              .textLight,
                                                          fontSize: 9)),
                                                ]);
                                          }).toList(),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  pageCount,
                                      (i) => Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      height: 6,
                                      width: _currentDashboardPage == i
                                          ? 18
                                          : 6,
                                      decoration: BoxDecoration(
                                          color: _currentDashboardPage == i
                                              ? accentColor
                                              : AppTheme.border,
                                          borderRadius:
                                          BorderRadius.circular(10)))),
                            ),
                            const SizedBox(height: 10),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ChoiceChip(
                                    label: const Text('PLAYER STATS',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    selected: _dashboardTabIndex == 0,
                                    selectedColor: accentColor,
                                    backgroundColor: AppTheme.surface,
                                    labelStyle: TextStyle(
                                        color: _dashboardTabIndex == 0
                                            ? Colors.white
                                            : AppTheme.textPrimary),
                                    shape: StadiumBorder(
                                        side: BorderSide(
                                            color: AppTheme.border)),
                                    onSelected: (_) => setState(
                                            () => _dashboardTabIndex = 0),
                                  ),
                                  const SizedBox(width: 12),
                                  ChoiceChip(
                                    label: const Text('RECENT',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    selected: _dashboardTabIndex == 1,
                                    selectedColor: accentColor,
                                    backgroundColor: AppTheme.surface,
                                    labelStyle: TextStyle(
                                        color: _dashboardTabIndex == 1
                                            ? Colors.white
                                            : AppTheme.textPrimary),
                                    shape: StadiumBorder(
                                        side: BorderSide(
                                            color: AppTheme.border)),
                                    onSelected: (_) => setState(
                                            () => _dashboardTabIndex = 1),
                                  ),
                                ]),
                            if (_dashboardTabIndex == 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: 'Search player...',
                                    hintStyle: const TextStyle(
                                        color: AppTheme.textLight),
                                    prefixIcon:
                                    Icon(Icons.search, color: accentColor),
                                    filled: true,
                                    fillColor: AppTheme.surface,
                                    contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: AppTheme.border)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: AppTheme.border)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                        BorderSide(color: accentColor)),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: _dashboardTabIndex == 1
                                  ? (activeT != null
                                  ? ListView(
                                  padding:
                                  const EdgeInsets.only(bottom: 20),
                                  children: [
                                    if (isOfficialMode && !isCSMode)
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppTheme.accent
                                                  .withValues(
                                                  alpha: 0.4)),
                                        ),
                                        child: Row(children: [
                                          const Icon(Icons.star,
                                              color: AppTheme.accent,
                                              size: 24),
                                          const SizedBox(width: 10),
                                          CleanAvatar(
                                              imageUrl: mvpAvatar,
                                              size: 44,
                                              borderColor:
                                              AppTheme.accent),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Text('$featuredTourneyName MVP',
                                                        style: TextStyle(
                                                            color: AppTheme
                                                                .accent,
                                                            fontSize: 10,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            letterSpacing:
                                                            1)),
                                                    Text(mvpName,
                                                        overflow:
                                                        TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            color: AppTheme
                                                                .textPrimary,
                                                            fontSize: 14,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold)),
                                                  ])),
                                          Text('$mvpK KILLS',
                                              style: const TextStyle(
                                                  color: AppTheme.danger,
                                                  fontSize: 14,
                                                  fontWeight:
                                                  FontWeight.bold)),
                                        ]),
                                      ),
                                    _buildActiveTournamentCard(activeT, roster),
                                  ])
                                  : const Center(
                                  child: Text(
                                      'No active tournament data.',
                                      style: TextStyle(
                                          color: AppTheme.textLight))))
                                  : ListView.builder(
                                itemCount: filteredRoster.length,
                                itemBuilder: (_, i) {
                                  var pd = filteredRoster[i].data()
                                  as Map<String, dynamic>;
                                  String raw = pd['name'] ?? '';
                                  String safe = raw
                                      .toString()
                                      .toUpperCase()
                                      .replaceAll('GDR ', '')
                                      .replaceAll('NG ', '')
                                      .trim();
                                  Map<String, int> hist =
                                      playerLifetimeT[safe] ?? {};
                                  return _buildSimplePlayerCard(
                                      pd, hist, rawHistory);
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: const BoxDecoration(
                                  color: AppTheme.surface,
                                  border: Border(
                                      top: BorderSide(color: AppTheme.border))),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('stats')
                                        .doc('visitors')
                                        .snapshots(),
                                    builder: (ctx, vSnap) {
                                      int v = 0;
                                      if (vSnap.hasData &&
                                          vSnap.data!.exists) {
                                        v = (vSnap.data!.data()
                                        as Map<String, dynamic>)[
                                        'count'] ??
                                            0;
                                      }
                                      return Row(children: [
                                        Icon(Icons.visibility_outlined,
                                            color: accentColor, size: 14),
                                        const SizedBox(width: 4),
                                        Text('$v VISITS',
                                            style: TextStyle(
                                                color: accentColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ]);
                                    },
                                  ),
                                  Row(children: [
                                    const Text('Developed By ',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 10)),
                                    InkWell(
                                      onTap: () => _launchExternalURL(
                                          'https://www.instagram.com/ngxadi45'),
                                      child: Text('ADITYA RAJ',
                                          style: TextStyle(
                                              color: accentColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                              TextDecoration.underline)),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
