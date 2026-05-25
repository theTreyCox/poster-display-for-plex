<p align="center">
  <img src="images/logo-square.png" alt="Poster Display for Plex" width="240" />
</p>

# Poster Display for Plex

A Roku channel that turns any TV into a beautiful, always-on movie and TV poster display driven by your Plex Media Server. Works on a Roku TV directly or on any television connected to a Roku streaming stick/box. Hang the TV in landscape or mount it vertically — the app rotates content to fit either orientation.

## Why this exists

If you've ever wanted a dedicated "now playing" poster display next to your home theater (or just a rotating digital art frame fed by your own Plex library), today's options are surprisingly limited:

- **[devMikeFrancis/digital-movie-poster](https://github.com/devMikeFrancis/digital-movie-poster)** is a great open-source project, but it requires a dedicated computer or Raspberry Pi wired to the TV.
- **[PosterBox](https://www.posterbox.app/)** is a polished commercial app, but it doesn't run on Roku — leaving every Roku TV owner without a native option.

Most of us already have a Roku stick or a Roku TV sitting in the living room. This project fills that gap: install the channel, point it at your Plex server, and the TV does the rest. No extra hardware, no second device, no PC running in the background. Just the Roku you already own and the Plex library you've already built.

## Features

- **Live poster display** — polls Plex every 15 seconds for the current session and shows the artwork
- **TV episode support** — for episodes, displays the **series poster** as the main image with a small **episode thumbnail** overlay, plus `Show Name — Episode Title` in the status bar
- **Four view modes**, cycling on a single keypress:
  - Landscape Fit / Landscape Fill
  - Portrait Fit / Portrait Fill (for vertically-mounted TVs — content auto-rotates 90°)
- **Random Carousel mode** — when no specific media is playing (or whenever you like), rotate through random posters from your Plex library every 30 seconds. Skip individual items by tagging them with a `no-poster` label in Plex
- **Now Playing border** — optional theater-style frame with marquee lights, gold trim, and a dynamic "NOW PLAYING" sign that shows the actual show/movie name in a retro display font
- **Info overlay** — toggleable progress bar (`current / total time`, fill bar) and `NOW PLAYING:` title strip, all in Roboto. Tied to a single toggle so you can keep the display clean
- **Screensaver suppression** — keeps the screen on indefinitely while the app is running (via background-thread call to `roAppManager.UpdateLastKeyPressTime` every 30s)
- **Persistent settings** — server URL, token, view mode, border state, info state, and carousel state are all saved per channel in the Roku registry

## Remote control

| Key | Action |
| --- | --- |
| **Play** / **Up** | Cycle view mode (Landscape Fit → Fill → Portrait Fit → Fill) |
| **Down** | Toggle the Now Playing border on/off |
| **Right** | Toggle info overlay (status text + progress bar + clock) |
| **`*`** (info) / **Left** | Open the Settings menu (server, token, carousel rating filter) |
| **Rewind** | Toggle random Carousel mode on/off |

### While Carousel mode is on

| Key | Action |
| --- | --- |
| **Play** / **Pause** | Pause or resume auto-advance (the current poster stays on screen while paused) |
| **Fast-forward** | Jump to the next random poster immediately (works whether playing or paused; if playing, resets the 30s interval) |
| **Up** | Still cycle view mode (Play is repurposed for pause while in Carousel) |
| **Rewind** | Exit Carousel mode |

The Settings button is normally hidden once your Plex server and token are configured — use **`*`** or the **Left arrow** to open the Settings menu any time. The menu lets you change the server, change the token, or edit the carousel rating filter.

## Initial setup

1. Sideload the app to your Roku in Developer Mode (see [Sideloading](#sideloading) below).
2. On first launch, you'll see "Press OK to enter your Plex server and token." — press **OK** on the visible Settings button.
3. The app automatically scans your local network for Plex Media Servers using Plex's GDM discovery protocol. After ~3 seconds:
   - If servers are found, a list appears — pick the one you want.
   - If none are found (or you'd rather type the URL yourself), choose **Enter manually** and provide `http://<your-server-ip>:32400`.
4. Enter your Plex token. To find it:
   - In the Plex web app, open any item's **Get Info → View XML**
   - Copy the `X-Plex-Token=...` value from the URL
   - Official guide: <https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/>
5. Start playing something on Plex — within ~15 seconds the poster appears on the Roku.

## Hiding posters from the Carousel

The app gives you two independent ways to keep specific posters out of the random Carousel. Use either or both; they're combined with OR.

### 1. By content rating (no Plex Pass needed)

Open the **Settings menu** (`*` or Left arrow) and choose **Edit carousel rating filter**. A checkbox list appears with the common content ratings:

- **Movies:** G, PG, PG-13, R, NC-17
- **TV:** TV-Y, TV-Y7, TV-G, TV-PG, TV-14, TV-MA
- **Not Rated** (also catches items that have no rating set at all in Plex)

Check the ratings you want skipped and choose Save. The carousel cache refreshes immediately. Items where Plex reports any of those ratings — including the "us/R" prefixed form that some metadata sources use — are excluded. This works regardless of whether you have a Plex Pass.

### 2. By per-item label (requires Plex Pass)

For finer-grained control, you can hide individual movies or shows by tagging them in Plex. **This feature requires a Plex Pass** because labels on movies and shows are a Plex Pass feature:

1. In the Plex web app, navigate to the movie or show you want to hide.
2. Click the **edit** (pencil) icon to open the metadata editor.
3. Open the **Tags** tab and add a **Label** with the value:

   ```
   no-poster
   ```

   (Lowercase, with a hyphen.)
4. Save.

The next time the Carousel cache refreshes — toggle the carousel off and on, or relaunch the app — those items will be excluded. The label name `no-poster` is hard-coded so no app-side configuration is needed.

## Project structure

```
poster-display-for-plex/
├── manifest                              # Roku channel metadata
├── source/main.brs                       # entry point + screen lifecycle
├── components/
│   ├── PosterDisplayScene.xml/.brs      # main scene UI + interaction
│   ├── PlexSessionTask.xml/.brs         # background task that polls /status/sessions
│   ├── PlexLibraryTask.xml/.brs         # background task that fetches library items for the carousel
│   ├── PlexDiscoveryTask.xml/.brs       # background task that broadcasts Plex GDM and collects responses
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
