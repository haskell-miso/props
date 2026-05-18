# miso-props

Demonstrates [miso](https://github.com/dmjio/miso) **props** — passing data from a parent `Component` down to a child and grandchild via [`mountProps`](https://haddocks.haskell-miso.org) / [`checkProps`](https://haddocks.haskell-miso.org).

## What it shows

```
Parent ──mountProps──► Child ──mountProps──► Grandchild
```

- **Parent** owns a counter, `+`/`-` changes the count. The value is passed down as `Int` `Props`.
- **Child** receives those props via `useProps = checkProps ...` and re-renders the count it was given. It also owns its own independent local counter. It then **drills** the same props further down to the grandchild.
- **Grandchild** receives the drilled props and shows them in a colored rectangle.  It owns its own independent toggle.

Each component box distinguishes:
- **Props section** (green dashed border) — values received from the parent.
- **Local state section** (purple dashed border) — values owned by this component.

## Build

```bash
# enter WASM dev shell
nix develop .#wasm

# compile + link
make

# serve
make serve
```
