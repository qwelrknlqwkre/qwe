enum CardType { gwang, tti, pi, animal, back }

class GoStopCard {
  final int id;
  final int month; // 1 ~ 12
  final CardType type;
  final String name;
  final String imageUrl;

  GoStopCard({
    required this.id,
    required this.month,
    required this.type,
    required this.name,
    required this.imageUrl,
  });
}