import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PageLogBook extends StatelessWidget {
    const PageLogBook({ super.key });
    
    @override
    Widget build(BuildContext context) {
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
}
