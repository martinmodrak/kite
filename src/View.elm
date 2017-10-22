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
        [ ( "left", toString x ++ "px" )
        , ( "top", toString y ++ "px" )
        ]


float2ToSizeStyle : Matrix3.Float3x3 -> Float2 -> List ( String, String )
float2ToSizeStyle viewMatrix ( sizeX, sizeY ) =
    let
        ( x, y, _ ) =
            Matrix3.mulVector viewMatrix ( sizeX, sizeY, 0 )
    in
        [ ( "width", toString x ++ "px" )
        , ( "height", toString (abs y) ++ "px" )
          --TODO abs is bull shit
        ]


view : Model -> Html Msg.Msg
view model =
    let
        viewMatrix =
            computeViewMatrix model
    in
        div [ Attr.class "game" ]            
            (
                (text ("Wind: " ++ (toString model.windSpeed) 
                ++ " Lift: " ++ (toString model.kiteLiftCoefficient)
                ++ " Drag: " ++ (toString model.kiteDragCoefficient)                
                ++ " Time warp: " ++ (toString model.physicsTimeWarp)                
                ++ " Frame skip: " ++ (toString model.physicsFrameSkip)                
                ++ " Kite dist: " ++ (
                    (Vec2.sub model.kitePos model.playerPos) |>
                    Vec2.length |> (*) 100 |> round
                    |> toString  
                )
                )) ::                
                (List.map (viewGraphics viewMatrix) model.graphics)
                ++ ((div
                        [ Attr.class "kite"
                        , Attr.style (float2ToStyle viewMatrix model.kitePos)
                        ]
                        []
                    )
                        :: (div [ Attr.class "player", Attr.style (float2ToStyle viewMatrix (Vec2.add model.playerPos ( 0, 0.5 ))) ] [])
                        :: (div [ Attr.class "windIndicator", Attr.style (float2ToStyle viewMatrix ( model.windIndicatorX, 3 )) ] [])
                        :: (div [ Attr.class "windIndicator", Attr.style (float2ToStyle viewMatrix ( 60, 3 )) ] [])
                        :: (div [ Attr.class "windIndicator", Attr.style (float2ToStyle viewMatrix ( 3, 0 )) ] [])
                        :: []
                    --spacer
                   )
                ++ (List.concatMap (viewDebugArrow viewMatrix model.debugArrowsScale) model.debugArrows)
            )


viewGraphics : Matrix3.Float3x3 -> Graphics -> Html Msg.Msg
viewGraphics viewMatrix graphics =
    div
        [ Attr.class "graphics"
        , Attr.style
            ((( "background-color", graphics.color )
                :: (float2ToStyle viewMatrix graphics.pos)
             )
                ++ (float2ToSizeStyle viewMatrix graphics.size)
            )
        ]
        []


viewDebugArrow : Matrix3.Float3x3 -> Float -> DebugArrow -> List (Html Msg.Msg)
viewDebugArrow viewMatrix scale arrow =
    let
        endPosition =
            (Vec2.add arrow.start (Vec2.scale scale arrow.vector))
    in
        [ div
            [ Attr.class "debugArrowSource"
            , Attr.style (( "background-color", arrow.color ) :: (float2ToStyle viewMatrix arrow.start))
            ]
            []
        , div
            [ Attr.class "debugArrowEnd"
            , Attr.style (( "background-color", arrow.color ) :: (float2ToStyle viewMatrix endPosition))
            ]
            []
        , div
            [ Attr.class "debugArrowCaption"
            , Attr.style (( "color", arrow.color ) :: (float2ToStyle viewMatrix endPosition))
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
