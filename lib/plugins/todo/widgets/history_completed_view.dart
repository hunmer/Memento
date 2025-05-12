
import 'package:Memento/plugins/todo/widgets/history_task_detail_view.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../controllers/task_controller.dart';

class HistoryCompletedView extends StatefulWidget {
  final List<Task> completedTasks;
  final TaskController taskController;

  const HistoryCompletedView({
    super.key,
    required this.completedTasks,
    required this.taskController,
  });

  @override
  State<HistoryCompletedView> createState() => _HistoryCompletedViewState();
}

class _HistoryCompletedViewState extends State<HistoryCompletedView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.completedTasks.length,
        itemBuilder: (context, index) {
          final task = widget.completedTasks[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryTaskDetailView(
                    task: task,
                  ),
                ),
              );
            },
            child: ListTile(
              title: Text(task.title),
              subtitle: Text(
                'Completed on: ${task.completedDate?.toLocal()}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await widget.taskController.removeFromHistory(task.id);
                  setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
