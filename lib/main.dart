import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      if (_toDoController.text.isEmpty) {
        return;
      }
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _toDoController.text;
      _toDoController.text = '';
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && !b['ok'])
          return 0;
        else
          return -1;
      });

      _saveData();
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de tarefas'),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              textDirection: TextDirection.ltr,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    style: TextStyle(fontSize: 20.0),
                    decoration: InputDecoration(
                        hintText: 'Tarefa',
                        hintStyle:
                            TextStyle(fontSize: 20.0, color: Colors.black),
                        labelText: 'Nova Tarefa',
                        labelStyle:
                            TextStyle(color: Colors.lightBlue, fontSize: 20.0)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 90.0),
                ),
                SizedBox(
                  height: 50.0,
                  width: 60.0,
                  child: RawMaterialButton(
                    child: Icon(
                      Icons.add_circle,
                      size: 50.0,
                      color: Colors.lightBlue,
                    ),
                    shape: CircleBorder(),
                    elevation: 6.0,
                    fillColor: Colors.black,
                    onPressed: _addToDo,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemBuilder: buildItem,
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _toDoList.length,
            ),
          ))
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);
          _saveData();

          final snackBar = SnackBar(
            content: Text(
              'Tarefa \"${_lastRemoved['title']}\" foi removida!',
            ),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child:
              Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error_outline),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]['ok'] = c;
            _saveData();
          });
        },
      ),
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
