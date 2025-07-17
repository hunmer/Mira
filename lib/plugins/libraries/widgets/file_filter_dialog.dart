import 'package:flutter/material.dart';

class FileFilterDialog extends StatefulWidget {
  const FileFilterDialog({Key? key}) : super(key: key);

  @override
  _FileFilterDialogState createState() => _FileFilterDialogState();
}

class _FileFilterDialogState extends State<FileFilterDialog> {
  late String nameFilter;
  late DateTimeRange? dateRangeFilter;
  late int? minSizeFilter;
  late int? maxSizeFilter;
  late Set<String> selectedTags;
  late int? minRatingFilter;
  late String? typeFilter;

  @override
  void initState() {
    super.initState();
    nameFilter = '';
    dateRangeFilter = null;
    minSizeFilter = null;
    maxSizeFilter = null;
    selectedTags = {};
    minRatingFilter = null;
    typeFilter = null;
  }

  Map<String, dynamic> _getFilterOptions() {
    return {
      'name': nameFilter.isNotEmpty ? nameFilter : null,
      'dateRange': dateRangeFilter,
      'minSize': minSizeFilter,
      'maxSize': maxSizeFilter,
      'tags': selectedTags.isNotEmpty ? selectedTags.toList() : null,
      'minRating': minRatingFilter,
      'type': typeFilter,
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeFilterCount =
        [
          nameFilter.isNotEmpty,
          dateRangeFilter != null,
          minSizeFilter != null,
          maxSizeFilter != null,
          selectedTags.isNotEmpty,
          minRatingFilter != null,
          typeFilter != null,
        ].where((active) => active).length;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Options'),
          if (activeFilterCount > 0)
            Text(
              '$activeFilterCount active filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activeFilterCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        nameFilter = '';
                        dateRangeFilter = null;
                        minSizeFilter = null;
                        maxSizeFilter = null;
                        selectedTags.clear();
                        minRatingFilter = null;
                        typeFilter = null;
                      });
                    },
                    child: const Text('Clear all'),
                  ),
                ),
              ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Name contains',
                border: const OutlineInputBorder(),
                suffixIcon:
                    nameFilter.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() => nameFilter = '');
                            FocusScope.of(context).unfocus();
                          },
                        )
                        : null,
              ),
              onChanged: (value) => setState(() => nameFilter = value),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => dateRangeFilter = picked);
                }
              },
              child: Text(
                dateRangeFilter == null
                    ? 'Select date range'
                    : '${dateRangeFilter!.start.toLocal().toString().split(' ')[0]}'
                        ' to ${dateRangeFilter!.end.toLocal().toString().split(' ')[0]}',
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Min size (KB)',
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          minSizeFilter != null
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => minSizeFilter = null);
                                  FocusScope.of(context).unfocus();
                                },
                              )
                              : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged:
                        (value) => setState(() {
                          minSizeFilter =
                              value.isEmpty ? null : int.tryParse(value);
                        }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Max size (KB)',
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          maxSizeFilter != null
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => maxSizeFilter = null);
                                  FocusScope.of(context).unfocus();
                                },
                              )
                              : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged:
                        (value) => setState(() {
                          maxSizeFilter =
                              value.isEmpty ? null : int.tryParse(value);
                        }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Minimum rating',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ...List.generate(5, (i) => i + 1).map((rating) {
                  return DropdownMenuItem(
                    value: rating.toString(),
                    child: Text('$rating+ stars'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  minRatingFilter = value == null ? null : int.parse(value);
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              nameFilter = '';
              dateRangeFilter = null;
              minSizeFilter = null;
              maxSizeFilter = null;
              selectedTags.clear();
              minRatingFilter = null;
              typeFilter = null;
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _getFilterOptions());
          },
          child: Column(
            children: [
              const Text('Apply'),
              if (activeFilterCount > 0)
                Text(
                  '$activeFilterCount filters',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
