import 'dart:async';

import 'package:flutter/material.dart';
import 'package:repo/models/enums.dart';
import 'package:repo/models/todo.dart';
import 'package:repo/services/database_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> todos = [];

  StreamSubscription? todosStream;
  @override
  void initState() {
    super.initState();
    todosStream = DatabaseService.db.todos
        .buildQuery<Todo>()
        .watch(fireImmediately: true,
    ).listen(
          (data){
            setState((){
              todos = data;
            });
          },
    );
  }

  @override
  void dispose() {
    todosStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: SizedBox.expand(
      child: _buildUI(),
    ),
    ),
      floatingActionButton: FloatingActionButton(
          onPressed: _addOrEditTodo,
        child: const Icon(
            Icons.add,
         ),
      ),
    );
  }

  Widget _buildUI() {
    return Padding(padding: EdgeInsets.symmetric(
      vertical: 20,
      horizontal: 20,
    ),
      child: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.only(
              left: 10,
            ),
            title: Text(
                todo.content ?? "",
            ),
            subtitle: Text("Marked ${todo.status.name} at ${todo.updatedAt}"),
            trailing: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                icon: const Icon(
                  Icons.edit,
                ),
                onPressed: () {
                  _addOrEditTodo(
                    todo: todo,
                  );
                } ,
              ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.purple,
                  ),
                  onPressed: () async {
                    await DatabaseService.db.writeTxn(() async {
                      await DatabaseService.db.todos.delete(
                        todo.id,
                      );
                    },
                    );
                  } ,
                ),
              ],
                      ),

          ),
        );
      },
      ),
    );
  }
  void _addOrEditTodo({
    Todo? todo,
  }) {
    TextEditingController contentController = TextEditingController(
        text: todo?.content ?? "",
    );
    Status status = todo?.status?? Status.pending;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
          title: Text(todo != null ? "Edit To-Do": "Add To-Do"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                        labelText: 'Content'
                    ),
                  ),
                  DropdownButtonFormField<Status>(
                    value: status,
                    items: Status.values.map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e.name,
                            ),
                          ),
                    )
                      .toList(),
                    onChanged: (value){
                        if (value == null) return;
                        status = value;
                    },
                  ),
                ],
            ),
            //CANCEL
            actions: [
              TextButton(
              onPressed: () {
              Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
              //SAVE
              TextButton(
                onPressed: () async {
                  if (contentController.text.isNotEmpty) {
                    late Todo newTodo;
                    if (todo != null) {
                      newTodo = todo.copyWith(
                        content: contentController.text,
                        status: status,
                      );
                    }else {
                      newTodo = Todo().copyWith(
                        content: contentController.text,
                        status: status,
                      );
                    }
                    await DatabaseService.db.writeTxn(
                          () async {
                            await DatabaseService.db.todos.put(
                              newTodo,
                            );
                          },
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
    );
  }
}

