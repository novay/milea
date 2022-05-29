//+------------------------------------------------------------------+
//|                                                     Response.mqh |
//|                                Copyright 2020, Noviyanto Rahmadi |
//|                                          https://milea.btekno.id |
//+------------------------------------------------------------------+
#property copyright     "Copyright © 2020 Noviyanto Rahmadi"
#property link          "https://btekno.id"
#property description   "Response class for Requests.mqh"
#property library

class Response {
public:
    string text;
    string status_code;
    string error;
    string url;
    string parameters;

    Response() {};
    ~Response() {};

    Response::Response(const Response &r) {
        text = r.text;
        status_code = r.status_code;
        error = r.error;
        url = r.url;
        parameters = r.parameters;
    }
};