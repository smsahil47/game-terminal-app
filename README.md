# Game Terminal mobile

Flutter implementation for Android and iOS. The website is a read-only functional reference.

Run `flutter run` for the disconnected staff sign-in screen. Supabase is disabled by default; no production credentials are included.

When a **separate test project** with the existing schema, RLS, realtime publication, and assigned staff profiles is available, copy `env/development.example.json` to the ignored `env/development.json`. Set its test URL/public key and explicitly enable `ENABLE_SUPABASE`, then run:

```sh
flutter run --dart-define-from-file=env/development.json
```

Never supply a service-role key. Database roles come only from `profiles.role`; owners remain read-only. This increment includes authentication, role routing, and the station/session overview. Session operations, billing, bookings, and financial reports are not implemented yet.

Verification: `flutter analyze`, `flutter test`, `flutter build apk --debug`.
