# Launcher icon source

`flutter_launcher_icons` reads `tool/icon/xdreamer-logo.png`, which is **not
tracked** — it is a 4.3MB master that already lives in the backend repo.

To regenerate the launcher icons:

```bash
cp ../aixman/public/xdreamer-logo.png tool/icon/xdreamer-logo.png
dart run flutter_launcher_icons
```

The generated `android/app/src/main/res/mipmap-*` files **are** tracked, so a
normal build needs none of this.
