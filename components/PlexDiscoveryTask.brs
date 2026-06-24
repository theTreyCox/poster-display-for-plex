sub init()
    m.top.functionName = "discover"
end sub

' Plex GDM (G'Day Mate) discovery — broadcast a UDP hello on the Plex multicast
' group 239.0.0.250:32414 and listen 3s for replies from servers on the LAN.
sub discover()
    discovered = []

    udp = createObject("roDatagramSocket")
    if udp = invalid then
        m.top.servers = discovered
        return
    end if

    msgPort = createObject("roMessagePort")
    udp.setMessagePort(msgPort)
    udp.notifyReadable(true)

    target = createObject("roSocketAddress")
    target.setHostName("239.0.0.250")
    target.setPort(32414)
    udp.setSendToAddress(target)

    packet = "M-SEARCH * HTTP/1.1" + chr(13) + chr(10) + chr(13) + chr(10)
    udp.sendStr(packet)

    seen = {}
    timer = createObject("roTimespan")
    timer.mark()
    while timer.totalMilliseconds() < 3000
        ev = wait(200, msgPort)
        if type(ev) = "roSocketEvent" then
            if udp.isReadable() then
                response = udp.receiveStr(2048)
                fromAddr = udp.getReceivedFromAddress()
                if response <> "" and fromAddr <> invalid then
                    ip = fromAddr.getHostName()
                    info = parseGDMResponse(response, ip)
                    if info <> invalid then
                        if seen[info.url] <> true then
                            seen[info.url] = true
                            discovered.push(info)
                        end if
                    end if
                end if
            end if
        end if
    end while

    m.top.servers = discovered
end sub

function parseGDMResponse(response as String, sourceIP as String) as Object
    if response = invalid or response = "" then return invalid
    if Instr(1, response, "plex/media-server") = 0 then return invalid

    name = ""
    port = "32400"

    lines = response.Split(chr(10))
    for each line in lines
        cleanLine = line.Trim()
        lower = LCase(cleanLine)
        if lower.StartsWith("name:") then
            name = cleanLine.Mid(5).Trim()
        else if lower.StartsWith("port:") then
            port = cleanLine.Mid(5).Trim()
        end if
    end for

    if sourceIP = "" then return invalid
    if name = "" then name = sourceIP

    return {
        name: name,
        url: "http://" + sourceIP + ":" + port
    }
end function
