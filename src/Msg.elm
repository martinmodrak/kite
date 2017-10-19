module Msg exposing(Msg(..))

import Time
import Types exposing(..)
import Keyboard

type Msg = 
    Frame Time.Time
    | KeyPress Keyboard.KeyCode
    | AddGraphics (List Graphics)    

