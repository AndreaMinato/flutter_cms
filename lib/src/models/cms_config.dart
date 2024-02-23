import 'dart:convert';

class CMSConfig {
  bool enabled = false;
  List<CMSContent> contents = [];

  CMSConfig(Map<String, dynamic> json) {
    enabled = json["enabled"] ?? false;

    List<dynamic> jsonContent = json["contents"] ?? [];
    contents = [];
    for (var content in jsonContent) {
      contents.add(CMSContent(content));
    }
  }

  static final String defaultContent =
      jsonEncode({"enabled": false, "contents": []});
}

class CMSContent {
  String type = "";
  String path = "";
  List<CMSField> meta = [];

  CMSContent(Map<String, dynamic> json) {
    type = json["type"] ?? "";
    path = json["path"] ?? "";
    List<dynamic> jsonMeta = json["meta"] ?? [];
    meta = [];
    for (var m in jsonMeta) {
      meta.add(CMSField(m));
    }
  }
}

class CMSField {
  String name = "";
  String type = "";

  CMSField(Map<String, dynamic> json) {
    name = json["name"] ?? "";
    type = json["type"] ?? "";
  }
}
