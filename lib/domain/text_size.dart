enum TextSize {
  small(0.85),
  normal(1.0),
  large(1.15),
  extraLarge(1.3);

  final double scale;

  const TextSize(this.scale);
}
