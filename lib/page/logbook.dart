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
                                net.requestAuth(
                                    v,
                                    onReplyOk: () => net.requestLogBook()
                                );
                            },
                            decoration: const InputDecoration(
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
    PageLogBook({ super.key });

    final ScrollController _scrollController = ScrollController();
    _scrollToBottom() {
        if (!_scrollController.hasClients) {
            return;
        }
        //_scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut
        );
    }
    
    @override
    Widget build(BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: net.notifyInf,
            builder: (BuildContext context, inf, Widget? child) {
                if (net.state == NetState.waitauth) {
                    return _pageAuth();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ValueListenableBuilder(
                    valueListenable: net.notifyLogBook,
                    builder: (BuildContext context, count, Widget? child) {
                        if (net.logbook.isEmpty) {
                            return const Center(
                                child: Text(
                                    'Не найдено', 
                                    style: TextStyle(color: Colors.black26)
                                )
                            );
                        }
                        
                        return ListView.separated(
                            itemCount: net.logbook.length,
                            itemBuilder: (BuildContext contextItem, int index) {
                                final lb = net.logbook[index];
                                return Card(
                                    child: ListTile(
                                        onTap: () {
                                            developer.log('tap on: $index');
                                            //net.start(w.ip, w.port);
                                            //Pager.push(context, PageCode.logbook);
                                        },
                                        trailing: const SizedBox.shrink(),
                                        title: Text(lb.num.toString()),
                                    )
                                );
                            },
                            separatorBuilder: (BuildContext context, int index) => const Divider(),
                            controller: _scrollController,
                        );
                    },
                );
            }
        );
    }
}
