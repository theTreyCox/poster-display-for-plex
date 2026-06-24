sub init()
    m.top.functionName = "run"
end sub

sub run()
    mode = m.top.mode
    if mode = "requestPin" then
        m.top.result = requestPin(m.top.clientId)
    else if mode = "pollPin" then
        m.top.result = pollPin(m.top.clientId, m.top.pinId, m.top.pinCode)
    else if mode = "listServers" then
        m.top.result = listServers(m.top.clientId, m.top.plexToken)
    else
        m.top.result = { mode: mode, ok: false, error: "unknown mode" }
    end if
end sub

' POST https://plex.tv/api/v2/pins  (no strong=true — that returns a 25-char
' device-strong code that the user can't type into plex.tv/link. The plain
' endpoint returns the short 4-char human-friendly code.)
' roUrlTransfer.PostFromString returns only the HTTP status code, not the
' body. We need the XML body to extract the PIN, so we use AsyncPostFromString
' against an roMessagePort and wait for the roUrlEvent.
function requestPin(clientId as String) as Object
    result = { mode: "requestPin", ok: false, pinId: "", pinCode: "", expiresAt: "", error: "" }
    transfer = createPlexTransfer(clientId)
    if transfer = invalid then
        result.error = "transfer create failed"
        return result
    end if
    transfer.SetUrl("https://plex.tv/api/v2/pins")
    transfer.AddHeader("Accept", "application/xml")
    transfer.AddHeader("Content-Length", "0")

    port = createObject("roMessagePort")
    transfer.SetMessagePort(port)
    if not transfer.AsyncPostFromString("") then
        result.error = "async post failed to start"
        return result
    end if

    body = ""
    httpCode = -1
    msg = wait(20000, port)
    if type(msg) = "roUrlEvent" then
        body = msg.GetString()
        httpCode = msg.GetResponseCode()
    end if
    if httpCode < 200 or httpCode > 299 then
        result.error = "http " + httpCode.ToStr()
        return result
    end if
    if body = invalid or body = "" then
        result.error = "empty response"
        return result
    end if
    pin = parsePin(body)
    if pin = invalid then
        result.error = "parse failed"
        return result
    end if
    result.ok = true
    result.pinId = pin.id
    result.pinCode = pin.code
    result.expiresAt = pin.expiresAt
    return result
end function

' GET https://plex.tv/api/v2/pins/{id}?code={code}
' Uses async so we can read the response code from the roUrlEvent (404 means
' the PIN expired). roUrlTransfer itself has no GetResponseCode method on a
' sync GET — the code lives on roUrlEvent.
function pollPin(clientId as String, pinId as String, pinCode as String) as Object
    result = { mode: "pollPin", ok: false, authToken: "", expired: false, error: "" }
    if pinId = "" then
        result.error = "missing pinId"
        return result
    end if
    transfer = createPlexTransfer(clientId)
    if transfer = invalid then
        result.error = "transfer create failed"
        return result
    end if
    url = "https://plex.tv/api/v2/pins/" + pinId
    if pinCode <> "" then url = url + "?code=" + transfer.Escape(pinCode)
    transfer.SetUrl(url)
    transfer.AddHeader("Accept", "application/xml")

    port = createObject("roMessagePort")
    transfer.SetMessagePort(port)
    if not transfer.AsyncGetToString() then
        result.error = "async get failed to start"
        return result
    end if

    body = ""
    httpCode = -1
    msg = wait(15000, port)
    if type(msg) = "roUrlEvent" then
        body = msg.GetString()
        httpCode = msg.GetResponseCode()
    end if
    if httpCode = 404 then
        result.expired = true
        return result
    end if
    if body = invalid or body = "" then
        result.error = "empty response"
        return result
    end if
    pin = parsePin(body)
    if pin = invalid then
        result.error = "parse failed"
        return result
    end if
    result.ok = true
    result.authToken = pin.authToken
    return result
end function

' GET https://plex.tv/api/v2/resources?includeHttps=1
function listServers(clientId as String, plexToken as String) as Object
    result = { mode: "listServers", ok: false, servers: [], error: "" }
    if plexToken = "" then
        result.error = "missing token"
        return result
    end if
    transfer = createPlexTransfer(clientId)
    if transfer = invalid then
        result.error = "transfer create failed"
        return result
    end if
    url = "https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1&X-Plex-Token=" + transfer.Escape(plexToken)
    transfer.SetUrl(url)
    transfer.AddHeader("Accept", "application/xml")
    transfer.AddHeader("X-Plex-Token", plexToken)
    print "[plex.listServers] GET " + url
    body = transfer.GetToString()
    if body = invalid then
        result.error = "transfer invalid"
        print "[plex.listServers] GetToString returned invalid (TLS/DNS failure?)"
        return result
    end if
    if body = "" then
        result.error = "empty response"
        print "[plex.listServers] empty body"
        return result
    end if
    print "[plex.listServers] body bytes=" + body.Len().ToStr()
    print "[plex.listServers] body start=" + Left(body, 300)
    xml = createObject("roXMLElement")
    if not xml.Parse(body) then
        result.error = "parse failed"
        print "[plex.listServers] xml parse failed"
        return result
    end if
    devices = xml.GetChildElements()
    servers = []
    if devices = invalid then
        print "[plex.listServers] no child elements at all"
    else
        print "[plex.listServers] child element count=" + devices.Count().ToStr()
        for each dev in devices
            attrs = dev.GetAttributes()
            provides = stringOrEmpty(attrs["provides"])
            name = stringOrEmpty(attrs["name"])
            accessToken = stringOrEmpty(attrs["accessToken"])
            owned = stringOrEmpty(attrs["owned"])
            print "[plex.listServers] device name='" + name + "' provides='" + provides + "' owned=" + owned + " tokenLen=" + Len(accessToken).ToStr()
            if Instr(1, provides, "server") > 0 then
                ' Plex.tv's v2 XML response uses lowercase element names
                ' (<resource>, <connection>) inside a <resources> root, not the
                ' Capitalized names the legacy /api/resources used. Look for
                ' either, and also handle the case where connections are wrapped
                ' in a <connections> parent.
                conns = collectConnectionElements(dev)
                bestUrl = ""
                bestLocal = false
                print "[plex.listServers]   connections found=" + conns.Count().ToStr()
                for each conn in conns
                    connAttrs = conn.GetAttributes()
                    uri = stringOrEmpty(connAttrs["uri"])
                    local = (stringOrEmpty(connAttrs["local"]) = "1")
                    relay = (stringOrEmpty(connAttrs["relay"]) = "1")
                    print "[plex.listServers]     uri=" + uri + " local=" + local.ToStr() + " relay=" + relay.ToStr()
                    if uri <> "" then
                        if bestUrl = "" then
                            bestUrl = uri
                            bestLocal = local
                        else if local and not bestLocal then
                            bestUrl = uri
                            bestLocal = local
                        end if
                    end if
                end for
                if accessToken <> "" and bestUrl <> "" then
                    servers.push({ name: name, url: bestUrl, accessToken: accessToken, owned: (owned = "1") })
                    print "[plex.listServers]   ADDED url=" + bestUrl
                else
                    print "[plex.listServers]   SKIPPED (no token or no url)"
                end if
            end if
        end for
    end if
    print "[plex.listServers] final server count=" + servers.Count().ToStr()
    result.ok = true
    result.servers = servers
    return result
end function

' Collect all Connection elements from a Plex resource/Device, regardless of
' element casing or whether they're wrapped in a <connections> parent. Also
' dumps each direct child's name for diagnostic visibility while we figure out
' which response shape Plex.tv is returning.
function collectConnectionElements(resource as Object) as Object
    out = []
    children = resource.GetChildElements()
    if children = invalid then return out
    for each child in children
        nm = child.GetName()
        print "[plex.listServers]     child=<" + nm + ">"
        lname = LCase(nm)
        if lname = "connection" then
            out.push(child)
        else if lname = "connections" then
            inner = child.GetChildElements()
            if inner <> invalid then
                for each c in inner
                    if LCase(c.GetName()) = "connection" then out.push(c)
                end for
            end if
        end if
    end for
    return out
end function

function createPlexTransfer(clientId as String) as Object
    t = createObject("roUrlTransfer")
    if t = invalid then return invalid
    t.SetCertificatesFile("common:/certs/ca-bundle.crt")
    t.InitClientCertificates()
    t.EnableEncodings(true)
    t.AddHeader("X-Plex-Client-Identifier", clientId)
    t.AddHeader("X-Plex-Product", "Poster Display for Plex")
    t.AddHeader("X-Plex-Device", "Roku")
    t.AddHeader("X-Plex-Device-Name", "Roku")
    t.AddHeader("X-Plex-Platform", "Roku")
    t.AddHeader("X-Plex-Version", "1.0.1")
    return t
end function

function parsePin(body as String) as Object
    xml = createObject("roXMLElement")
    if not xml.Parse(body) then return invalid
    attrs = xml.GetAttributes()
    if attrs = invalid then return invalid
    return {
        id: stringOrEmpty(attrs["id"]),
        code: stringOrEmpty(attrs["code"]),
        expiresAt: stringOrEmpty(attrs["expiresAt"]),
        authToken: stringOrEmpty(attrs["authToken"])
    }
end function

function stringOrEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function
