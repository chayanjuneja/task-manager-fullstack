import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskService {
  final String baseUrl = "http://127.0.0.1:8000";

  // ✅ GET (search + filter)
  Future<List<dynamic>> getTasks({
    String search = "",
    String status = "All",
  }) async {
    final queryParams = {
      if (search.isNotEmpty) "search": search,
      if (status != "All") "status": status,
    };

    final uri = Uri.parse("$baseUrl/tasks")
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);
    final data = jsonDecode(response.body);

    return data['data'];
  }

  // ✅ CREATE
  Future<void> createTask(Map<String, dynamic> task) async {
    await Future.delayed(const Duration(seconds: 2));

    await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(task),
    );
  }

  // ✅ UPDATE
  Future<void> updateTask(String id, Map<String, dynamic> task) async {
    await Future.delayed(const Duration(seconds: 2));

    await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(task),
    );
  }

  Future<void> reorderTasks(List<String> order) async {
  await http.put(
    Uri.parse('$baseUrl/tasks/reorder'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(order),
  );
}

  // ✅ DELETE
  Future<void> deleteTask(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
    );
  }
}