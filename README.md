# Tourism Portal — Premium Admin Settings

This package includes two complete replacement Flutter files:

- `lib/pages/admin_home_page.dart` — enables the Settings tile.
- `lib/pages/admin_settings_page.dart` — new premium admin settings hub.

## Installation

From the Mac terminal, assuming this ZIP is in Downloads:

```bash
cd "$HOME/Development/tourism_portal_app"
cp lib/pages/admin_home_page.dart lib/pages/admin_home_page.dart.backup-before-settings
unzip -o "$HOME/Downloads/tourism_admin_settings.zip" -d .
flutter analyze lib/pages/admin_home_page.dart lib/pages/admin_settings_page.dart
```

The new hub links to existing, working admin pages and provides a confirmation dialog for signing out. It does not add fictional persistent settings or alter the Laravel backend, Awards voting, or advertisements.

Future editable global settings will require their corresponding Laravel API endpoints and authorization checks.
