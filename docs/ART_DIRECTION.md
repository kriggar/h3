# Draconia visual direction

## Accepted references and corrections

The intended world has the natural materials, weather, and rural medieval atmosphere of the user's Manor Lords reference. The interface needs the richness and clear command structure associated with classic Heroes strategy games. The user's particular illustration reference is the medieval painted miniature inside the logging-camp card: ink contours, flat pigments, parchment, small narrative scenes, and ornamental framing.

The visual interpretation here is **medieval manuscript illumination**, particularly narrative miniatures. Historical reference for the materials and vocabulary: the Getty Museum's [The Making of a Medieval Manuscript](https://www.getty.edu/exhibitions/making-medieval-manuscript/) describes painting and decorating manuscripts with tempera colors, ink and gold on parchment. This identifies the art direction; it is not a claim about the specific production technique used for Manor Lords' digital artwork.

The first flat adventure-map screenshot was rejected for looking like a cheap browser game. It is not the target visual standard. The replacement uses actual Godot 3D terrain, models, lighting, shadows and camera projection, together with newly generated manuscript illustrations inside native game controls.

## Current visual language

- **World:** muted olive and brown terrain, weathered timber and stone, forest masses, a cloudy Carpathian atmosphere, and visible roads and landmarks. Full naturalistic character production remains incomplete.
- **Interface frame:** dark carved wood, aged bronze bevels, restrained gold, a Dacian wolf-dragon crest, and substantial controls.
- **Information pages:** warm vellum with dark readable ink, illustrated narrative scenes, serif body text, and Cinzel headings. Ornament must stay outside text and interaction areas.
- **Characters:** original medieval manuscript portraits for army, recruitment and initiative cards. They are distinct from the animated sprites or 3D models used on the battlefield.
- **Illustrations:** woodcutters with an ox, masons at a fortress, Ileana leading a host, Iele in an oak grove, a Solomonar with a storm dragon, and a fortified Romanian-inspired village.

## Asset implementation

[generation-prompts-v2.json](../assets/generated/generation-prompts-v2.json) records the complete prompts, built-in image-generation mode, filenames, hashes, dimensions and transparency settings. The original generated images were copied into the project without overwriting the earlier artwork.

`manuscript-portraits.png` is a four-column, three-row atlas in this order: Oștean, Arcaș, Străjer, Cavaler; Solomonar, Iele, Strigoi, Spiriduș; Vârcolac, Balaur, Ileana, night lord. `manuscript-scenes.png` is a two-column, three-row atlas in reading order matching the six scenes listed above. `DraconiaArt` creates runtime atlas regions; the UI uses real controls over these pictures, not a flattened screenshot.

Downloaded 3D environment models, animated assets, font and audio retain their own licenses. See [ASSET_CREDITS.md](../ASSET_CREDITS.md). The user's Manor Lords screenshot was a visual reference; its artwork is not packaged in Draconia.

## Visual acceptance checks

Inspect the real engine at desktop and smaller window sizes. Check contrast, text wrapping, image cropping, model scale, character silhouettes, fog, foreground obstruction, exact target selection, and readable troop counts. A test-suite pass alone does not establish visual quality, and a generated illustration alone does not establish an implemented game screen.
