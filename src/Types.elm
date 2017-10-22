module Types exposing (Model, DebugArrow, Graphics, JumpState(..))

import Vector2 as Vec2 exposing (Float2)


type alias DebugArrow =
    { name : String
    , color : String
    , start : Float2
    , vector : Float2
    }

type alias Graphics = {
    pos: Float2,
    size: Float2,
    color: String
}

type JumpState =
    None
    | Preparing
    | Air

type alias Model =
    { playerPos : Float2
    , playerVelocity : Float2
    , jumpState : JumpState
    , kitePos : Float2
    , kiteVelocity : Float2
    , kiteLiftCoefficient : Float
    , kiteDragCoefficient : Float
    , tetherLength : Float
    , windSpeed : Float
    , windIndicatorX : Float
    , timeAccumulator : Float
    , totalTime : Float
    , graphics: List Graphics
    , debugArrows : List DebugArrow
    , debugArrowsScale : Float
    , physicsTimeWarp : Float
    , physicsFrameSkip: Float
    , paused : Bool
    }
