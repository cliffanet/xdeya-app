import 'package:flutter/material.dart';

class TitleBar extends AppBar {
    TitleBar() : super(
                leading: const IconButton(
                    icon: Icon(Icons.arrow_back),
                    tooltip: 'Назад',
                    onPressed: null,
                ),
                title: Row(
                    children: [
                        const IconButton(
                            icon: Icon(Icons.wifi),
                            tooltip: 'Navigation menu',
                            onPressed: null,
                        ),
                        Expanded(
                            child: Center(
                                child: Text('Hello, world!'),
                            ),
                        ),
                        Text('Xde-Ya2'),
                    ]
                ),
                actions: const <Widget>[
                    IconButton(
                        icon: Icon(Icons.refresh),
                        tooltip: 'Обновить',
                        onPressed: null,
                    ),
                ],
    );
}
