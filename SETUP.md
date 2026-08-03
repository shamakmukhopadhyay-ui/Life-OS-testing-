# Verifying Phase 1 Locally

This sandbox has no Flutter SDK and no network access, so I hand-wrote every
file exactly as `flutter create` plus manual setup would produce — but I
could not run the compiler myself. Please verify on your machine:

1. Copy this `lifeos/` folder wherever you keep projects.
2. Since I couldn't run `flutter create`, the native platform folders
   (`android/`, `ios/`, etc.) don't exist yet. Generate them in place
   without touching `lib/` or `pubspec.yaml`:
   ```
   flutter create . --project-name lifeos --org com.yourname
   ```
   Flutter will detect the existing `lib/` and `pubspec.yaml` and only add
   the missing platform scaffolding.
3. Fetch dependencies:
   ```
   flutter pub get
   ```
4. Confirm there are no analysis errors:
   ```
   flutter analyze
   ```
5. Run it:
   ```
   flutter run
   ```
   You should see an app titled "LifeOS" with a single screen showing the
   Phase 1 placeholder text, respecting your device's light/dark setting.

If `flutter analyze` or `flutter run` surface any errors, send them to me
and I'll fix them before we move to Phase 2.
