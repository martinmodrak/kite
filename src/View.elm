module View exposing (view)

import Types exposing (..)
import Vector2 as Vec2 exposing (Float2)
import Matrix3
import Msg
import Html exposing (..)
import Html.Attributes as Attr
import GameConstants


float2ToStyle : Float2 -> List ( String, String )
float2ToStyle pos =
    let
        ( x, y ) =
            Matrix3.transform GameConstants.viewMatrix pos
    in
        [ ( "left", toString x )
        , ( "top", toString y )
        ]


view : Model -> Html Msg.Msg
view model =
    div [ Attr.class "game" ]
        ((div
            [ Attr.class "kite"
            , Attr.style (float2ToStyle model.kitePos)
            ]
            []
         )
            :: (div [ Attr.class "player", Attr.style (float2ToStyle model.playerPos) ] [])
            :: (div [ Attr.class "windIndicator", Attr.style (float2ToStyle (model.windIndicatorX, 3))] [])
            :: (List.concatMap viewDebugArrow model.debugArrows)
        )


viewDebugArrow : DebugArrow -> List (Html Msg.Msg)
viewDebugArrow arrow =
    [ div
        [ Attr.class "debugArrowSource"
        , Attr.style (( "background-color", arrow.color ) :: (float2ToStyle arrow.start))
        ]
        []
    , div
        [ Attr.class "debugArrowEnd"
        , Attr.style (( "background-color", arrow.color ) :: (float2ToStyle (Vec2.add arrow.start arrow.vector)))        
        ]
        []
    , div
        [ Attr.class "debugArrowCaption"
        , Attr.style (( "color", arrow.color ) :: (float2ToStyle (Vec2.add arrow.start arrow.vector)))        
        ]
        [ text arrow.name]
    ]
