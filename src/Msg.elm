module Msg exposing(Msg(..))

import Time
import Types exposing(..)

type Msg = 
    Frame Time.Time
    | AddGraphics (List Graphics)

