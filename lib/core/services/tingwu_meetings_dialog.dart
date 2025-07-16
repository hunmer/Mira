// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mira/core/services/tingwu_service.dart';

class TingWuMeetingsDialog extends StatefulWidget {
  final TingWuService service;
  final Function(Map<String, dynamic> selectedMeeting) onConfirm;

  const TingWuMeetingsDialog({
    super.key,
    required this.service,
    required this.onConfirm,
  });

  @override
  State<TingWuMeetingsDialog> createState() => _TingWuMeetingsDialogState();
}

class _TingWuMeetingsDialogState extends State<TingWuMeetingsDialog> {
  Map<String, dynamic>? _selectedMeeting;
  List<Map<String, dynamic>> _meetings = [];
  String _filterStatus = 'all';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      final response = await widget.service.getLiveMeetings();
      setState(() {
        _meetings = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载会议列表失败: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('会议列表'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  try {
                    await widget.service.clearCompletedMeetings();
                    setState(() {
                      _meetings.removeWhere(
                        (meeting) => meeting['TaskStatus'] == 'COMPLETED',
                      );
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('清空失败: ${e.toString()}')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) {
                      final titleController = TextEditingController();
                      int selectedCount = 1;

                      return AlertDialog(
                        title: Text('创建会议'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: '会议名称',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: selectedCount,
                              decoration: InputDecoration(
                                labelText: '发言人数量',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  List.generate(5, (index) => index + 1)
                                      .map(
                                        (count) => DropdownMenuItem(
                                          value: count,
                                          child: Text('$count speaker(s)'),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  selectedCount = value;
                                }
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                final newMeeting = await widget.service
                                    .createLiveMeeting(
                                      speakerCount: selectedCount,
                                      title: titleController.text,
                                    );
                                Navigator.of(context).pop(newMeeting);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('创建会议失败: ${e.toString()}'),
                                  ),
                                );
                              }
                            },
                            child: Text('确定'),
                          ),
                        ],
                      );
                    },
                  );

                  if (result != null) {
                    setState(() {
                      _meetings.insert(0, result);
                      _selectedMeeting = result;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterChip(
                      label: Text('全部'),
                      selected: _filterStatus == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = 'all';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text('进行中'),
                      selected: _filterStatus == 'active',
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = 'active';
                        });
                      },
                    ),
                    FilterChip(
                      label: Text('已完成'),
                      selected: _filterStatus == 'completed',
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = 'completed';
                        });
                      },
                    ),
                  ],
                ),
              ),
              for (final meeting
                  in _meetings
                      .where(
                        (m) =>
                            _filterStatus == 'all' ||
                            (_filterStatus == 'active' &&
                                m['TaskStatus'] != 'COMPLETED') ||
                            (_filterStatus == 'completed' &&
                                m['TaskStatus'] == 'COMPLETED'),
                      )
                      .toList()
                    ..sort((a, b) {
                      final aStatus = a['TaskStatus'] ?? '';
                      final bStatus = b['TaskStatus'] ?? '';

                      // Always put completed meetings last
                      if (aStatus == 'COMPLETED' && bStatus != 'COMPLETED')
                        return 1;
                      if (aStatus != 'COMPLETED' && bStatus == 'COMPLETED')
                        return -1;

                      // Then sort by create_time (newest first)
                      final aTime = a['create_time'] ?? '';
                      final bTime = b['create_time'] ?? '';
                      return bTime.compareTo(aTime);
                    }))
                ListTile(
                  title: Text(meeting['title'] ?? '无标题'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('创建者: ${meeting['creator'] ?? '未知'}'),
                      Text('创建时间: ${meeting['create_time'] ?? '未知'}'),
                      Text(
                        '状态: ${meeting['TaskStatus'] ?? '未知'}',
                        style: TextStyle(
                          color:
                              meeting['TaskStatus'] == 'COMPLETED'
                                  ? Colors.grey
                                  : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  selected: _selectedMeeting == meeting,
                  selectedTileColor: Colors.blue.withOpacity(0.1),
                  onTap: () {
                    if (meeting['TaskStatus'] != 'COMPLETED') {
                      setState(() {
                        _selectedMeeting = meeting;
                      });
                    }
                  },
                  trailing:
                      meeting['TaskStatus'] != 'COMPLETED'
                          ? PopupMenuButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    child: const Text('标记完成'),
                                    onTap: () async {
                                      try {
                                        await widget.service.stopLiveMeeting(
                                          meeting['TaskId'],
                                        );
                                        setState(() {
                                          meeting['TaskStatus'] = 'COMPLETED';
                                          if (_selectedMeeting == meeting) {
                                            _selectedMeeting = null;
                                          }
                                        });
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '标记失败: ${e.toString()}',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                          )
                          : null,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed:
              _selectedMeeting != null
                  ? () {
                    widget.onConfirm(_selectedMeeting!);
                    Navigator.of(context).pop(_selectedMeeting);
                  }
                  : null,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
