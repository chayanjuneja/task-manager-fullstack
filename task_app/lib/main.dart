import 'package:flutter/material.dart';
import 'services/task_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
  final FocusNode searchFocusNode = FocusNode();
  Timer? _debounce;

  String searchQuery = "";
  String filterStatus = "All";

  List tasks = [];
  bool isLoading = true;
  bool isSaving = false;

  String selectedStatus = "To-Do";
  DateTime? selectedDate;
  String? selectedBlockedBy;

  // ✅ DRAFT FUNCTIONS
  Future<void> saveDraft(String title, String desc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_title', title);
    await prefs.setString('draft_desc', desc);
  }

  Future<Map<String, String>> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "title": prefs.getString('draft_title') ?? "",
      "desc": prefs.getString('draft_desc') ?? "",
    };
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_desc');
  }

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
      loadDraft().then((draft) {
        title.text = draft["title"]!;
        desc.text = draft["desc"]!;
      });
    } else {
      title.text = task['title'] ?? "";
      desc.text = task['description'] ?? "";
    }

    selectedStatus = task?['status'] ?? "To-Do";
    selectedDate = task != null ? DateTime.tryParse(task['due_date']) : null;
    selectedBlockedBy = task?['blocked_by'];

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
                    DropdownButtonFormField(
                      hint: const Text("Blocked By"),
                      value: selectedBlockedBy,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("None"),
                        ),
                        ...tasks.map<DropdownMenuItem>((t) {
                          return DropdownMenuItem(
                            value: t['id'],
                            child: Text(t['title']),
                          );
                        }).toList(),
                      ],
                      onChanged: (v) => setModal(() => selectedBlockedBy = v),
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
                              "blocked_by": selectedBlockedBy
                            });

                            // ✅ CLEAR DRAFT ONLY AFTER CREATE
                            await clearDraft();
                          } else {
                            await _service.updateTask(task['id'], {
                              "title": title.text,
                              "description": desc.text,
                              "due_date": (selectedDate ?? DateTime.now()).toIso8601String(),
                              "status": selectedStatus,
                              "blocked_by": selectedBlockedBy
                            });
                          }

                          setState(() => isSaving = false);

                          Navigator.pop(context);
                          fetchTasks(search: searchQuery, status: filterStatus);
                        },
                  child: isSaving ? const CircularProgressIndicator() : const Text("Save"),
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
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (width > 1200) crossAxisCount = 5;
    else if (width > 900) crossAxisCount = 4;
    else if (width > 600) crossAxisCount = 3;

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
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final t = tasks[i];

                final blockedTask = tasks.where((x) => x['id'] == t['blocked_by']).toList();
                final isBlocked = t['blocked_by'] != null &&
                    (blockedTask.isEmpty || blockedTask.first['status'] != "Done");

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isBlocked ? Colors.grey.shade400 : getCardColor(i),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      highlightText(t['title'], searchQuery),
                      const SizedBox(height: 4),
                      Text(t['description'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t['status'], style: const TextStyle(fontSize: 12)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => openTaskDialog(task: t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => deleteTask(t['id']),
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