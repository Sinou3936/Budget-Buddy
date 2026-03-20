class OcrResult {
  final String title;
  final double? amount;
  final String category;
  final String? memo;

  const OcrResult({
    required this.title,
    required this.amount,
    required this.category,
    this.memo,
  });
}
