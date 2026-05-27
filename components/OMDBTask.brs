sub init()
    m.top.functionName = "fetch"
end sub

sub fetch()
    result = { ok: false, imdbRating: "", rottenTomatoes: "", metacritic: "", awards: "", error: "" }

    apiKey = m.top.apiKey
    imdbId = m.top.imdbId
    if apiKey = "" or imdbId = "" then
        result.error = "missing apiKey or imdbId"
        m.top.result = result
        return
    end if

    transfer = createObject("roUrlTransfer")
    if transfer = invalid then
        result.error = "transfer create failed"
        m.top.result = result
        return
    end if
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.EnableEncodings(true)
    transfer.SetUrl("https://www.omdbapi.com/?apikey=" + transfer.Escape(apiKey) + "&i=" + transfer.Escape(imdbId))
    transfer.AddHeader("Accept", "application/json")

    body = transfer.GetToString()
    if body = invalid or body = "" then
        result.error = "empty response"
        m.top.result = result
        return
    end if

    json = parseJson(body)
    if json = invalid then
        result.error = "json parse failed"
        m.top.result = result
        return
    end if

    if json.Response = "True" then
        result.ok = true
        result.imdbRating = stringOrEmpty(json.imdbRating)
        result.awards = stringOrEmpty(json.Awards)
        ratings = json.Ratings
        if ratings <> invalid then
            for each r in ratings
                source = stringOrEmpty(r.Source)
                value = stringOrEmpty(r.Value)
                if source = "Rotten Tomatoes" then result.rottenTomatoes = value
                if source = "Metacritic" then result.metacritic = value
            end for
        end if
    else
        result.error = stringOrEmpty(json.Error)
    end if

    m.top.result = result
end sub

function stringOrEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function
