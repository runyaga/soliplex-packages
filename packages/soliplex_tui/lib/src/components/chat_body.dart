import 'package:nocterm/nocterm.dart';
import 'package:soliplex_agent/soliplex_agent.dart' hide State;

import 'package:soliplex_tui/src/components/message_item.dart';
import 'package:soliplex_tui/src/signal_builder.dart';

/// Scrollable chat message body with auto-scroll on new content.
///
/// Subscribes to [messages] and [streaming] signals independently,
/// so it only rebuilds when conversation content changes.
///
/// Tracks a stick-to-end flag so the view follows new content
/// automatically.  The flag resets to `true` whenever the message
/// count increases (i.e. user submitted or assistant replied) and
/// is set to `false` when the user manually scrolls away from the
/// bottom between turns.
class ChatBody extends StatefulComponent {
  const ChatBody({
    required this.scrollController,
    required this.messages,
    required this.streaming,
    super.key,
  });

  final ScrollController scrollController;
  final ReadonlySignal<List<ChatMessage>> messages;
  final ReadonlySignal<StreamingState?> streaming;

  @override
  State<ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<ChatBody> {
  /// Message count on the previous build — used to detect new messages.
  int _prevMessageCount = 0;

  /// When `true` the body auto-scrolls to follow new content.
  /// Re-enabled whenever the message count grows; disabled when the
  /// user scrolls away from the end between turns.
  bool _stickToEnd = true;

  /// `true` while the user is drag-selecting text.  Auto-scroll is
  /// suppressed so the viewport doesn't jump out from under the cursor.
  bool _isSelecting = false;

  @override
  Component build(BuildContext context) {
    // Combine both signals into a single builder — they change together
    // during streaming anyway.
    return SignalBuilder<List<ChatMessage>>(
      signal: component.messages,
      builder: (context, msgs) {
        final stream = component.streaming.value;
        final hasStreamingItem =
            stream is TextStreaming && stream.text.isNotEmpty ||
                stream is AwaitingText && stream.hasThinkingContent;

        final itemCount = msgs.length + (hasStreamingItem ? 1 : 0);

        // Between turns (no active stream), honour the user's scroll
        // position: if they scrolled away from the end, stop sticking.
        if (stream == null && !component.scrollController.atEnd) {
          _stickToEnd = false;
        }

        // New message(s) added — re-enable stick and snap to end so the
        // user always sees their latest question / the assistant reply.
        if (msgs.length > _prevMessageCount) {
          _stickToEnd = true;
          if (!_isSelecting) {
            component.scrollController.scrollToEnd();
          }
        }
        _prevMessageCount = msgs.length;

        // Follow streaming content while sticking to end.
        if (stream != null && _stickToEnd && !_isSelecting) {
          component.scrollController.scrollToEnd();
        }

        return SelectionArea(
          onSelectionChanged: (text) {
            // Only suppress auto-scroll for real selections, not clicks.
            _isSelecting = text.isNotEmpty;
          },
          onSelectionCompleted: (text) {
            _isSelecting = false;
            if (text.isNotEmpty) {
              ClipboardManager.copy(text);
            }
          },
          child: Scrollbar(
            controller: component.scrollController,
            child: ListView.builder(
              controller: component.scrollController,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index < msgs.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: MessageItem(message: msgs[index]),
                  );
                }
                if (stream != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: StreamingMessageItem(streaming: stream),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  }
}
