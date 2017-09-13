module Types exposing (Model)

import Vector2 as Vec2 exposing (Float2)

type alias Model =
    { anchorPos : Float2
    , kitePos : Float2
    , kiteVelocity : Float2
    , tetherLength : Float
    , windSpeed : Float
    , timeAccumulator: Float
    }
