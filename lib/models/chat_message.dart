enum ChatRole { user, assistant }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
