class GoStopCard {
  final int id;
  final int month; // 1 ~ 12
  final String type; // '광', '띠', '피', etc.
  final String name;
  final String imageUrl;
  final bool isBonus;

  GoStopCard({
    required this.id,
    required this.month,
    required this.type,
    required this.name,
    required this.imageUrl,
    this.isBonus = false,
  });
}