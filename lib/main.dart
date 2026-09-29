import 'package:flutter/material.dart';

import 'models/task.dart';
import 'services/task_local_database.dart';
import 'services/task_sync_service.dart';

import 'package:hive_ce_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter(); // inicjalizacja Hive
  await Hive.openBox("tasks"); // otwarcie kontenera

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krakflow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(title: 'Krakflow'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await TaskSyncService.loadInitialDataIfNeeded();
      final tasks = TaskLocalDatabase.getTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // zmienna pomocnicza przetrzymująca obecnie przefiltrowaną listę
    List<Task> filteredTasks = _tasks;
    if (selectedFilter == "wykonane") {
      filteredTasks = _tasks.where((task) => task.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = _tasks.where((task) => !task.done).toList();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: Text("Potwierdzenie"),
                    content: Text(
                      "Czy na pewno chcesz usunąć wszystkie zadania?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text("Anuluj"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await TaskLocalDatabase.deleteAllTasks();
                          if (!mounted || !dialogContext.mounted) return;
                          setState(() {
                            _tasks.clear();
                          });
                          Navigator.pop(dialogContext); // zamyka dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Wszystkie zadania zostały usunięte",
                              ),
                            ),
                          );
                        },
                        child: Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Masz dziś ${_tasks.length} zadania do wykonania',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'wszystkie', label: Text('Wszystkie')),
                  ButtonSegment(value: 'wykonane', label: Text('Wykonane')),
                  ButtonSegment(
                    value: 'do zrobienia',
                    label: Text('Do zrobienia'),
                  ),
                ],
                selected: {selectedFilter},
                onSelectionChanged: (selection) {
                  setState(() {
                    selectedFilter = selection.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Dzisiejsze zadania:',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Nie udało się pobrać zadań: $_loadError'),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _loadTasks,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Spróbuj ponownie'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTasks.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return Dismissible(
                            key: ValueKey(task.title),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) async {
                              setState(() {
                                _tasks.remove(task);
                              });
                              await TaskLocalDatabase.deleteTask(task.id);
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Zadanie "${task.title}" usunięte',
                                  ),
                                ),
                              );
                            },
                            child: TaskCard(
                              title: task.title,
                              deadline: 'Termin: ${task.deadline}',
                              priority: 'Priorytet: ${task.priority}',
                              done: task.done,
                              onChanged: (value) async {
                                if (value == null) return;
                                setState(() {
                                  task.done = value;
                                });
                                await TaskLocalDatabase.updateTask(task);
                              },
                              onTap: () async {
                                final Task? updatedTask = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditTaskScreen(task: task),
                                  ),
                                );

                                if (updatedTask == null || !context.mounted) {
                                  return;
                                }
                                await TaskLocalDatabase.updateTask(updatedTask);
                                if (!mounted) return;
                                setState(() {
                                  final taskIndex = _tasks.indexOf(task);
                                  _tasks[taskIndex] = updatedTask;
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(
                id:
                    _tasks.fold<int>(
                      0,
                      (maxId, task) => task.id > maxId ? task.id : maxId,
                    ) +
                    1,
              ),
            ),
          );
          if (newTask == null || !mounted) return;
          await TaskLocalDatabase.addTask(newTask);
          if (!mounted) return;
          setState(() {
            _tasks.add(newTask);
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key, required this.id});
  final int id;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nowe zadanie")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  id: id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: false,
                );

                Navigator.pop(context, newTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;

  EditTaskScreen({super.key, required this.task});
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    titleController.text = task.title;
    deadlineController.text = task.deadline;
    priorityController.text = task.priority;

    return Scaffold(
      appBar: AppBar(title: Text("Edytuj zadanie")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  id: task.id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: task.done,
                );

                Navigator.pop(context, updatedTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String deadline;
  final String priority;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = done;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDone ? Colors.white : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(value: isDone, onChanged: onChanged),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            decorationThickness: 2,
            color: isDone ? Colors.grey[700] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              deadline,
              style: TextStyle(
                color: isDone ? Colors.grey[600] : null,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              priority,
              style: TextStyle(
                color: isDone
                    ? Colors.grey[600]
                    : (priority == "Priorytet: wysoki"
                          ? Colors.red
                          : (priority == "Priorytet: średni"
                                ? Colors.orange
                                : Colors.green)),
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
