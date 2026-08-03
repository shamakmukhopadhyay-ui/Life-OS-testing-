import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/day_workspace/presentation/day_workspace_screen.dart';
import '../../features/documents/data/document_model.dart';
import '../../features/documents/presentation/document_editor_screen.dart';
import '../../features/documents/presentation/documents_list_screen.dart';
import '../../features/documents/presentation/search_screen.dart';
import '../../features/documents/presentation/tag_documents_screen.dart';
import '../../features/documents/presentation/tag_explorer_screen.dart';
import '../../features/documents/presentation/vault_status_screen.dart';
import '../../features/documents/presentation/views_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/objectives/presentation/objectives_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/objectives',
        name: 'objectives',
        builder: (context, state) => const ObjectivesScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/calendar/:date',
        name: 'dayWorkspace',
        builder: (context, state) {
          final parts = state.pathParameters['date']!.split('-');
          return DayWorkspaceScreen(
            date: DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ),
          );
        },
      ),
      GoRoute(
        path: '/document',
        name: 'documentEditor',
        builder: (context, state) {
          // Document is passed via extra to avoid encoding path in URL.
          // Not deep-linkable — acceptable for local documents (MVP).
          final doc = state.extra as Document;
          return DocumentEditorScreen(document: doc);
        },
      ),
      GoRoute(
        path: '/documents',
        name: 'documentsList',
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: '/vault-status',
        name: 'vaultStatus',
        builder: (context, state) => const VaultStatusScreen(),
      ),
      GoRoute(
        path: '/views',
        name: 'documentViews',
        builder: (context, state) => const ViewsScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/tags',
        name: 'tagExplorer',
        builder: (context, state) => const TagExplorerScreen(),
      ),
      GoRoute(
        path: '/tag',
        name: 'tagDocuments',
        builder: (context, state) {
          // Tag is passed via extra to avoid encoding an arbitrary
          // frontmatter string into a URL path segment — same reasoning
          // as the /document route above.
          final tag = state.extra as String;
          return TagDocumentsScreen(tag: tag);
        },
      ),
      // V2-01: deep-link into a specific shell tab. Each just picks a
      // different initialIndex on the same HomeScreen the '/' route
      // already uses — not four separate screens.
      GoRoute(
        path: '/home',
        name: 'homeTab',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/today',
        name: 'todayTab',
        builder: (context, state) => const HomeScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/learn',
        name: 'learnTab',
        builder: (context, state) => const HomeScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/library',
        name: 'libraryTab',
        builder: (context, state) => const HomeScreen(initialIndex: 3),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
