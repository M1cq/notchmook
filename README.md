# NotchDesk

NotchDesk is an original SwiftUI macOS utility inspired by the idea of turning the MacBook notch area into an interactive productivity panel. It is not a copy of NotchNook and does not use NotchNook branding, assets, or private APIs.

## Features

- Top-center notch-style overlay that expands on hover or click
- Music / Spotify playback controls through Apple Events
- System volume slider
- Upcoming calendar events through EventKit
- Temporary drag-and-drop file tray
- Local camera mirror preview through AVFoundation
- Quick actions for Music, Calendar, Shortcuts, AirDrop sharing, System Settings, and tray clearing
- Small status item with show, pin, and quit actions

## Build

```bash
bash scripts/build-app.sh
```

The app bundle is generated at:

```text
build/NotchDesk.app
```

Open it with:

```bash
open build/NotchDesk.app
```

## Permissions

macOS may ask for:

- Calendar access for event display
- Camera access for the mirror widget
- Automation access for Music or Spotify media controls

The file tray is in-memory and intentionally clears when the app quits.
