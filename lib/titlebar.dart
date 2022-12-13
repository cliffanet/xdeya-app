import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'pager.dart';
import 'net/wifidiscovery.dart';
import 'net/proc.dart';

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
    return ValueListenableBuilder(
        valueListenable: net.notifyState,
        builder: (BuildContext context, state, Widget? child) {
            List<Widget> row = [];

            if (net.error != null) {
                String txt;
                switch (net.error) {
                    case NetError.connect:
                        txt = 'Не могу подключиться';
                        break;

                    case NetError.disconnected:
                        txt = 'Соединение разорвано';
                        break;
                        
                    case NetError.proto:
                        txt = 'Ошибка протокола передачи';
                        break;
                        
                    case NetError.cmddup:
                        txt = 'Задублированный запрос';
                        break;
                        
                    case NetError.auth:
                        txt = 'Неверный код авторизации';
                        break;
                    
                    default:
                        txt = 'Неизвестная ошибка';
                }
                row.add(Expanded(
                    child: Text(
                        txt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)
                    )
                ));
            }
            else
            if (net.state != NetState.online) {
                String ?txt;
                switch (net.state) {
                    case NetState.connecting:
                        txt = 'Подключение';
                        break;

                    case NetState.connected:
                        txt = 'Ожидание приветствия';
                        break;
                        
                    case NetState.waitauth:
                        txt = 'Авторизация на устройстве';
                        break;
                    
                    default:
                }
                if (txt != null) {
                    row.add(Expanded(
                        child: Text(
                            txt,
                            textAlign: TextAlign.center,
                        )
                    ));
                }
            }
            
            /*
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
                title: Row(children: row),
                actions: <Widget>[
                    IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Обновить',
                        onPressed: null
                    ),
                ],
            );
        }
    );
}
