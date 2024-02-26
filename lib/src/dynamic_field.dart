import 'package:flutter/material.dart';

class DynamicField extends StatefulWidget {
  const DynamicField({required this.name, required this.type, super.key});
  final String name;
  final String type;

  @override
  State<DynamicField> createState() => _DynamicFieldState();
}

class _DynamicFieldState extends State<DynamicField> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.name),
        Expanded(
            child: switch (widget.type) {
          "string" => const TextField(),
          "date" => ElevatedButton(
              onPressed: () => showDatePicker(
                  context: context,
                  initialDate: DateTime(2024),
                  firstDate: DateTime(2015, 8),
                  lastDate: DateTime(2101)),
              child: const Text('Select date'),
            ),
          "bool" => Checkbox(
              value: false,
              onChanged: (value) {
                print(value ?? "buh");
              },
            ),
          String() => const Text("Non implemented"),
        })
      ],
    );
  }
}
