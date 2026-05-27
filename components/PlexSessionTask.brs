sub init()
    m.top.functionName = "fetchSession"
end sub

sub fetchSession()
    result = {
        valid: false,
        isPlaying: false,
        title: "",
        showName: "",
        year: "",
        contentRating: "",
        posterUri: "",
        backgroundUri: "",
        episodePosterUri: "",
        mediaType: "",
        duration: 0,
        viewOffset: 0,
        state: "",
        ' Extended metadata for the Left-button metadata overlay
        tagline: "",
        summary: "",
        studio: "",
        releaseDate: "",
        directors: "",
        writers: "",
        cast: "",
        genres: "",
        audienceRating: "",
        imdbId: ""
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
    year = stringOrEmpty(attrs["year"])
    if year = "" then year = stringOrEmpty(attrs["grandparentYear"])
    contentRating = stringOrEmpty(attrs["contentRating"])
    ' TV episodes often carry the rating on the show, not the episode itself.
    if contentRating = "" then contentRating = stringOrEmpty(attrs["grandparentContentRating"])
    if contentRating = "" then contentRating = stringOrEmpty(attrs["parentContentRating"])
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

    ' Extended metadata fields
    tagline = stringOrEmpty(attrs["tagline"])
    summary = stringOrEmpty(attrs["summary"])
    studio = stringOrEmpty(attrs["studio"])
    releaseDate = stringOrEmpty(attrs["originallyAvailableAt"])
    directors = collectTagAttribute(media, "Director")
    writers = collectTagAttribute(media, "Writer")
    cast = collectTagAttributeLimited(media, "Role", 5)
    genres = collectTagAttribute(media, "Genre")
    audienceRating = stringOrEmpty(attrs["audienceRating"])
    imdbId = extractImdbId(media)

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
    result.year = year
    result.contentRating = contentRating
    result.posterUri = posterUri
    result.backgroundUri = backgroundUri
    result.episodePosterUri = episodePosterUri
    result.mediaType = mediaType
    result.duration = duration
    result.viewOffset = viewOffset
    result.state = state
    result.tagline = tagline
    result.summary = summary
    result.studio = studio
    result.releaseDate = releaseDate
    result.directors = directors
    result.writers = writers
    result.cast = cast
    result.genres = genres
    result.audienceRating = audienceRating
    result.imdbId = imdbId
    print "[plex.session] " + title + " — imdbId='" + imdbId + "'"

    m.top.result = result
end sub

' Pull out the IMDB id (with tt prefix) from whichever Plex agent format the
' server is using. New movie/TV scanners surface it via nested <Guid id="imdb://tt...">;
' the legacy IMDB agent puts it on the Video's own guid attribute as
' "com.plexapp.agents.imdb://tt0073195?lang=en".
function extractImdbId(media as Object) as String
    ' Newer multi-source format
    guids = media.GetNamedElements("Guid")
    if guids <> invalid and guids.Count() > 0 then
        for each g in guids
            a = g.GetAttributes()
            if a <> invalid then
                id = stringOrEmpty(a["id"])
                if Instr(1, id, "imdb://") = 1 then return id.Mid(7)
            end if
        end for
    end if

    ' Legacy agent format on Video's own guid attribute
    attrs = media.GetAttributes()
    if attrs <> invalid then
        guidAttr = stringOrEmpty(attrs["guid"])
        if guidAttr <> "" then
            idx = Instr(1, guidAttr, "imdb://")
            if idx > 0 then
                after = guidAttr.Mid(idx + 6)
                qIdx = Instr(1, after, "?")
                if qIdx > 0 then after = after.Mid(0, qIdx - 1)
                if Instr(1, after, "tt") = 1 then return after
            end if
        end if
    end if

    return ""
end function

' Plex returns tags like <Director tag="Steven Spielberg"/> nested inside the
' media element. Collect each child of the given tag name and concatenate the
' `tag` attributes with " · " as a separator.
function collectTagAttribute(media as Object, tagName as String) as String
    return collectTagAttributeLimited(media, tagName, 0)
end function

' Same as collectTagAttribute, but caps the output to the first N matches.
' Pass limit=0 for no cap (use everything). Useful for cast lists where Plex
' returns the full cast and we only want the top few.
function collectTagAttributeLimited(media as Object, tagName as String, limit as Integer) as String
    elements = media.GetNamedElements(tagName)
    if elements = invalid or elements.Count() = 0 then return ""
    parts = []
    count = 0
    for each el in elements
        if limit > 0 and count >= limit then exit for
        a = el.GetAttributes()
        if a <> invalid then
            t = stringOrEmpty(a["tag"])
            if t <> "" then
                parts.push(t)
                count = count + 1
            end if
        end if
    end for
    if parts.Count() = 0 then return ""
    out = parts[0]
    for i = 1 to parts.Count() - 1
        out = out + " · " + parts[i]
    end for
    return out
end function

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
