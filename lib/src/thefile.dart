import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:markdown_editor_plus/widgets/markdown_auto_preview.dart';

class RepoDetail extends StatefulWidget {
  const RepoDetail({required this.gitHub, required this.repository, super.key});
  final GitHub gitHub;
  final Repository repository;

  @override
  State<RepoDetail> createState() => _RepoDetailState();
}

class _RepoDetailState extends State<RepoDetail> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.gitHub.repositories
            .getContents(widget.repository.slug(), "flutter_cms.json"),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.isFile ?? false) {
            TextEditingController controller = TextEditingController();
            DateTime date = DateTime.now();
            String title =
                "${date.year}-${date.month}-${date.day}-${date.hour}-${date.minute}-${date.second}";
            controller.text = """
---
title: '$title'
description: 'meta description of the page'
---

# Hello Content
""";
            return Column(children: [
              Center(child: Text('${snapshot.data?.file?.text}')),
              MarkdownAutoPreview(
                controller: controller,
                emojiConvert: true,
              ),
              FilledButton(
                  onPressed: () async {
                    try {
                      var creation = await widget.gitHub.repositories
                          .createFile(
                              widget.repository.slug(),
                              CreateFile(
                                  path: "content/blog/$title.md",
                                  branch: "master",
                                  committer: CommitUser(
                                      widget.gitHub.auth.username ??
                                          "AndreaMinatoDefault",
                                      "andreamianto@outlook.com"),
                                  message: "Uploaded new file from flutter",
                                  content: base64
                                      .encode(utf8.encode(controller.text))));

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    } catch (er) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Something gone wrong"),
                      ));
                    }
                  },
                  child: const Text("Write content"))
            ]);
          }

          return const Center(child: Text('BOH'));
        });
  }
}
