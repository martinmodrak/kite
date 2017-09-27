module View exposing (view)

import Types exposing (..)
import Vector2 as Vec2 exposing (Float2)
import Matrix3
import Msg
import Html exposing (..)
import Html.Attributes as Attr
import GameConstants


float2ToStyle : Matrix3.Float3x3 -> Float2 -> List ( String, String )
float2ToStyle viewMatrix pos =
    let
        ( x, y ) =
            Matrix3.transform viewMatrix pos
    in
        [ ( "left", toString x )
        , ( "top", toString y )
        ]


view : Model -> Html Msg.Msg
view model =
    let
        viewMatrix = computeViewMatrix model
    in
        
    div [ Attr.class "game" ]
        ((div
            [ Attr.class "kite"
            , Attr.style (float2ToStyle viewMatrix model.kitePos)
            ]
            []
         )
            :: (div [ Attr.class "player", Attr.style (float2ToStyle viewMatrix model.playerPos) ] [])
            :: (div [ Attr.class "windIndicator", Attr.style (float2ToStyle viewMatrix ( model.windIndicatorX, 3 )) ] [])
            :: (div [ Attr.class "windIndicator", Attr.style (float2ToStyle viewMatrix ( 60, 3 )) ] [])
            :: (div [ Attr.class "windIndicator", Attr.style (float2ToStyle viewMatrix ( 3, 0 )) ] [])
            --spacer
            ::
                (List.concatMap (viewDebugArrow viewMatrix) model.debugArrows)
        )


viewDebugArrow : Matrix3.Float3x3 -> DebugArrow -> List (Html Msg.Msg)
viewDebugArrow viewMatrix arrow =
    [ div
        [ Attr.class "debugArrowSource"
        , Attr.style (( "background-color", arrow.color ) :: (float2ToStyle viewMatrix arrow.start))
        ]
        []
    , div
        [ Attr.class "debugArrowEnd"
        , Attr.style (( "background-color", arrow.color ) :: (float2ToStyle viewMatrix (Vec2.add arrow.start arrow.vector)))
        ]
        []
    , div
        [ Attr.class "debugArrowCaption"
        , Attr.style (( "color", arrow.color ) :: (float2ToStyle viewMatrix (Vec2.add arrow.start arrow.vector)))
        ]
        [ text arrow.name ]
    ]


computeViewMatrix : Model -> Matrix3.Float3x3
computeViewMatrix model =
    let
        ( playerX, playerY ) =
            model.playerPos

        playerPosScaled =
            ( GameConstants.viewScaleX * playerX, GameConstants.viewScaleY * playerY )

        ( shiftX, shiftY ) =
            Vec2.sub GameConstants.playerPosOnScreen playerPosScaled
    in
        ( ( GameConstants.viewScaleX, 0, shiftX )
        , ( 0, GameConstants.viewScaleY, shiftY )
        , ( 0, 0, 1 )
        )
