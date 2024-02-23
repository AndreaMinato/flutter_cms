import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cms/src/repo_detail.dart';
import 'package:github/github.dart';
import 'package:markdown_editor_plus/widgets/markdown_auto_preview.dart';

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

  int _selectedIndex = 0;

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
        var repositories = snapshot.data ?? [];
        return Row(
          children: [
            LayoutBuilder(builder: (context, constraint) {
              return SingleChildScrollView(
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraint.maxHeight),
                      child: IntrinsicHeight(
                          child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: repositories.map((Repository repo) {
                          return NavigationRailDestination(
                            icon: const Icon(Icons.pageview),
                            label: Text(repo.name),
                          );
                        }).toList(),
                      ))));
            }),

            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content.
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: repositories.map((Repository repo) {
                  return RepoDetail(
                    gitHub: widget.gitHub,
                    repository: repo,
                  );
                }).toList(),
              ),
            ),
          ],
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
                                    content: base64
                                        .encode(utf8.encode(controller.text))));

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
