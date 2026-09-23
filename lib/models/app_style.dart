/// Persisted presentation identity. Only installed presentations are selectable.
enum AppStyle {
  southAfrica2010('south-africa-2010');

  const AppStyle(this.storageValue);
  final String storageValue;

  static AppStyle fromStorage(String? value) => values.firstWhere(
    (style) => style.storageValue == value,
    orElse: () => southAfrica2010,
  );
}
