import 'package:flutter/material.dart';

class FileFilterDialog extends StatefulWidget {
  final Map<String, dynamic> filterOptions;

  const FileFilterDialog({super.key, this.filterOptions = const {}});

  @override
  // ignore: library_private_types_in_public_api
  _FileFilterDialogState createState() => _FileFilterDialogState();
}

class _FileFilterDialogState extends State<FileFilterDialog> {
  String nameFilter = '';
  DateTimeRange? dateRangeFilter;
  int? minSizeFilter;
  int? maxSizeFilter;
  Set<String> selectedTags = {};
  int? minRatingFilter;
  String? typeFilter;

  // TextEditingControllers
  late TextEditingController nameController;
  late TextEditingController minSizeController;
  late TextEditingController maxSizeController;

  @override
  void initState() {
    super.initState();
    nameFilter = widget.filterOptions['name'] ?? nameFilter;
    dateRangeFilter = widget.filterOptions['dateRange'] ?? dateRangeFilter;
    minSizeFilter = widget.filterOptions['minSize'] ?? minSizeFilter;
    maxSizeFilter = widget.filterOptions['maxSize'] ?? maxSizeFilter;
    selectedTags = Set.from(widget.filterOptions['tags'] ?? selectedTags);
    minRatingFilter = widget.filterOptions['minRating'] ?? minRatingFilter;
    typeFilter = widget.filterOptions['type'] ?? typeFilter;

    // Initialize TextEditingControllers with values from filterOptions
    nameController = TextEditingController(text: nameFilter);
    minSizeController = TextEditingController(
      text: minSizeFilter != null ? minSizeFilter.toString() : '',
    );
    maxSizeController = TextEditingController(
      text: maxSizeFilter != null ? maxSizeFilter.toString() : '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    minSizeController.dispose();
    maxSizeController.dispose();
    super.dispose();
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

                        // Clear TextEditingControllers
                        nameController.clear();
                        minSizeController.clear();
                        maxSizeController.clear();
                      });
                    },
                    child: const Text('Clear all'),
                  ),
                ),
              ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name contains',
                border: const OutlineInputBorder(),
                suffixIcon:
                    nameFilter.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              nameFilter = '';
                              nameController.clear();
                            });
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
                    controller: minSizeController,
                    decoration: InputDecoration(
                      labelText: 'Min size (KB)',
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          minSizeFilter != null
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    minSizeFilter = null;
                                    minSizeController.clear();
                                  });
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
                    controller: maxSizeController,
                    decoration: InputDecoration(
                      labelText: 'Max size (KB)',
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          maxSizeFilter != null
                              ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    maxSizeFilter = null;
                                    maxSizeController.clear();
                                  });
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

              // Clear TextEditingControllers
              nameController.clear();
              minSizeController.clear();
              maxSizeController.clear();
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
