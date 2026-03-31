import 'package:flutter/material.dart';
import 'services/task_service.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: const TaskScreen(),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TaskService _service = TaskService();

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  String searchQuery = "";
  String filterStatus = "All";

  List tasks = [];
  bool isLoading = true;
  bool isSaving = false;

  String selectedStatus = "To-Do";
  DateTime? selectedDate;
  String? selectedBlockedBy;
  String recurring = "None";

  Map<String, String> draft = {"title": "", "desc": ""};

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks({String search = "", String status = "All"}) async {
    final data = await _service.getTasks(search: search, status: status);
    setState(() {
      tasks = data;
      isLoading = false;
    });
  }

  void saveDraft(String title, String desc) {
    draft = {"title": title, "desc": desc};
  }

  Map<String, String> loadDraft() {
    return draft;
  }

  Widget highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final start = text.toLowerCase().indexOf(query.toLowerCase());
    if (start == -1) return Text(text);

    final end = start + query.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, start), style: const TextStyle(color: Colors.black)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              backgroundColor: Color(0xFFD7E5F0),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextSpan(text: text.substring(end), style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  Color getCardColor(int index) {
    final colors = [
      const Color(0xFFF4EDE4),
      const Color(0xFFD7E5F0),
      const Color(0xFFE8F0E8),
    ];
    return colors[index % colors.length];
  }

  Future<void> pickDate(StateSetter setModalState) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setModalState(() => selectedDate = picked);
    }
  }

  void openTaskDialog({Map? task}) {
    final title = TextEditingController();
    final desc = TextEditingController();

    if (task == null) {
      final d = loadDraft();
      title.text = d["title"]!;
      desc.text = d["desc"]!;
    } else {
      title.text = task['title'] ?? "";
      desc.text = task['description'] ?? "";
    }

    selectedStatus = task?['status'] ?? "To-Do";
    selectedDate = task != null ? DateTime.tryParse(task['due_date']) : null;
    selectedBlockedBy = task?['blocked_by'];
    recurring = task?['recurring'] ?? "None";

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setModal) {
            return AlertDialog(
              title: Text(task == null ? "Create Task" : "Edit Task"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: "Title"),
                      onChanged: (v) => saveDraft(v, desc.text),
                    ),
                    TextField(
                      controller: desc,
                      decoration: const InputDecoration(labelText: "Description"),
                      onChanged: (v) => saveDraft(title.text, v),
                    ),
                    DropdownButtonFormField(
                      value: selectedStatus,
                      items: ["To-Do", "In Progress", "Done"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setModal(() => selectedStatus = v!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedDate == null
                            ? "Pick Due Date"
                            : selectedDate.toString().split(" ")[0]),
                        TextButton(
                          onPressed: () => pickDate(setModal),
                          child: const Text("Select"),
                        )
                      ],
                    ),
                    DropdownButtonFormField<String?>(
  hint: const Text("Select Blocker"),
  value: selectedBlockedBy,
  isExpanded: true,
  items: [
    const DropdownMenuItem(
      value: null,
      child: Text("None"),
    ),
    ...tasks.map<DropdownMenuItem<String?>>((t) {
      return DropdownMenuItem(
        value: t['id'],
        child: Text(t['title']),
      );
    }).toList(),
  ],
  onChanged: (v) => setModal(() => selectedBlockedBy = v),
),
                    DropdownButtonFormField(
                      value: recurring,
                      items: ["None", "Daily", "Weekly"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setModal(() => recurring = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);

                          if (task == null) {
                            await _service.createTask({
                              "title": title.text,
                              "description": desc.text,
                              "due_date": (selectedDate ?? DateTime.now()).toIso8601String(),
                              "status": selectedStatus,
                              "blocked_by": selectedBlockedBy,
                              "recurring": recurring,
                              "priority": tasks.length
                            });
                          } else {
                            await _service.updateTask(task['id'], {
                              "title": title.text,
                              "description": desc.text,
                              "due_date": (selectedDate ?? DateTime.now()).toIso8601String(),
                              "status": selectedStatus,
                              "blocked_by": selectedBlockedBy,
                              "recurring": recurring,
                              "priority": task['priority'] ?? 0
                            });
                          }

                          setState(() => isSaving = false);

                          Navigator.pop(context);
                          fetchTasks(search: searchQuery, status: filterStatus);
                        },
                  child: isSaving
                      ? const CircularProgressIndicator()
                      : const Text("Save"),
                )
              ],
            );
          },
        );
      },
    );
  }

  void deleteTask(String id) async {
    await _service.deleteTask(id);
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.tune),
            onSelected: (v) {
              setState(() => filterStatus = v.toString());
              fetchTasks(search: searchQuery, status: filterStatus);
            },
            itemBuilder: (_) => ["All", "To-Do", "In Progress", "Done"]
                .map((e) => PopupMenuItem(value: e, child: Text(e)))
                .toList(),
          )
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                searchQuery = v;
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  fetchTasks(search: searchQuery, status: filterStatus);
                });
              },
            ),
          ),

          Expanded(
            child: ReorderableListView.builder(
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;

                final item = tasks.removeAt(oldIndex);
                tasks.insert(newIndex, item);

                setState(() {});

                await _service.reorderTasks(
                  tasks.map((e) => e['id'] as String).toList(),
                );
              },
              itemBuilder: (_, i) {
                final t = tasks[i];

                final blockedTask =
                    tasks.where((x) => x['id'] == t['blocked_by']).toList();

                final isBlocked = t['blocked_by'] != null &&
                    (blockedTask.isEmpty ||
                        blockedTask.first['status'] != "Done");

                return Container(
                  key: ValueKey(t['id']),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  height: 100,
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? Colors.grey.shade400
                        : getCardColor(i),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            highlightText(t['title'], searchQuery),
                            const SizedBox(height: 4),
                            Text(
                              t['description'] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(t['status'],
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () =>
                                    openTaskDialog(task: t),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, size: 18),
                                onPressed: () =>
                                    deleteTask(t['id']),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => openTaskDialog(),
        backgroundColor: const Color(0xFFD7E5F0),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}