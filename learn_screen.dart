import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

/// Learn tab root — LifeOS V2-01.
///
/// Just the empty state and a Create button, per this sprint's scope —
/// "no functionality yet." No Learning Space model, no persistence, no
/// AI: those need the Learn feature's actual Data/Logic layers, which a
/// future sprint builds.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  void _createSpace(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Learning Spaces are coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyState(
                icon: Icons.school_outlined,
                title: 'No Learning Spaces yet',
                message: 'Learning Spaces will hold your notebooks, '
                    'sources, study guides, and flashcards for a topic.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _createSpace(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Learning Space'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
