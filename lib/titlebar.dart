import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'core.dart';

class TitleBar extends StatefulWidget {

  TitleBar({super.key});

  @override
  _TitleBarState createState() => _TitleBarState();
}


class _TitleBarState extends State<TitleBar> {
    _TitleBarState() : super() {
        app.reloadTitleBar = () => { setState(() => {}) };
    }

    @override
    Widget build(BuildContext context) {
        List<Widget> row = [
            const Expanded(child: Text('Xde-Ya', textAlign: TextAlign.center))
        ];

        if ((app.progmax > 0) && (app.progval >= 0) && (app.progval <= app.progmax)) {
            row.insert(0,
                SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                            value: app.progval / app.progmax,
                            minHeight: 10,
                            color: Colors.green,
                    )
                )
            );
        }
        else
        if (app.progval != 0) {
            row.insert(0,
                LoadingAnimationWidget.horizontalRotatingDots(
                    color: Colors.white,
                    size: 20,
                )
            );
        }

        if (false) {
            row.insert(0,
                const IconButton(
                    icon: Icon(Icons.wifi),
                    tooltip: 'Navigation menu',
                    onPressed: null,
                ),
            );
        }

        return AppBar(
            leading: const IconButton(
                icon: Icon(Icons.arrow_back),
                tooltip: 'Назад',
                onPressed: null,
            ),
            title: Row(children: row),
            actions: const <Widget>[
                IconButton(
                    icon: Icon(Icons.refresh),
                    tooltip: 'Обновить',
                    onPressed: null,
                ),
            ],
        );
    }
}
