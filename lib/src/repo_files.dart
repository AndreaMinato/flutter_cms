import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cms/src/github_file.dart';
import 'package:flutter_cms/src/models/cms_config.dart';
import 'package:github/github.dart';

class RepoFiles extends StatefulWidget {
  const RepoFiles(
      {required this.gitHub,
      required this.repository,
      required this.config,
      super.key});
  final GitHub gitHub;
  final CMSContent config;
  final Repository repository;

  @override
  State<RepoFiles> createState() => _RepoFilesState();
}

class _RepoFilesState extends State<RepoFiles> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.gitHub.repositories
            .getContents(widget.repository.slug(), widget.config.path),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // return Center(child: Text('${snapshot.error}'));
            return ListView(children: [
              ListTile(
                title: const Text("New file"),
                onTap: () => newFile(this),
              )
            ]);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.isDirectory ?? false) {
            var tree = snapshot.data?.tree ?? [];

            return ListView(children: [
              ListTile(
                title: const Text("New file"),
                onTap: () => newFile(this),
              ),
              ...tree.map((e) => ListTile(
                  title: Text(e.name ?? "File"),
                  onTap: () => showContent(this, e),
                  onLongPress: () async {
                    await deleteFile(this, e);
                    setState(() {});
                  })),
            ]);
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

              return GithubFileEditor(
                  gitHub: state.widget.gitHub,
                  repository: state.widget.repository,
                  file: file,
                  config: state.widget.config,
                  path: file.path ?? "",
                  text: text);
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

Future<void> deleteFile(State<RepoFiles> state, GitHubFile file) async {
  return showDialog(
      context: state.context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Please Confirm'),
          content: Text('Are you sure to delete the ${file.name}?'),
          actions: [
            // The "Yes" button
            TextButton(
                onPressed: () {
                  // Remove the box
                  state.widget.gitHub.repositories.deleteFile(
                      state.widget.repository.slug(),
                      file.path ?? "",
                      "Delete ${file.path} from CMS",
                      file.sha ?? "",
                      "master");

                  // Close the dialog
                  Navigator.of(state.context).pop();
                },
                child: const Text('Yes')),
            TextButton(
                onPressed: () {
                  // Close the dialog
                  Navigator.of(state.context).pop();
                },
                child: const Text('No'))
          ],
        );
      });
}

Future<void> newFile(State<RepoFiles> state) async {
  return showDialog(
    context: state.context,
    builder: (context) => AlertDialog(
      title: const Text("New file"),
      content: GithubFileEditor(
          gitHub: state.widget.gitHub,
          repository: state.widget.repository,
          config: state.widget.config,
          path: state.widget.config.path,
          text: ""),
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
