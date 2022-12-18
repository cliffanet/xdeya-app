import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:developer' as developer;

import 'binproto.dart';
import 'types.dart';

enum NetState {
    offline,
    connecting,
    connected,
    waitauth,
    online
}

enum NetError {
    connect,
    disconnected,
    proto,
    cmddup,
    auth
}

enum NetRecvElem {
    logbook,
    tracklist,
    trackdata,
    wifipass
}

final net = NetProc();

class NetProc {
    Socket ?_sock;

    NetState _state = NetState.offline;
    NetState get state => _state;
    bool get isActive => (_state != NetState.offline);

    NetError? _err;
    NetError? get error => _err;

    final Set<NetRecvElem> _rcvelm = {};
    Set<NetRecvElem> get rcvElem => _rcvelm;

    int _datacnt = 0;
    int _datamax = 0;
    double get dataProgress => _datacnt > _datamax ? 1.0 : _datacnt / _datamax;
    bool get isProgress => _datamax > 0;

    final ValueNotifier<int> _notify = ValueNotifier(0);
    ValueNotifier<int> get notifyInf => _notify;
    void _infNotify() => _notify.value++;

    void stop() {
        _sock?.close();
    }

    void _errstop(NetError ?err) {
        _err = err;
        _infNotify();
        stop();
    }

    Future<bool> start(InternetAddress ip, int port) async {
        _sock?.close();
        //await Future.doWhile(() => isActive);

        developer.log('net connecting to: $ip:$port');
        _state = NetState.connecting;
        _err = null;
        _infNotify();

        try {
            _sock = await Socket.connect(ip, port);
        }
        catch (err) {
            _sock = null;
            _state = NetState.offline;
            _err = NetError.connect;
            _infNotify();
            return false;
        }

        _sock?.listen(
            recv,
            onDone: () {
                _state = NetState.offline;
                _sock!.close();
                _sock = null;
                _pro.rcvClear();
                _reciever.clear();
                _err ??= NetError.disconnected;
                _infNotify();
                developer.log('net disconnected');
            }
        );
        developer.log('net connected');

        _state = NetState.connected;
        _infNotify();

        // запрос hello
        if (!recieverAdd(0x02, () {
                recieverDel(0x02);
                _pro.rcvNext();
                _state = NetState.waitauth;
                _infNotify();
                developer.log('rcv hello');
            }))
        {
            _errstop(NetError.cmddup);
            return false;
        }

        if (!send(0x02)) {
            return false;
        }

        return true;
    }

    final BinProto _pro = BinProto();
    void recv(data) {
        if (!_pro.rcvProcess(data)) {
            _errstop(NetError.proto);
            return;
        }

        while (_pro.rcvState == BinProtoRecv.complete) {
            Function() ?hnd = _reciever[ _pro.rcvCmd ];

            if (hnd != null) {
                hnd();
            }
            else {
                developer.log('recv unknown: cmd=0x${_pro.rcvCmd.toRadixString(16)}');
                _pro.rcvNext();
            }

            if (!_pro.rcvProcess()) {
                _errstop(NetError.proto);
                return;
            }
        }
    }

    bool send(int cmd, [String? pk, List<dynamic>? vars]) {
        if (_sock == null) {
            _err = NetError.disconnected;
            _infNotify();
            return false;
        }
        
        var data = _pro.pack(cmd, pk, vars);
        _sock?.add(data);
        developer.log('send cmd=$cmd, size=${ data.length }');

        return true;
    }

    final Map<int, void Function()> _reciever = {};
    bool get isLoading => _reciever.isNotEmpty;

    bool recieverAdd(int cmd, void Function() hnd) {
        if (_reciever[cmd] != null) {
            return false;
        }

        _reciever[cmd] = hnd;

        return true;
    }
    
    bool recieverDel(int cmd) {
        if (_reciever[cmd] == null) {
            return false;
        }

        _reciever.remove(cmd);

        return true;
    }

    void Function()? reciever(int cmd) {
        return _reciever[cmd];
    }

    bool requestAuth(String codehex, { Function() ?onReplyOk, Function() ?onReplyErr }) {
        int code = int.parse(codehex, radix: 16);
        if (code == 0) {
            return false;
        }

        bool ok = recieverAdd(0x03, () {
                recieverDel(0x03);
                List<dynamic> ?v = _pro.rcvData('C');
                if ((v == null) || v.isEmpty || (v[0] > 0)) {
                    _errstop(NetError.auth);
                    if (onReplyErr != null) onReplyErr();
                    return;
                }
                developer.log('auth ok');
                _state = NetState.online;
                _infNotify();
                if (onReplyOk != null) onReplyOk();
            });
        if (!ok) return false;
        _infNotify();

        return send(0x03, 'n', [code]);
    }

    final ValueNotifier<int> _logbooksz = ValueNotifier(0);
    ValueNotifier<int> get notifyLogBook => _logbooksz;
    final List<LogBook> _logbook = [];
    List<LogBook> get logbook => _logbook;

    bool requestLogBook({ int beg = 50, int count = 50, Function() ?onReply }) {
        if (_rcvelm.contains(NetRecvElem.logbook)) {
            return false;
        }
        bool ok = recieverAdd(0x31, () {
                recieverDel(0x31);
                List<dynamic> ?v = _pro.rcvData('NN');
                if ((v == null) || v.isEmpty) {
                    return;
                }

                developer.log('logbook beg ${v[0]}, ${v[1]}');
                _rcvelm.add(NetRecvElem.logbook);
                _datamax = v[0] < v[1] ? v[0] : v[1];
                _logbook.clear();
                _logbooksz.value = 0;
                _datacnt = 0;
                _infNotify();

                recieverAdd(0x32, () {
                    List<dynamic> ?v = _pro.rcvData(LogBook.pk);
                    if ((v == null) || v.isEmpty) {
                        return;
                    }
                    _logbook.add(LogBook.byvars(v));
                    _logbooksz.value = _logbook.length;
                    _datacnt = _logbook.length;
                    _infNotify();
                });
                recieverAdd(0x33, () {
                    recieverDel(0x32);
                    recieverDel(0x33);
                    developer.log('logbook end $_datacnt / $_datamax');
                    _pro.rcvNext();
                    _rcvelm.remove(NetRecvElem.logbook);
                    _datamax = 0;
                    _datacnt = 0;
                    _infNotify();
                });
            });
        if (!ok) return false;
        _infNotify();

        return send(0x31, 'NN', [beg, count]);
    }
}
