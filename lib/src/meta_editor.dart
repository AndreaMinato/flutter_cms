import 'package:flutter/material.dart';
import 'package:flutter_cms/src/models/cms_config.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class MetaEditor extends StatefulWidget {
  const MetaEditor(
      {required this.value,
      required this.metas,
      required this.onChanged,
      super.key});
  final Map<String, dynamic> value;
  final List<CMSField> metas;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<MetaEditor> createState() => _MetaEditorState();
}

class _MetaEditorState extends State<MetaEditor> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      FormBuilder(
          key: _formKey,
          initialValue: widget.value,
          onChanged: () {
            if (_formKey.currentState != null) {
              widget.onChanged(_formKey.currentState!.instantValue);
            } else {
              widget.onChanged({});
            }
          },
          child: Column(
            children: [
              ...widget.metas.map((meta) => switch (meta.type) {
                    "string" => FormBuilderTextField(
                        initialValue: widget.value[meta.name] ?? "",
                        decoration: InputDecoration(labelText: meta.name),
                        name: meta.name,
                      ),
                    "date" => FormBuilderDateTimePicker(
                        initialValue: widget.value[meta.name] != null
                            ? DateTime.tryParse(widget.value[meta.name].toString())
                            : DateTime.now(),
                        name: meta.name,
                        decoration: InputDecoration(labelText: meta.name),
                      ),
                    "bool" => FormBuilderCheckbox(
                        initialValue: widget.value[meta.name] ?? false,
                        title: Text(meta.name),
                        name: meta.name,
                      ),
                    String() => const Text("Non implemented"),
                  })
            ],
          ))
    ]);
  }
}
