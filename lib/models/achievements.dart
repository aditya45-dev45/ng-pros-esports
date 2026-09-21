import 'package:flutter/material.dart';
import '../core/theme.dart';

class Achievement {
  final String name, icon, desc;
  final Color color;

  Achievement(this.name, this.icon, this.desc, this.color);
}

List<Achievement> computeAchievements(
    Map<String, dynamic> p, Map<String, int> tournamentKills) {
  List<Achievement> badges = [];
  int kills = p['eliminations'] ?? 0;
  int matches = p['matchesPlayed'] ?? 0;
  int highest = p['highestKills'] ?? 0;

  if (highest >= 10) {
    badges.add(Achievement(
        'SNIPER', '🎯', '10+ kills in a single match', AppTheme.danger));
  }
  if (matches >= 50) {
    badges.add(
        Achievement('VETERAN', '🛡️', '50+ matches played', AppTheme.primary));
  }
  if (kills >= 500) {
    badges.add(Achievement(
        'LEGEND', '👑', '500+ total eliminations', AppTheme.accent));
  }
  if (kills >= 100 && kills < 500) {
    badges.add(Achievement(
        'GRINDER', '⚙️', '100+ eliminations', AppTheme.secondary));
  }
  if (tournamentKills.length >= 5) {
    badges.add(Achievement('CAMPAIGNER', '🏆', 'Played 5+ tournaments',
        const Color(0xFF8B5CF6)));
  }

  double avg = matches > 0 ? kills / matches : 0;
  if (avg >= 3) {
    badges.add(Achievement(
        'CLUTCH KING', '⚡', 'Avg 3+ kills/match', const Color(0xFFEC4899)));
  }

  return badges;
}