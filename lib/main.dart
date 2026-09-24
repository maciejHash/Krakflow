import 'package:flutter/material.dart';
import 'task_repository.dart';

void main() {
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Masz dziś ${TaskRepository.tasks.length} zadania do wykonania',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Dzisiejsze zadania:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: TaskRepository.tasks.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final task = TaskRepository.tasks[index];
                    return Dismissible(
                      key: ValueKey(task.title),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        setState(() {
                          TaskRepository.tasks.remove(task);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Zadanie \"${task.title}\" usunięte"),
                          ),
                        );
                      },
                      child: TaskCard(
                        title: task.title,
                        deadline: 'Termin: ${task.deadline}',
                        priority: 'Priorytet: ${task.priority}',
                        done: task.done,
                        icon: task.done ? Icons.check_circle : Icons.circle_outlined,
                        onChanged: (value) {
                          setState(() {
                            task.done = value!;
                          });
                        },
                        onTap: () async {
                          final Task? updatedTask = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          );

                          if (updatedTask != null) {
                            setState(() {
                            TaskRepository.tasks[index] = updatedTask;
                            });
                          }
                        }
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
            builder: (context) => AddTaskScreen(),
            ),
          );
          if (newTask != null) {
            setState(() {
            TaskRepository.tasks.add(newTask);
          });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowe zadanie"),
      ),
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
      appBar: AppBar(
        title: Text("Edytuj zadanie"),
      ),
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
  final IconData icon;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.done,
    required this.icon,
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
        leading: Checkbox(
          value: isDone,
          onChanged: onChanged,
        ),
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
                color: isDone ? Colors.grey[600] : null,
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