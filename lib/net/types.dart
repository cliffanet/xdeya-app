import 'dart:typed_data';
import 'binproto.dart';

const String pkLogItem = 'NnaaiiNNNiiNNC nNNNNNN';
const List<String> fldLogItem = [
    'tmoffset',     // время от начала измерений        (ms)
    'flags',        // флаги: валидность
    'state',        // статус высотомера (земля, подъём, падение, под куполом)
    'direct',       // направление движения по высоте
    'alt',          // высота по барометру              (m)
    'altspeed',     // скорость падения по барометру    (cm/s)
    'lon',          // Longitude                        (deg * 10^7)
    'lat',          // Latitude                         (deg * 10^7)
    'hspeed',       // Ground speed                     (cm/s)
    'heading',      // направление движения             (deg)
    'gpsalt',       // высота по NAV (над ур моря)      (m)
    'vspeed',       // 3D speed                         (cm/s)
    'gpsdage',      // gps data age  // тут вместо millis уже используется только 1 байт для хранения, можно пересмотреть формат
    'sat',          // количество найденных спутников
    
    'batval',       // raw-показания напряжения на батарее
    // поля для отладки
    'hAcc',         // Horizontal accuracy estimate (mm)
    'vAcc',         // Vertical accuracy estimate   (mm)
    'sAcc',         // Speed accuracy estimate      (cm/s)
    'cAcc',         // Heading accuracy estimate    (deg * 10^5)
    'millis',       // для отладки времени tmoffset
    'msave',
];

class LogBook {
    static const pk = 'NNT$pkLogItem$pkLogItem$pkLogItem$pkLogItem';

    final int num;
    final int key;
    final DateTime tm;
    final Struct toff;
    final Struct beg;
    final Struct cnp;
    final Struct end;

    LogBook({
        required this.num,
        required this.key,
        required this.tm,
        required this.toff,
        required this.beg,
        required this.cnp,
        required this.end
    });

    LogBook.byvars(List<dynamic> vars) :
        this(
            num: vars[0] is int ? vars[0] : 0,
            key: vars[1] is int ? vars[1] : 0,
            tm:  vars[2] is DateTime ? vars[2] : DateTime(0),
            toff: fldUnpack(fldLogItem, vars, 3),
            beg:  fldUnpack(fldLogItem, vars, 3 + fldLogItem.length),
            cnp:  fldUnpack(fldLogItem, vars, 3 + fldLogItem.length * 2),
            end:  fldUnpack(fldLogItem, vars, 3 + fldLogItem.length * 2)
        );
}

