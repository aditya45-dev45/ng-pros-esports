String cleanPlayerName(String rawName) {
  return rawName
      .toUpperCase()
      .replaceAll('GDR ', '')
      .replaceAll('NG ', '')
      .trim();
}

String getBaseTournamentName(String rawName) {
  return rawName
      .toUpperCase()
      .replaceAll(RegExp(r'\s*(LEAGUE|BONUS|GROUP STAGE|K\.O STAGE|TOP\s*\d+|PLAYINS|KNOCKOUT|PLAYOFF|POINT RUSH|FINALS|QT\.|MATCH|DAY|ROUND|GAME|WEEK|QUALIFIER|SEMI|FINAL|GRAND)\s*\d*.*$'), '')
      .trim();
}