import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';

import 'dart:math';

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";
  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse("$baseUrl/todos"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];
      return todos.map((todo) {
        final random = Random();
        final deadlines = ["jutro", "dzisiaj", "w piątek", "brak"];
        final deadline = deadlines[random.nextInt(deadlines.length)];
        final priorities = ["niski", "średni", "wysoki"];
        final priority = priorities[random.nextInt(priorities.length)];
        return Task(
          id: todo["id"],
          title: todo["todo"],
          deadline: deadline,
          done: todo["completed"],
          priority: priority,
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}
