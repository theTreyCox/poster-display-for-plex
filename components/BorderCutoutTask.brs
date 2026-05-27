sub init()
    m.top.functionName = "detectCutouts"
end sub

' For each border PNG, find the bounding box of (near-)transparent pixels.
' Returns an array of { uri, x, y, w, h } in the same order as inputs.
' If detection fails (image can't load, no transparent pixels), w/h = -1.
sub detectCutouts()
    uris = m.top.uris
    results = []
    if uris = invalid then
        m.top.result = results
        return
    end if

    for each uri in uris
        rect = detectAlphaRect(uri)
        if rect = invalid then
            results.push({ uri: uri, x: -1, y: -1, w: -1, h: -1 })
        else
            results.push({ uri: uri, x: rect.x, y: rect.y, w: rect.w, h: rect.h })
        end if
    end for

    m.top.result = results
end sub

' Scan the PNG's alpha channel to find the bounding box of transparent pixels.
' Uses edge-scan order (top, bottom, left, right) so we usually only read a
' small fraction of the image rather than the whole pixel array.
function detectAlphaRect(uri as String) as Object
    bitmap = createObject("roBitmap", uri)
    if bitmap = invalid then return invalid
    w = bitmap.GetWidth()
    h = bitmap.GetHeight()
    if w <= 0 or h <= 0 then return invalid

    bytes = bitmap.GetByteArray(0, 0, w, h)
    if bytes = invalid then return invalid
    if bytes.Count() < w * h * 4 then return invalid

    alphaT = 16  ' below this counts as "transparent" — gives a little fuzz tolerance

    ' Top edge: first row containing a transparent pixel.
    minY = -1
    for y = 0 to h - 1
        rowOff = y * w * 4
        for x = 0 to w - 1
            if bytes[rowOff + x * 4 + 3] < alphaT then
                minY = y
                exit for
            end if
        end for
        if minY >= 0 then exit for
    end for
    if minY < 0 then return invalid

    ' Bottom edge.
    maxY = minY
    for y = h - 1 to minY step -1
        rowOff = y * w * 4
        found = false
        for x = 0 to w - 1
            if bytes[rowOff + x * 4 + 3] < alphaT then
                found = true
                exit for
            end if
        end for
        if found then
            maxY = y
            exit for
        end if
    end for

    ' Left edge (only within the min/max-Y range).
    minX = -1
    for x = 0 to w - 1
        for y = minY to maxY
            if bytes[y * w * 4 + x * 4 + 3] < alphaT then
                minX = x
                exit for
            end if
        end for
        if minX >= 0 then exit for
    end for
    if minX < 0 then return invalid

    ' Right edge.
    maxX = minX
    for x = w - 1 to minX step -1
        found = false
        for y = minY to maxY
            if bytes[y * w * 4 + x * 4 + 3] < alphaT then
                found = true
                exit for
            end if
        end for
        if found then
            maxX = x
            exit for
        end if
    end for

    return { x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1 }
end function
