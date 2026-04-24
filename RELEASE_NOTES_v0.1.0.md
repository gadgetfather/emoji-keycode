# EmojiKeycode v0.1.0

First public release. Type `:shortcode:` in any macOS input field and have it replaced with the corresponding emoji, system-wide.

## Install

1. Download **EmojiKeycode-v0.1.0-macos.zip** below.
2. Unzip and drag **EmojiKeycode.app** to `/Applications`.
3. Because this build is unsigned, macOS Gatekeeper will block the first launch. Clear the quarantine flag once:

   ```sh
   xattr -d com.apple.quarantine /Applications/EmojiKeycode.app
   ```

4. Launch it. A menu-bar icon appears with a red dot.
5. Grant Accessibility permission when prompted: **System Settings → Privacy & Security → Accessibility → enable EmojiKeycode**. The red dot disappears within 2 seconds.
6. Open any app and type `:heart:` → ❤️.

## What's in this release

- Auto-replace on closing colon: `:tada:` → 🎉
- Live suggestion popup while typing (`:sm…` → list of matches)
- 1,870 shortcodes bundled from [github/gemoji](https://github.com/github/gemoji)
- Multi-codepoint emoji support (ZWJ families, flags, skin-tone modifiers insert atomically)
- Password-field bypass via secure-input detection
- No clipboard, no network, no telemetry — everything runs locally
- Menu-bar only (`LSUIElement=true`); no Dock icon
- Launch-at-login toggle

## System requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel

## Known limitations

- Unsigned build (see install steps above for the Gatekeeper workaround).
- Suggestion popup positioning falls back to mouse location in apps that don't expose the text caret via the Accessibility API (some Electron apps, Terminal variants).

## Verify the download

```
SHA-256: bbaacc6ce6bb755bb1ff2dcb2f34fcd08205cdbbadfc67c72e0279293e0960dc
File:    EmojiKeycode-v0.1.0-macos.zip
```

## Build from source

If you'd rather not run an unsigned binary, build it yourself:

```sh
git clone https://github.com/gadgetfather/emoji-keycode.git
cd emoji-keycode
make emoji-db
make app
open ./EmojiKeycode.app
```

See the [README](https://github.com/gadgetfather/emoji-keycode#readme) for full instructions.

---

Feedback and bug reports welcome. Open source under personal-use terms.
