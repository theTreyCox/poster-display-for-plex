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

' POST https://plex.tv/api/v2/pins?strong=true
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
    transfer.SetUrl("https://plex.tv/api/v2/pins?strong=true")
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
    body = transfer.GetToString()
    code = transfer.GetResponseCode()
    if code = 404 then
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
    transfer.SetUrl("https://plex.tv/api/v2/resources?includeHttps=1")
    transfer.AddHeader("Accept", "application/xml")
    transfer.AddHeader("X-Plex-Token", plexToken)
    body = transfer.GetToString()
    if body = invalid or body = "" then
        result.error = "empty response"
        return result
    end if
    xml = createObject("roXMLElement")
    if not xml.Parse(body) then
        result.error = "parse failed"
        return result
    end if
    devices = xml.GetChildElements()
    servers = []
    if devices <> invalid then
        for each dev in devices
            attrs = dev.GetAttributes()
            provides = stringOrEmpty(attrs["provides"])
            if Instr(1, provides, "server") > 0 then
                name = stringOrEmpty(attrs["name"])
                accessToken = stringOrEmpty(attrs["accessToken"])
                owned = stringOrEmpty(attrs["owned"])
                ' Pick the best connection: prefer local + http, fall back to remote
                conns = dev.GetNamedElements("Connection")
                bestUrl = ""
                bestLocal = false
                if conns <> invalid then
                    for each conn in conns
                        connAttrs = conn.GetAttributes()
                        uri = stringOrEmpty(connAttrs["uri"])
                        local = (stringOrEmpty(connAttrs["local"]) = "1")
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
                end if
                if accessToken <> "" and bestUrl <> "" then
                    servers.push({ name: name, url: bestUrl, accessToken: accessToken, owned: (owned = "1") })
                end if
            end if
        end for
    end if
    result.ok = true
    result.servers = servers
    return result
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
