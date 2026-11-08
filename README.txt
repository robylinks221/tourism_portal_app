TOURIST GUIDE — ADMIN ROOM TYPES NAVIGATION FIX

1. Extract this ZIP anywhere on your Mac.
2. Open Terminal and cd into your existing Flutter project root (the folder with pubspec.yaml).
3. Run:
   python3 /path/to/extracted/install_room_types.py
   (Replace /path/to/extracted/ with the actual extraction folder.)
4. Run: flutter pub get
5. Run: flutter run
6. In Admin > Accommodations, save the accommodation first.
7. On its listing card, tap the three-dot menu > Manage Room Types.
8. Add Single, Twin/Double, Triple, or other room types.

Why: the backend room-type endpoint requires an accommodation ID. The earlier
package did not connect the admin navigation. This package connects it.

The installer makes backups of existing files before replacing them. It will
stop without changing files if the admin page differs from the reviewed GitHub
version. No GitHub push or backend modification is performed.

NOTE: Flutter build and live API writes were not tested in this environment.
