bool        nDrawLines = true, nNextLine = false, nSignal = false, nImpact = false;
color       nLineColor = clrRed;
int         nLineStyle = 2, nUpdate = 86400, nMinBefore = 0, nMinAfter = 0, nNomNews = 0, nNow = 0;
string      nNewsArr[4][1000], nSymbol;
datetime    nLastUpd;

void NewsOnInit() 
{
    if(StringLen(nPairs) > 1) nSymbol = nPairs;
    else nSymbol = Symbol();

    nImpact = nAvoidNews;
    nMinBefore = nMinsBeforeNews;
    nMinAfter = nMinsAfterNews;
}

void NewsOnTick() 
{
    double CheckNews = 0;
    if(nMinsAfterNews > 0) {
        if(TimeCurrent()-nLastUpd >= nUpdate) {
            Comment("News Loading...");
            nNewsString = "News Loading...";
            Print("News Loading...");
            NewsUpdate();
            nLastUpd = TimeCurrent();
            Comment("");
            nNewsString = "~";
        }
        
        WindowRedraw();
        if(nDrawLines) { 
            for(int i=0; i<nNomNews; i++) {
                string Name = StringSubstr(TimeToStr(NewsTimeFunc(i), TIME_MINUTES)+"_"+nNewsArr[1][i]+"_"+nNewsArr[3][i], 0, 63);
                if(nNewsArr[3][i] != "") if(ObjectFind(Name) == 0) continue;
                if(StringFind(nSymbol, nNewsArr[1][i]) < 0) continue;
                if(NewsTimeFunc(i) < TimeCurrent() && nNextLine) continue;

                color clrf = clrNONE;
                if(nImpact && StringFind(nNewsArr[2][i], "High") >= 0) clrf = nLineColor;
                if(clrf == clrNONE) continue;
                if(nNewsArr[3][i] != "") {
                    ObjectCreate(Name, 0, OBJ_VLINE, NewsTimeFunc(i), 0);
                    ObjectSet(Name, OBJPROP_COLOR, clrf);
                    ObjectSet(Name, OBJPROP_STYLE, nLineStyle);
                    ObjectSetInteger(0, Name, OBJPROP_BACK, true);
                }
            }
        }
        
        int i;
        CheckNews = 0;
        for(i=0; i<nNomNews; i++) {
            int power = 0;
            if(nImpact && StringFind(nNewsArr[2][i], "High") >= 0) power = 1;
            if(power == 0) continue;
            if(TimeCurrent()+nMinBefore*60 > NewsTimeFunc(i) && 
                TimeCurrent()-nMinAfter*60 < NewsTimeFunc(i) && 
                StringFind(nSymbol, nNewsArr[1][i]) >= 0) {
                CheckNews=1;
                break;
            } else { 
                CheckNews=0;
            }
        }
        
        if(CheckNews == 1 && i != nNow && nSignal) { 
            Alert("In ", (int)(NewsTimeFunc(i)-TimeCurrent())/60, " minutes released news ", nNewsArr[1][i], "_", nNewsArr[3][i]);
            nNow = i;
        }
    }

    if(CheckNews > 0) {
        Comment("News time");
        nNewsString = "News time";
        run = false;
        CloseAllOrders();

        if(!IsTesting()) Alert("News! High Impact!");
        return;
    } else {
        Comment("No news");
        nNewsString = "No news";
    }
}

string ReadCBOE()
{
    string cookie = NULL, headers;
    char post[], result[]; 
    string TXT = "";
    int res;

    string news_url = "https://ec.forexprostools.com/?columns=exc_currency,exc_importance&importance=3&calType=week&timeZone="+(string)nTimeZone+"&lang=1";
    ResetLastError();
    
    int timeout = 5000;
    res = WebRequest("GET", news_url, cookie, NULL, timeout, post, 0, result, headers);
    
    if(res == -1) {
        Print("WebRequest error, err.code  =", GetLastError());
        MessageBox("You must add the address ' "+news_url+"' in the list of allowed URL tab 'Advisors' ", " Error ", MB_ICONINFORMATION);
    } else {
        PrintFormat("File successfully downloaded, the file size in bytes  =%d.",ArraySize(result)); 

        int filehandle = FileOpen("news-log.html", FILE_WRITE|FILE_BIN);
        if(filehandle != INVALID_HANDLE) {
            FileWriteArray(filehandle, result, 0, ArraySize(result));
            FileClose(filehandle);

            int filehandle2 = FileOpen("news-log.html", FILE_READ|FILE_BIN);
            TXT = FileReadString(filehandle2, ArraySize(result));
            FileClose(filehandle2);
        } else {
            Print("Error in FileOpen. Error code =", GetLastError());
        }
    }
    
    return(TXT);
}

datetime NewsTimeFunc(int nomf)
{
    string s = nNewsArr[0][nomf];
    string time = StringConcatenate(StringSubstr(s, 0, 4), ".", StringSubstr(s, 5, 2), ".", StringSubstr(s, 8, 2), " ", StringSubstr(s, 11, 2), ":", StringSubstr(s, 14, 4));

    return((datetime)(StringToTime(time) + nTimeZone*3600));
}

void NewsUpdate()
{
    string response = ReadCBOE();
    int sh = StringFind(response, "pageStartAt>")+12;
    int sh2 = StringFind(response, "</tbody>");
    response = StringSubstr(response, sh, sh2-sh);

    sh = 0;
    while(!IsStopped()) {
        sh = StringFind(response, "event_timestamp", sh)+17;
        sh2 = StringFind(response, "onclick", sh)-2;
        if(sh<17 || sh2<0) break;
        nNewsArr[0][nNomNews] = StringSubstr(response, sh, sh2-sh);

        sh = StringFind(response, "flagCur", sh)+10;
        sh2 = sh+3;
        if(sh<10 || sh2<3) break;
        nNewsArr[1][nNomNews] = StringSubstr(response, sh, sh2-sh);
        if(StringFind(nSymbol, nNewsArr[1][nNomNews])<0) continue;

        sh = StringFind(response, "title", sh)+7;
        sh2 = StringFind(response, "Volatility", sh)-1;
        if(sh<7 || sh2<0) break;
        nNewsArr[2][nNomNews] = StringSubstr(response, sh, sh2-sh);
        if(StringFind(nNewsArr[2][nNomNews], "High") >= 0 && !nImpact) continue;

        sh = StringFind(response, "left event", sh)+12;
        int sh1 = StringFind(response, "Speaks", sh);
        sh2 = StringFind(response, "<", sh);
        if(sh<12 || sh2<0) break;
        if(sh1<0 || sh1>sh2) nNewsArr[3][nNomNews] = StringSubstr(response, sh, sh2-sh);
        else nNewsArr[3][nNomNews] = StringSubstr(response, sh, sh1-sh);

        nNomNews++;
        if(nNomNews == 300) break;
    }
}