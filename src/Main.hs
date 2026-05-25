-----------------------------------------------------------------------------
{-# LANGUAGE CPP               #-}
{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- Demonstrates Miso typesafe props: passing and drilling data from a parent
-- component down through a child and into a grandchild via 'mountProps'.
-- Props flow as plain Haskell values via the new 'view :: props -> model -> View'
-- signature
--
-- Layout:
--   Parent  ──mountProps──►  Child  ──mountProps──►  Grandchild
--
-- Each component also has its own independent local count to illustrate the
-- difference between "props received from parent" and "component-owned state".
-----------------------------------------------------------------------------
module Main where
-----------------------------------------------------------------------------
import           Miso
import           Miso.Html
import           Miso.String (MisoString, ms)
import qualified Miso.CSS    as CSS
-----------------------------------------------------------------------------
#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif
-----------------------------------------------------------------------------
-- | Shared prop payload: count :: Int
type SharedProps = Int
-----------------------------------------------------------------------------
-- =====================================================================
-- Grandchild component
-- =====================================================================
data GCModel = GCModel
  { gcToggle :: Bool
  } deriving (Show, Eq)

data GCAction
  = GCToggleLocal

grandchild :: Component ChildModel SharedProps GCModel GCAction
grandchild = component (GCModel False) gcUpdate gcView

gcUpdate :: GCAction -> Effect ChildModel SharedProps GCModel GCAction
gcUpdate GCToggleLocal = modify $ \m -> m { gcToggle = not (gcToggle m) }

gcView :: SharedProps -> GCModel -> View GCModel GCAction
gcView n m =
  div_ [ CSS.style_ gcBoxStyle ]
  [ componentHeader "Grandchild"
  , propsSection
    [ sectionLabel "Props (drilled from parent via child)"
    , infoRow "Drilled count" (ms n)
    ]
  , stateSection
    [ sectionLabel "Local state"
    , infoRow "Toggle" (if gcToggle m then "ON" else "OFF")
    , buttonRow
      [ btn gcBtnStyle GCToggleLocal "Toggle" ]
    ]
  ]
-----------------------------------------------------------------------------
-- =====================================================================
-- Child component
-- =====================================================================
data ChildModel = ChildModel
  { childLocal :: Int
  } deriving (Show, Eq)

data ChildAction
  = ChildIncr
  | ChildDecr

child :: Component ParentModel SharedProps ChildModel ChildAction
child = component (ChildModel 0) childUpdate childView

childUpdate :: ChildAction -> Effect ParentModel SharedProps ChildModel ChildAction
childUpdate = \case
  ChildIncr -> modify $ \m -> m { childLocal = childLocal m + 1 }
  ChildDecr -> modify $ \m -> m { childLocal = childLocal m - 1 }

childView :: SharedProps -> ChildModel -> View ChildModel ChildAction
childView n m =
  div_ [ CSS.style_ rowStyle ]
  [ div_ [ CSS.style_ childBoxStyle ]
    [ componentHeader "Child"
    , propsSection
      [ sectionLabel "Props (from parent)"
      , infoRow "Prop count" (ms n)
      ]
    , stateSection
      [ sectionLabel "Local state"
      , infoRow "Local count" (ms (childLocal m))
      , buttonRow
        [ btn childBtnStyle ChildIncr "+"
        , btn childBtnStyle ChildDecr "-"
        ]
      ]
    ]
  , mountWithProps n grandchild
  ]
-----------------------------------------------------------------------------
-- =====================================================================
-- Parent component (App root)
-- =====================================================================
data ParentModel = ParentModel
  { parentCount :: Int
  } deriving (Show, Eq)

data ParentAction
  = ParentIncr
  | ParentDecr

main :: IO ()
main = startApp defaultEvents app

app :: App ParentModel ParentAction
app = component (ParentModel 0) parentUpdate parentView

parentUpdate :: ParentAction -> Effect ROOT () ParentModel ParentAction
parentUpdate = \case
  ParentIncr -> modify $ \m -> m { parentCount = parentCount m + 1 }
  ParentDecr -> modify $ \m -> m { parentCount = parentCount m - 1 }

parentView :: () -> ParentModel -> View ParentModel ParentAction
parentView _ m =
  div_ [ CSS.style_ pageStyle ]
  [ h1_  [ CSS.style_ titleStyle ] [ "🍜 ", a_ [ href_ "https://github.com/haskell-miso/miso-props", target_ "blank" ] [ "miso-props" ] ]
  , p_ [ CSS.style_ subtitleStyle ]
    [ "Props are passed "
    , strong_ [] [ "parent → child → grandchild" ]
    , " via "
    , code_ [] [ "mountProps" ]
    , ". Each component also owns independent local state."
    ]
  , div_ [ CSS.style_ rowStyle ]
    [ div_ [ CSS.style_ parentBoxStyle ]
      [ componentHeader "Parent (App root)"
      , stateSection
        [ sectionLabel "Local state"
        , infoRow "Count" (ms (parentCount m))
        , buttonRow
          [ btn parentBtnStyle ParentIncr "+"
          , btn parentBtnStyle ParentDecr "-"
          ]
        ]
      ]
    , mountWithProps (parentCount m) child
    ]
  ]
-----------------------------------------------------------------------------
-- =====================================================================
-- Shared view helpers
-- =====================================================================

componentHeader :: MisoString -> View model action
componentHeader label =
  div_ [ CSS.style_ headerStyle ] [ text label ]

infoRow :: MisoString -> MisoString -> View model action
infoRow label val =
  div_
  [ CSS.style_
    [ CSS.display "flex"
    , CSS.gap "6px"
    , CSS.alignItems "center"
    , CSS.marginBottom "4px"
    , CSS.fontSize "0.9rem"
    ]
  ]
  [ span_ [ CSS.style_ [ CSS.fontWeight "700" ] ] [ text (label <> ":") ]
  , span_ [ CSS.style_ [ CSS.color (CSS.hex "#444") ] ] [ text val ]
  ]

sectionLabel :: MisoString -> View model action
sectionLabel label =
  div_
  [ CSS.style_
    [ CSS.fontSize "0.7rem"
    , CSS.fontWeight "700"
    , CSS.color (CSS.hex "#888")
    , CSS.letterSpacing "0.08em"
    , CSS.marginBottom "8px"
    ]
  ]
  [ text label ]

btn :: [CSS.Style] -> action -> MisoString -> View model action
btn btnSty action label =
  button_
  [ onClick action, CSS.style_ btnSty ]
  [ text label ]

buttonRow :: [View model action] -> View model action
buttonRow children =
  div_ [ CSS.style_ [ CSS.display "flex", CSS.gap "8px", CSS.marginTop "10px" ] ]
  children

propsSection :: [View model action] -> View model action
propsSection children =
  div_ [ CSS.style_ propsSectionStyle ] children

stateSection :: [View model action] -> View model action
stateSection children =
  div_ [ CSS.style_ stateSectionStyle ] children

-----------------------------------------------------------------------------
-- =====================================================================
-- Styles
-- =====================================================================

rowStyle :: [CSS.Style]
rowStyle =
  [ CSS.display "flex"
  , CSS.gap "18px"
  , CSS.alignItems "flex-start"
  ]

pageStyle :: [CSS.Style]
pageStyle =
  [ CSS.fontFamily "system-ui, -apple-system, sans-serif"
  , CSS.padding "28px 32px"
  , CSS.maxWidth "960px"
  , CSS.margin "0 auto"
  , CSS.color (CSS.hex "#222")
  ]

titleStyle :: [CSS.Style]
titleStyle =
  [ CSS.fontSize "2rem"
  , CSS.fontWeight "800"
  , CSS.margin "0 0 8px 0"
  ]

subtitleStyle :: [CSS.Style]
subtitleStyle =
  [ CSS.margin "0 0 28px 0"
  , CSS.color (CSS.hex "#555")
  , CSS.lineHeight "1.6"
  ]

parentBoxStyle :: [CSS.Style]
parentBoxStyle =
  [ CSS.border "2px solid #6c5ce7"
  , CSS.borderRadius "10px"
  , CSS.padding "18px"
  , CSS.minWidth "200px"
  , CSS.backgroundColor (CSS.rgba 108 92 231 0.04)
  ]

childBoxStyle :: [CSS.Style]
childBoxStyle =
  [ CSS.border "2px solid #00b894"
  , CSS.borderRadius "10px"
  , CSS.padding "18px"
  , CSS.minWidth "200px"
  , CSS.backgroundColor (CSS.rgba 0 184 148 0.04)
  ]

gcBoxStyle :: [CSS.Style]
gcBoxStyle =
  [ CSS.border "2px solid #fdcb6e"
  , CSS.borderRadius "10px"
  , CSS.padding "18px"
  , CSS.minWidth "200px"
  , CSS.backgroundColor (CSS.rgba 253 203 110 0.04)
  ]

headerStyle :: [CSS.Style]
headerStyle =
  [ CSS.fontWeight "800"
  , CSS.fontSize "1.05rem"
  , CSS.marginBottom "14px"
  , CSS.color (CSS.hex "#333")
  ]

propsSectionStyle :: [CSS.Style]
propsSectionStyle =
  [ CSS.padding "14px"
  , CSS.border "1px dashed #00b894"
  , CSS.borderRadius "8px"
  , CSS.marginBottom "12px"
  , CSS.backgroundColor (CSS.rgba 0 184 148 0.05)
  ]

stateSectionStyle :: [CSS.Style]
stateSectionStyle =
  [ CSS.padding "14px"
  , CSS.border "1px dashed #6c5ce7"
  , CSS.borderRadius "8px"
  , CSS.marginBottom "12px"
  , CSS.backgroundColor (CSS.rgba 108 92 231 0.05)
  ]

parentBtnStyle :: [CSS.Style]
parentBtnStyle =
  [ CSS.padding "6px 16px"
  , CSS.border "none"
  , CSS.borderRadius "5px"
  , CSS.cursor "pointer"
  , CSS.backgroundColor (CSS.hex "#6c5ce7")
  , CSS.color (CSS.hex "#333")
  , CSS.fontWeight "700"
  , CSS.fontSize "1rem"
  ]

childBtnStyle :: [CSS.Style]
childBtnStyle =
  [ CSS.padding "6px 16px"
  , CSS.border "none"
  , CSS.borderRadius "5px"
  , CSS.cursor "pointer"
  , CSS.backgroundColor (CSS.hex "#00b894")
  , CSS.color (CSS.hex "#333")
  , CSS.fontWeight "700"
  , CSS.fontSize "1rem"
  ]

gcBtnStyle :: [CSS.Style]
gcBtnStyle =
  [ CSS.padding "6px 16px"
  , CSS.border "none"
  , CSS.borderRadius "5px"
  , CSS.cursor "pointer"
  , CSS.backgroundColor (CSS.hex "#e17055")
  , CSS.color (CSS.hex "#333")
  , CSS.fontWeight "700"
  , CSS.fontSize "0.9rem"
  ]

-----------------------------------------------------------------------------
