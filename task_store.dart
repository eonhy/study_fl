import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task.dart';

class TaskStore {
  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}tasks.json');
  }

  Future<List<Task>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as List<dynamic>;
    return [
      for (final entry in data) Task.fromJson(entry as Map<String, dynamic>),
    ];
  }

  Future<void> save(List<Task> tasks) async {
    final file = await _file();
    final temporaryFile = File('${file.path}.tmp');
    final json = jsonEncode([for (final task in tasks) task.toJson()]);
    await temporaryFile.writeAsString(json, flush: true);
    await temporaryFile.rename(file.path);
  }
}
