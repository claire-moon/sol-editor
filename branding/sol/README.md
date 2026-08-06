# SOL branding

The shared SOL engine/editor icon was approved on 2026-08-06.

- `sol-icon-master.png` preserves the supplied source bytes unchanged.
- `sol-icon.ico` is the padded Windows derivative.
- `Source/Core/Resources/UDB2.ico` uses that derivative for Windows and Mono editor builds.
- The editor ICO uses an uncompressed 24-bit bitmap frame because Mono's legacy `System.Drawing.Icon` reader rejects PNG-compressed ICO frames during `.resx` compilation.

Additional package sizes are generated from the master image when installers are introduced. Do not redraw, recolor, label, or split the engine/editor identity without a recorded design decision. Creator, copyright holder, and distribution license must be recorded before the first public binary release.
