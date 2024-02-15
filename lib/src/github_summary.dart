import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'package:markdown_editor_plus/widgets/markdown_auto_preview.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GitHubSummary extends StatefulWidget {
  const GitHubSummary({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<GitHubSummary> createState() => _GitHubSummaryState();
}

class _GitHubSummaryState extends State<GitHubSummary> {
  @override
  Widget build(BuildContext context) {
    return RepositoriesList(gitHub: widget.gitHub);
  }
}

class RepositoriesList extends StatefulWidget {
  const RepositoriesList({required this.gitHub, super.key});
  final GitHub gitHub;

  @override
  State<RepositoriesList> createState() => _RepositoriesListState();
}

class _RepositoriesListState extends State<RepositoriesList> {
  @override
  initState() {
    super.initState();
    _repositories = widget.gitHub.repositories.listRepositories().toList();
  }

  late Future<List<Repository>> _repositories;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Repository>>(
      future: _repositories,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var repositories = snapshot.data;
        return ListView.builder(
          primary: false,
          itemBuilder: (context, index) {
            var repository = repositories[index];
            return ListTile(
              title:
                  Text('${repository.owner?.login ?? ''}/${repository.name}'),
              subtitle: Text(repository.description),
              onTap: () => showContent(this, repository),
            );
          },
          itemCount: repositories!.length,
        );
      },
    );
  }
}

Future<void> showContent(State<RepositoriesList> state, Repository repo) async {
  return showDialog(
    context: state.context,
    builder: (context) => AlertDialog(
      title: Text(repo.fullName),
      content: FutureBuilder(
          future: state.widget.gitHub.repositories
              .getContents(repo.slug(), "flutter_cms.json"),
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
                      print("starting");
                      try {
                        var creation = await state.widget.gitHub.repositories
                            .createFile(
                                repo.slug(),
                                CreateFile(
                                    path: "content/blog/$title.md",
                                    branch: "master",
                                    committer: CommitUser(
                                        state.widget.gitHub.auth.username ??
                                            "AndreaMinatoDefault",
                                        "andreamianto@outlook.com"),
                                    message: "Uploaded new file from flutter",
                                    content:
                                        base64.encode(utf8.encode(controller.text))));

                        print("done cretaing");
                        print(creation.toJson());
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      } catch (er) {
                        print("uhoh");
                      }
                    },
                    child: const Text("Write content"))
              ]);
            }

            return const Center(child: Text('BOH'));
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

Future<void> _launchUrl(State state, String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    if (state.mounted) {
      return showDialog(
        context: state.context,
        builder: (context) => AlertDialog(
          title: const Text('Navigation error'),
          content: Text('Could not launch $url'),
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
  }
}
