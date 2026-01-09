class FallingWord {
  FallingWord({
    required this.text,
    required this.x,
    required this.y,
    required this.speed,
  });

  final String text;
  double x; // 0..1
  double y; // 0..1 (0 top, 1 bottom)
  double speed; // logical units per second
}


