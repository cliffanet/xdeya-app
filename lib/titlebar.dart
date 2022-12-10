import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'pager.dart';
import 'net/wifidiscovery.dart';

Widget getTitleBarDiscovery() {
    return ValueListenableBuilder(
        valueListenable: wifi.notifyActive,
        builder: (BuildContext context, isActive, Widget? child) {
            return AppBar(
                title: isActive ? Row(
                    children: [
                        LoadingAnimationWidget.horizontalRotatingDots(
                            color: Colors.white,
                            size: 20,
                        ),
                        const Expanded(child: Text('Поиск устройств', textAlign: TextAlign.center))
                    ]
                ) : null,
                actions: <Widget>[
                    IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Обновить',
                        onPressed: isActive ? null : wifi.search
                    ),
                ],
            );
        },
    );
}

Widget getTitleBarClient(PageCode page) {
    /*
        List<Widget> row = [];

        if ((app.progmax > 0) && (app.progval >= 0) && (app.progval <= app.progmax)) {
            row.add(
                SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                            value: app.progval / app.progmax,
                            minHeight: 10,
                            color: Colors.black54,
                    )
                )
            );
        }
        else {
            bool load = wifi.isActive;
            if (load) {
                row.add(
                    LoadingAnimationWidget.horizontalRotatingDots(
                        color: Colors.white,
                        size: 20,
                    )
                );
            }
        }

        final String txt =
            wifi.isActive ?
                'Поиск WiFi' :
                '';
        if (!txt.isEmpty) {
            row.add(
                Expanded(child: Text(txt, textAlign: TextAlign.center))
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
        */
    return AppBar(
        title: null,
        actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Обновить',
                onPressed: null
            ),
        ],
    );
}
