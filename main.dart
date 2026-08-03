import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/database_service.dart';
import 'features/documents/data/default_vault_repository.dart';
import 'features/documents/logic/document_provider.dart';

/// Opens the database, wires the vault repository, and starts the app.
///
/// Provider override order matters: [databaseProvider] must be available
/// before [documentRepositoryProvider] reads it (which happens lazily
/// when the first document screen is shown, not at startup).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseService.openDatabase();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        vaultRepositoryProvider.overrideWithValue(
          const DefaultVaultRepository(),
        ),
      ],
      child: const LifeOSApp(),
    ),
  );
}
