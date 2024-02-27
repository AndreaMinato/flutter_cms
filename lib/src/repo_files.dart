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
                  onTap: () async {
                    await newFile(this);
                    setState(() {});
                  })
            ]);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.isDirectory ?? false) {
            var tree = snapshot.data?.tree ?? [];

            return ListView(children: [
              ListTile(
                title: const Text("Refresh"),
                onTap: () => setState(() {}),
              ),
              ListTile(
                  title: const Text("New file"),
                  onTap: () async {
                    await newFile(this);
                    setState(() {});
                  }),
              ...tree.map((e) => ListTile(
                  title: Text(e.name ?? "File"),
                  onTap: () async {
                    bool result = await showContent(this, e);
                    if (result) {
                      setState(() {});
                    }
                  },
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

Future<bool> showContent(State<RepoFiles> state, GitHubFile file) async {
  try {
    var fileContent = await state.widget.gitHub.repositories
        .getContents(state.widget.repository.slug(), file.path ?? "");

    if (fileContent.isFile) {
      String text = fileContent.file?.text ?? "";
      await Navigator.of(state.context).push(PageRouteBuilder(
          pageBuilder: (BuildContext context, _, __) => GithubFileEditor(
              gitHub: state.widget.gitHub,
              repository: state.widget.repository,
              file: file,
              config: state.widget.config,
              path: file.path ?? "",
              text: text)));

      return true;
    }
  } catch (er) {
    ScaffoldMessenger.of(state.context).showSnackBar(const SnackBar(
      content: Text("Something gone wrong"),
    ));
  }
  return false;
}

Future<dynamic> deleteFile(State<RepoFiles> state, GitHubFile file) async {
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

Future<dynamic> newFile(State<RepoFiles> state) async {
  return Navigator.of(state.context).push(PageRouteBuilder(
      pageBuilder: (BuildContext context, _, __) => GithubFileEditor(
          gitHub: state.widget.gitHub,
          repository: state.widget.repository,
          config: state.widget.config,
          path: state.widget.config.path,
          text: "")));
}
