class User {
  final String id;
  final String username;
  final String? iconPath;

  const User({
    required this.id,
    required this.username,
    this.iconPath,
  });
}