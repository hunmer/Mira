import 'package:flutter/material.dart';

/// 计数器组件，用于演示自定义组件类型
class CounterWidget extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int>? onChanged;

  const CounterWidget({Key? key, this.initialValue = 0, this.onChanged})
    : super(key: key);

  @override
  State<CounterWidget> createState() => CounterWidgetState();
}

class CounterWidgetState extends State<CounterWidget> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialValue;
  }

  int get currentValue => _count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Count: $_count', style: TextStyle(fontSize: 24)),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() => _count++);
                widget.onChanged?.call(_count);
              },
              child: Text('+'),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _count--);
                widget.onChanged?.call(_count);
              },
              child: Text('-'),
            ),
          ],
        ),
      ],
    );
  }
}
