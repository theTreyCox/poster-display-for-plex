sub init()
    m.top.functionName = "fetchSession"
end sub

sub fetchSession()
    result = {
        valid: false,
        isPlaying: false,
        title: "",
        showName: "",
        posterUri: "",
        backgroundUri: "",
        episodePosterUri: "",
        mediaType: "",
        duration: 0,
        viewOffset: 0,
        state: ""
    }

    server = m.top.plexServer
    token = m.top.plexToken
    if server = "" or token = "" then
        m.top.result = result
        return
    end if

    transfer = createObject("roUrlTransfer")
    if transfer = invalid then
        m.top.result = result
        return
    end if

    transfer.SetUrl(server + "/status/sessions")
    transfer.AddHeader("X-Plex-Token", token)
    transfer.AddHeader("Accept", "application/xml")

    xmlString = transfer.GetToString()
    if xmlString = invalid or xmlString = "" then
        m.top.result = result
        return
    end if

    xml = createObject("roXMLElement")
    if not xml.Parse(xmlString) then
        m.top.result = result
        return
    end if

    children = xml.GetChildElements()
    if children = invalid or children.Count() = 0 then
        m.top.result = result
        return
    end if

    media = children[0]
    attrs = media.GetAttributes()

    title = stringOrEmpty(attrs["title"])
    showName = stringOrEmpty(attrs["grandparentTitle"])
    thumb = stringOrEmpty(attrs["thumb"])
    seriesThumb = stringOrEmpty(attrs["grandparentThumb"])
    if thumb = "" then thumb = stringOrEmpty(attrs["art"])
    mediaType = stringOrEmpty(attrs["type"])
    duration = intOrZero(attrs["duration"])
    viewOffset = intOrZero(attrs["viewOffset"])

    state = ""
    players = media.GetNamedElements("Player")
    if players <> invalid and players.Count() > 0 then
        playerAttrs = players[0].GetAttributes()
        state = stringOrEmpty(playerAttrs["state"])
    end if

    ' Prefer the series poster (portrait) for shows; fall back to thumb for movies
    mainThumb = seriesThumb
    if mainThumb = "" then mainThumb = thumb

    posterUri = buildPlexUri(server, mainThumb, token, transfer)
    backgroundUri = buildBlurredPlexUri(server, mainThumb, token, transfer)
    episodePosterUri = ""
    ' Only expose a separate episode poster when this is a TV episode (show name present)
    ' AND it's a distinct image from the main poster
    if showName <> "" and thumb <> "" and thumb <> seriesThumb then
        episodePosterUri = buildPlexUri(server, thumb, token, transfer)
    end if

    result.valid = true
    result.isPlaying = true
    result.title = title
    result.showName = showName
    result.posterUri = posterUri
    result.backgroundUri = backgroundUri
    result.episodePosterUri = episodePosterUri
    result.mediaType = mediaType
    result.duration = duration
    result.viewOffset = viewOffset
    result.state = state

    m.top.result = result
end sub

function intOrZero(value as Dynamic) as Integer
    if value = invalid then return 0
    return value.ToInt()
end function

function buildPlexUri(server as String, path as String, token as String, transfer as Object) as String
    if path = "" then return ""
    if path.Left(1) = "/" then
        return server + path + "?X-Plex-Token=" + transfer.Escape(token)
    end if
    return path
end function

' Build a Plex transcoder URL that returns a small, server-side-blurred copy of the image.
' Used as a soft ambient backdrop behind the main poster in landscape modes.
function buildBlurredPlexUri(server as String, path as String, token as String, transfer as Object) as String
    if path = "" then return ""
    if path.Left(1) <> "/" then return ""
    encodedPath = transfer.Escape(path)
    encodedToken = transfer.Escape(token)
    return server + "/photo/:/transcode?width=480&height=270&minSize=1&upscale=1&blur=50&url=" + encodedPath + "&X-Plex-Token=" + encodedToken
end function

function stringOrEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function
