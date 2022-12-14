import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:developer' as developer;

import 'binproto.dart';

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

final net = NetProc();

class NetProc {
    Socket ?_sock;
    final ValueNotifier<NetState> _state = ValueNotifier(NetState.offline);
    final ValueNotifier<NetError?> _err = ValueNotifier(null);

    bool get isActive => (_state.value != NetState.offline);

    NetState get state => _state.value;
    ValueNotifier<NetState> get notifyState => _state;
    NetError? get error => _err.value;
    ValueNotifier<NetError?> get notifyError => _err;

    void stop() {
        _sock?.close();
    }

    Future<bool> start(InternetAddress ip, int port) async {
        _sock?.close();
        //await Future.doWhile(() => isActive);

        developer.log('net connecting to: $ip:$port');
        _state.value = NetState.connecting;
        _err.value = null;

        try {
            _sock = await Socket.connect(ip, port);
        }
        catch (err) {
            _sock = null;
            _state.value = NetState.offline;
            _err.value = NetError.connect;
            return false;
        }

        _sock?.listen(
            recv,
            onDone: () {
                _state.value = NetState.offline;
                _sock!.close();
                _sock = null;
                _pro.rcvClear();
                _reciever.clear();
                _err.value ??= NetError.disconnected;
            }
        );
        developer.log('net connected');

        _state.value = NetState.connected;

        // запрос hello
        if (!recieverAdd(0x02, () {
                recieverDel(0x02);
                _pro.rcvNext();
                _state.value = NetState.waitauth;
                developer.log('rcv hello');
            }))
        {
            _err.value = NetError.cmddup;
            stop();
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
            _err.value = NetError.proto;
            stop();
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
                _err.value = NetError.proto;
                stop();
                return;
            }
        }
    }

    bool send(int cmd, [String? pk, List<dynamic>? vars]) {
        if (_sock == null) {
            _err.value = NetError.disconnected;
            return false;
        }
        
        var data = _pro.pack(cmd, pk, vars);
        _sock?.add(data);
        developer.log('send cmd=$cmd, size=${ data.length }');

        return true;
    }

    final Map<int, void Function()> _reciever = {};

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

    bool requestAuth(String codehex) {
        int code = int.parse(codehex, radix: 16);
        if (code == 0) {
            return false;
        }

        bool ok = recieverAdd(0x03, () {
                recieverDel(0x03);
                List<dynamic> ?v = _pro.rcvData('C');
                if ((v == null) || v.isEmpty || (v[0] > 0)) {
                    _err.value = NetError.auth;
                    stop();
                    return;
                }
                developer.log('auth ok');
                _state.value = NetState.online;
            });
        if (!ok) return false;

        return send(0x03, 'n', [code]);
    }
}
