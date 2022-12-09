
import 'dart:developer' as developer;

var app = CoreClass();

class CoreClass {
    int _progr_max = 0;
    int _progr_val = 0;
    void Function() _reloadTitleBar = () => {};

    int get progmax => _progr_max;
    set progmax(int max) {
        _progr_max = max;
        _reloadTitleBar();
    }
    int get progval => _progr_val;
    set progval(int val) {
        _progr_val = val;
        _reloadTitleBar();
        developer.log('log me: $_progr_val ($val)');
    }

    set reloadTitleBar(void Function() func) => _reloadTitleBar = func;
}
