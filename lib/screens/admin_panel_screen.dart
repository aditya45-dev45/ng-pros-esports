import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../widgets/clean_avatar.dart';
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool isOfficialMode = true;
  bool isCSMode = false;

  String get activePlayersCollection => !isOfficialMode
      ? 'players'
      : (isCSMode ? 'players_official_cs' : 'players_official');
  String get activeTournamentsCollection => !isOfficialMode
      ? 'tournaments'
      : (isCSMode ? 'tournaments_official_cs' : 'tournaments_official');
  String get activeStatsDocument => !isOfficialMode
      ? 'third_party'
      : (isCSMode ? 'official_cs' : 'official');

  Color get themeAccentColor =>
      !isOfficialMode ? AppTheme.accent : AppTheme.primary;

  final tournamentNameController = TextEditingController();
  final tournamentDateController = TextEditingController();
  final tournamentTimeController = TextEditingController();
  List<String> selectedPlayingFour = [];

  TextEditingController manualTotalMatchesController = TextEditingController();
  TextEditingController manualTotalKillsController = TextEditingController();
  TextEditingController manualSecondaryStatsController =
  TextEditingController();

  Future<void> _createNewTournament() async {
    if (selectedPlayingFour.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select exactly 4 players!'),
          backgroundColor: AppTheme.danger));
      return;
    }
    await FirebaseFirestore.instance
        .collection(activeTournamentsCollection)
        .add({
      'name': tournamentNameController.text,
      'date': tournamentDateController.text,
      'time': tournamentTimeController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'playingFour': selectedPlayingFour,
      'matches': [],
      'totalKills': 0,
      'totalPosPts': 0,
      'overallPts': 0,
      'podiumPosition': 0,
    });
    tournamentNameController.clear();
    tournamentDateController.clear();
    tournamentTimeController.clear();
    setState(() {
      selectedPlayingFour.clear();
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('New Tournament Started!'),
        backgroundColor: AppTheme.secondary));
  }

  void _openCreateTournamentDialog(List<DocumentSnapshot> roster) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Start New Tournament',
                style: TextStyle(color: themeAccentColor)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _buildAdminTextField(
                    tournamentDateController, 'Match Date (e.g. 28 Feb)'),
                _buildAdminTextField(
                    tournamentTimeController, 'Start Time (e.g. 12 PM)'),
                _buildAdminTextField(tournamentNameController,
                    'Tournament Name (Add "FINAL" for Trophy)'),
                const SizedBox(height: 10),
                const Text('Select Default Playing 4:',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold)),
                ...roster.map((d) {
                  String n = d['name'];
                  bool sel = selectedPlayingFour.contains(n);
                  return CheckboxListTile(
                    title: Text(n,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14)),
                    value: sel,
                    activeColor: themeAccentColor,
                    onChanged: (v) => setS(() {
                      if (v == true && selectedPlayingFour.length < 4) {
                        selectedPlayingFour.add(n);
                      } else if (v == false) {
                        selectedPlayingFour.remove(n);
                      }
                    }),
                  );
                }),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: _createNewTournament,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: themeAccentColor,
                      foregroundColor: Colors.white),
                  child: const Text('Create')),
            ],
          )),
    );
  }

  void _openAddMatchDataDialog(String tId, Map<String, dynamic> tData,
      List<DocumentSnapshot> allP) {
    final mNCtrl = TextEditingController();
    final secCtrl = TextEditingController();
    List<String> roster = allP.map((d) => d['name'].toString()).toList();
    if (roster.isEmpty) roster.add("No Players");

    List<String> squad = List<String>.from(tData['playingFour'] ?? []);
    if (squad.length < 4 || squad.toSet().length < 4) {
      squad.clear();
      for (int i = 0; i < 4; i++) {
        squad.add(i < roster.length ? roster[i] : roster.first);
      }
    }

    List<TextEditingController> kCtrls =
    List.generate(4, (_) => TextEditingController(text: '0'));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Add Match Data',
                style: TextStyle(color: themeAccentColor)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _buildAdminTextField(mNCtrl, 'Match Map/Name'),
                _buildAdminTextField(
                    secCtrl,
                    isCSMode ? 'Total Rounds' : 'Placement Points',
                    isNumberInput: true),
                const Divider(color: AppTheme.divider),
                const Text('Playing 4 & Kills:',
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 12)),
                const SizedBox(height: 10),
                ...List.generate(
                    4,
                        (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10),
                              decoration: BoxDecoration(
                                  color: AppTheme.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppTheme.border)),
                              child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: roster.contains(squad[i])
                                        ? squad[i]
                                        : roster.first,
                                    isExpanded: true,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13),
                                    items: roster
                                        .map((n) => DropdownMenuItem(
                                        value: n, child: Text(n)))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setS(() => squad[i] = v);
                                      }
                                    },
                                  )),
                            )),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 1,
                            child: _buildAdminTextField(
                                kCtrls[i], 'Kills',
                                isNumberInput: true)),
                      ]),
                    )),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: themeAccentColor,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  int sec = int.tryParse(secCtrl.text) ?? 0;
                  int totK = 0;
                  Map<String, int> pkData = {};
                  for (int i = 0; i < 4; i++) {
                    String n = squad[i];
                    int k = int.tryParse(kCtrls[i].text) ?? 0;
                    totK += k;
                    pkData[n] = (pkData[n] ?? 0) + k;
                  }
                  Map<String, dynamic> rec = {
                    'matchName': mNCtrl.text,
                    'matchKills': totK,
                    'playerKills': pkData
                  };
                  if (isCSMode) {
                    rec['rounds'] = sec;
                  } else {
                    rec['posPts'] = sec;
                    rec['matchTotal'] = totK + sec;
                  }

                  await FirebaseFirestore.instance
                      .collection(activeTournamentsCollection)
                      .doc(tId)
                      .update({
                    'matches': FieldValue.arrayUnion([rec]),
                    'totalKills': FieldValue.increment(totK),
                    if (!isCSMode)
                      'totalPosPts': FieldValue.increment(sec),
                    if (!isCSMode)
                      'overallPts': FieldValue.increment(totK + sec),
                    if (isCSMode)
                      'totalRounds': FieldValue.increment(sec),
                  });

                  for (String pn in pkData.keys) {
                    int kc = pkData[pn]!;
                    var q = await FirebaseFirestore.instance
                        .collection(activePlayersCollection)
                        .where('name', isEqualTo: pn)
                        .get();
                    if (q.docs.isNotEmpty) {
                      var d = q.docs.first;
                      int hi = (d.data() as Map<String, dynamic>)
                          .containsKey('highestKills')
                          ? d['highestKills']
                          : 0;
                      int newHi = kc > hi ? kc : hi;
                      await d.reference.update({
                        'eliminations': FieldValue.increment(kc),
                        'matchesPlayed': FieldValue.increment(1),
                        'highestKills': newHi
                      });
                    }
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Match Saved!'),
                          backgroundColor: AppTheme.secondary));
                },
                child: const Text('Save Match'),
              ),
            ],
          )),
    );
  }

  Future<void> _deleteSpecificMatch(String tId, Map<String, dynamic> tData,
      Map<String, dynamic> rec) async {
    bool? c = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Delete Match?',
              style: TextStyle(color: AppTheme.danger)),
          content: Text("Delete '${rec['matchName']}'? Stats will revert.",
              style: const TextStyle(color: AppTheme.textPrimary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete')),
          ],
        ));
    if (c != true) return;

    int kR = rec['matchKills'] ?? 0;
    int sR = isCSMode ? (rec['rounds'] ?? 0) : (rec['posPts'] ?? 0);
    int tR = rec['matchTotal'] ?? 0;

    await FirebaseFirestore.instance
        .collection(activeTournamentsCollection)
        .doc(tId)
        .update({
      'matches': FieldValue.arrayRemove([rec]),
      'totalKills': FieldValue.increment(-kR),
      if (!isCSMode) 'totalPosPts': FieldValue.increment(-sR),
      if (!isCSMode) 'overallPts': FieldValue.increment(-tR),
      if (isCSMode) 'totalRounds': FieldValue.increment(-sR),
    });

    Map<String, dynamic> pk = rec['playerKills'] ?? {};
    for (String pn in pk.keys) {
      int kr = pk[pn] ?? 0;
      var q = await FirebaseFirestore.instance
          .collection(activePlayersCollection)
          .where('name', isEqualTo: pn)
          .get();
      if (q.docs.isNotEmpty) {
        await q.docs.first.reference.update({
          'eliminations': FieldValue.increment(-kr),
          'matchesPlayed': FieldValue.increment(-1)
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Match Deleted!'),
        backgroundColor: AppTheme.accent));
  }

  Future<void> _deleteTournamentAndRevertStats(
      String tId, Map<String, dynamic> tData) async {
    List ms = tData['matches'] ?? [];
    for (var sm in ms) {
      Map<String, dynamic> pk = sm['playerKills'] ?? {};
      for (String pn in pk.keys) {
        int kr = pk[pn] ?? 0;
        var q = await FirebaseFirestore.instance
            .collection(activePlayersCollection)
            .where('name', isEqualTo: pn)
            .get();
        if (q.docs.isNotEmpty) {
          await q.docs.first.reference.update({
            'eliminations': FieldValue.increment(-kr),
            'matchesPlayed': FieldValue.increment(-1)
          });
        }
      }
    }
    await FirebaseFirestore.instance
        .collection(activeTournamentsCollection)
        .doc(tId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tournament Deleted!'),
        backgroundColor: AppTheme.danger));
  }

  void _setPodiumPositionDialog(String tId, Map<String, dynamic> tData) {
    int currentPos = tData['podiumPosition'] ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Set Podium Finish',
                style: TextStyle(color: themeAccentColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Did the team finish in the top 3? Select the position to add a trophy to the cabinet.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 15),
                ListTile(
                  title: const Text('🥇 1st Place (Gold)',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  leading: Radio<int>(
                      value: 1,
                      groupValue: currentPos,
                      activeColor: AppTheme.accent,
                      onChanged: (v) =>
                          setDialogState(() => currentPos = v!)),
                  onTap: () => setDialogState(() => currentPos = 1),
                ),
                ListTile(
                  title: const Text('🥈 2nd Place (Silver)',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  leading: Radio<int>(
                      value: 2,
                      groupValue: currentPos,
                      activeColor: AppTheme.textLight,
                      onChanged: (v) =>
                          setDialogState(() => currentPos = v!)),
                  onTap: () => setDialogState(() => currentPos = 2),
                ),
                ListTile(
                  title: const Text('🥉 3rd Place (Bronze)',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  leading: Radio<int>(
                      value: 3,
                      groupValue: currentPos,
                      activeColor: const Color(0xFFCD7F32),
                      onChanged: (v) =>
                          setDialogState(() => currentPos = v!)),
                  onTap: () => setDialogState(() => currentPos = 3),
                ),
                ListTile(
                  title: const Text('❌ Not in Top 3',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  leading: Radio<int>(
                      value: 0,
                      groupValue: currentPos,
                      activeColor: AppTheme.danger,
                      onChanged: (v) =>
                          setDialogState(() => currentPos = v!)),
                  onTap: () => setDialogState(() => currentPos = 0),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: themeAccentColor,
                    foregroundColor: Colors.white),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection(activeTournamentsCollection)
                      .doc(tId)
                      .update({'podiumPosition': currentPos});
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Podium Position Saved!'),
                          backgroundColor: AppTheme.secondary));
                },
                child: const Text('Save Trophy'),
              ),
            ],
          )),
    );
  }

  Widget _buildAdminTextField(TextEditingController c, String l,
      {bool isNumberInput = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: c,
        keyboardType: isNumberInput ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surfaceAlt,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: themeAccentColor)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('ADMIN CONTROL',
              style: TextStyle(
                  color: themeAccentColor, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: themeAccentColor),
          actions: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(isOfficialMode ? 'OFFICIAL' : '3RD PARTY',
                  style: TextStyle(
                      color: themeAccentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Switch(
                value: isOfficialMode,
                activeColor: AppTheme.primary,
                inactiveThumbColor: AppTheme.accent,
                onChanged: (v) => setState(() {
                  isOfficialMode = v;
                  if (!isOfficialMode) isCSMode = false;
                  manualTotalMatchesController.clear();
                  manualTotalKillsController.clear();
                  manualSecondaryStatsController.clear();
                }),
              ),
            ]),
            const SizedBox(width: 15),
          ],
          bottom: TabBar(
            indicatorColor: themeAccentColor,
            labelColor: themeAccentColor,
            unselectedLabelColor: AppTheme.textLight,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'PLAYERS'),
              Tab(icon: Icon(Icons.timeline), text: 'TOURNAMENTS'),
              Tab(icon: Icon(Icons.settings), text: 'TEAM STATS')
            ],
          ),
        ),
        body: Column(
          children: [
            if (isOfficialMode)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 5),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                          label: Text('BR MODE',
                              style: TextStyle(
                                  color: !isCSMode
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold)),
                          selected: !isCSMode,
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.surface,
                          shape: StadiumBorder(
                              side: BorderSide(color: AppTheme.border)),
                          onSelected: (_) => setState(() {
                            isCSMode = false;
                            manualTotalMatchesController.clear();
                            manualTotalKillsController.clear();
                            manualSecondaryStatsController.clear();
                          })),
                      const SizedBox(width: 15),
                      ChoiceChip(
                          label: Text('CS MODE',
                              style: TextStyle(
                                  color: isCSMode
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold)),
                          selected: isCSMode,
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.surface,
                          shape: StadiumBorder(
                              side: BorderSide(color: AppTheme.border)),
                          onSelected: (_) => setState(() {
                            isCSMode = true;
                            manualTotalMatchesController.clear();
                            manualTotalKillsController.clear();
                            manualSecondaryStatsController.clear();
                          })),
                    ]),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  // PLAYERS TAB
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(activePlayersCollection)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: themeAccentColor));
                      }
                      final list = snap.data!.docs;
                      if (list.isEmpty) {
                        return Center(
                            child: Text("No players yet.",
                                style: TextStyle(color: themeAccentColor)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          var pd = list[i].data() as Map<String, dynamic>;
                          var pid = list[i].id;
                          final eEl = TextEditingController(
                              text: '${pd['eliminations'] ?? 0}');
                          final eM = TextEditingController(
                              text: '${pd['matchesPlayed'] ?? 0}');
                          final eH = TextEditingController(
                              text: '${pd['highestKills'] ?? 0}');
                          final eI = TextEditingController(
                              text: pd['instaLink'] ?? '');
                          final eY = TextEditingController(
                              text: pd['ytLink'] ?? '');
                          return Card(
                            color: AppTheme.surface,
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppTheme.border)),
                            child: ExpansionTile(
                              leading: CleanAvatar(
                                  imageUrl: pd['imageUrl'] ??
                                      'https://via.placeholder.com/150',
                                  size: 44,
                                  borderColor: themeAccentColor),
                              title: Text(pd['name'] ?? '',
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text('Tap to Edit',
                                  style: TextStyle(
                                      color: themeAccentColor, fontSize: 12)),
                              iconColor: themeAccentColor,
                              collapsedIconColor: AppTheme.textLight,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(children: [
                                    Row(children: [
                                      Expanded(
                                          child: _buildAdminTextField(
                                              eM, 'Matches',
                                              isNumberInput: true)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: _buildAdminTextField(
                                              eEl, 'Kills',
                                              isNumberInput: true)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: _buildAdminTextField(
                                              eH, 'Highest',
                                              isNumberInput: true)),
                                    ]),
                                    _buildAdminTextField(eI, 'Instagram Link'),
                                    _buildAdminTextField(eY, 'YouTube Link'),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.secondary,
                                          foregroundColor: Colors.white),
                                      icon: const Icon(Icons.save),
                                      label: const Text('Save'),
                                      onPressed: () {
                                        FirebaseFirestore.instance
                                            .collection(
                                            activePlayersCollection)
                                            .doc(pid)
                                            .update({
                                          'eliminations':
                                          int.tryParse(eEl.text) ?? 0,
                                          'matchesPlayed':
                                          int.tryParse(eM.text) ?? 0,
                                          'highestKills':
                                          int.tryParse(eH.text) ?? 0,
                                          'instaLink': eI.text,
                                          'ytLink': eY.text,
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                            content:
                                            Text('Player Updated!'),
                                            backgroundColor:
                                            AppTheme.secondary));
                                      },
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // TOURNAMENTS TAB
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(activePlayersCollection)
                        .snapshots(),
                    builder: (ctx, rSnap) => Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Start New Tournament',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: themeAccentColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50)),
                          onPressed: () {
                            if (rSnap.hasData) {
                              _openCreateTournamentDialog(rSnap.data!.docs);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(activeTournamentsCollection)
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (ctx, tSnap) {
                            if (!tSnap.hasData) {
                              return Center(
                                  child: CircularProgressIndicator(
                                      color: themeAccentColor));
                            }
                            final tl = tSnap.data!.docs;
                            return ListView.builder(
                              itemCount: tl.length,
                              itemBuilder: (_, i) {
                                var td = tl[i].data() as Map<String, dynamic>;
                                var tid = tl[i].id;

                                bool isFinalMatch = (td['name'] ?? '')
                                    .toString()
                                    .toUpperCase()
                                    .contains('FINAL');

                                return Card(
                                  color: AppTheme.surface,
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side:
                                      BorderSide(color: AppTheme.border)),
                                  child: ExpansionTile(
                                    title: Text(
                                        '${td['name']} (${td['date']})',
                                        style: TextStyle(
                                            color: themeAccentColor,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        isCSMode
                                            ? 'Kills: ${td['totalKills']}'
                                            : 'Pts: ${td['overallPts']} | Kills: ${td['totalKills']}',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary)),
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.add_circle,
                                            color: AppTheme.secondary),
                                        title: const Text('Add Match Data',
                                            style: TextStyle(
                                                color: AppTheme.secondary)),
                                        onTap: () {
                                          if (rSnap.hasData) {
                                            _openAddMatchDataDialog(
                                                tid, td, rSnap.data!.docs);
                                          }
                                        },
                                      ),
                                      const Divider(color: AppTheme.divider),
                                      if (isFinalMatch) ...[
                                        ListTile(
                                          leading: const Icon(
                                              Icons.emoji_events,
                                              color: AppTheme.accent),
                                          title: const Text(
                                              'Set Podium Finish (Trophy)',
                                              style: TextStyle(
                                                  color: AppTheme.accent)),
                                          onTap: () =>
                                              _setPodiumPositionDialog(tid, td),
                                        ),
                                        const Divider(color: AppTheme.divider),
                                      ],
                                      ...((td['matches'] ?? []) as List)
                                          .map((rec) => ListTile(
                                        dense: true,
                                        title: Text(rec['matchName'],
                                            style: const TextStyle(
                                                color: AppTheme
                                                    .textPrimary,
                                                fontWeight:
                                                FontWeight.bold)),
                                        subtitle: Text(
                                            'Kills: ${rec['matchKills']}',
                                            style: const TextStyle(
                                                color: AppTheme
                                                    .textSecondary,
                                                fontSize: 11)),
                                        trailing: IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppTheme.danger),
                                            onPressed: () =>
                                                _deleteSpecificMatch(
                                                    tid, td, rec)),
                                      )),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_forever,
                                            color: AppTheme.danger),
                                        label: const Text('Delete Tournament',
                                            style: TextStyle(
                                                color: AppTheme.danger)),
                                        onPressed: () =>
                                            _deleteTournamentAndRevertStats(
                                                tid, td),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ]),
                  ),

                  // TEAM STATS TAB
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MANUAL OVERRIDE (BASE STATS)',
                            style: TextStyle(
                                color: themeAccentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 5),
                        const Text('Foundation of Overall Dashboard.',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 15),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('team_stats')
                              .doc(activeStatsDocument)
                              .snapshots(),
                          builder: (ctx, sSnap) {
                            if (sSnap.hasData && sSnap.data!.exists) {
                              var d = sSnap.data!.data()
                              as Map<String, dynamic>;
                              if (manualTotalMatchesController.text.isEmpty) {
                                manualTotalMatchesController.text =
                                    (d['matches'] ?? 0).toString();
                              }
                              if (manualTotalKillsController.text.isEmpty) {
                                manualTotalKillsController.text =
                                    (d['kills'] ?? 0).toString();
                              }
                              if (manualSecondaryStatsController.text.isEmpty) {
                                manualSecondaryStatsController.text =
                                    (d['secondary'] ?? 0).toString();
                              }
                            }
                            return Column(children: [
                              _buildAdminTextField(manualTotalMatchesController,
                                  'Total Past Matches',
                                  isNumberInput: true),
                              _buildAdminTextField(manualTotalKillsController,
                                  'Total Past Kills',
                                  isNumberInput: true),
                              _buildAdminTextField(
                                  manualSecondaryStatsController,
                                  isCSMode
                                      ? 'Total Past Rounds'
                                      : 'Total Past Booyahs',
                                  isNumberInput: true),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondary,
                                    foregroundColor: Colors.white,
                                    minimumSize:
                                    const Size(double.infinity, 45)),
                                icon: const Icon(Icons.save),
                                label: const Text('UPDATE STATS',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1)),
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('team_stats')
                                      .doc(activeStatsDocument)
                                      .set({
                                    'matches': int.tryParse(
                                        manualTotalMatchesController
                                            .text) ??
                                        0,
                                    'kills': int.tryParse(
                                        manualTotalKillsController.text) ??
                                        0,
                                    'secondary': int.tryParse(
                                        manualSecondaryStatsController
                                            .text) ??
                                        0,
                                  }, SetOptions(merge: true));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Base Stats Updated!'),
                                          backgroundColor: AppTheme.secondary));
                                },
                              ),
                            ]);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
