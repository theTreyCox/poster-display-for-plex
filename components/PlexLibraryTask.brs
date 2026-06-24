sub init()
    m.top.functionName = "fetchLibrary"
end sub

sub fetchLibrary()
    server = m.top.plexServer
    token = m.top.plexToken
    if server = "" or token = "" then
        m.top.items = []
        return
    end if

    transfer = createObject("roUrlTransfer")
    if transfer = invalid then
        m.top.items = []
        return
    end if

    transfer.SetUrl(server + "/library/sections")
    transfer.AddHeader("X-Plex-Token", token)
    transfer.AddHeader("Accept", "application/xml")
    sectionsBody = transfer.GetToString()
    if sectionsBody = invalid or sectionsBody = "" then
        m.top.items = []
        return
    end if

    sectionsXml = createObject("roXMLElement")
    if not sectionsXml.Parse(sectionsBody) then
        m.top.items = []
        return
    end if

    items = []
    sectionElements = sectionsXml.GetChildElements()
    if sectionElements = invalid then
        m.top.items = []
        return
    end if

    blockedRatings = parseBlockedRatings(m.top.blockedRatings)

    for each section in sectionElements
        sectionAttrs = section.GetAttributes()
        sectionType = stringOrEmpty(sectionAttrs["type"])
        if sectionType = "movie" or sectionType = "show" then
            sectionKey = stringOrEmpty(sectionAttrs["key"])
            if sectionKey <> "" then
                ' Build the set of ratingKeys in this library that the user has labeled
                ' with the carousel-ignore tag, so we can skip them below.
                excludedKeys = fetchExcludedKeys(server, sectionKey, token)

                libraryTransfer = createObject("roUrlTransfer")
                if libraryTransfer <> invalid then
                    libraryTransfer.SetUrl(server + "/library/sections/" + sectionKey + "/all?X-Plex-Container-Size=500")
                    libraryTransfer.AddHeader("X-Plex-Token", token)
                    libraryTransfer.AddHeader("Accept", "application/xml")
                    libraryBody = libraryTransfer.GetToString()
                    if libraryBody <> invalid and libraryBody <> "" then
                        libraryXml = createObject("roXMLElement")
                        if libraryXml.Parse(libraryBody) then
                            itemElements = libraryXml.GetChildElements()
                            if itemElements <> invalid then
                                for each itemEl in itemElements
                                    itemAttrs = itemEl.GetAttributes()
                                    ratingKey = stringOrEmpty(itemAttrs["ratingKey"])
                                    contentRating = normalizeRating(stringOrEmpty(itemAttrs["contentRating"]))
                                    skipByLabel = (ratingKey <> "" and excludedKeys[ratingKey] = true)
                                    skipByRating = (blockedRatings[contentRating] = true)
                                    if not skipByLabel and not skipByRating then
                                        title = stringOrEmpty(itemAttrs["title"])
                                        year = stringOrEmpty(itemAttrs["year"])
                                        rawRating = stringOrEmpty(itemAttrs["contentRating"])
                                        thumb = stringOrEmpty(itemAttrs["thumb"])
                                        if thumb <> "" then
                                            posterUri = buildPlexUri(server, thumb, token, libraryTransfer)
                                            backgroundUri = buildBlurredPlexUri(server, thumb, token, libraryTransfer)
                                            ' Landscape art for the modal backdrop. Falls back to the
                                            ' thumb when an item has no dedicated art.
                                            artPath = stringOrEmpty(itemAttrs["art"])
                                            artUri = buildPlexUri(server, artPath, token, libraryTransfer)
                                            tagline = stringOrEmpty(itemAttrs["tagline"])
                                            summary = stringOrEmpty(itemAttrs["summary"])
                                            studio = stringOrEmpty(itemAttrs["studio"])
                                            releaseDate = stringOrEmpty(itemAttrs["originallyAvailableAt"])
                                            duration = intOrZero(itemAttrs["duration"])
                                            directors = collectTagAttribute(itemEl, "Director")
                                            writers = collectTagAttribute(itemEl, "Writer")
                                            cast = collectTagAttributeLimited(itemEl, "Role", 5)
                                            genres = collectTagAttribute(itemEl, "Genre")
                                            audienceRating = stringOrEmpty(itemAttrs["audienceRating"])
                                            imdbId = extractImdbId(itemEl)
                                            if imdbId = "" then print "[plex.library] no imdbId for " + title
                                            items.push({
                                                title: title,
                                                year: year,
                                                contentRating: rawRating,
                                                posterUri: posterUri,
                                                backgroundUri: backgroundUri,
                                                artUri: artUri,
                                                tagline: tagline,
                                                summary: summary,
                                                studio: studio,
                                                releaseDate: releaseDate,
                                                duration: duration,
                                                directors: directors,
                                                writers: writers,
                                                cast: cast,
                                                genres: genres,
                                                audienceRating: audienceRating,
                                                imdbId: imdbId
                                            })
                                        end if
                                    end if
                                end for
                            end if
                        end if
                    end if
                end if
            end if
        end if
    end for

    m.top.items = items
end sub

' Fetch ratingKeys of items in this section that the user has labeled with the
' carousel-ignore label "no-poster". Returns an associative array used as a set.
function fetchExcludedKeys(server as String, sectionKey as String, token as String) as Object
    result = {}
    transfer = createObject("roUrlTransfer")
    if transfer = invalid then return result
    transfer.SetUrl(server + "/library/sections/" + sectionKey + "/all?label=no-poster&X-Plex-Container-Size=500")
    transfer.AddHeader("X-Plex-Token", token)
    transfer.AddHeader("Accept", "application/xml")
    body = transfer.GetToString()
    if body = invalid or body = "" then return result
    xml = createObject("roXMLElement")
    if not xml.Parse(body) then return result
    elements = xml.GetChildElements()
    if elements = invalid then return result
    for each elem in elements
        attrs = elem.GetAttributes()
        ratingKey = stringOrEmpty(attrs["ratingKey"])
        if ratingKey <> "" then result[ratingKey] = true
    end for
    return result
end function

function stringOrEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function

' See PlexSessionTask.extractImdbId — same dual-format logic for library items.
function extractImdbId(itemEl as Object) as String
    guids = itemEl.GetNamedElements("Guid")
    if guids <> invalid and guids.Count() > 0 then
        for each g in guids
            a = g.GetAttributes()
            if a <> invalid then
                id = stringOrEmpty(a["id"])
                if Instr(1, id, "imdb://") = 1 then return id.Mid(7)
            end if
        end for
    end if

    attrs = itemEl.GetAttributes()
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

function intOrZero(value as Dynamic) as Integer
    if value = invalid then return 0
    return value.ToInt()
end function

' Collect each <TagName tag="..."/> child and join the tag attributes with " · ".
function collectTagAttribute(itemEl as Object, tagName as String) as String
    return collectTagAttributeLimited(itemEl, tagName, 0)
end function

' Same as collectTagAttribute, but caps the output to the first N matches.
function collectTagAttributeLimited(itemEl as Object, tagName as String, limit as Integer) as String
    elements = itemEl.GetNamedElements(tagName)
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

function buildPlexUri(server as String, path as String, token as String, transfer as Object) as String
    if path = "" then return ""
    if path.Left(1) = "/" then
        return server + path + "?X-Plex-Token=" + transfer.Escape(token)
    end if
    return path
end function

' Parse the user's comma-separated blocked ratings into a lookup set
' (associative array keyed by lower-case normalized rating).
function parseBlockedRatings(s as String) as Object
    result = {}
    if s = invalid or s = "" then return result
    parts = s.Split(",")
    for each part in parts
        normalized = normalizeRating(part)
        if normalized <> "" then result[normalized] = true
    end for
    return result
end function

' Normalize a content rating string. Plex sometimes prefixes ratings with a
' country code (e.g. "us/PG-13"); we strip that. Empty/NR are treated as
' "not rated" so the blocked-ratings set can match both literal "Not Rated"
' values and items with no rating at all.
function normalizeRating(rating as String) as String
    if rating = invalid then return "not rated"
    r = LCase(rating.Trim())
    if r = "" then return "not rated"
    slash = Instr(1, r, "/")
    if slash > 0 then r = r.Mid(slash + 1)
    r = r.Trim()
    if r = "" or r = "nr" or r = "unrated" then return "not rated"
    return r
end function

function buildBlurredPlexUri(server as String, path as String, token as String, transfer as Object) as String
    if path = "" then return ""
    if path.Left(1) <> "/" then return ""
    encodedPath = transfer.Escape(path)
    encodedToken = transfer.Escape(token)
    return server + "/photo/:/transcode?width=480&height=270&minSize=1&upscale=1&blur=50&url=" + encodedPath + "&X-Plex-Token=" + encodedToken
end function
