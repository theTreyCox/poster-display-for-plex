# Poster Display for Plex

A Roku app that displays the poster of whatever's currently playing on your Plex Media Server — designed to make a Roku TV (mounted normally or vertically) a beautiful always-on movie/TV poster display.

## Features

- **Live poster display** — polls Plex every 15 seconds for the current session and shows the artwork
- **TV episode support** — for episodes, displays the **series poster** as the main image with a small **episode thumbnail** overlay, plus `Show Name — Episode Title` in the status bar
- **Four view modes**, cycling on a single keypress:
  - Landscape Fit / Landscape Fill
  - Portrait Fit / Portrait Fill (for vertically-mounted TVs — content auto-rotates 90°)
- **Random Carousel mode** — when no specific media is playing (or whenever you like), rotate through random posters from your Plex library every 30 seconds
- **Now Playing border** — optional theater-style frame with marquee lights, gold trim, and a dynamic "NOW PLAYING" sign that shows the actual show/movie name in a retro display font
- **Info overlay** — toggleable progress bar (`current / total time`, fill bar) and `NOW PLAYING:` title strip, all in Roboto. Tied to a single toggle so you can keep the display clean
- **Screensaver suppression** — keeps the screen on indefinitely while the app is running (via background-thread call to `roAppManager.UpdateLastKeyPressTime` every 30s)
- **Persistent settings** — server URL, token, view mode, border state, info state, and carousel state are all saved per channel in the Roku registry

## Remote control

| Key | Action |
| --- | --- |
| **Play** / **Up** / **`*`** | Cycle view mode (Landscape Fit → Fill → Portrait Fit → Fill) |
| **Down** | Toggle the Now Playing border on/off |
| **Right** | Toggle info overlay (status text + progress bar + Settings) |
| **Left** | Open Settings (server URL + token entry) |
| **Rewind** | Toggle random Carousel mode |

The Settings button is normally hidden once your Plex server and token are configured — use the Left arrow to open the settings dialog any time.

## Initial setup

1. Sideload the app to your Roku in Developer Mode (see [Sideloading](#sideloading) below).
2. On first launch, you'll see "Press Settings to enter your Plex server and token." — press **OK** on the visible Settings button.
3. Enter your Plex server URL — typically `http://<your-server-ip>:32400`.
4. Enter your Plex token. To find it:
   - In the Plex web app, open any item's **Get Info → View XML**
   - Copy the `X-Plex-Token=...` value from the URL
   - Official guide: <https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/>
5. Start playing something on Plex — within ~15 seconds the poster appears on the Roku.

## Project structure

```
poster-display-for-plex/
├── manifest                              # Roku channel metadata
├── source/main.brs                       # entry point + screen lifecycle
├── components/
│   ├── PosterDisplayScene.xml/.brs      # main scene UI + interaction
│   ├── PlexSessionTask.xml/.brs         # background task that polls /status/sessions
│   ├── PlexLibraryTask.xml/.brs         # background task that fetches library items for the carousel
│   └── KeepAliveTask.xml/.brs           # background task that suppresses the screensaver
├── images/
│   ├── splash.png                        # app splash/icon
│   └── borders/
│       ├── landscape/landscape-border-01.png
│       └── portrait/portrait-border-01.png
├── fonts/
│   ├── Roboto-Bold.ttf                   # status text, progress numbers, Settings glyph
│   ├── Roboto-Medium.ttf
│   └── RetroSigned-DYYY0.ttf            # marquee display font for the border
└── package.sh                            # builds poster-display-for-plex.zip for sideloading
```

## Architecture notes

- **All network I/O runs on Task threads.** `roUrlTransfer` cannot be created on the SceneGraph render thread; the scene observes `result` fields on the Tasks and reacts when they update.
- **Screensaver suppression also runs on a Task thread** for the same reason — `roAppManager` is a MAIN/TASK-only component.
- **Two rendering paths per view mode:** with-border and without-border. The bordered variants size the poster to fit precisely inside the border PNG's transparent cutout (cutout bounds were measured directly from the PNG's alpha channel).
- **Chrome (status bar, progress, Settings) has separate landscape and portrait layouts.** The portrait layout sits in a `Group` with `rotation = π/2` so it appears correctly oriented for a vertically-mounted TV; the poster also shrinks slightly in portrait when info is on to leave room for the chrome strip below it.

## Sideloading

1. Enable **Developer Mode** on your Roku and note the device IP (Settings → System → About).
2. From your Mac in this project folder:
   ```sh
   ./package.sh
   ```
   This produces `poster-display-for-plex.zip`.
3. Open `http://<roku-ip>` in your browser, sign in with your developer credentials, and upload the ZIP via the **Upload** button.
4. The app appears on your Roku home screen as "Poster Display for Plex".

### Debugging

Telnet to the Roku for live BrightScript console output:

```sh
nc <roku-ip> 8085
```

(The `nc` tool ships with macOS; `telnet` was removed in recent versions.)

## Packaging for distribution

This project's `package.sh` produces an **unsigned source bundle** for sideloading only. To upload to the Roku Channel Store, you need to generate a **signed `.pkg`** from your developer-enabled Roku device using its built-in Packager utility. The Roku store will reject a raw source ZIP.

## Customization

- **Border art** lives in `images/borders/`. Each PNG must be 1920×1080 RGBA with the poster area marked by `alpha = 0`. The app measures the transparent rectangle automatically and aligns the poster inside it.
- **Fonts** live in `fonts/` and are referenced by path in `PosterDisplayScene.xml`. Drop in another `.ttf` and swap the `uri` to change the marquee or status font.
- **Poll interval** is set in `PosterDisplayScene.xml` on the `pollTimer` node (`duration` in seconds). Default is 15 seconds.
- **Carousel interval** is set on the `carouselTimer` node — default 30 seconds.
