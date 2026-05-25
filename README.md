# miso-props

Demonstrates [miso](https://github.com/dmjio/miso) **props** — passing data from a parent `Component` down to a child and grandchild via [`mountProps`](https://haddocks.haskell-miso.org).

## What it shows

```
Parent ──mountProps──► Child ──mountProps──► Grandchild
```

Props flow as plain Haskell values through the `view` function signature:

```haskell
view :: props -> model -> View model action
```

Each component is defined with `component`:

```haskell
component :: model -> (action -> Effect parent props model action) -> (props -> model -> View model action) -> Component parent props model action
```

- **Parent** (`Component ParentModel ParentAction`) owns a counter; `+`/`-` changes it. The count is passed down as `SharedProps` (`Int`) via `mountProps`.
- **Child** (`Component ParentModel SharedProps ChildModel ChildAction`) receives the count as the first argument to its `view` function. It owns its own independent local counter and drills the same props to the grandchild via `mountProps`.
- **Grandchild** (`Component ChildModel SharedProps GCModel GCAction`) receives the drilled count and displays it. It owns its own independent toggle.

Each component box distinguishes:
- **Props section** (green dashed border) — values received from the parent.
- **Local state section** (purple dashed border) — values owned by this component.

Component colors: Parent = purple, Child = green, Grandchild = yellow.

## Build

```bash
# enter WASM dev shell
nix develop .#wasm

# compile + link
make

# serve
make serve
```
