import 'package:flutter/material.dart';
import 'titlebar.dart';

import 'page/discovery.dart';
import 'page/logbook.dart';

enum PageCode { discovery, logbook }

final Map<PageCode, Widget> _pageMap = {
    PageCode.discovery: PageDiscovery(),
    PageCode.logbook:   PageLogBook()
};

class Pager extends StatelessWidget {
    final PageCode page;
    const Pager({ super.key, required this.page });

    Widget get widget => _pageMap[page] ?? Container();

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: PreferredSize(
                preferredSize: const Size(double.infinity, kToolbarHeight), // here the desired height
                child:
                    page == PageCode.discovery ?
                        getTitleBarDiscovery() :
                        getTitleBarClient(page)
            ),
            body: widget
        );
    }

    static push(BuildContext context, PageCode page) {
        Widget ?w = _pageMap[page];
        if (w == null) {
            return;
        }

        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Pager(page: page)),
        );
    }
    static pop(BuildContext context) {
        Navigator.pop(context);
    }
}