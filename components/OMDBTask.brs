sub init()
    m.top.functionName = "fetch"
end sub

sub fetch()
    result = { ok: false, imdbRating: "", rottenTomatoes: "", metacritic: "", awards: "", error: "" }

    apiKey = m.top.apiKey
    imdbId = m.top.imdbId
    if apiKey = "" or imdbId = "" then
        result.error = "missing apiKey or imdbId"
        print "[omdb] skipping — missing apiKey=" + (apiKey <> "").ToStr() + " imdbId='" + imdbId + "'"
        m.top.result = result
        return
    end if

    transfer = createObject("roUrlTransfer")
    if transfer = invalid then
        result.error = "transfer create failed"
        print "[omdb] roUrlTransfer create failed"
        m.top.result = result
        return
    end if
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.EnableEncodings(true)
    url = "https://www.omdbapi.com/?apikey=" + transfer.Escape(apiKey) + "&i=" + transfer.Escape(imdbId)
    transfer.SetUrl(url)
    transfer.AddHeader("Accept", "application/json")
    print "[omdb] GET " + url

    body = transfer.GetToString()
    if body = invalid then
        result.error = "transfer returned invalid"
        print "[omdb] GetToString returned invalid (TLS or DNS failure?)"
        m.top.result = result
        return
    end if
    if body = "" then
        result.error = "empty response"
        print "[omdb] empty body"
        m.top.result = result
        return
    end if
    print "[omdb] body bytes=" + body.Len().ToStr()

    json = parseJson(body)
    if json = invalid then
        result.error = "json parse failed"
        print "[omdb] parseJson failed; raw start=" + Left(body, 120)
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
        print "[omdb] ok imdb=" + result.imdbRating + " rt=" + result.rottenTomatoes + " meta=" + result.metacritic
    else
        result.error = stringOrEmpty(json.Error)
        print "[omdb] response=False error=" + result.error
    end if

    m.top.result = result
end sub

function stringOrEmpty(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function
