#!/usr/bin/env python3
"""Apply global appearance integration to the latest local Tourist Guide files.
Run from project root: python3 apply_theme_fix.py
Creates .before-appearance-fix backups; never pushes to GitHub.
"""
from pathlib import Path
import shutil
import sys

root = Path.cwd()
main_path = root / 'lib/main.dart'
settings_path = root / 'lib/pages/admin_app_appearance_page.dart'
controller_src = Path(__file__).resolve().parent / 'lib/theme/app_appearance_controller.dart'
controller_dst = root / 'lib/theme/app_appearance_controller.dart'

if not main_path.exists() or not settings_path.exists():
    sys.exit('Run this script from the Flutter project root (containing lib/main.dart).')

main = main_path.read_text()
settings = settings_path.read_text()
if 'AppAppearanceController.instance' in main:
    sys.exit('Appearance controller already installed in main.dart. No files changed.')

# Fail rather than risk damaging an unexpected version.
checks = [
    ('main.dart: app class', 'class TourismPortalApp extends StatelessWidget', main),
    ('main.dart: theme mode', 'themeMode: ThemeMode.light,', main),
    ('main.dart: light theme', 'const primary = FieldGuidePalette.primary;', main),
    ('main.dart: dark theme', 'const primary = FieldGuidePalette.sage;', main),
    ('appearance: save', 'await AdminCustomizationService.instance.saveAppearance(', settings),
    ('appearance: reset', 'await AdminCustomizationService.instance.resetAppearance();', settings),
]
for name, token, content in checks:
    if token not in content:
        sys.exit('Cannot safely patch '+name+'; GitHub file differs. No changes made.')

main = main.replace("import 'theme/field_guide_theme.dart';", "import 'theme/field_guide_theme.dart';\nimport 'theme/app_appearance_controller.dart';", 1)
main = main.replace('void main() {\n  runApp(const TourismPortalApp());\n}',
    'void main() {\n  WidgetsFlutterBinding.ensureInitialized();\n  AppAppearanceController.instance.refresh();\n  runApp(const TourismPortalApp());\n}', 1)
main = main.replace('const primary = FieldGuidePalette.primary;', 'final primary = AppAppearanceController.instance.primary;', 1)
main = main.replace('const secondary = FieldGuidePalette.secondary;', 'final secondary = AppAppearanceController.instance.secondary;', 1)
main = main.replace('const background = FieldGuidePalette.background;', 'final background = AppAppearanceController.instance.background;', 1)
main = main.replace('const primary = FieldGuidePalette.sage;', 'final primary = AppAppearanceController.instance.primary;', 1)
main = main.replace('const secondary = FieldGuidePalette.secondary;', 'final secondary = AppAppearanceController.instance.secondary;', 1)
main = main.replace('const background = FieldGuidePalette.night;', 'final background = FieldGuidePalette.night;', 1)
# Nonconstant ThemeData properties now depend on controller.
main = main.replace('appBarTheme: const AppBarTheme(\n        backgroundColor: background,', 'appBarTheme: AppBarTheme(\n        backgroundColor: background,', 1)
main = main.replace('borderSide: const BorderSide(color: primary, width: 1.6)', 'borderSide: BorderSide(color: primary, width: 1.6)', 1)
main = main.replace('side: const BorderSide(color: primary)', 'side: BorderSide(color: primary)')
main = main.replace('borderSide: const BorderSide(color: primary, width: 1.6)', 'borderSide: BorderSide(color: primary, width: 1.6)')
main = main.replace('    final baseTheme = ThemeData(\n', '    final baseTheme = ThemeData(\n      fontFamily: AppAppearanceController.instance.fontFamily,\n', 2)
# FieldGuideType currently applies Inter explicitly. Override its resulting text themes
# so the selected font can be used wherever Flutter theme typography is inherited.
main = main.replace('color: darkText),', 'color: darkText).apply(fontFamily: AppAppearanceController.instance.fontFamily),', 1)
main = main.replace('color: Colors.white,\n      ),', 'color: Colors.white,\n      ).apply(fontFamily: AppAppearanceController.instance.fontFamily),', 1)
main = main.replace('color: lightText,\n      ),', 'color: lightText,\n      ).apply(fontFamily: AppAppearanceController.instance.fontFamily),', 1)
# Wrap MaterialApp in a notifier builder, so the theme updates immediately.
main = main.replace('    return MaterialApp(\n', '    return AnimatedBuilder(\n      animation: AppAppearanceController.instance,\n      builder: (context, _) => MaterialApp(\n', 1)
main = main.replace('themeMode: ThemeMode.light,', 'themeMode: AppAppearanceController.instance.mode,', 1)
# Match only the end of the root MaterialApp build (before _LaunchGate class).
start = main.index('    return AnimatedBuilder(')
next_class = main.find('class _LaunchGate', start)
if next_class < 0:
    sys.exit('Cannot locate _LaunchGate. No changes made.')
block = main[start:next_class]
# Last MaterialApp closing expression inside the root widget build.
pos = block.rfind('    );')
if pos < 0:
    sys.exit('Cannot locate MaterialApp closing expression. No changes made.')
block = block[:pos] + block[pos:].replace('    );', '      ),\n    );', 1)
main = main[:start] + block + main[next_class:]

settings = settings.replace("import '../services/admin_customization_service.dart';", "import '../services/admin_customization_service.dart';\nimport '../theme/app_appearance_controller.dart';", 1)
# Wait for API success, then reload canonical server values and notify the root.
needle = "      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appearance saved on the server.')));"
if needle not in settings:
    sys.exit('Cannot locate appearance save success callback. No changes made.')
settings = settings.replace(needle, '      await AppAppearanceController.instance.refresh();\n'+needle, 1)
needle = "      final data = await AdminCustomizationService.instance.resetAppearance();"
settings = settings.replace(needle, needle+'\n      await AppAppearanceController.instance.refresh();', 1)

for target in (main_path, settings_path):
    backup = target.with_name(target.name+'.before-appearance-fix')
    if backup.exists():
        sys.exit('Backup already exists: '+str(backup)+'; no changes made.')
for target in (main_path, settings_path):
    shutil.copy2(target, target.with_name(target.name+'.before-appearance-fix'))
controller_dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(controller_src, controller_dst)
main_path.write_text(main)
settings_path.write_text(settings)
print('Applied appearance controller and updated main.dart + admin_app_appearance_page.dart')
print('Original files backed up with .before-appearance-fix suffix')
print('Next: flutter analyze && flutter run')
