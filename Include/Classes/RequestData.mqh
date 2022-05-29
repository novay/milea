//+------------------------------------------------------------------+
//|                                                  RequestData.mqh |
//|                                Copyright 2020, Noviyanto Rahmadi |
//|                                          https://milea.btekno.id |
//+------------------------------------------------------------------+
#property copyright     "Copyright © 2020 Noviyanto Rahmadi"
#property link          "https://btekno.id"
#property description   "RequestData class for Requests.mqh"
#property library

class RequestData {
private:
    struct RequestDataPair {
        string name;
        string value;
    };

    RequestDataPair pairs[];

public:
    void add(string name, string value) {
        int pairs_len = ArraySize(pairs);
        bool updated = false;

        for (int i=0; i < pairs_len; i++) {
            if (pairs[i].name == name) {
                pairs[i].value = value;
                updated = true;
                break;
            }
        }
        if (!updated) {
            ArrayResize(pairs, ++pairs_len);
            pairs[pairs_len-1].name = name;
            pairs[pairs_len-1].value = value;
        }
    }

    void remove() {
        ArrayFree(pairs);
    }

    void remove(string name) {
        int pairs_len = ArraySize(pairs);
        bool need_remove = false;

        for (int i=0; i < pairs_len; i++) {
            if (pairs[i].name == name) need_remove = true;

            if (need_remove) {
                if (i+1 == pairs_len) ArrayResize(pairs, --pairs_len);
                else pairs[i] = pairs[i+1];
            }
        }
    }

    string to_str() {
        string res = "";
        int pairs_len = ArraySize(pairs);

        for (int i=0; i < pairs_len; i++) {
            res += pairs[i].name + "=" + pairs[i].value;
            if (i != pairs_len - 1) res += "&";
        }

        return res;
    }

    static string to_str(string& _data[][]) {
        string res = "";
        int _data_len = ArrayRange(_data, 0);

        for (int i=0; i < _data_len; i++)
            if (_data[i][0] != NULL) {
                res += _data[i][0] + "=" + _data[i][1];
                if (i != _data_len - 1) res += "&";
            }

        return res;
    }
};