#!/usr/bin/env python3
"""Install Tourist Guide room type files and wire admin accommodation menu.
Run from the Flutter project root. Creates a backup before editing.
"""
from pathlib import Path
import shutil, sys
root=Path.cwd()
target=root/'lib/pages/admin_accommodations_page.dart'
if not target.exists():
    sys.exit('ERROR: Run this from your Flutter project root (lib/pages/admin_accommodations_page.dart not found).')
source=Path(__file__).resolve().parent/'lib'
for rel in ['models/accommodation_room_type.dart','services/accommodation_room_type_service.dart','pages/accommodation_room_types_page.dart','pages/accommodation_details_page.dart']:
    src=source/rel
    if not src.exists(): sys.exit(f'Missing packaged file: {src}')
text=target.read_text()
imp="import 'accommodation_room_types_page.dart';\nimport '../services/accommodation_room_type_service.dart';\n"
anchor="import 'package:flutter/material.dart';"
if 'accommodation_room_types_page.dart' not in text:
    assert anchor in text, 'Expected Flutter import not found; admin file differs from reviewed version'
    text=text.replace(anchor,anchor+'\n'+imp,1)
method='''
  Future<void> _manageRoomTypes(Accommodation accommodation) async {
    try {
      final service = await AccommodationRoomTypeService.forCurrentApp();
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AccommodationRoomTypesPage(
            accommodationId: accommodation.id,
            service: service,
            admin: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open room types: $error')),
      );
    }
  }

'''
if '_manageRoomTypes(Accommodation accommodation)' not in text:
    needle='  Future<void> _delete(Accommodation accommodation) async {'
    assert needle in text, 'Admin accommodation structure has changed; installer stopped safely'
    text=text.replace(needle,method+needle,1)
old="""value == 'edit'
                                          ? _edit(item)
                                          : _delete(item),"""
new="""value == 'edit'
                                          ? _edit(item)
                                          : value == 'rooms'
                                              ? _manageRoomTypes(item)
                                              : _delete(item),"""
if "value == 'rooms'" not in text:
    assert old in text, 'Accommodation menu differs from reviewed GitHub version; installer stopped safely'
    text=text.replace(old,new,1)
    needle="""PopupMenuItem(
                                      value: 'delete',"""
    assert needle in text
    text=text.replace(needle,"""PopupMenuItem(
                                      value: 'rooms',
                                      child: Text('Manage Room Types'),
                                    ),
                                    """+needle,1)
# Complete validation before writing.
backup=target.with_suffix('.dart.roomtypes-backup')
if not backup.exists(): shutil.copy2(target,backup)
for rel in ['models/accommodation_room_type.dart','services/accommodation_room_type_service.dart','pages/accommodation_room_types_page.dart','pages/accommodation_details_page.dart']:
    src=source/rel; dst=root/'lib'/rel
    dst.parent.mkdir(parents=True,exist_ok=True)
    if dst.exists():
        b=dst.with_suffix(dst.suffix+'.roomtypes-backup')
        if not b.exists(): shutil.copy2(dst,b)
    if src.resolve() != dst.resolve(): shutil.copy2(src,dst)
target.write_text(text)
print('Installed room type module and connected Manage Room Types in admin accommodation menu.')
print('Open Admin > Accommodations > existing accommodation > three-dot menu > Manage Room Types.')
print('For a new accommodation, save it first, then open its Manage Room Types menu.')
print('Backups created with .roomtypes-backup suffix. No GitHub changes made.')
