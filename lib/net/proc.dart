import 'dart:typed_data';
import 'dart:io';
import 'dart:developer' as developer;

enum NetState {
    offline,
    disconnected,
    connecting,
    connected
}

final net = NetProc();

class NetProc {
    Socket ?_sock;
    NetState _state = NetState.offline;

    bool get isActive => (_state != NetState.offline) && (_state != NetState.disconnected);

    void stop() {
        _sock?.close();
    }

    Future<bool> start(InternetAddress ip, int port) async {
        _sock?.close();
        await Future.doWhile(() => isActive);

        developer.log('net connecting to: $ip:$port');
        _state = NetState.connecting;

        try {
            _sock = await Socket.connect(ip, port);
        }
        catch (err) {
            _sock = null;
            _state = NetState.offline;
            return false;
        }

        _sock?.listen(
            recv,
            onDone: () {
                _state = NetState.disconnected;
                _sock!.close();
                _sock = null;
            }
        );
        developer.log('net connected');

        _state = NetState.connected;
        return true;
    }

    void recv(data) {
        developer.log('packet: ' + data.toString());
    }
}
