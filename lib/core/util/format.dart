/// Human-friendly relative time in French ("il y a 3 h").
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'à l’instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem';
  if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
  final years = (diff.inDays / 365).floor();
  return 'il y a $years an${years > 1 ? 's' : ''}';
}

/// Compact count formatting (1234 -> "1,2 k", 1500000 -> "1,5 M").
String compactCount(int n) {
  if (n.abs() >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1).replaceAll('.', ',')} M';
  }
  if (n.abs() >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll('.', ',')} k';
  }
  return '$n';
}
