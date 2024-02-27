import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cms/src/meta_editor.dart';
import 'package:flutter_cms/src/models/cms_config.dart';
import 'package:github/github.dart';
import 'package:markdown_toolbar/markdown_toolbar.dart';
import 'package:cosmic_frontmatter/cosmic_frontmatter.dart';
import 'package:slugify/slugify.dart';

class GithubFileEditor extends StatefulWidget {
  const GithubFileEditor(
      {required this.gitHub,
      required this.repository,
      required this.path,
      required this.config,
      required this.text,
      this.file,
      super.key});
  final GitHub gitHub;
  final String path;
  final CMSContent config;
  final Repository repository;
  final GitHubFile? file;
  final String text;

  @override
  State<GithubFileEditor> createState() => _GithubFileEditorState();
}

class _GithubFileEditorState extends State<GithubFileEditor> {
  final TextEditingController _controller =
      TextEditingController(); // Declare the TextEditingController
  late final FocusNode _focusNode; // Declare the FocusNode

  Map<String, dynamic> metas = {};

  @override
  void initState() {
    Document<Map<String, dynamic>> parsed =
        const Document(frontmatter: {}, body: "");
    if (widget.text.isNotEmpty) {
      parsed = parseFrontmatter(
          content: widget.text,
          frontmatterBuilder: (map) {
            return map;
          });
      metas = parsed.frontmatter;
    }
    _controller.text = parsed.body;
    _controller
        .addListener(() => setState(() {})); // Update the text when typing
    _focusNode = FocusNode(); // Assign a FocusNode

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the TextEditingController
    _focusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: () {
                  if (widget.file == null) {
                    createFile();
                  } else {
                    updateFile();
                  }
                },
              )
            ],
            title: Text(
                "${widget.repository.name}/${widget.file?.name ?? 'New File'}"),
            bottom: const TabBar(tabs: [
              Tab(
                text: "Meta",
                icon: Icon(Icons.settings),
              ),
              Tab(
                text: "Content",
                icon: Icon(Icons.file_present),
              )
            ]),
          ),
          body: TabBarView(
            children: [
              MetaEditor(
                value: metas,
                metas: widget.config.meta,
                onChanged: (val) {
                  setState(() {
                    metas = val;
                  });
                },
              ),
              Column(
                children: [
                  MarkdownToolbar(
                    useIncludedTextField:
                        false, // Because we want to use our own, set useIncludedTextField to false
                    controller: _controller, // Add the _controller
                    focusNode: _focusNode, // Add the _focusNode
                    collapsable: false,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      minLines: 15,
                      maxLines: 50,
                      controller: _controller, // Add the _controller
                      focusNode: _focusNode, // Add the _focusNode
                    ),
                  ),
                ],
              )
            ],
          ),
        ));
  }

  void updateFile() async {
    try {
      await widget.gitHub.repositories.updateFile(
          widget.repository.slug(),
          widget.path,
          "Edit ${widget.file!.name} from CMS",
          getFileContent(),
          widget.file!.sha ?? "",
          branch: "master");
    } catch (er) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Something gone wrong"),
      ));
    }
  }

  void createFile() async {
    try {
      var fileName = slugify(metas['title']);
      await widget.gitHub.repositories.createFile(
          widget.repository.slug(),
          CreateFile(
              branch: "master",
              content: getFileContent(),
              message: "Create ${widget.path}/$fileName.md from CMS",
              path: "${widget.path}/$fileName.md",
              committer: CommitUser("FlutterCMS", "flutter@example.com")));
    } catch (er) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Something gone wrong"),
      ));
    }
  }

  String getFileContent() {
    String fileContent = "---";

    const htmlEscapeMode = HtmlEscapeMode(
      name: 'custom',
      escapeLtGt: true,
      escapeQuot: true,
      escapeApos: true,
      escapeSlash: true,
    );

    const HtmlEscape htmlEscape = HtmlEscape(htmlEscapeMode);

    metas.forEach((key, value) {
      var escaped = htmlEscape.convert(value.toString());
      fileContent += "\n $key: $escaped";
    });

    fileContent += " \n---\n\n${_controller.text}";

    return base64.encode(utf8.encode(fileContent));
  }
}
