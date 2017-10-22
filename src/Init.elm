module Init exposing (init)

import Types exposing (..)
import Msg
import Random
import LevelGenerator

init : ( Model, Cmd Msg.Msg )
init =
    { playerPos = ( 0, 0 )
    , playerVelocity = ( 0, 0 )
    , jumpState = None
    , kitePos = ( 2, 2 )
    , kiteVelocity = ( 0, 0 )
    , kiteLiftCoefficient = 1.5
    , kiteDragCoefficient = 3
    , windSpeed = 9
    , windIndicatorX = 0
    , tetherLength = sqrt 8
    , timeAccumulator = 0
    , totalTime = 0
    , graphics = []
    , debugArrows = []
    , debugArrowsScale = 0.1
    , physicsTimeWarp = 1
    , physicsFrameSkip = 1
    , paused = False
    }
        ! [Random.generate Msg.AddGraphics (LevelGenerator.graphicsGenerator -10 20)]

