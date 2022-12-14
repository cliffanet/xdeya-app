import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:masked_text/masked_text.dart';
import 'dart:developer' as developer;

import '../net/proc.dart';

Widget _pageAuth() {
    return Container(
        //color: Colors.black54,
        child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 32.0,
            ),
            child: Column(
                children: [
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: MaskedTextField(
                            mask: '####',
                            maskFilter: { "#": RegExp(r'[0-9A-Fa-f]') },
                            onChanged: (v) {
                                if (v.length != 4) {
                                    return;
                                }
                                net.requestAuth(v);
                            },
                            decoration: InputDecoration(
                                labelText: 'Введите код с экрана',
                            ),
                            //autofocus: true,
                        ),
                    )
                ],
            )
        )
    );
}

Widget _pageLogBook(BuildContext context) {
        switch (Theme.of(context).platform) {
            case TargetPlatform.android:
            case TargetPlatform.iOS:
                return const WebView(
                    javascriptMode: JavascriptMode.unrestricted,
                    initialUrl: "https://maps.yandex.ru"
                );
            default:
        }

        return const Center(
            child: Text('Logbook')
        );
}

class PageLogBook extends StatelessWidget {
    const PageLogBook({ super.key });
    
    @override
    Widget build(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: net.notifyState,
            builder: (BuildContext context, count, Widget? child) {
                if (net.state == NetState.waitauth) {
                    return _pageAuth();
                }
                return _pageLogBook(context);
            }
        );
    }
}
