import 'dart:math';

/// Generates a locally-unique string id for mock/in-memory records,
/// before real persistence (with real primary keys) exists.
///
/// Bug fix: both the Objectives and Tasks "create" forms previously
/// generated ids as `DateTime.now().microsecondsSinceEpoch.toString()`
/// alone. Two ids created in extremely quick succession could in theory
/// collide on that value on some platforms. Appending a random suffix
/// makes that collision effectively impossible without requiring a new
/// dependency (uses only `dart:math`, already part of the Dart SDK).
final Random _random = Random();

String generateLocalId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final randomSuffix = _random.nextInt(1000000).toString().padLeft(6, '0');
  return '$timestamp-$randomSuffix';
}
