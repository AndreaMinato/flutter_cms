import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:markdown_editor_plus/widgets/markdown_auto_preview.dart';

class RepoFiles extends StatefulWidget {
  const RepoFiles(
      {required this.gitHub,
      required this.repository,
      required this.path,
      super.key});
  final GitHub gitHub;
  final String path;
  final Repository repository;

  @override
  State<RepoFiles> createState() => _RepoFilesState();
}

class _RepoFilesState extends State<RepoFiles> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.gitHub.repositories
            .getContents(widget.repository.slug(), widget.path),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.isDirectory ?? false) {
            var tree = snapshot.data?.tree ?? [];

            return ListView(
              children: tree
                  .map((e) => ListTile(
                        title: Text(e.name ?? "File"),
                        onTap: () => showContent(this, e),
                      ))
                  .toList(),
            );
          }

          return const Center(child: Text('BOH'));
        });
  }
}

Future<void> showContent(State<RepoFiles> state, GitHubFile file) async {
  return showDialog(
    context: state.context,
    builder: (context) => AlertDialog(
      title: Text(file.name ?? ""),
      content: FutureBuilder(
          future: state.widget.gitHub.repositories
              .getContents(state.widget.repository.slug(), file.path ?? ""),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data?.isFile ?? false) {
              String text = snapshot.data?.file?.text ?? "";
              TextEditingController controller = TextEditingController();
              controller.text = text;

              return Column(children: [
                MarkdownAutoPreview(
                  controller: controller,
                  emojiConvert: true,
                ),
                FilledButton(
                    onPressed: () async {
                      try {
                        await state.widget.gitHub.repositories
                            .updateFile(
                                state.widget.repository.slug(),
                                file.path ?? "",
                                "Edit ${file.name}",
                                base64.encode(utf8.encode(controller.text)),
                                "sha");

                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      } catch (er) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Something gone wrong"),
                        ));
                      }
                    },
                    child: const Text("Write content"))
              ]);
            }
            return const Center(child: Text("Not a file"));
          }),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
