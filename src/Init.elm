module Init exposing (init)

import Types exposing (..)
import Msg
import Random
import LevelGenerator

init : ( Model, Cmd Msg.Msg )
init =
    { playerPos = ( 0, 0 )
    , playerVelocity = ( 0, 0 )
    , kitePos = ( 2, 2 )
    , kiteVelocity = ( 0, 0 )
    , windSpeed = 3
    , windIndicatorX = 0
    , tetherLength = sqrt 8
    , timeAccumulator = 0
    , totalTime = 0
    , graphics = []
    , debugArrows = []
    }
        ! [Random.generate Msg.AddGraphics (LevelGenerator.graphicsGenerator -10 20)]

