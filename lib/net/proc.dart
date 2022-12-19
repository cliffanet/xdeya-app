import 'dart:ffi';

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
                _rcvelm.clear();
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

    bool requestLogBook({ int beg = 50, int count = 50, Function() ?onLoad }) {
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
                    if (onLoad != null) onLoad();
                });
            });
        if (!ok) return false;
        if (!send(0x31, 'NN', [beg, count])) {
            recieverDel(0x31);
            return false;
        }
        _rcvelm.add(NetRecvElem.logbook);
        _infNotify();

        return true;
    }

    bool requestLogBookDefault() {
        return requestLogBook(
            onLoad: () => requestTrkList()
        );
    }

    final ValueNotifier<int> _trklistsz = ValueNotifier(0);
    ValueNotifier<int> get notifyTrkList => _trklistsz;
    final List<TrkItem> _trklist = [];
    List<TrkItem> get trklist => _trklist;
    List<TrkItem> trkListByJmp(LogBook jmp) {
        return _trklist.where((trk) => trk.jmpnum == jmp.num).toList();
    }

    bool requestTrkList({ Function() ?onLoad }) {
        if (_rcvelm.contains(NetRecvElem.tracklist)) {
            return false;
        }
        bool ok = recieverAdd(0x51, () {
                recieverDel(0x51);
                _pro.rcvNext();

                developer.log('trklist beg');
                _trklist.clear();
                _trklistsz.value = 0;
                _infNotify();

                recieverAdd(0x52, () {
                    List<dynamic> ?v = _pro.rcvData('NNNNTNC');
                    if ((v == null) || v.isEmpty) {
                        return;
                    }
                    _trklist.add(TrkItem.byvars(v));
                    _trklistsz.value = _trklist.length;
                    _infNotify();
                });
                recieverAdd(0x53, () {
                    recieverDel(0x52);
                    recieverDel(0x53);
                    developer.log('trklist end');
                    _pro.rcvNext();
                    _rcvelm.remove(NetRecvElem.tracklist);
                    _infNotify();
                    if (onLoad != null) onLoad();
                });
            });
        if (!ok) return false;
        if (!send(0x51)) {
            recieverDel(0x51);
            return false;
        }
        _rcvelm.add(NetRecvElem.tracklist);
        _infNotify();

        return true;
    }

    TrkInfo _trkinfo = TrkInfo.byvars([]);
    TrkInfo get trkinfo => _trkinfo;
    final ValueNotifier<int> _trkdatasz = ValueNotifier(0);
    ValueNotifier<int> get notifyTrkData => _trkdatasz;
    final List<Struct> _trkdata = [];
    List<Struct> get trkdata => _trkdata;
    Struct ?_trkcenter;
    Struct ? get trkCenter => _trkcenter;

    bool requestTrkData(TrkItem trk, { Function() ?onLoad, Function(Struct) ?onCenter }) {
        if (_rcvelm.contains(NetRecvElem.trackdata)) {
            return false;
        }
        bool ok = recieverAdd(0x54, () {
                recieverDel(0x54);
                List<dynamic> ?v = _pro.rcvData('NNNNTNH');
                if ((v == null) || v.isEmpty) {
                    return;
                }
                _trkinfo = TrkInfo.byvars(v);

                developer.log('trkdata beg ${_trkinfo.jmpnum}, ${_trkinfo.dtBeg}');
                _datamax = (_trkinfo.fsize-32) ~/ 64;
                _trkdata.clear();
                _trkdatasz.value = 0;
                _trkcenter = null;
                _datacnt = 0;
                _infNotify();

                recieverAdd(0x55, () {
                    List<dynamic> ?v = _pro.rcvData(pkLogItem);
                    if ((v == null) || v.isEmpty) {
                        return;
                    }
                    Struct ti = fldUnpack(fldLogItem, v);
                    _trkdata.add(ti);
                    _trkdatasz.value = _trkdata.length;
                    _datacnt = _trkdata.length;
                    if ((_trkcenter == null) && (((ti['flags'] ?? 0) & 0x0001) > 0)) {
                        _trkcenter = ti;
                        if (onCenter != null) onCenter(ti);
                    }
                    _infNotify();
                });
                recieverAdd(0x56, () {
                    recieverDel(0x55);
                    recieverDel(0x56);
                    developer.log('trkdata end $_datacnt / $_datamax');
                    _pro.rcvNext();
                    _rcvelm.remove(NetRecvElem.trackdata);
                    _datamax = 0;
                    _datacnt = 0;
                    _infNotify();
                    if (onLoad != null) onLoad();
                });
            });
        if (!ok) return false;
        if (!send(0x54, 'NNNTC', [trk.id, trk.jmpnum, trk.jmpkey, trk.tmbeg, trk.fnum])) {
            recieverDel(0x54);
            return false;
        }
        _rcvelm.add(NetRecvElem.trackdata);
        _infNotify();

        return true;
    }
}
