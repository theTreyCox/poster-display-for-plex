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
    m.ratingIcon = m.top.findNode("ratingIcon")
    m.nowPlayingTitle = m.top.findNode("nowPlayingTitle")
    m.nowPlayingYear = m.top.findNode("nowPlayingYear")
    m.settingsButton = m.top.findNode("settingsButton")
    m.progressGroup = m.top.findNode("progressGroup")
    m.currentTimeLabel = m.top.findNode("currentTimeLabel")
    m.totalTimeLabel = m.top.findNode("totalTimeLabel")
    m.progressBarFill = m.top.findNode("progressBarFill")
    m.clockLabel = m.top.findNode("clockLabel")

    ' Portrait chrome
    m.portraitChrome = m.top.findNode("portraitChrome")
    m.portraitMessageLabel = m.top.findNode("portraitMessageLabel")
    m.portraitNowPlayingPrefix = m.top.findNode("portraitNowPlayingPrefix")
    m.portraitRatingIcon = m.top.findNode("portraitRatingIcon")
    m.portraitNowPlayingTitle = m.top.findNode("portraitNowPlayingTitle")
    m.portraitNowPlayingYear = m.top.findNode("portraitNowPlayingYear")
    m.portraitSettingsButton = m.top.findNode("portraitSettingsButton")
    m.portraitSettingsButtonBg = m.top.findNode("portraitSettingsButtonBg")
    m.portraitProgressGroup = m.top.findNode("portraitProgressGroup")
    m.portraitCurrentTimeLabel = m.top.findNode("portraitCurrentTimeLabel")
    m.portraitTotalTimeLabel = m.top.findNode("portraitTotalTimeLabel")
    m.portraitProgressBarFill = m.top.findNode("portraitProgressBarFill")
    m.portraitClockLabel = m.top.findNode("portraitClockLabel")
    m.landscapeMetadata = m.top.findNode("landscapeMetadata")
    m.landscapeMetaTagline = m.top.findNode("landscapeMetaTagline")
    m.landscapeMetaStats = m.top.findNode("landscapeMetaStats")
    m.landscapeMetaSummary = m.top.findNode("landscapeMetaSummary")
    m.landscapeMetaReadMoreHint = m.top.findNode("landscapeMetaReadMoreHint")
    m.portraitMetadata = m.top.findNode("portraitMetadata")
    m.portraitMetaTagline = m.top.findNode("portraitMetaTagline")
    m.portraitMetaStats = m.top.findNode("portraitMetaStats")
    m.portraitMetaSummary = m.top.findNode("portraitMetaSummary")
    m.portraitMetaReadMoreHint = m.top.findNode("portraitMetaReadMoreHint")
    m.expandedDescription = m.top.findNode("expandedDescription")
    m.expandedTitle = m.top.findNode("expandedTitle")
    m.expandedTagline = m.top.findNode("expandedTagline")
    m.expandedStats = m.top.findNode("expandedStats")
    m.expandedDirector = m.top.findNode("expandedDirector")
    m.expandedWriter = m.top.findNode("expandedWriter")
    m.expandedCast = m.top.findNode("expandedCast")
    m.expandedStudio = m.top.findNode("expandedStudio")
    m.expandedReleased = m.top.findNode("expandedReleased")
    m.expandedSummary = m.top.findNode("expandedSummary")
    m.ratingPlexValue = m.top.findNode("ratingPlexValue")
    m.ratingImdbValue = m.top.findNode("ratingImdbValue")
    m.ratingRtValue = m.top.findNode("ratingRtValue")
    m.ratingMetaValue = m.top.findNode("ratingMetaValue")

    ' OMDB integration. Hardcoded key for now; could move to Settings later.
    m.omdbApiKey = "89ae9603"
    m.portraitPosterBorderGroup = m.top.findNode("portraitPosterBorderGroup")
    m.portraitPosterBorderTop = m.top.findNode("portraitPosterBorderTop")
    m.portraitPosterBorderBottom = m.top.findNode("portraitPosterBorderBottom")
    m.portraitPosterBorderLeft = m.top.findNode("portraitPosterBorderLeft")
    m.portraitPosterBorderRight = m.top.findNode("portraitPosterBorderRight")

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
    m.posterFadeOut = m.top.findNode("posterFadeOut")
    m.posterFadeIn = m.top.findNode("posterFadeIn")
    m.posterSlideOut = m.top.findNode("posterSlideOut")
    m.posterSlideIn = m.top.findNode("posterSlideIn")
    m.posterSlideOutInterp = m.top.findNode("posterSlideOutInterp")
    m.posterSlideInInterp = m.top.findNode("posterSlideInInterp")
    m.registry = createObject("roRegistrySection", "PosterDisplayForPlex")

    ' Persistent client identifier for the Plex.tv sign-in flow. Generated once
    ' per install; without a stable id, Plex.tv treats each request as a new
    ' device and the PIN flow won't complete.
    m.plexClientId = m.registry.Read("plexClientId")
    if m.plexClientId = "" then
        di = createObject("roDeviceInfo")
        if di <> invalid then m.plexClientId = di.GetRandomUUID()
        if m.plexClientId = "" then m.plexClientId = "pdfp-" + createObject("roDateTime").AsSeconds().ToStr()
        m.registry.Write("plexClientId", m.plexClientId)
        m.registry.Flush()
    end if

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
    m.plexSignInOverlay = m.top.findNode("plexSignInOverlay")
    m.plexSignInCodeLabel = m.top.findNode("plexSignInCodeLabel")
    m.plexSignInStatusLabel = m.top.findNode("plexSignInStatusLabel")
    m.plexSignInPollTimer = m.top.findNode("plexSignInPollTimer")
    m.blockedRatingsCheckList = m.top.findNode("blockedRatingsCheckList")

    ' Ratings users can toggle, in order shown in the dialog
    m.blockedRatingOptions = ["G", "PG", "PG-13", "R", "NC-17", "XXX", "TV-Y", "TV-Y7", "TV-G", "TV-PG", "TV-14", "TV-MA", "Not Rated"]
    m.viewMode = m.registry.Read("viewMode").ToInt()
    m.borderEnabled = (m.registry.Read("borderEnabled") = "1")
    m.infoEnabled = (m.registry.Read("infoEnabled") <> "0")
    m.carouselEnabled = (m.registry.Read("carouselEnabled") = "1")
    m.portraitFlip = (m.registry.Read("portraitFlip") = "1")
    m.transitionStyle = m.registry.Read("transitionStyle")
    if m.transitionStyle <> "fade" and m.transitionStyle <> "slide" then m.transitionStyle = "abrupt"
    m.portraitBorderEnabled = (m.registry.Read("portraitBorderEnabled") = "1")

    ' Accent / theme colors. Applied to the progress bar fill AND the metadata
    ' panel taglines so the brand identity carries through. Persisted as an
    ' index so the palette can change without invalidating existing saves.
    m.accentColors = [
        { name: "Orange", hex: "0xFFA500FF" },
        { name: "Red", hex: "0xFF3030FF" },
        { name: "Amber", hex: "0xFFBF00FF" },
        { name: "Yellow", hex: "0xFFE600FF" },
        { name: "Lime", hex: "0xA8FF30FF" },
        { name: "Green", hex: "0x33CC33FF" },
        { name: "Teal", hex: "0x009999FF" },
        { name: "Cyan", hex: "0x00CCFFFF" },
        { name: "Blue", hex: "0x3060FFFF" },
        { name: "Indigo", hex: "0x6020A0FF" },
        { name: "Purple", hex: "0x9933CCFF" },
        { name: "Pink", hex: "0xFF3399FF" }
    ]
    m.accentColorIndex = m.registry.Read("accentColorIndex").ToInt()
    if m.accentColorIndex < 0 or m.accentColorIndex >= m.accentColors.Count() then m.accentColorIndex = 0

    ' Portrait theater-frame styles. Geometry below is a fallback used until the
    ' BorderCutoutTask returns a measured cutout for each PNG; once it does, the
    ' fit/fill values are recomputed from the actual alpha=0 region so the
    ' poster always lands inside whatever cutout the artwork defines.
    m.portraitBorderStyles = [
        { id: "01", name: "Marquee Gold",
          uri: "pkg:/images/borders/portrait/portrait-border-01.png",
          fitW: 760, fitH: 1140, fitPivot: [380, 570], fitT: [551, -34],
          fillW: 1027, fillH: 1540, fillPivot: [513, 770], fillT: [417, -234] },
        { id: "02", name: "Theater Silver",
          uri: "pkg:/images/borders/portrait/portrait-border-02.png",
          fitW: 900, fitH: 1695, fitPivot: [450, 847], fitT: [115, -307],
          fillW: 1215, fillH: 2288, fillPivot: [608, 1144], fillT: [355, -607] }
    ]
    m.portraitBorderStyleIndex = m.registry.Read("portraitBorderStyleIndex").ToInt()
    if m.portraitBorderStyleIndex < 0 or m.portraitBorderStyleIndex >= m.portraitBorderStyles.Count() then m.portraitBorderStyleIndex = 0

    m.metadataEnabled = (m.registry.Read("metadataEnabled") = "1")
    m.currentSessionMetadata = invalid
    m.transitionInProgress = false
    m.pendingPosterUri = ""
    m.pendingBackgroundUri = ""
    m.savedPosterTranslation = [0, 0]
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

    ' When the title text re-renders, reposition the year label so it sits right after.
    m.nowPlayingTitle.observeField("boundingRect", "positionYearLabel")
    m.portraitNowPlayingTitle.observeField("boundingRect", "positionPortraitYearLabel")

    m.posterFadeOut.observeField("state", "onPosterFadeOutState")
    m.posterFadeIn.observeField("state", "onPosterFadeInState")
    m.posterSlideOut.observeField("state", "onPosterSlideOutState")
    m.posterSlideIn.observeField("state", "onPosterSlideInState")
    m.pollTimer.observeField("fire", "onPollTimerFired")
    m.hideIndicatorTimer.observeField("fire", "hideModeIndicator")
    m.tickTimer.observeField("fire", "onTick")
    m.tickTimer.control = "start"
    m.carouselTimer.observeField("fire", "onCarouselTick")
    m.plexSignInPollTimer.observeField("fire", "onPlexSignInPollTick")

    applyAccentColor()
    applyViewMode()
    startPortraitBorderCutoutDetection()

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

    ' Blocked-ratings overlay: intercept Back to save the current CheckList state
    ' and dismiss. (CheckList captures arrow keys internally so the previous
    ' Save / Cancel buttons were unreachable; saving on Back is the reliable path.)
    if m.blockedRatingsOverlay.visible then
        if key = "back" then
            saveBlockedRatings()
            return true
        end if
        return false
    end if

    ' Plex sign-in overlay: Back cancels the PIN flow and returns to Settings.
    if m.plexSignInOverlay.visible then
        if key = "back" then
            cancelPlexSignIn("")
            return true
        end if
        return true  ' swallow all other keys while the overlay is up
    end if

    ' Expanded "Read more" description modal: Back closes; all other keys
    ' are swallowed so they don't drive the underlying display while reading.
    if m.expandedDescription.visible then
        if key = "back" then
            closeExpandedDescription()
            return true
        end if
        return true
    end if

    ' OK opens the expanded description when metadata is visible AND the
    ' read-more hint is showing (so we don't open an "expanded" modal for
    ' a 30-word summary that's already fully visible).
    if key = "OK" and m.metadataEnabled and m.isPlaying then
        if m.landscapeMetaReadMoreHint.visible or m.portraitMetaReadMoreHint.visible then
            openExpandedDescription()
            return true
        end if
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
    else if key = "left" then
        toggleMetadata()
        return true
    else if key = "options" then
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
    resetPosterTransitions()
    m.poster.loadDisplayMode = "scaleToFit"
    applyPortraitFlip()
    if m.borderEnabled then
        applyBorderedViewMode()
    else
        applyPlainViewMode()
    end if
    applyPortraitPosterBorder()
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
        m.portraitChrome.translation = [-425, 425]
        ' Metadata sits at viewer-TOP — mirrored translation from the chrome strip.
        m.portraitMetadata.rotation = -1.5707963
        m.portraitMetadata.translation = [1200, 360]
    else
        m.portraitChrome.rotation = 1.5707963
        m.portraitChrome.translation = [1265, 425]
        m.portraitMetadata.rotation = 1.5707963
        m.portraitMetadata.translation = [-360, 360]
    end if
end sub

function portraitRotation() as Float
    if m.portraitFlip then return -1.5707963
    return 1.5707963
end function

' Place a centered portrait-fit poster at a target viewer-Y center, accounting
' for the rotation direction (flip mirrors physical-x across screen-center).
sub setPortraitFitPoster(W as Integer, H as Integer, centerYViewer as Integer)
    m.poster.width = W
    m.poster.height = H
    m.poster.scaleRotateCenter = [W / 2, H / 2]
    m.poster.rotation = portraitRotation()
    if m.portraitFlip then
        physX = 1920 - centerYViewer
    else
        physX = centerYViewer
    end if
    m.poster.translation = [physX - W / 2, 540 - H / 2]
end sub

sub applyPlainViewMode()
    m.borderLandscape.visible = false
    m.borderPortrait.visible = false
    if m.viewMode = 0 then
        m.poster.width = 720
        m.poster.height = 1080
        ' Info strip pins to x=0..400, metadata strip pins to x=1520..1920.
        ' Center the poster in whatever's free between them based on what's on.
        leftEdge = 0
        rightEdge = 1920
        if m.infoEnabled then leftEdge = 400
        if m.metadataEnabled and m.isPlaying then rightEdge = 1520
        m.poster.translation = [(leftEdge + rightEdge - 720) / 2, 0]
        m.poster.scaleRotateCenter = [360, 540]
        m.poster.rotation = 0
    else if m.viewMode = 1 then
        m.poster.width = 1920
        m.poster.height = 2880
        m.poster.translation = [0, -900]
        m.poster.scaleRotateCenter = [960, 1440]
        m.poster.rotation = 0
    else if m.viewMode = 2 then
        ' Portrait Fit. The poster needs to fit between whichever panels are
        ' visible: metadata at viewer-top (280px), info at viewer-bottom (230px).
        ' Pick width/height + viewer center based on which panels are active so
        ' the poster always sits cleanly in the available area.
        metaActive = m.metadataEnabled and m.isPlaying
        infoActive = m.infoEnabled
        if metaActive and infoActive then
            ' Sandwiched between meta (top 360) and info (bottom 230). 1330 tall.
            ' 2:3 aspect: width = 886.
            setPortraitFitPoster(886, 1330, 1025)
        else if metaActive then
            ' Meta only: 1560 tall available (360..1920). 2:3 width = 1040.
            setPortraitFitPoster(1040, 1560, 1140)
        else if infoActive then
            setPortraitFitPoster(1080, 1620, 830)
        else
            setPortraitFitPoster(1080, 1620, 960)
        end if
    else if m.viewMode = 3 then
        ' Portrait Fill. The bbox is sized at the poster's content aspect (2:3)
        ' and centered on the available viewer area. Whichever axis is smaller
        ' than the content needs bleeds past the visible area (under panels or
        ' off-screen). Because the bbox aspect matches the content, the poster
        ' never stretches — it fits perfectly inside the bbox.
        m.poster.rotation = portraitRotation()
        contentAspect = 2.0 / 3.0  ' W:H for Plex movie posters
        viewerW = 1080
        metaActive = m.metadataEnabled and m.isPlaying
        if metaActive and m.infoEnabled then
            availTop = 360
            availBottom = 1690
        else if metaActive then
            availTop = 360
            availBottom = 1920
        else if m.infoEnabled then
            availTop = 0
            availBottom = 1690
        else
            availTop = 0
            availBottom = 1920
        end if
        availHeight = availBottom - availTop
        centerY = (availTop + availBottom) / 2

        ' Pick the smaller bbox that fully covers viewerW × availHeight while
        ' keeping the content's 2:3 aspect. Either height-limited (wide bleed)
        ' or width-limited (vertical bleed).
        needHeightForWidth = viewerW / contentAspect
        if availHeight > needHeightForWidth then
            boxH = availHeight
            boxW = Int(availHeight * contentAspect)
        else
            boxH = Int(needHeightForWidth)
            boxW = viewerW
        end if
        setPortraitFitPoster(boxW, boxH, centerY)
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
    else if m.viewMode = 2 or m.viewMode = 3 then
        style = m.portraitBorderStyles[m.portraitBorderStyleIndex]
        m.borderPortrait.uri = style.uri
        if m.viewMode = 2 then
            m.poster.width = style.fitW
            m.poster.height = style.fitH
            m.poster.scaleRotateCenter = style.fitPivot
            m.poster.translation = style.fitT
        else
            m.poster.width = style.fillW
            m.poster.height = style.fillH
            m.poster.scaleRotateCenter = style.fillPivot
            m.poster.translation = style.fillT
        end if
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

    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Settings"
    dialog.message = ["Server: " + serverDisplay, "Token: " + tokenDisplay]
    dialog.buttons = ["Plex Connection", "Display & Appearance", "Close"]
    dialog.observeField("buttonSelected", "onSettingsMenuSelected")
    m.settingsContext = "main"
    m.top.dialog = dialog
end sub

sub onSettingsMenuSelected(event as Object)
    selectedIndex = event.getData()
    m.top.dialog = invalid
    if selectedIndex = 0 then
        openPlexSettings()
    else if selectedIndex = 1 then
        openDisplaySettings()
    else
        cancelSettings()
    end if
end sub

sub openPlexSettings()
    serverDisplay = m.settings.plexServer
    if serverDisplay = "" then serverDisplay = "(not set)"
    tokenDisplay = "(set)"
    if m.settings.plexToken = "" then tokenDisplay = "(not set)"
    ratingsDisplay = m.settings.blockedRatings
    if ratingsDisplay = "" then ratingsDisplay = "(none)"

    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Plex Connection"
    dialog.message = ["Server: " + serverDisplay, "Token: " + tokenDisplay, "Carousel blocks ratings: " + ratingsDisplay]
    dialog.buttons = ["Sign in with Plex", "Change Plex server", "Change Plex token", "Edit carousel rating filter", "Back"]
    dialog.observeField("buttonSelected", "onPlexMenuSelected")
    m.settingsContext = "plex"
    m.top.dialog = dialog
end sub

sub onPlexMenuSelected(event as Object)
    selectedIndex = event.getData()
    m.top.dialog = invalid
    if selectedIndex = 0 then
        startPlexSignIn()
    else if selectedIndex = 1 then
        promptServer()
    else if selectedIndex = 2 then
        promptToken()
    else if selectedIndex = 3 then
        showBlockedRatingsOverlay()
    else
        openSettingsMenu()
    end if
end sub

sub openDisplaySettings()
    flipDisplay = "Top on right (CW mount)"
    if m.portraitFlip then flipDisplay = "Top on left (CCW mount)"
    transitionDisplay = transitionLabel(m.transitionStyle)
    accentDisplay = m.accentColors[m.accentColorIndex].name
    matteDisplay = "Off"
    if m.portraitBorderEnabled then matteDisplay = "On"
    frameStyleDisplay = m.portraitBorderStyles[m.portraitBorderStyleIndex].name

    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Display & Appearance"
    dialog.message = ["Portrait orientation: " + flipDisplay, "Poster transition: " + transitionDisplay, "Accent color: " + accentDisplay, "Portrait poster matte: " + matteDisplay, "Portrait frame style: " + frameStyleDisplay]
    dialog.buttons = ["Cycle poster transition", "Change accent color", "Flip portrait orientation", "Toggle portrait poster matte", "Change portrait frame style", "Back"]
    dialog.observeField("buttonSelected", "onDisplayMenuSelected")
    m.settingsContext = "display"
    m.top.dialog = dialog
end sub

sub onDisplayMenuSelected(event as Object)
    selectedIndex = event.getData()
    m.top.dialog = invalid
    if selectedIndex = 0 then
        cycleTransitionStyle()
        openDisplaySettings()
    else if selectedIndex = 1 then
        showAccentColorMenu()
    else if selectedIndex = 2 then
        togglePortraitFlip()
        openDisplaySettings()
    else if selectedIndex = 3 then
        togglePortraitPosterBorder()
        openDisplaySettings()
    else if selectedIndex = 4 then
        showPortraitFrameStyleMenu()
    else
        openSettingsMenu()
    end if
end sub

' After a sub-dialog (prompt or picker) closes, return to the menu that opened it.
sub returnToSettingsContext()
    if m.settingsContext = "plex" then
        openPlexSettings()
    else if m.settingsContext = "display" then
        openDisplaySettings()
    else
        openSettingsMenu()
    end if
end sub

function transitionLabel(style as String) as String
    if style = "fade" then return "Fade"
    if style = "slide" then return "Slide"
    return "Abrupt"
end function

sub togglePortraitFlip()
    m.portraitFlip = not m.portraitFlip
    state = "0"
    if m.portraitFlip then state = "1"
    m.registry.Write("portraitFlip", state)
    m.registry.Flush()
    applyViewMode()
end sub

sub cycleTransitionStyle()
    if m.transitionStyle = "abrupt" then
        m.transitionStyle = "fade"
    else if m.transitionStyle = "fade" then
        m.transitionStyle = "slide"
    else
        m.transitionStyle = "abrupt"
    end if
    m.registry.Write("transitionStyle", m.transitionStyle)
    m.registry.Flush()
end sub

' Apply the chosen accent (theme) color to every UI element that uses it:
' progress bar fills + metadata taglines on both orientations.
sub applyAccentColor()
    color = m.accentColors[m.accentColorIndex].hex
    m.progressBarFill.color = color
    m.portraitProgressBarFill.color = color
    m.landscapeMetaTagline.color = color
    m.portraitMetaTagline.color = color
end sub

' Spin up the BorderCutoutTask once at startup to measure each portrait
' border's alpha=0 region. Results come back asynchronously and we recompute
' the poster fit/fill geometry from the measured cutouts.
sub startPortraitBorderCutoutDetection()
    uris = []
    for each style in m.portraitBorderStyles
        uris.push(style.uri)
    end for
    m.borderCutoutTask = createObject("roSGNode", "BorderCutoutTask")
    if m.borderCutoutTask = invalid then return
    m.borderCutoutTask.observeField("result", "onBorderCutoutsDetected")
    m.borderCutoutTask.uris = uris
    m.borderCutoutTask.control = "RUN"
end sub

sub onBorderCutoutsDetected(event as Object)
    cutouts = event.getData()
    if cutouts = invalid then return
    for each c in cutouts
        if c.w > 0 and c.h > 0 then
            for each style in m.portraitBorderStyles
                if style.uri = c.uri then
                    applyCutoutToStyle(style, c)
                    exit for
                end if
            end for
        end if
    end for
    ' Refresh the screen so the active border picks up the new geometry.
    applyViewMode()
end sub

' Given a measured cutout, derive fit/fill poster geometry. The poster is
' rotated ±π/2 around its center, so pre-rotation (width × height) maps to
' post-rotation (height × width) on screen. Pre-rotation width = cutout
' height; pre-rotation height = cutout width. Fill mode is 1.35× fit so the
' poster bleeds past the cutout edges (the frame covers the overflow).
sub applyCutoutToStyle(style as Object, cutout as Object)
    cw = cutout.w
    ch = cutout.h
    centerX = cutout.x + cw / 2
    centerY = cutout.y + ch / 2

    style.fitW = ch
    style.fitH = cw
    style.fitPivot = [ch / 2, cw / 2]
    style.fitT = [centerX - ch / 2, centerY - cw / 2]

    fillFactor = 1.35
    fillW = Int(ch * fillFactor)
    fillH = Int(cw * fillFactor)
    style.fillW = fillW
    style.fillH = fillH
    style.fillPivot = [fillW / 2, fillH / 2]
    style.fillT = [centerX - fillW / 2, centerY - fillH / 2]
end sub

sub showAccentColorMenu()
    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Accent Color"
    dialog.message = ["Current: " + m.accentColors[m.accentColorIndex].name]
    buttons = []
    for each c in m.accentColors
        buttons.push(c.name)
    end for
    buttons.push("Cancel")
    dialog.buttons = buttons
    dialog.observeField("buttonSelected", "onAccentColorSelected")
    m.top.dialog = dialog
end sub

sub onAccentColorSelected(event as Object)
    selectedIndex = event.getData()
    m.top.dialog = invalid
    if selectedIndex >= 0 and selectedIndex < m.accentColors.Count() then
        m.accentColorIndex = selectedIndex
        m.registry.Write("accentColorIndex", m.accentColorIndex.ToStr())
        m.registry.Flush()
        applyAccentColor()
    end if
    returnToSettingsContext()
end sub

sub showPortraitFrameStyleMenu()
    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Portrait Frame Style"
    dialog.message = ["Current: " + m.portraitBorderStyles[m.portraitBorderStyleIndex].name]
    buttons = []
    for each s in m.portraitBorderStyles
        buttons.push(s.name)
    end for
    buttons.push("Cancel")
    dialog.buttons = buttons
    dialog.observeField("buttonSelected", "onPortraitFrameStyleSelected")
    m.top.dialog = dialog
end sub

sub onPortraitFrameStyleSelected(event as Object)
    selectedIndex = event.getData()
    m.top.dialog = invalid
    if selectedIndex >= 0 and selectedIndex < m.portraitBorderStyles.Count() then
        m.portraitBorderStyleIndex = selectedIndex
        m.registry.Write("portraitBorderStyleIndex", m.portraitBorderStyleIndex.ToStr())
        m.registry.Flush()
        applyViewMode()
    end if
    returnToSettingsContext()
end sub

sub togglePortraitPosterBorder()
    m.portraitBorderEnabled = not m.portraitBorderEnabled
    state = "0"
    if m.portraitBorderEnabled then state = "1"
    m.registry.Write("portraitBorderEnabled", state)
    m.registry.Flush()
    applyViewMode()
end sub

' Left-button metadata overlay. In Fit modes the poster shifts to make room
' for the metadata panel; in Fill modes the panel floats translucently over
' the poster (so the artwork keeps its bleed).
sub toggleMetadata()
    m.metadataEnabled = not m.metadataEnabled
    state = "0"
    if m.metadataEnabled then state = "1"
    m.registry.Write("metadataEnabled", state)
    m.registry.Flush()
    applyViewMode()
    label = "Metadata: Off"
    if m.metadataEnabled then label = "Metadata: On"
    showModeIndicator(label)
end sub

' Open the full-screen "Read more" modal with the current session's full
' description + a recap of the chrome (title, tagline, stats). Pauses the
' carousel timer so it doesn't advance behind the modal.
sub openExpandedDescription()
    if m.currentSessionMetadata = invalid then return

    ' Recover the current title from whichever chrome label is on screen.
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    if isLandscape then
        title = m.nowPlayingTitle.text
    else
        title = m.portraitNowPlayingTitle.text
    end if

    meta = m.currentSessionMetadata

    m.expandedTitle.text = title
    m.expandedTagline.text = m.landscapeMetaTagline.text  ' already uppercased
    m.expandedTagline.color = m.accentColors[m.accentColorIndex].hex

    ' Modal stats line: UPPERCASE and includes the content rating between year
    ' and runtime. The metadata strip stats (no rating, mixed case) stays as-is.
    modalParts = []
    if meta.year <> "" then modalParts.push(meta.year)
    if meta.contentRating <> "" then modalParts.push(meta.contentRating)
    if meta.duration > 0 then modalParts.push(formatRuntime(meta.duration))
    if meta.genres <> "" then modalParts.push(meta.genres)
    m.expandedStats.text = UCase(joinSeparator(modalParts, "  ·  "))

    m.expandedDirector.text = labeledLine("Directed by", meta.directors)
    m.expandedWriter.text = labeledLine("Written by", meta.writers)
    m.expandedCast.text = labeledLine("Starring", meta.cast)
    m.expandedStudio.text = labeledLine("Studio", meta.studio)
    m.expandedReleased.text = labeledLine("Released", formatReleaseDate(meta.releaseDate))

    m.expandedDirector.visible = (meta.directors <> "")
    m.expandedWriter.visible = (meta.writers <> "")
    m.expandedCast.visible = (meta.cast <> "")
    m.expandedStudio.visible = (meta.studio <> "")
    m.expandedReleased.visible = (meta.releaseDate <> "")

    m.expandedSummary.text = meta.summary

    ' Ratings section: Plex is populated immediately from the session
    ' metadata; IMDb / Rotten Tomatoes / Metacritic come from OMDB and arrive
    ' asynchronously. Show "—" placeholders until the OMDB task returns.
    accent = m.accentColors[m.accentColorIndex].hex
    m.ratingPlexValue.color = accent
    m.ratingImdbValue.color = accent
    m.ratingRtValue.color = accent
    m.ratingMetaValue.color = accent
    if meta.audienceRating <> "" then
        m.ratingPlexValue.text = meta.audienceRating + "/10"
    else
        m.ratingPlexValue.text = "—"
    end if
    m.ratingImdbValue.text = "—"
    m.ratingRtValue.text = "—"
    m.ratingMetaValue.text = "—"

    fetchOmdbRatings(meta.imdbId)

    if m.carouselEnabled then m.carouselTimer.control = "stop"
    m.expandedDescription.visible = true
end sub

' Spin up OMDBTask if we have an IMDB id to look up. Result is observed and
' applied to the rating labels when it arrives.
sub fetchOmdbRatings(imdbId as String)
    if imdbId = "" then return
    task = createObject("roSGNode", "OMDBTask")
    if task = invalid then return
    task.observeField("result", "onOmdbResult")
    task.apiKey = m.omdbApiKey
    task.imdbId = imdbId
    task.control = "RUN"
end sub

sub onOmdbResult(event as Object)
    result = event.getData()
    if result = invalid or not result.ok then return
    if not m.expandedDescription.visible then return  ' user closed before we returned

    if result.imdbRating <> "" then m.ratingImdbValue.text = result.imdbRating + "/10"
    if result.rottenTomatoes <> "" then m.ratingRtValue.text = result.rottenTomatoes
    if result.metacritic <> "" then m.ratingMetaValue.text = result.metacritic
end sub

' "Directed by " + "Steven Spielberg" -> "Directed by Steven Spielberg"; if the
' value is empty, returns empty so the caller can hide the line.
function labeledLine(label as String, value as String) as String
    if value = "" then return ""
    return label + " " + value
end function

' Convert Plex's ISO-style "YYYY-MM-DD" date into "Month DD, YYYY".
function formatReleaseDate(d as String) as String
    if d = "" then return ""
    if Len(d) < 10 then return d
    yearStr = d.Mid(0, 4)
    monthStr = d.Mid(5, 2)
    dayStr = d.Mid(8, 2)
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    monthIdx = monthStr.ToInt() - 1
    if monthIdx < 0 or monthIdx >= 12 then return d
    return months[monthIdx] + " " + dayStr.ToInt().ToStr() + ", " + yearStr
end function

sub closeExpandedDescription()
    m.expandedDescription.visible = false
    if m.carouselEnabled and not m.carouselPaused then
        m.carouselTimer.control = "start"
    end if
end sub

' Snapshot the current session's metadata so we can show it whenever the user
' toggles the panel — even between Plex poll refreshes.
sub setMetadataFromSession(sessionInfo as Object)
    m.currentSessionMetadata = {
        tagline: sessionInfo.tagline,
        summary: sessionInfo.summary,
        studio: sessionInfo.studio,
        releaseDate: sessionInfo.releaseDate,
        directors: sessionInfo.directors,
        writers: sessionInfo.writers,
        cast: sessionInfo.cast,
        genres: sessionInfo.genres,
        year: sessionInfo.year,
        duration: sessionInfo.duration,
        contentRating: sessionInfo.contentRating,
        audienceRating: sessionInfo.audienceRating,
        imdbId: stringOrEmptyAny(sessionInfo.imdbId)
    }

    ' Stats line: year · runtime · genres. The Plex audience rating moves to
    ' the dedicated Ratings section in the expanded modal instead.
    statsParts = []
    if sessionInfo.year <> "" then statsParts.push(sessionInfo.year)
    if sessionInfo.duration > 0 then statsParts.push(formatRuntime(sessionInfo.duration))
    if sessionInfo.genres <> "" then statsParts.push(sessionInfo.genres)
    stats = joinSeparator(statsParts, "  ·  ")

    taglineUpper = ""
    if sessionInfo.tagline <> "" then taglineUpper = UCase(sessionInfo.tagline)

    ' Landscape panel
    m.landscapeMetaTagline.text = taglineUpper
    m.landscapeMetaStats.text = stats
    m.landscapeMetaSummary.text = sessionInfo.summary

    ' Portrait panel
    m.portraitMetaTagline.text = taglineUpper
    m.portraitMetaStats.text = stats
    m.portraitMetaSummary.text = sessionInfo.summary

    ' Read More always available — there's always something extra to see in
    ' the modal (full slogan, cast, writers, etc.) even when the panel summary
    ' looks complete.
    m.landscapeMetaReadMoreHint.visible = true
    m.portraitMetaReadMoreHint.visible = true
end sub

' Format a duration in ms as "Xh Ym" or "Ym" if under an hour.
function formatRuntime(ms as Integer) as String
    totalMins = Int(ms / 60000)
    if totalMins < 60 then return totalMins.ToStr() + "m"
    h = Int(totalMins / 60)
    m_ = totalMins mod 60
    if m_ = 0 then return h.ToStr() + "h"
    return h.ToStr() + "h " + m_.ToStr() + "m"
end function

function joinSeparator(parts as Object, sep as String) as String
    if parts = invalid or parts.Count() = 0 then return ""
    out = parts[0]
    for i = 1 to parts.Count() - 1
        out = out + sep + parts[i]
    end for
    return out
end function

' Render a thick black matte around the portrait poster when enabled. The matte
' is four separate strips (top/bottom/left/right) inside a Group that shares
' the poster's rotation + center; the inner region is sized to the Plex poster
' content aspect (2:3) so the matte appears visually uniform on all sides
' instead of getting padded by scaleToFit on the top/bottom. When info is on
' the viewer-bottom strip hides because the chrome strip already provides a
' black band there. Hidden in landscape modes and whenever the theater border
' is on (that PNG provides its own frame).
sub applyPortraitPosterBorder()
    isPortrait = (m.viewMode = 2 or m.viewMode = 3)
    showBorder = m.portraitBorderEnabled and isPortrait and not m.borderEnabled
    m.portraitPosterBorderGroup.visible = showBorder
    if not showBorder then return

    thickness = 60
    contentAspect = 2.0 / 3.0

    posterT = m.poster.translation
    outerW = m.poster.width
    outerH = m.poster.height
    posterCenter = [posterT[0] + outerW / 2, posterT[1] + outerH / 2]

    ' Largest 2:3 (W:H) box that fits inside outer minus `thickness` on each side.
    maxInnerW = outerW - thickness * 2
    maxInnerH = outerH - thickness * 2
    innerW = maxInnerW
    innerH = innerW / contentAspect
    if innerH > maxInnerH then
        innerH = maxInnerH
        innerW = innerH * contentAspect
    end if

    matteW = innerW + thickness * 2
    matteH = innerH + thickness * 2

    m.portraitPosterBorderGroup.scaleRotateCenter = [matteW / 2, matteH / 2]
    m.portraitPosterBorderGroup.translation = [posterCenter[0] - matteW / 2, posterCenter[1] - matteH / 2]
    m.portraitPosterBorderGroup.rotation = m.poster.rotation

    m.portraitPosterBorderTop.translation = [0, 0]
    m.portraitPosterBorderTop.width = matteW
    m.portraitPosterBorderTop.height = thickness

    m.portraitPosterBorderBottom.translation = [0, matteH - thickness]
    m.portraitPosterBorderBottom.width = matteW
    m.portraitPosterBorderBottom.height = thickness

    m.portraitPosterBorderLeft.translation = [0, 0]
    m.portraitPosterBorderLeft.width = thickness
    m.portraitPosterBorderLeft.height = matteH

    m.portraitPosterBorderRight.translation = [matteW - thickness, 0]
    m.portraitPosterBorderRight.width = thickness
    m.portraitPosterBorderRight.height = matteH

    ' For both flip orientations, the pre-rotation TOP edge (local y=0) ends up
    ' at the viewer's bottom — that's the side that overlaps the chrome strip
    ' when info is on, so hide it then.
    m.portraitPosterBorderTop.visible = not m.infoEnabled

    m.poster.width = innerW
    m.poster.height = innerH
    m.poster.scaleRotateCenter = [innerW / 2, innerH / 2]
    m.poster.translation = [posterCenter[0] - innerW / 2, posterCenter[1] - innerH / 2]
    ' Fill the matte's inner box even for off-aspect posters (square album art,
    ' 4:3 covers, etc.) so the matte stays a clean uniform frame. Without this
    ' override, scaleToFit would letterbox the content inside the 2:3 inner box.
    ' (Note: zoomToFill preserves aspect and crops; scaleToFill stretches.)
    m.poster.loadDisplayMode = "zoomToFill"
end sub

' Swap the main poster (and ambient backdrop) to new images, optionally animated.
' Carousel ticks and Plex playback updates funnel through here so the
' transition style picked in Settings is honored everywhere.
sub transitionPoster(newUri as String, newBackgroundUri as String)
    if newUri = "" then return
    if m.poster.uri = newUri then return
    if m.transitionInProgress then
        ' A transition is already running — let it finish but update the
        ' pending target so the very next frame snaps in the latest poster.
        m.pendingPosterUri = newUri
        m.pendingBackgroundUri = newBackgroundUri
        return
    end if

    if m.transitionStyle = "abrupt" then
        m.poster.uri = newUri
        m.backgroundPoster.uri = newBackgroundUri
        return
    end if

    m.pendingPosterUri = newUri
    m.pendingBackgroundUri = newBackgroundUri
    m.transitionInProgress = true

    if m.transitionStyle = "fade" then
        m.posterFadeOut.control = "start"
    else if m.transitionStyle = "slide" then
        m.savedPosterTranslation = m.poster.translation
        offX = m.savedPosterTranslation[0]
        offY = m.savedPosterTranslation[1]
        delta = slideOutDelta()
        m.posterSlideOutInterp.keyValue = [[offX, offY], [offX + delta[0], offY + delta[1]]]
        m.posterSlideOut.control = "start"
    end if
end sub

' Compute the slide-out translation delta in physical coordinates so the poster
' always exits toward viewer-LEFT (regardless of the rotation applied for
' portrait modes). For landscape the poster isn't rotated, so a screen-x shift
' looks horizontal directly. For portrait non-flip (rotation +π/2 CCW), viewer-x
' maps to (1080 - physical-y), so sliding viewer-left = increasing physical-y.
' For portrait flip (rotation -π/2 CW), viewer-x = physical-y, so viewer-left =
' decreasing physical-y.
function slideOutDelta() as Object
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    if isLandscape then return [-2000, 0]
    if m.portraitFlip then return [0, -2000]
    return [0, 2000]
end function

sub onPosterFadeOutState(event as Object)
    if event.getData() <> "stopped" then return
    if not m.transitionInProgress then return
    m.poster.uri = m.pendingPosterUri
    m.backgroundPoster.uri = m.pendingBackgroundUri
    m.posterFadeIn.control = "start"
end sub

sub onPosterFadeInState(event as Object)
    if event.getData() <> "stopped" then return
    m.transitionInProgress = false
end sub

sub onPosterSlideOutState(event as Object)
    if event.getData() <> "stopped" then return
    if not m.transitionInProgress then return
    m.poster.uri = m.pendingPosterUri
    m.backgroundPoster.uri = m.pendingBackgroundUri
    offX = m.savedPosterTranslation[0]
    offY = m.savedPosterTranslation[1]
    delta = slideOutDelta()
    ' Slide-in enters from the OPPOSITE side, so its starting offset is -delta.
    startX = offX - delta[0]
    startY = offY - delta[1]
    m.poster.translation = [startX, startY]
    m.posterSlideInInterp.keyValue = [[startX, startY], [offX, offY]]
    m.posterSlideIn.control = "start"
end sub

sub onPosterSlideInState(event as Object)
    if event.getData() <> "stopped" then return
    m.transitionInProgress = false
end sub

' Cancel any running poster transition. Called from applyViewMode before we
' reposition / resize the poster so the animation can't fight the new layout.
sub resetPosterTransitions()
    m.transitionInProgress = false
    m.posterFadeOut.control = "stop"
    m.posterFadeIn.control = "stop"
    m.posterSlideOut.control = "stop"
    m.posterSlideIn.control = "stop"
    m.poster.opacity = 1.0
    m.backgroundPoster.opacity = 0.18
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

sub saveBlockedRatings()
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

sub closeBlockedRatingsOverlay()
    m.blockedRatingsOverlay.visible = false
    refocusSettings()
    returnToSettingsContext()
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
    transitionPoster(item.posterUri, item.backgroundUri)
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    m.backgroundPoster.visible = isLandscape and (item.backgroundUri <> "")
    itemYear = ""
    if item.year <> invalid then itemYear = item.year
    itemRating = ""
    if item.contentRating <> invalid then itemRating = item.contentRating
    setNowPlayingTitle(item.title, "", itemYear, itemRating)
    m.titleMarqueeLabel.text = UCase(item.title)
    m.isPlaying = true
    m.duration = 0
    m.hasEpisodePoster = false
    ' Library items carry the same metadata fields as session items (extracted
    ' by PlexLibraryTask), so we can reuse the same overlay setter.
    setMetadataFromSession(carouselItemAsMetadata(item))
    updateInfoVisibility()
end sub

' Normalize a carousel item into the shape setMetadataFromSession expects.
' PlexLibraryTask doesn't expose `state` and never has a duration > 0 right
' now (we don't track playback progress on library items), so we fill those
' with safe defaults.
function carouselItemAsMetadata(item as Object) as Object
    return {
        tagline: stringOrEmptyAny(item.tagline),
        summary: stringOrEmptyAny(item.summary),
        studio: stringOrEmptyAny(item.studio),
        releaseDate: stringOrEmptyAny(item.releaseDate),
        directors: stringOrEmptyAny(item.directors),
        writers: stringOrEmptyAny(item.writers),
        cast: stringOrEmptyAny(item.cast),
        genres: stringOrEmptyAny(item.genres),
        year: stringOrEmptyAny(item.year),
        duration: intOrZeroAny(item.duration),
        contentRating: stringOrEmptyAny(item.contentRating),
        audienceRating: stringOrEmptyAny(item.audienceRating),
        imdbId: stringOrEmptyAny(item.imdbId)
    }
end function

function stringOrEmptyAny(v as Dynamic) as String
    if v = invalid then return ""
    return v
end function

function intOrZeroAny(v as Dynamic) as Integer
    if v = invalid then return 0
    return v
end function

' Entry point for the Settings flow. Tries Plex GDM discovery first so the user
' can pick a server from a list rather than typing an IP. Falls back to manual
' URL entry if nothing's found or the user opts out.
' ----- Plex.tv sign-in (PIN flow) -----
' Replaces the manual token entry for users who'd rather log into Plex on
' their phone/computer. Flow: request a 4-char PIN, display it with the
' plex.tv/link URL, poll Plex.tv every few seconds for the user to enter the
' code, then list the user's Plex servers and let them pick one.

sub startPlexSignIn()
    m.plexPinId = ""
    m.plexPinCode = ""
    m.plexAuthToken = ""
    m.plexSignInCodeLabel.text = "----"
    m.plexSignInStatusLabel.text = "Requesting code..."
    m.plexSignInOverlay.visible = true

    task = createObject("roSGNode", "PlexAuthTask")
    if task = invalid then
        cancelPlexSignIn("Plex sign-in unavailable on this device.")
        return
    end if
    task.observeField("result", "onPlexPinRequested")
    task.mode = "requestPin"
    task.clientId = m.plexClientId
    task.control = "RUN"
end sub

sub onPlexPinRequested(event as Object)
    result = event.getData()
    if result = invalid or not result.ok then
        cancelPlexSignIn("Couldn't reach Plex.tv. Try again later.")
        return
    end if
    m.plexPinId = result.pinId
    m.plexPinCode = result.pinCode
    m.plexSignInCodeLabel.text = UCase(result.pinCode)
    m.plexSignInStatusLabel.text = "Waiting for authorization..."
    m.plexSignInPollTimer.control = "start"
end sub

sub onPlexSignInPollTick()
    if not m.plexSignInOverlay.visible then
        m.plexSignInPollTimer.control = "stop"
        return
    end if
    if m.plexPinId = "" then return

    task = createObject("roSGNode", "PlexAuthTask")
    if task = invalid then return
    task.observeField("result", "onPlexPinPolled")
    task.mode = "pollPin"
    task.clientId = m.plexClientId
    task.pinId = m.plexPinId
    task.pinCode = m.plexPinCode
    task.control = "RUN"
end sub

sub onPlexPinPolled(event as Object)
    result = event.getData()
    if result = invalid then return
    if result.expired then
        cancelPlexSignIn("Code expired. Please try again.")
        return
    end if
    if not result.ok then return  ' transient — keep polling
    if result.authToken = "" then return  ' user hasn't entered the code yet

    ' Got a token! Fetch the user's server list.
    m.plexSignInPollTimer.control = "stop"
    m.plexAuthToken = result.authToken
    m.plexSignInStatusLabel.text = "Signed in. Loading servers..."

    task = createObject("roSGNode", "PlexAuthTask")
    if task = invalid then
        cancelPlexSignIn("Couldn't load servers.")
        return
    end if
    task.observeField("result", "onPlexServersListed")
    task.mode = "listServers"
    task.clientId = m.plexClientId
    task.plexToken = m.plexAuthToken
    task.control = "RUN"
end sub

sub onPlexServersListed(event as Object)
    result = event.getData()
    if result = invalid or not result.ok then
        cancelPlexSignIn("Couldn't load your Plex servers.")
        return
    end if
    if result.servers.Count() = 0 then
        cancelPlexSignIn("No Plex servers found on your account.")
        return
    end if

    m.plexServerChoices = result.servers
    m.plexSignInOverlay.visible = false

    dialog = createObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Choose a Plex Server"
    dialog.message = ["Pick the server this display should use."]
    buttons = []
    for each s in result.servers
        label = s.name
        if not s.owned then label = label + " (shared)"
        buttons.push(label)
    end for
    buttons.push("Cancel")
    dialog.buttons = buttons
    dialog.observeField("buttonSelected", "onPlexServerChosen")
    m.top.dialog = dialog
end sub

sub onPlexServerChosen(event as Object)
    idx = event.getData()
    m.top.dialog = invalid
    if idx < 0 or idx >= m.plexServerChoices.Count() then
        returnToSettingsContext()
        return
    end if
    server = m.plexServerChoices[idx]
    m.settings.plexServer = server.url
    m.settings.plexToken = server.accessToken
    m.registry.Write("plexServer", server.url)
    m.registry.Write("plexToken", server.accessToken)
    m.registry.Flush()
    m.carouselPosters = []
    returnToSettingsContext()
end sub

sub cancelPlexSignIn(msg as String)
    m.plexSignInPollTimer.control = "stop"
    m.plexSignInOverlay.visible = false
    m.plexPinId = ""
    m.plexPinCode = ""
    if msg <> "" then setStatusMessage(msg)
    returnToSettingsContext()
end sub

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
    dialog.message = ["These servers responded on your network. Pick one or enter a URL manually."]

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
        returnToSettingsContext()
    else if selectedIndex = numServers then
        promptServerManual()
    else
        returnToSettingsContext()
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
        returnToSettingsContext()
        return
    end if

    normalized = normalizeServer(enteredText)
    if normalized = "" then
        setStatusMessage("Invalid Plex server URL. Try again.")
        returnToSettingsContext()
        return
    end if

    m.settings.plexServer = normalized
    m.registry.Write("plexServer", normalized)
    m.registry.Flush()
    m.carouselPosters = []
    returnToSettingsContext()
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
    returnToSettingsContext()
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

    transitionPoster(sessionInfo.posterUri, sessionInfo.backgroundUri)
    isLandscape = (m.viewMode = 0 or m.viewMode = 1)
    m.backgroundPoster.visible = isLandscape and (sessionInfo.backgroundUri <> "")
    setNowPlayingTitle(sessionInfo.title, sessionInfo.showName, sessionInfo.year, sessionInfo.contentRating)

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
    setMetadataFromSession(sessionInfo)
    updateInfoVisibility()
    if m.duration > 0 then renderProgress(m.viewOffset)
end sub

sub setStatusMessage(text as String)
    m.messageLabel.text = text
    m.portraitMessageLabel.text = text
    m.isPlaying = false
    updateInfoVisibility()
end sub

sub setNowPlayingTitle(title as String, showName as String, year as String, contentRating as String)
    fullTitle = title
    if showName <> "" and title <> "" then
        fullTitle = showName + " — " + title
    else if showName <> "" then
        fullTitle = showName
    end if

    upperTitle = UCase(fullTitle)
    yearText = ""
    if year <> "" and year <> "0" then yearText = year

    ' Rating: prefer a PNG icon, fall back to bracketed text if none exists for
    ' this rating (TV-Y / TV-Y7 currently have no icon, for example).
    iconInfo = getRatingIcon(contentRating)
    if iconInfo <> invalid then
        m.ratingIcon.uri = iconInfo.uri
        m.ratingIcon.width = Int(56 * iconInfo.aspect)
        m.ratingIcon.height = 56
        m.portraitRatingIcon.uri = iconInfo.uri
        m.portraitRatingIcon.width = Int(48 * iconInfo.aspect)
        m.portraitRatingIcon.height = 48
        m.nowPlayingPrefix.text = ""
        m.portraitNowPlayingPrefix.text = ""
    else
        m.ratingIcon.uri = ""
        m.portraitRatingIcon.uri = ""
        prefixText = ""
        if contentRating <> "" then prefixText = "[" + UCase(contentRating) + "]"
        m.nowPlayingPrefix.text = prefixText
        m.portraitNowPlayingPrefix.text = prefixText
    end if

    m.nowPlayingTitle.text = upperTitle
    m.portraitNowPlayingTitle.text = upperTitle
    m.nowPlayingYear.text = yearText
    m.portraitNowPlayingYear.text = yearText
end sub

' Year-label positioning helpers. boundingRect on Roku Labels isn't always
' fresh when read synchronously (or even observable on some firmwares), so we
' use the rendered-text width when it's valid and otherwise fall back to a
' text-length × average-char-width estimate based on Oswald Bold metrics.
' That keeps the year glued right after the title even before the first paint
' completes for a new title.
sub positionYearLabel()
    ' Landscape chrome is now a vertical left strip — the year sits at a fixed
    ' position below the wrapped title, not horizontally next to it. No-op here.
end sub

sub positionPortraitYearLabel()
    yearY = m.portraitNowPlayingYear.translation[1]
    titleX = m.portraitNowPlayingTitle.translation[0]
    width = measuredOrEstimatedTextWidth(m.portraitNowPlayingTitle, 20)
    m.portraitNowPlayingYear.translation = [titleX + width + 20, yearY]
end sub

' On-device Roku returns boundingRect as an AA with x/y/width/height fields.
' The BrightScript Simulator exposes it as a callable method instead, so we
' handle either shape. If neither yields a positive width we fall back to a
' text-length * average-char-width estimate.
function measuredOrEstimatedTextWidth(label as Object, avgCharWidth as Integer) as Integer
    rect = label.boundingRect
    if type(rect) = "Function" or type(rect) = "roFunction" then rect = rect()
    if type(rect) = "roAssociativeArray" and rect.width <> invalid and rect.width > 0 then
        return rect.width
    end if
    return estimatedTextWidth(label.text, avgCharWidth)
end function

' Rough text-width estimator for Oswald Bold uppercase. The avg-char-width
' value should be a tiny bit larger than the real average so the year never
' visually crowds the title.
function estimatedTextWidth(text as String, avgCharWidth as Integer) as Integer
    if text = invalid or text = "" then return 0
    return text.Len() * avgCharWidth
end function

' Map a Plex contentRating string to the bundled rating PNG. Returns invalid
' when no icon exists for that rating (caller falls back to a text badge).
function getRatingIcon(rating as String) as Object
    nrIcon = { uri: "pkg:/images/ratings/rating_nr.png", aspect: 1.0 }
    if rating = invalid then return nrIcon
    r = LCase(rating).Trim()
    slash = Instr(1, r, "/")
    if slash > 0 then r = r.Mid(slash + 1).Trim()
    if r = "" or r = "unrated" or r = "not rated" or r = "nr" then return nrIcon
    if r = "g" then return { uri: "pkg:/images/ratings/rating_g.png", aspect: 1.0 }
    if r = "pg" then return { uri: "pkg:/images/ratings/rating_pg.png", aspect: 1.0 }
    if r = "pg-13" then return { uri: "pkg:/images/ratings/rating_pg13.png", aspect: 1.5 }
    if r = "r" then return { uri: "pkg:/images/ratings/rating_r.png", aspect: 1.0 }
    if r = "nc-17" then return { uri: "pkg:/images/ratings/rating_nc17.png", aspect: 1.5 }
    if r = "xxx" then return { uri: "pkg:/images/ratings/rating_xxx.png", aspect: 1.5 }
    if r = "tv-y" then return { uri: "pkg:/images/ratings/rating_tvy.png", aspect: 1.0 }
    if r = "tv-y7" then return { uri: "pkg:/images/ratings/rating_tvy7.png", aspect: 1.0 }
    if r = "tv-g" then return { uri: "pkg:/images/ratings/rating_tvg.png", aspect: 1.0 }
    if r = "tv-pg" then return { uri: "pkg:/images/ratings/rating_tvpg.png", aspect: 1.0 }
    if r = "tv-14" then return { uri: "pkg:/images/ratings/rating_tv14.png", aspect: 1.5 }
    if r = "tv-ma" then return { uri: "pkg:/images/ratings/rating_tvma.png", aspect: 1.0 }
    return invalid
end function

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
    return Stri(h) + ":" + padTwo(mins) + ampm
end function

sub renderProgress(positionMs as Integer)
    currentText = formatTime(positionMs)
    totalText = formatTime(m.duration)

    m.currentTimeLabel.text = currentText
    m.totalTimeLabel.text = totalText
    m.portraitCurrentTimeLabel.text = currentText
    m.portraitTotalTimeLabel.text = totalText

    if m.duration > 0 then
        ratio = positionMs / m.duration
        if ratio < 0 then ratio = 0
        if ratio > 1 then ratio = 1
        landscapeW = Int(ratio * 360)
        if landscapeW < 1 then landscapeW = 1
        portraitW = Int(ratio * 690)
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

    ' Landscape: the vertical left strip hides when the theater marquee is on
    ' (the marquee handles title + brand by itself). Otherwise it's always
    ' visible when chrome is — backgrounds are now solid black.
    m.landscapeChrome.visible = m.landscapeChrome.visible and not marqueeVisible
    showLandscapeStatus = m.landscapeChrome.visible
    m.overlay.visible = showLandscapeStatus
    m.messageLabel.visible = showLandscapeStatus and not m.isPlaying
    landscapeRatingShown = showLandscapeStatus and m.isPlaying
    m.ratingIcon.visible = landscapeRatingShown and (m.ratingIcon.uri <> "")
    m.nowPlayingPrefix.visible = landscapeRatingShown and (m.ratingIcon.uri = "") and (m.nowPlayingPrefix.text <> "")
    m.nowPlayingTitle.visible = showLandscapeStatus and m.isPlaying
    ' Year lives in the metadata panel now — keep it out of the info chrome.
    m.nowPlayingYear.visible = false
    m.clockLabel.visible = showLandscapeStatus

    ' Portrait: same identical layout in both modes.
    portraitRatingShown = m.portraitChrome.visible and m.isPlaying
    m.portraitMessageLabel.visible = m.portraitChrome.visible and not m.isPlaying
    m.portraitRatingIcon.visible = portraitRatingShown and (m.portraitRatingIcon.uri <> "")
    m.portraitNowPlayingPrefix.visible = portraitRatingShown and (m.portraitRatingIcon.uri = "") and (m.portraitNowPlayingPrefix.text <> "")
    m.portraitNowPlayingTitle.visible = m.portraitChrome.visible and m.isPlaying
    ' Year lives in the metadata panel now — keep it out of the info chrome.
    m.portraitNowPlayingYear.visible = false

    ' Width of whatever fills the rating slot — the PNG icon if we have one
    ' (variable, depends on aspect), otherwise the fixed-width text badge.
    landscapeRatingWidth = 160
    if m.ratingIcon.uri <> "" then landscapeRatingWidth = m.ratingIcon.width
    portraitRatingWidth = 120
    if m.portraitRatingIcon.uri <> "" then portraitRatingWidth = m.portraitRatingIcon.width

    ' Landscape: vertical left strip. Rating icon centered above the title;
    ' title wraps centered in the strip; year sits at fixed Y below title.
    ' (Sizing for the icon comes from getRatingIcon — variable width because
    ' some ratings use 3:2 wide PNGs and others are square.)
    iconY = 50
    landscapeRatingX = (400 - landscapeRatingWidth) / 2
    m.ratingIcon.translation = [landscapeRatingX, iconY]
    m.nowPlayingPrefix.translation = [20, iconY]  ' text prefix uses full strip width
    m.nowPlayingTitle.translation = [20, 140]
    m.nowPlayingTitle.width = 360
    m.nowPlayingTitle.horizAlign = "center"

    ' Vertical layout inside the 230-tall strip:
    '   With progress: 50 top + 32 progress + 50 gap + 48 row + 50 bottom (progress y=50, row y=132)
    '   Without progress (live stream, no duration yet): row alone centered at y=91
    hasPortraitProgress = (m.infoEnabled and not isLandscape and m.duration > 0)
    portraitRowY = 132
    if not hasPortraitProgress then portraitRowY = 91

    m.portraitRatingIcon.translation = [90, portraitRowY]
    m.portraitNowPlayingPrefix.translation = [90, portraitRowY]
    portraitTitleX = 90 + portraitRatingWidth + 20
    m.portraitNowPlayingTitle.translation = [portraitTitleX, portraitRowY]
    m.portraitNowPlayingTitle.width = 780 - portraitTitleX
    m.portraitNowPlayingTitle.horizAlign = "left"
    yearX = m.portraitNowPlayingYear.translation[0]
    m.portraitNowPlayingYear.translation = [yearX, portraitRowY]
    clockX = m.portraitClockLabel.translation[0]
    m.portraitClockLabel.translation = [clockX, portraitRowY]
    ' Clock only renders alongside the now-playing row, so when nothing is
    ' playing the message label can sit cleanly centered without a stray clock
    ' on the right pulling the eye off-center.
    m.portraitClockLabel.visible = m.portraitChrome.visible and m.isPlaying

    ' Settings button (60 tall) sits centered on the row (48 tall): rowY + (48-60)/2 = rowY - 6
    settingsY = portraitRowY - 6
    m.portraitSettingsButton.translation = [m.portraitSettingsButton.translation[0], settingsY]
    m.portraitSettingsButtonBg.translation = [m.portraitSettingsButtonBg.translation[0], settingsY]

    if chromeVisible then updateClock()

    ' Marquee + progress
    m.titleMarquee.visible = marqueeVisible
    m.progressGroup.visible = m.infoEnabled and isLandscape and m.duration > 0
    m.portraitProgressGroup.visible = m.infoEnabled and not isLandscape and m.duration > 0

    ' Episode thumbnail (TV episodes in landscape mode when info is on)
    m.episodePosterGroup.visible = m.infoEnabled and isLandscape and m.hasEpisodePoster

    ' Metadata panel (Left key toggle). Only meaningful when something's actually
    ' playing — otherwise there's nothing to describe.
    metadataActive = m.metadataEnabled and m.isPlaying
    m.landscapeMetadata.visible = metadataActive and isLandscape
    m.portraitMetadata.visible = metadataActive and not isLandscape

    ' App logo — only when info is showing in landscape, hidden when border or Settings would overlap
    m.appLogo.visible = chromeVisible and isLandscape and not m.borderEnabled and not needsSetup

    ' Re-pin the year label to the title's right edge any time chrome layout
    ' changes. The boundingRect observer also fires when the title text
    ' actually changes, so this is the belt-and-suspenders path that catches
    ' translation/width changes that don't trigger a re-render of the text.
    positionYearLabel()
    positionPortraitYearLabel()
end sub

function formatTime(ms as Integer) as String
    totalSec = Int(ms / 1000)
    h = Int(totalSec / 3600)
    mins = Int((totalSec mod 3600) / 60)
    secs = totalSec mod 60
    return padTwo(h) + ":" + padTwo(mins) + ":" + padTwo(secs)
end function

function padTwo(n as Integer) as String
    s = n.ToStr()
    if n < 10 then return "0" + s
    return s
end function
