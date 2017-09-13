module Init exposing (init)

import Types exposing (..)
import Msg

init : (Model, Cmd Msg.Msg)
init =
    { anchorPos = ( 600, 400)
    , kitePos = ( 400, 600 )
    , kiteVelocity = (0,0)
    , windSpeed = 10
    , tetherLength = 100
    , timeAccumulator = 0
    } ! []
