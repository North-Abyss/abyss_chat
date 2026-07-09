import 'dart:io';

void main() {
  final file = File('lib/providers/chat_provider.dart');
  final lines = file.readAsLinesSync();
  int depth = 0;
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('class ChatThreadsNotifier')) {
      print('Class starts at line ${i+1}');
    }
    for (int j = 0; j < line.length; j++) {
      if (line[j] == '{') depth++;
      if (line[j] == '}') depth--;
    }
    if (depth == 0 && i > 150) {
      print('Depth 0 at line ${i+1}: $line');
      break;
    }
  }
}
