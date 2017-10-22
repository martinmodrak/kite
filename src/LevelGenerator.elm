module LevelGenerator exposing (graphicsGenerator)

import Types exposing (..)
import Random
import RandomUtils


graphicsGenerator : Float -> Float -> Random.Generator (List Graphics)
graphicsGenerator startPos endPos =
    let
        posGenerator =
            Random.pair (Random.float startPos endPos) (Random.float -3 -0.3)

        sizeGenerator =
            Random.pair (Random.float 0.1 1.3) (Random.float 0.05 0.3)

        singleGraphicsGenerator =
            Random.map2 (\pos size -> Graphics pos size "rgb(221,243,249)") posGenerator sizeGenerator

        maxGraphics =
            ceiling ((endPos - startPos) / 0.1)

        minGraphics =
            maxGraphics // 2

        baseGraphics =
            Graphics ( startPos, 0 ) ( endPos - startPos, 4 ) "rgb(153,217,234)"
    in
        Random.int minGraphics maxGraphics
            |> Random.andThen
                (\n -> Random.map (\x -> baseGraphics :: x) 
                (Random.list n singleGraphicsGenerator)
                )
