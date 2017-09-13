module View exposing (view)

import Types exposing (..)
import Vector2 as Vec2 exposing (Float2)
import Msg
import Html exposing (..)
import Html.Attributes as Attr


float2ToStyle : Float2 -> Html.Attribute Msg.Msg
float2ToStyle ( x, y ) =
    Attr.style
        [ ( "left", toString x )
        , ( "top", toString y )
        ]


view : Model -> Html Msg.Msg
view model =
    div [ Attr.class "game" ]
        [ div
            [ Attr.class "kite"
            , float2ToStyle model.kitePos ]
            []
            , div [ Attr.class "anchor", float2ToStyle model.anchorPos ] [] 
        ]
