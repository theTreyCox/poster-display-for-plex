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

    excluded = parseExcludedLibraries(m.top.excludedLibraries)

    for each section in sectionElements
        sectionAttrs = section.GetAttributes()
        sectionType = stringOrEmpty(sectionAttrs["type"])
        sectionTitle = stringOrEmpty(sectionAttrs["title"])
        if (sectionType = "movie" or sectionType = "show") and not isLibraryExcluded(sectionTitle, excluded) then
            sectionKey = stringOrEmpty(sectionAttrs["key"])
            if sectionKey <> "" then
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
                                    title = stringOrEmpty(itemAttrs["title"])
                                    thumb = stringOrEmpty(itemAttrs["thumb"])
                                    if thumb <> "" then
                                        posterUri = buildPlexUri(server, thumb, token, libraryTransfer)
                                        backgroundUri = buildBlurredPlexUri(server, thumb, token, libraryTransfer)
                                        items.push({ title: title, posterUri: posterUri, backgroundUri: backgroundUri })
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

function stringOrEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function

function buildPlexUri(server as String, path as String, token as String, transfer as Object) as String
    if path = "" then return ""
    if path.Left(1) = "/" then
        return server + path + "?X-Plex-Token=" + transfer.Escape(token)
    end if
    return path
end function

function parseExcludedLibraries(commaList as String) as Object
    result = {}
    if commaList = "" then return result
    parts = commaList.Split(",")
    for each part in parts
        normalized = LCase(part.Trim())
        if normalized <> "" then result[normalized] = true
    end for
    return result
end function

function isLibraryExcluded(name as String, excluded as Object) as Boolean
    return excluded[LCase(name.Trim())] = true
end function

function buildBlurredPlexUri(server as String, path as String, token as String, transfer as Object) as String
    if path = "" then return ""
    if path.Left(1) <> "/" then return ""
    encodedPath = transfer.Escape(path)
    encodedToken = transfer.Escape(token)
    return server + "/photo/:/transcode?width=480&height=270&minSize=1&upscale=1&blur=50&url=" + encodedPath + "&X-Plex-Token=" + encodedToken
end function
