module Update exposing (update)

import Types exposing (..)
import Msg
import Time
import GameConstants
import Vector2 as Vec2 exposing (Float2)


update : Msg.Msg -> Model -> ( Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.Frame time ->
            updatePhysicsWrapper (model.timeAccumulator + (Time.inSeconds time)) model
                ! []


updatePhysicsWrapper : Float -> Model -> Model
updatePhysicsWrapper timeAccumulator model =
    if timeAccumulator > GameConstants.maxTimeAccumulator then
        updatePhysicsWrapper GameConstants.maxTimeAccumulator model
    else if timeAccumulator > GameConstants.physicsUpdateTime then
        updatePhysicsWrapper
            (timeAccumulator - GameConstants.physicsUpdateTime)
            (updatePhysics (GameConstants.physicsUpdateTime * GameConstants.physicsTimeWarp) model)
    else
        { model | timeAccumulator = timeAccumulator}


updatePhysics : Float -> Model -> Model
updatePhysics timeStep model =
    let
        ( forcesKiteBeforeTransfer, debugArrowsForce ) =
            forcesOnKite model

        forceTransfer = 
            forceTransferKite model forcesKiteBeforeTransfer
        forcesKite =
            Vec2.add forceTransfer forcesKiteBeforeTransfer

        --symplectic Euler - update velocity before updating position
        modelWithForces =
            { model
                | kiteVelocity = Vec2.add model.kiteVelocity (Vec2.scale (timeStep / GameConstants.kiteWeight) forcesKite)
            }

        modelWithImpulse =
            { modelWithForces
                | kiteVelocity =
                    impulseOnKite modelWithForces
            }

        kitePosWithImpulse =
            Vec2.add modelWithImpulse.kitePos (Vec2.scale timeStep modelWithImpulse.kiteVelocity)

        ( correctKitePos, correctKiteVelocity ) =
            correctKiteForTether modelWithImpulse kitePosWithImpulse modelWithImpulse.kiteVelocity
    in
        { modelWithImpulse
            | kitePos = correctKitePos
            , kiteVelocity = correctKiteVelocity
            , totalTime = model.totalTime + timeStep
            , windSpeed = 5 + (sin model.totalTime * 2)
            , debugArrows =
                [ DebugArrow "velocity" "green" model.kitePos modelWithImpulse.kiteVelocity
                , DebugArrow "transfer" "pink" model.kitePos (Vec2.scale 0.1 forceTransfer)
                ]
                    ++ debugArrowsForce
        }


forcesOnKite : Model -> ( Float2, List DebugArrow )
forcesOnKite model =
    let
        kiteY =
            (Vec2.getY model.kitePos)

        gravityForce =
            if kiteY > 0.001 then
                Vec2.scale GameConstants.kiteWeight GameConstants.gravity
            else
                ( 0, 0 )

        airVelocity =
            Vec2.scale model.windSpeed GameConstants.windDirection

        kiteAirVelocity =
            Vec2.sub airVelocity model.kiteVelocity

        kiteAirSpeed =
            Vec2.length kiteAirVelocity

        normalizedAirVelocity =
            Vec2.normalize kiteAirVelocity

        ( normalizedAirVelocityX, normalizedAirVelocityY ) =
            normalizedAirVelocity

        dragForce =
            Vec2.scale
                (0.5 * kiteAirSpeed ^ 2 * (coefficientOfDrag model))
                --TODO: cross sectional area (but maybe included in coefficient of drag)
                normalizedAirVelocity

        liftForce =
            Vec2.scale
                (0.5 * kiteAirSpeed ^ 2 * (coefficientOfLift model))
                --TODO: cross sectional area (but maybe included in coefficient of drag)
                ( 0, normalizedAirVelocityX )
    in
        ( gravityForce
            |> Vec2.add (Debug.log "Drag: " dragForce)
            |> Vec2.add (Debug.log "Lift" liftForce)
        , [ DebugArrow "drag" "red" model.kitePos (Vec2.scale 0.1 dragForce)
          , DebugArrow "lift" "blue" model.kitePos (Vec2.scale 0.1 liftForce)
          ]
        )


impulseOnKite : Model -> Float2
impulseOnKite model =
    let
        kiteY =
            (Vec2.getY model.kitePos)

        ( kiteVelocityX, kiteVelocityY ) =
            model.kiteVelocity
    in
        if (kiteY < -0.001) && (kiteVelocityY < 0) then
            ( kiteVelocityX, -0.3 * kiteVelocityY )
        else
            model.kiteVelocity


coefficientOfDrag : Model -> Float
coefficientOfDrag model =
    1


coefficientOfLift : Model -> Float
coefficientOfLift model =
    1


forceTransferKite : Model -> Float2 -> Float2
forceTransferKite model forcesKite =
    let
        tether =
            (Vec2.sub model.kitePos model.anchorPos)

        distanceToKite =
            Vec2.length tether
    in
        if distanceToKite >= model.tetherLength - GameConstants.tetherForceTransferTolerance then
            let 
                magnitude =
                    max 0 (((Vec2.dot forcesKite tether)) / (Vec2.lengthSquared tether))
            in
                Vec2.scale -magnitude tether
        else
            ( 0, 0 )


correctKiteForTether : Model -> Float2 -> Float2 -> ( Float2, Float2 )
correctKiteForTether model proposedPosition proposedVelocity =
    let
        tether =
            (Vec2.sub proposedPosition model.anchorPos)

        distanceToKite =
            Vec2.length tether
    in
        if distanceToKite >= model.tetherLength then
            ( Vec2.scale model.tetherLength (Vec2.normalize tether)
                |> Vec2.add model.anchorPos
            , Vec2.scale -(((Vec2.dot proposedVelocity tether)) / (Vec2.lengthSquared tether)) tether
                |> Vec2.add proposedVelocity
            )
        else
            ( proposedPosition, proposedVelocity )
