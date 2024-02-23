import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cms/src/models/cms_config.dart';
import 'package:flutter_cms/src/repo_files.dart';
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
            String text = snapshot.data?.file?.text ?? CMSConfig.defaultContent;
            CMSConfig config = CMSConfig(jsonDecode(text));

            return DefaultTabController(
              initialIndex: 0,
              length: config.contents.length,
              child: Scaffold(
                appBar: AppBar(

                  title: Text(widget.repository.name),
                  bottom: TabBar(
                    tabs: config.contents
                        .map((e) => Tab(
                              text: e.type,
                              icon: const Icon(Icons.cloud_outlined),
                            ))
                        .toList(),
                  ),
                ),
                body: TabBarView(
                  children: config.contents
                      .map((e) => RepoFiles(
                            gitHub: widget.gitHub,
                            repository: widget.repository,
                            path: e.path,
                          ))
                      .toList(),
                ),
              ),
            );

            // return Column(children: [
            //   Center(child: Text('${snapshot.data?.file?.text}')),

            //   RepoFiles(gitHub: widget.gitHub, repository: widget.repository, path: "content/blog")
            // ]);
          }

          return const Center(child: Text('BOH'));
        });
  }
}
