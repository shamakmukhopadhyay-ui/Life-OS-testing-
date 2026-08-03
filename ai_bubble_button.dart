import 'package:flutter/material.dart';

/// The floating AI assistant entry point — LifeOS V2-01 Task 6.
///
/// Lives on HomeScreen's `floatingActionButton` so it's visible from
/// every primary tab (Home/Today/Learn/Library share one Scaffold — see
/// home_screen.dart), rather than being duplicated per-screen. Tapping
/// it opens a placeholder bottom sheet; nothing here talks to any AI
/// provider yet.
///
/// Deliberately owns its own tap handling rather than taking an
/// `onPressed` callback — replacing "show a placeholder sheet" with a
/// real assistant later means changing what happens inside [_open], not
/// this widget's shape or where it's mounted. Uses an explicit
/// [FloatingActionButton.heroTag] since it can sit alongside Home's
/// existing "add task" FAB.
class AiBubbleButton extends StatelessWidget {
  const AiBubbleButton({super.key});

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 32),
              SizedBox(height: 12),
              Text('AI Assistant coming soon.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'aiBubble',
      tooltip: 'AI Assistant',
      onPressed: () => _open(context),
      child: const Icon(Icons.auto_awesome),
    );
  }
}
