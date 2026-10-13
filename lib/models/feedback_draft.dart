class FeedbackDraft {
  const FeedbackDraft({this.message = '', this.email = ''});

  final String message;
  final String email;

  Map<String, String> toJson() => {'message': message, 'email': email};

  factory FeedbackDraft.fromJson(Map<String, dynamic> json) {
    if (json['message'] is! String || json['email'] is! String) {
      throw const FormatException('Invalid feedback draft');
    }
    return FeedbackDraft(
      message: json['message'] as String,
      email: json['email'] as String,
    );
  }
}

class FeedbackContext {
  const FeedbackContext({
    required this.version,
    required this.build,
    required this.platform,
  });

  final String version;
  final String build;
  final String platform;
}
