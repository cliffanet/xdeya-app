import 'package:flutter/material.dart';

class PageLogBook extends StatefulWidget {

  PageLogBook({super.key});

  @override
  _PageLogBookState createState() => _PageLogBookState();
}


class _PageLogBookState extends State<PageLogBook> {
    //PageLogBook() : super() {
    //    wifi.redraw = () => setState(() => {});
    //}
    
    @override
    Widget build(BuildContext context) {
        return Center(
            child: const Text('Logbook')
        );
    }
}
