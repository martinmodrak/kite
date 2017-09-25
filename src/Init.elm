module Init exposing (init)

import Types exposing (..)
import Msg

init : (Model, Cmd Msg.Msg)
init =
    { anchorPos = ( 0, 0)
    , kitePos = ( 2, 2 )
    , kiteVelocity = (0,0)
    , windSpeed = 1
    , tetherLength = sqrt 8
    , timeAccumulator = 0
    , debugArrows = []
    } ! []
