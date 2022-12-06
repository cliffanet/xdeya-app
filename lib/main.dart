import 'package:flutter/material.dart';
import 'titlebar.dart';

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
            appBar: TitleBar(),
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
            body: const Center(
                child: Text('Hello, world!'),
            ),
        );
    }
}
