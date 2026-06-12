import 'package:flutter/foundation.dart';

/// Commands accepted by a [MagicWidgetController].
enum MagicCommand {
  /// Start (or restart) the reveal animation.
  play,

  /// Hide the child again and rewind the effect.
  reset,
}

/// Controls a `MagicWidget` from outside the widget tree.
///
/// Attach it via `MagicWidget(controller: ...)`, then call [play] to start
/// (or replay) the reveal and [reset] to hide the child again.
class MagicWidgetController extends ChangeNotifier {
  MagicCommand? _pendingCommand;

  /// The last command issued, consumed by the widget state.
  MagicCommand? get pendingCommand => _pendingCommand;

  /// Starts or restarts the magic reveal.
  void play() => _sendCommand(MagicCommand.play);

  /// Hides the child and rewinds the effect.
  void reset() => _sendCommand(MagicCommand.reset);

  void _sendCommand(MagicCommand command) {
    _pendingCommand = command;
    notifyListeners();
  }

  /// Marks the pending command as handled. Called by the widget state.
  void consumeCommand() => _pendingCommand = null;
}
