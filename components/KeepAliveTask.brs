sub init()
    m.top.functionName = "keepAliveLoop"
end sub

sub keepAliveLoop()
    appManager = createObject("roAppManager")
    if appManager = invalid then
        print "[KeepAlive] roAppManager unavailable in task thread"
        return
    end if
    while true
        appManager.UpdateLastKeyPressTime()
        print "[KeepAlive] tick at "; createObject("roDateTime").AsSeconds()
        sleep(30000)
    end while
end sub
