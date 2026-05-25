sub init()
    m.poster = m.top.findNode("poster")
    m.backgroundPoster = m.top.findNode("backgroundPoster")
    m.borderLandscape = m.top.findNode("borderLandscape")
    m.borderPortrait = m.top.findNode("borderPortrait")
    m.titleMarquee = m.top.findNode("titleMarquee")
    m.titleMarqueeLabel = m.top.findNode("titleMarqueeLabel")

    ' Landscape chrome
    m.landscapeChrome = m.top.findNode("landscapeChrome")
    m.overlay = m.top.findNode("overlay")
    m.messageLabel = m.top.findNode("messageLabel")
    m.nowPlayingPrefix = m.top.findNode("nowPlayingPrefix")
    m.nowPlayingTitle = m.top.findNode("nowPlayingTitle")
    m.settingsButton = m.top.findNode("settingsButton")
    m.progressGroup = m.top.findNode("progressGroup")
    m.currentTimeLabel = m.top.findNode("currentTimeLabel")
    m.totalTimeLabel = m.top.findNode("totalTimeLabel")
    m.progressBarFill = m.top.findNode("progressBarFill")
    m.remainingTimeLabel = m.top.findNode("remainingTimeLabel")
    m.clockLabel = m.top.findNode("clockLabel")

    ' Portrait chrome
    m.portraitChrome = m.top.findNode("portraitChrome")
    m.portraitMessageLabel = m.top.findNode("portraitMessageLabel")
    m.portraitNowPlayingPrefix = m.top.findNode("portraitNowPlayingPrefix")
    m.portraitNowPlayingTitle = m.top.findNode("portraitNowPlayingTitle")
    m.portraitSettingsButton = m.top.findNode("portraitSettingsButton")
    m.portraitProgressGroup = m.top.findNode("portraitProgressGroup")
    m.portraitCurrentTimeLabel = m.top.findNode("portraitCurrentTimeLabel")
    m.portraitTotalTimeLabel = m.top.findNode("portraitTotalTimeLabel")
    m.portraitProgressBarFill = m.top.findNode("portraitProgressBarFill")
    m.portraitRemainingTimeLabel = m.top.findNode("portraitRemainingTimeLabel")
    m.portraitClockLabel = m.top.findNode("portraitClockLabel")

    ' App logo + episode poster overlay
    m.appLogo = m.top.findNode("appLogo")
    m.episodePosterGroup = m.top.findNode("episodePosterGroup")
    m.episodePoster = m.top.findNode("episodePoster")

    ' Timers + mode indicator
    m.pollTimer = m.top.findNode("pollTimer")
    m.modeIndicator = m.top.findNode("modeIndicator")
    m.modeIndicatorLabel = m.top.findNode("modeIndicatorLabel")
    m.hideIndicatorTimer = m.top.findNode("hideIndicatorTimer")
    m.tickTimer = m.top.findNode("tickTimer")
    m.carouselTimer = m.top.findNode("carouselTimer")
    m.registry = createObject("roRegistrySection", "PosterDisplayForPlex")

    ' roAppManager cannot be created on the render thread, so the screensaver-suppression
    ' lives in KeepAliveTask which runs on its own thread.
    m.keepAliveTask = createObject("roSGNode", "KeepAliveTask")
    m.keepAliveTask.control = "RUN"

    m.settings = {
        plexServer: m.registry.Read("plexServer"),
        plexToken: m.registry.Read("plexToken"),
        blockedRatings: m.registry.Read("blockedRatings")
    }

    ' Node refs for the blocked-ratings overlay
    m.blockedRatingsOverlay = m.top.findNode("blockedRatingsOverlay")
    m.blockedRatingsCheckList = m.top.findNode("blockedRatingsCheckList")
    m.blockedRatingsSave = m.top.findNode("blockedRatingsSave")
    m.blockedRatingsCancel = m.top.findNode("blockedRatingsCancel")

    ' Ratings users can toggle, in order shown in the dialog
    m.blockedRatingOptions = ["G", "PG", "PG-13", "R", "NC-17", "XXX", "TV-Y", "TV-Y7", "TV-G", "TV-PG", "TV-14", "TV-MA", "Not Rated"]
    m.viewMode = m.registry.Read("viewMode").ToInt()
    m.borderEnabled = (m.registry.Read("borderEnabled") = "1")
    m.infoEnabled = (m.registry.Read("infoEnabled") <> "0")
    m.carouselEnabled = (m.registry.Read("carouselEnabled") = "1")
    m.portraitFlip = (m.registry.Read("portraitFlip") = "1")
    m.duration = 0
    m.viewOffset = 0
    m.playerState = ""
    m.lastUpdate = 0
    m.isPlaying = false
    m.hasEpisodePoster = false
    m.carouselPosters = []
    m.carouselPaused = false

    m.settingsButton.observeField("buttonSelected", "onSettingsClicked")
    m.portraitSettingsButton.observeField("buttonSelected", "onSettingsClicked")
    m.blockedRatingsSave.observeField("buttonSelected", "onBlockedRatingsSave")
    m.blockedRatingsCancel.observeField("buttonSelected", "onBlockedRatingsCancel")
    m.pollTimer.observeField("fire", "onPollTimerFired")
    m.hideIndicatorTimer.observeField("fire", "hideModeIndicator")
    m.tickTimer.observeField("fire", "onTick")
    m.tickTimer.control = "start"
    m.carouselTimer.observeField("fire", "onCarouselTick")

    applyViewMode()

    if m.settings.plexServer <> "" and m.settings.plexToken <> "" then
        if m.carouselEnabled then
            setStatusMessage("Loading library posters...")
            startCarousel()
        else
            setStatusMessage("Loading current Plex poster...")
            m.pollTimer.control = "start"
            refreshPoster()
        end if
    else
        setStatusMessage("Press OK to enter your Plex server and token.")
    end if

    showModeIndicator(viewModeLabel(m.viewMode) + "  —  Up view • Down border • Right info • * or Left settings • Rwd carousel")
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' Blocked-ratings overlay: intercept Back to close without saving.
    if m.blockedRatingsOverlay.visible then
        if key = "back" then
            closeBlockedRatingsOverlay()
            return true
        end if
        return false
    end if

    ' In carousel mode, Play pauses/resumes auto-advance and Fwd manually advances.
    ' These take precedence over the global Play=cycle-view-mode binding.
    if m.carouselEnabled then
        if key = "play" then
            toggleCarouselPause()
            return true
        else if key = "fwd" or key = "forward" or key = "fastforward" then
            advanceCarousel()
            return true
        end if
    end if

    if key = "play" or key = "up" then
        cycleViewMode()
        return true
    else if key = "down" then
        toggleBorder()
        return true
    else if key = "right" then
        toggleInfo()
        return true
    else if key = "left" or key = "info" then
        openSettingsMenu()
        return true
    else if key = "rev" or key = "rewind" then
        toggleCarousel()
        return true
    end if
    return false
end function

sub toggleBorder()
    m.borderEnabled = not m.borderEnabled
    state = "0"
    if m.borderEnabled then state = "1"
    m.registry.Write("borderEnabled", state)
    m.registry.Flush()
    applyViewMode()
    label = "Now Playing border: Off"
    if m.borderEnabled then label = "Now Playing border: On"
    showModeIndicator(label)
end sub

sub toggleInfo()
    m.infoEnabled = not m.infoEnabled
    state = "0"
    if m.infoEnabled then state = "1"
    m.registry.Write("infoEnabled", state)
    m.registry.Flush()
    applyViewMode()
    if m.infoEnabled and m.duration > 0 then renderProgress(m.viewOffset)
    label = "Info: Off"
    if m.infoEnabled then label = "Info: On"
    showModeIndicator(label)
end sub

sub cycleViewMode()
    m.viewMode = (m.viewMode + 1) mod 4
    m.registry.Write("viewMode", m.viewMode.ToStr())
    m.registry.Flush()
    applyViewMode()
    showModeIndicator(viewModeLabel(m.viewMode))
end sub

sub applyViewMode()
    m.poster.loadDisplayMode = "scaleToFit"
    applyPortraitFlip()
    if m.borderEnabled then
        applyBorderedViewMode()
    else
        applyPlainViewMode()
    end if
    updateInfoVisibility()
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    ' Blurred ambient backdrop only in landscape modes
    m.backgroundPoster.visible = isLandscape and (m.backgroundPoster.uri <> "")
    if isLandscape then
        m.settingsButton.setFocus(true)
    else
        m.portraitSettingsButton.setFocus(true)
    end if
end sub

' Position and rotate the portrait chrome strip so it lands at viewer-bottom
' for the user's TV mount direction. m.portraitFlip = false (default) targets
' a TV mounted with its original top on the viewer's right (CW). flip = true
' targets the opposite mount (original top on viewer's left, CCW).
sub applyPortraitFlip()
    if m.portraitFlip then
        m.portraitChrome.rotation = -1.5707963
        m.portraitChrome.translation = [-440, 440]
    else
        m.portraitChrome.rotation = 1.5707963
        m.portraitChrome.translation = [1280, 440]
    end if
end sub

function portraitRotation() as Float
    if m.portraitFlip then return -1.5707963
    return 1.5707963
end function

sub applyPlainViewMode()
    m.borderLandscape.visible = false
    m.borderPortrait.visible = false
    if m.viewMode = 0 then
        m.poster.width = 720
        m.poster.height = 1080
        m.poster.translation = [600, 0]
        m.poster.scaleRotateCenter = [360, 540]
        m.poster.rotation = 0
    else if m.viewMode = 1 then
        m.poster.width = 1920
        m.poster.height = 2880
        m.poster.translation = [0, -900]
        m.poster.scaleRotateCenter = [960, 1440]
        m.poster.rotation = 0
    else if m.viewMode = 2 then
        ' Portrait Fit — info on shifts poster up to leave room for chrome below
        m.poster.width = 1080
        m.poster.height = 1620
        m.poster.scaleRotateCenter = [540, 810]
        m.poster.rotation = portraitRotation()
        if m.infoEnabled then
            m.poster.translation = [320, -270]
        else
            m.poster.translation = [420, -270]
        end if
    else if m.viewMode = 3 then
        ' Portrait Fill — info on shrinks fill area to above chrome
        m.poster.rotation = portraitRotation()
        if m.infoEnabled then
            m.poster.width = 1147
            m.poster.height = 1720
            m.poster.translation = [287, -320]
            m.poster.scaleRotateCenter = [574, 860]
        else
            m.poster.width = 1280
            m.poster.height = 1920
            m.poster.translation = [320, -420]
            m.poster.scaleRotateCenter = [640, 960]
        end if
    end if
end sub

sub applyBorderedViewMode()
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    m.borderLandscape.visible = isLandscape
    m.borderPortrait.visible = not isLandscape
    if m.viewMode = 0 then
        m.poster.width = 529
        m.poster.height = 793
        m.poster.translation = [696, 110]
        m.poster.scaleRotateCenter = [264, 396]
        m.poster.rotation = 0
    else if m.viewMode = 1 then
        m.poster.width = 670
        m.poster.height = 1005
        m.poster.translation = [626, 4]
        m.poster.scaleRotateCenter = [335, 502]
        m.poster.rotation = 0
    else if m.viewMode = 2 then
        m.poster.width = 760
        m.poster.height = 1140
        m.poster.translation = [551, -34]
        m.poster.scaleRotateCenter = [380, 570]
        m.poster.rotation = portraitRotation()
    else if m.viewMode = 3 then
        m.poster.width = 1027
        m.poster.height = 1540
        m.poster.translation = [417, -234]
        m.poster.scaleRotateCenter = [513, 770]
        m.poster.rotation = portraitRotation()
    end if
end sub

function viewModeLabel(mode as Integer) as String
    if mode = 0 then return "Landscape - Fit"
    if mode = 1 then return "Landscape - Fill"
    if mode = 2 then return "Portrait - Fit"
    if mode = 3 then return "Portrait - Fill"
    return ""
end function

sub showModeIndicator(text as String)
    m.modeIndicatorLabel.text = text
    m.modeIndicator.visible = true
    m.hideIndicatorTimer.control = "start"
end sub

sub hideModeIndicator()
    m.modeIndicator.visible = false
end sub

sub onSettingsClicked()
    openSettingsMenu()
end sub

sub openSettingsMenu()
    serverDisplay = m.settings.plexServer
    if serverDisplay = "" then serverDisplay = "(not set)"
    tokenDisplay = "(set)"
    if m.settings.plexToken = "" then tokenDisplay = "(not set)"
    ratingsDisplay = m.settings.blockedRatings
    if ratingsDisplay = "" then ratingsDisplay = "(none)"
    flipDisplay = "Top on right (CW mount)"
    if m.portraitFlip then flipDisplay = "Top on left (CCW mount)"

    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Settings"
    dialog.message = "Server: " + serverDisplay + chr(10) + "Token: " + tokenDisplay + chr(10) + "Carousel blocks ratings: " + ratingsDisplay + chr(10) + "Portrait orientation: " + flipDisplay
    dialog.buttons = ["Change Plex server", "Change Plex token", "Edit carousel rating filter", "Flip portrait orientation", "Close"]
    dialog.observeField("buttonSelected", "onSettingsMenuSelected")
    m.top.dialog = dialog
end sub

sub onSettingsMenuSelected(event as Object)
    selectedIndex = event.getData()
    m.top.dialog = invalid
    if selectedIndex = 0 then
        promptServer()
    else if selectedIndex = 1 then
        promptToken()
    else if selectedIndex = 2 then
        showBlockedRatingsOverlay()
    else if selectedIndex = 3 then
        togglePortraitFlip()
        openSettingsMenu()
    else
        cancelSettings()
    end if
end sub

sub togglePortraitFlip()
    m.portraitFlip = not m.portraitFlip
    state = "0"
    if m.portraitFlip then state = "1"
    m.registry.Write("portraitFlip", state)
    m.registry.Flush()
    applyViewMode()
end sub

sub showBlockedRatingsOverlay()
    blocked = parseBlockedRatingsLocal(m.settings.blockedRatings)

    content = createObject("roSGNode", "ContentNode")
    checkedState = []
    for each rating in m.blockedRatingOptions
        item = content.createChild("ContentNode")
        item.title = rating
        checkedState.push(blocked[LCase(rating)] = true)
    end for

    m.blockedRatingsCheckList.content = content
    m.blockedRatingsCheckList.checkedState = checkedState
    m.blockedRatingsOverlay.visible = true
    m.blockedRatingsCheckList.setFocus(true)
end sub

sub onBlockedRatingsSave()
    if m.blockedRatingsCheckList = invalid then return
    state = m.blockedRatingsCheckList.checkedState
    parts = []
    for i = 0 to m.blockedRatingOptions.Count() - 1
        if state[i] = true then parts.push(m.blockedRatingOptions[i])
    end for
    joined = ""
    for i = 0 to parts.Count() - 1
        if i > 0 then joined = joined + ", "
        joined = joined + parts[i]
    end for
    m.settings.blockedRatings = joined
    m.registry.Write("blockedRatings", joined)
    m.registry.Flush()
    m.carouselPosters = []
    closeBlockedRatingsOverlay()
end sub

sub onBlockedRatingsCancel()
    closeBlockedRatingsOverlay()
end sub

sub closeBlockedRatingsOverlay()
    m.blockedRatingsOverlay.visible = false
    refocusSettings()
    openSettingsMenu()
end sub

function parseBlockedRatingsLocal(s as String) as Object
    result = {}
    if s = "" then return result
    parts = s.Split(",")
    for each part in parts
        normalized = LCase(part.Trim())
        if normalized <> "" then result[normalized] = true
    end for
    return result
end function

sub onPollTimerFired()
    if m.carouselEnabled then return
    refreshPoster()
end sub

sub toggleCarousel()
    m.carouselEnabled = not m.carouselEnabled
    state = "0"
    if m.carouselEnabled then state = "1"
    m.registry.Write("carouselEnabled", state)
    m.registry.Flush()

    if m.carouselEnabled then
        m.carouselPaused = false
        m.pollTimer.control = "stop"
        showModeIndicator("Carousel: On  —  Play pauses, Fwd advances")
        startCarousel()
    else
        m.carouselTimer.control = "stop"
        showModeIndicator("Carousel: Off")
        if m.settings.plexServer <> "" and m.settings.plexToken <> "" then
            m.pollTimer.control = "start"
            setStatusMessage("Loading current Plex poster...")
            refreshPoster()
        end if
    end if
end sub

sub toggleCarouselPause()
    m.carouselPaused = not m.carouselPaused
    if m.carouselPaused then
        m.carouselTimer.control = "stop"
        showModeIndicator("Carousel paused")
    else
        m.carouselTimer.control = "start"
        showModeIndicator("Carousel playing")
    end if
end sub

sub advanceCarousel()
    showNextCarouselPoster()
    ' Reset the timer so the new poster gets a full interval — unless paused,
    ' in which case the user is browsing manually and we leave the timer stopped.
    if not m.carouselPaused then
        m.carouselTimer.control = "stop"
        m.carouselTimer.control = "start"
    end if
end sub

sub startCarousel()
    if m.carouselPosters.Count() > 0 then
        showNextCarouselPoster()
        m.carouselTimer.control = "start"
        return
    end if

    if m.libraryTask = invalid then
        m.libraryTask = createObject("roSGNode", "PlexLibraryTask")
        m.libraryTask.observeField("items", "onLibraryItems")
    end if
    m.libraryTask.plexServer = m.settings.plexServer
    m.libraryTask.plexToken = m.settings.plexToken
    m.libraryTask.blockedRatings = m.settings.blockedRatings
    m.libraryTask.control = "RUN"
end sub

sub onLibraryItems(event as Object)
    items = event.getData()
    if items = invalid or items.Count() = 0 then
        setStatusMessage("Could not load library posters from Plex.")
        return
    end if
    m.carouselPosters = items
    showNextCarouselPoster()
    m.carouselTimer.control = "start"
end sub

sub onCarouselTick()
    showNextCarouselPoster()
end sub

sub showNextCarouselPoster()
    if m.carouselPosters.Count() = 0 then return
    idx = rnd(m.carouselPosters.Count()) - 1
    item = m.carouselPosters[idx]
    if item = invalid then return
    m.poster.uri = item.posterUri
    m.backgroundPoster.uri = item.backgroundUri
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    m.backgroundPoster.visible = isLandscape and (item.backgroundUri <> "")
    setNowPlayingTitle(item.title, "")
    m.titleMarqueeLabel.text = UCase(item.title)
    m.isPlaying = true
    m.duration = 0
    m.hasEpisodePoster = false
    updateInfoVisibility()
end sub

' Entry point for the Settings flow. Tries Plex GDM discovery first so the user
' can pick a server from a list rather than typing an IP. Falls back to manual
' URL entry if nothing's found or the user opts out.
sub promptServer()
    setStatusMessage("Searching for Plex servers...")
    if m.discoveryTask = invalid then
        m.discoveryTask = createObject("roSGNode", "PlexDiscoveryTask")
        m.discoveryTask.observeField("servers", "onServersDiscovered")
    end if
    m.discoveryTask.control = "RUN"
end sub

sub onServersDiscovered(event as Object)
    servers = event.getData()
    m.discoveredServers = servers
    if servers = invalid or servers.Count() = 0 then
        promptServerManual()
        return
    end if
    showServerSelectionDialog()
end sub

sub showServerSelectionDialog()
    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Choose a Plex Server"
    dialog.message = "These servers responded on your network. Pick one or enter a URL manually."

    buttons = []
    for each server in m.discoveredServers
        label = server.name
        if label = "" then label = server.url
        buttons.push(label)
    end for
    buttons.push("Enter manually")
    buttons.push("Cancel")
    dialog.buttons = buttons
    dialog.observeField("buttonSelected", "onServerSelected")
    m.top.dialog = dialog
end sub

sub onServerSelected(event as Object)
    dialog = event.getRoSGNode()
    if dialog = invalid then return

    selectedIndex = event.getData()
    m.top.dialog = invalid

    numServers = m.discoveredServers.Count()

    if selectedIndex < numServers then
        server = m.discoveredServers[selectedIndex]
        m.settings.plexServer = server.url
        m.registry.Write("plexServer", server.url)
        m.registry.Flush()
        m.carouselPosters = []
        openSettingsMenu()
    else if selectedIndex = numServers then
        promptServerManual()
    else
        openSettingsMenu()
    end if
end sub

sub promptServerManual()
    dialog = createObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "Plex Server URL"
    dialog.text = m.settings.plexServer
    dialog.buttons = ["OK", "Cancel"]
    dialog.observeField("buttonSelected", "onServerEntered")
    m.top.dialog = dialog
end sub

sub cancelSettings()
    refocusSettings()
    if m.settings.plexServer = "" or m.settings.plexToken = "" then
        setStatusMessage("Press OK to enter your Plex server and token.")
        return
    end if
    if m.carouselEnabled then
        m.carouselTimer.control = "stop"
        setStatusMessage("Loading library posters...")
        startCarousel()
    else
        setStatusMessage("Loading current Plex poster...")
        m.pollTimer.control = "start"
        refreshPoster()
    end if
end sub

sub onServerEntered(event as Object)
    dialog = event.getRoSGNode()
    if dialog = invalid then return

    selectedIndex = event.getData()
    enteredText = dialog.text
    if enteredText = invalid then enteredText = ""

    m.top.dialog = invalid

    if selectedIndex <> 0 then
        openSettingsMenu()
        return
    end if

    normalized = normalizeServer(enteredText)
    if normalized = "" then
        setStatusMessage("Invalid Plex server URL. Try again.")
        openSettingsMenu()
        return
    end if

    m.settings.plexServer = normalized
    m.registry.Write("plexServer", normalized)
    m.registry.Flush()
    m.carouselPosters = []
    openSettingsMenu()
end sub

sub promptToken()
    dialog = createObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = "Plex Token"
    dialog.text = m.settings.plexToken
    dialog.buttons = ["OK", "Cancel"]
    dialog.observeField("buttonSelected", "onTokenEntered")
    m.top.dialog = dialog
end sub

sub onTokenEntered(event as Object)
    dialog = event.getRoSGNode()
    if dialog = invalid then return

    selectedIndex = event.getData()
    enteredText = dialog.text
    if enteredText = invalid then enteredText = ""

    m.top.dialog = invalid

    if selectedIndex <> 0 or enteredText = "" then
        refocusSettings()
        return
    end if

    m.settings.plexToken = enteredText
    m.registry.Write("plexToken", m.settings.plexToken)
    m.registry.Flush()
    m.carouselPosters = []
    openSettingsMenu()
end sub

sub refocusSettings()
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    if isLandscape then
        m.settingsButton.setFocus(true)
    else
        m.portraitSettingsButton.setFocus(true)
    end if
end sub

function normalizeServer(server as String) as String
    server = server.Trim()
    if server = "" then return ""

    lower = LCase(server)
    if lower.StartsWith("http://") = false and lower.StartsWith("https://") = false then
        server = "http://" + server
    end if

    if server.Right(1) = "/" then
        server = server.Left(server.Len() - 1)
    end if

    return server
end function

sub refreshPoster()
    if m.settings.plexServer = "" or m.settings.plexToken = "" then return

    if m.fetchTask <> invalid and m.fetchTask.state = "RUN" then return

    if m.fetchTask = invalid then
        m.fetchTask = createObject("roSGNode", "PlexSessionTask")
        m.fetchTask.observeField("result", "onSessionResult")
    end if

    m.fetchTask.plexServer = m.settings.plexServer
    m.fetchTask.plexToken = m.settings.plexToken
    m.fetchTask.control = "RUN"
end sub

sub onSessionResult(event as Object)
    if m.carouselEnabled then return
    sessionInfo = event.getData()
    if sessionInfo = invalid then return

    if sessionInfo.valid = false or sessionInfo.isPlaying = false then
        setStatusMessage("No Plex playback detected.")
        m.duration = 0
        m.viewOffset = 0
        m.playerState = ""
        m.isPlaying = false
        m.hasEpisodePoster = false
        m.backgroundPoster.uri = ""
        m.backgroundPoster.visible = false
        updateInfoVisibility()
        return
    end if

    if sessionInfo.posterUri = "" then
        setStatusMessage("Could not resolve Plex poster URL.")
        return
    end if

    m.poster.uri = sessionInfo.posterUri
    m.backgroundPoster.uri = sessionInfo.backgroundUri
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    m.backgroundPoster.visible = isLandscape and (sessionInfo.backgroundUri <> "")
    setNowPlayingTitle(sessionInfo.title, sessionInfo.showName)

    ' Marquee shows show name for TV (fits better than full "Show — Episode"), title for movies
    marqueeText = sessionInfo.title
    if sessionInfo.showName <> "" then marqueeText = sessionInfo.showName
    m.titleMarqueeLabel.text = UCase(marqueeText)

    ' Episode thumbnail (TV only; movies have no episodePosterUri)
    m.episodePoster.uri = sessionInfo.episodePosterUri
    m.hasEpisodePoster = (sessionInfo.episodePosterUri <> "")

    m.duration = sessionInfo.duration
    m.viewOffset = sessionInfo.viewOffset
    m.playerState = sessionInfo.state
    m.lastUpdate = createObject("roDateTime").AsSeconds()
    m.isPlaying = true
    updateInfoVisibility()
    if m.duration > 0 then renderProgress(m.viewOffset)
end sub

sub setStatusMessage(text as String)
    m.messageLabel.text = text
    m.portraitMessageLabel.text = text
    m.isPlaying = false
    updateInfoVisibility()
end sub

sub setNowPlayingTitle(title as String, showName as String)
    fullTitle = title
    if showName <> "" and title <> "" then
        fullTitle = showName + " — " + title
    else if showName <> "" then
        fullTitle = showName
    end if
    m.nowPlayingTitle.text = UCase(fullTitle)
    m.portraitNowPlayingTitle.text = UCase(fullTitle)
end sub

sub onTick()
    if not m.infoEnabled then return
    updateClock()
    if m.duration <= 0 then return

    current = m.viewOffset
    if m.playerState = "playing" then
        now = createObject("roDateTime").AsSeconds()
        elapsed = now - m.lastUpdate
        current = m.viewOffset + (elapsed * 1000)
        if current > m.duration then current = m.duration
    end if
    renderProgress(current)
end sub

sub updateClock()
    timeText = formatLocalTime12()
    m.clockLabel.text = timeText
    m.portraitClockLabel.text = timeText
end sub

function formatLocalTime12() as String
    now = createObject("roDateTime")
    now.ToLocalTime()
    h = now.GetHours()
    mins = now.GetMinutes()
    ampm = "AM"
    if h >= 12 then ampm = "PM"
    if h = 0 then
        h = 12
    else if h > 12 then
        h = h - 12
    end if
    return Stri(h) + ":" + padTwo(mins) + " " + ampm
end function

sub renderProgress(positionMs as Integer)
    currentText = formatTime(positionMs)
    totalText = formatTime(m.duration)
    remainingMs = m.duration - positionMs
    if remainingMs < 0 then remainingMs = 0
    remainingText = "REMAINING " + formatTime(remainingMs)

    m.currentTimeLabel.text = currentText
    m.totalTimeLabel.text = totalText
    m.remainingTimeLabel.text = remainingText
    m.portraitCurrentTimeLabel.text = currentText
    m.portraitTotalTimeLabel.text = totalText
    m.portraitRemainingTimeLabel.text = remainingText

    if m.duration > 0 then
        ratio = positionMs / m.duration
        if ratio < 0 then ratio = 0
        if ratio > 1 then ratio = 1
        landscapeW = Int(ratio * 810)
        if landscapeW < 1 then landscapeW = 1
        portraitW = Int(ratio * 360)
        if portraitW < 1 then portraitW = 1
        m.progressBarFill.width = landscapeW
        m.portraitProgressBarFill.width = portraitW
    end if
end sub

sub updateInfoVisibility()
    needsSetup = (m.settings.plexServer = "" or m.settings.plexToken = "")
    chromeVisible = m.infoEnabled or needsSetup

    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    marqueeVisible = m.infoEnabled and m.borderEnabled and isLandscape and m.isPlaying

    ' Top-level chrome groups
    m.landscapeChrome.visible = chromeVisible and isLandscape
    m.portraitChrome.visible = chromeVisible and not isLandscape

    ' Settings buttons hide once Plex is configured — Left arrow opens settings instead
    m.settingsButton.visible = needsSetup
    m.portraitSettingsButton.visible = needsSetup

    ' Landscape: swap status mode (message vs now-playing) and hide status when marquee shows
    showLandscapeStatus = m.landscapeChrome.visible and not marqueeVisible
    m.overlay.visible = showLandscapeStatus
    m.messageLabel.visible = showLandscapeStatus and not m.isPlaying
    m.nowPlayingPrefix.visible = showLandscapeStatus and m.isPlaying and not m.carouselEnabled
    m.nowPlayingTitle.visible = showLandscapeStatus and m.isPlaying

    ' Portrait: similar status swap (no marquee in portrait)
    m.portraitMessageLabel.visible = m.portraitChrome.visible and not m.isPlaying
    m.portraitNowPlayingPrefix.visible = m.portraitChrome.visible and m.isPlaying and not m.carouselEnabled
    m.portraitNowPlayingTitle.visible = m.portraitChrome.visible and m.isPlaying

    ' In carousel mode, expand the title to span the full status row width and
    ' center it (no prefix). Outside carousel, title sits to the right of the
    ' NOW PLAYING prefix and is left-aligned.
    if m.carouselEnabled then
        m.nowPlayingTitle.translation = [130, 952]
        m.nowPlayingTitle.width = 1660
        m.nowPlayingTitle.horizAlign = "center"
        m.portraitNowPlayingTitle.translation = [20, 80]
        m.portraitNowPlayingTitle.width = 970
        m.portraitNowPlayingTitle.horizAlign = "center"
    else
        m.nowPlayingTitle.translation = [420, 952]
        m.nowPlayingTitle.width = 1370
        m.nowPlayingTitle.horizAlign = "left"
        m.portraitNowPlayingTitle.translation = [270, 80]
        m.portraitNowPlayingTitle.width = 720
        m.portraitNowPlayingTitle.horizAlign = "left"
    end if

    if chromeVisible then updateClock()

    ' Marquee + progress
    m.titleMarquee.visible = marqueeVisible
    m.progressGroup.visible = m.infoEnabled and isLandscape and m.duration > 0
    m.portraitProgressGroup.visible = m.infoEnabled and not isLandscape and m.duration > 0

    ' Episode thumbnail (TV episodes in landscape mode when info is on)
    m.episodePosterGroup.visible = m.infoEnabled and isLandscape and m.hasEpisodePoster

    ' App logo — only when info is showing in landscape, hidden when border or Settings would overlap
    m.appLogo.visible = chromeVisible and isLandscape and not m.borderEnabled and not needsSetup
end sub

function formatTime(ms as Integer) as String
    totalSec = Int(ms / 1000)
    h = Int(totalSec / 3600)
    mins = Int((totalSec mod 3600) / 60)
    secs = totalSec mod 60
    if h > 0 then return Stri(h) + ":" + padTwo(mins) + ":" + padTwo(secs)
    return Stri(mins) + ":" + padTwo(secs)
end function

function padTwo(n as Integer) as String
    if n < 10 then return "0" + Stri(n)
    return Stri(n)
end function
