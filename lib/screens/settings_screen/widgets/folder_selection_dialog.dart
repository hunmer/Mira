// ignore_for_file: library_private_types_in_public_api

import 'package:mira/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FolderSelectionDialog extends StatefulWidget {
  final List<Map<String, String>> items;

  const FolderSelectionDialog({super.key, required this.items});

  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectFolderToImport),
      content: SingleChildScrollView(
        child: ListBody(
          children:
              widget.items.map((item) {
                return CheckboxListTile(
                  title: Text(item['name'] ?? '未知插件'),
                  subtitle: Text(item['id'] ?? ''),
                  value: _selectedIds.contains(item['id']),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true && item['id'] != null) {
                        _selectedIds.add(item['id']!);
                      } else if (item['id'] != null) {
                        _selectedIds.remove(item['id']);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.ok),
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
        ),
      ],
    );
  }
}
