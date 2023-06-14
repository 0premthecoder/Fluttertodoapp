import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late Database _database;
  List<Map<String, dynamic>> _todoItems = [];

  @override
  void initState() {
    super.initState();
    _openDatabase().then((database) {
      _database = database;
      _loadTodoItems();
    });
  }

  Future<Database> _openDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, 'todo.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE todo_items(
            id INTEGER PRIMARY KEY,
            title TEXT,
            is_done INTEGER
          )
        ''');
      },
    );
  }

  Future<void> _loadTodoItems() async {
    final List<Map<String, dynamic>> todoItems = await _database.query('todo_items');
    setState(() {
      _todoItems = todoItems;
    });
  }

  Future<void> _addTodoItem(String title) async {
    await _database.insert(
      'todo_items',
      {'title': title, 'is_done': 0},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    _loadTodoItems();
  }

  Future<void> _updateTodoItem(int id, String title) async {
    await _database.update(
      'todo_items',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadTodoItems();
  }

  Future<void> _toggleTodoItem(int id, bool isDone) async {
    await _database.update(
      'todo_items',
      {'is_done': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadTodoItems();
  }

  Future<void> _deleteTodoItem(int id) async {
    await _database.delete(
      'todo_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadTodoItems();
  }

  void _showEditDialog(int id, String currentTitle) {
    showDialog(
      context: this.context,
      builder: (BuildContext dialogContext) {
        String newTitle = currentTitle;
        return AlertDialog(
          title: Text('Edit Todo'),
          content: TextField(
            controller: TextEditingController(text: currentTitle),
            onChanged: (value) {
              newTitle = value;
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _updateTodoItem(id, newTitle);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: this.context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Todo'),
          content: Text('Are you sure you want to delete this todo item?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteTodoItem(id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List From Team: 4;')),
      body: Container(
        margin: const EdgeInsets.only(top: 25),
        child: ListView.builder(
          itemCount: _todoItems.length,
          itemBuilder: (BuildContext context, int index) {
            final todoItem = _todoItems[index];
            return ListTile(
              title: Text(todoItem['title'],
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  decoration: todoItem['is_done']==1 ? TextDecoration.lineThrough : null),
              ),
              leading: Checkbox(
                value: todoItem['is_done'] == 1,
                onChanged: (bool? value) {
                  _toggleTodoItem(todoItem['id'], value ?? false);
                },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    color: Colors.blue,
                    onPressed: () {
                      _showEditDialog(todoItem['id'], todoItem['title']);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    color: Colors.redAccent,
                    onPressed: () {
                      _showDeleteConfirmationDialog(todoItem['id']);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              String newTodoTitle = '';
              return AlertDialog(
                title: Text('Add New Todo'),
                content: TextField(
                  onChanged: (value) {
                    newTodoTitle = value;
                  },
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Add'),
                    onPressed: () {
                      if (newTodoTitle.isNotEmpty) {
                        _addTodoItem(newTodoTitle);
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
