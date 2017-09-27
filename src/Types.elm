module Types exposing (Model, DebugArrow, Graphics)

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

type alias Model =
    { playerPos : Float2
    , playerVelocity : Float2
    , kitePos : Float2
    , kiteVelocity : Float2
    , tetherLength : Float
    , windSpeed : Float
    , windIndicatorX : Float
    , timeAccumulator : Float
    , totalTime : Float
    , graphics: List Graphics
    , debugArrows : List DebugArrow
    }
