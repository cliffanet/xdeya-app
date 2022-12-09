import 'package:flutter/material.dart';
import 'titlebar.dart';
import 'core.dart';

void main() {
    runApp(MaterialApp(
        title: 'Xde-Ya altimeter',
        home: XdeYaApp(),
    ));
}

class XdeYaApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: PreferredSize(
                preferredSize: const Size(double.infinity, kToolbarHeight), // here the desired height
                child: TitleBar()
            ),
            /*
            AppBar(
                leading: const IconButton(
                    icon: Icon(Icons.menu),
                    tooltip: 'Navigation menu',
                    onPressed: null,
                ),
                title: const Text('Xde-Ya'),
                actions: const <Widget>[
                    IconButton(
                        icon: Icon(Icons.search),
                        tooltip: 'Search',
                        onPressed: null,
                    ),
                ],
            ),
            */
            // body - это большая часть экрана.
            body: Column(
                    children: <Widget>[
                        Text('Hello, world!'),
                        OutlinedButton(
                            child: Text("Inc"),
                            onPressed: () {
                                app.progval ++;
                            }
                        ),
                        OutlinedButton(
                            child: Text("Max"),
                            onPressed: () {
                                app.progmax ++;
                            }
                        ),
                    ]
                ),
        );
    }
}
