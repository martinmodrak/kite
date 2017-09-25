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
            (updatePhysics GameConstants.physicsUpdateTime model)
    else
        { model | timeAccumulator = timeAccumulator }


updatePhysics : Float -> Model -> Model
updatePhysics timeStep model =
    let
        (forcesKiteBeforeTransfer, debugArrowsForce)  =
            forcesOnKite model

        forcesKite=
            Vec2.add (Debug.log "Transfer: " (forceTransfer model forcesKiteBeforeTransfer)) forcesKiteBeforeTransfer

        --symplectic Euler - update velocity before updating position
        modelWithForces =
            { model
                | kiteVelocity = Vec2.add model.kiteVelocity (Vec2.scale (timeStep / GameConstants.kiteWeight) forcesKite)
            }

        modelWithImpulse =
            { modelWithForces
                | kiteVelocity =
                    impulseOnKite modelWithForces --TODO lano se musi pridat do impulse
            }
    in
        { modelWithImpulse
            | kitePos =
                Vec2.add modelWithImpulse.kitePos (Vec2.scale timeStep modelWithImpulse.kiteVelocity)
                    |> correctKitePos modelWithImpulse --TODO correct kitePos je spatne - MUSI menit velocity
            , debugArrows =  [
                DebugArrow "velocity" "green" model.kitePos modelWithImpulse.kiteVelocity
            ]
            ++ debugArrowsForce
                
        }


forcesOnKite : Model -> (Float2, List DebugArrow)
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
                ( -normalizedAirVelocityY, normalizedAirVelocityX )
    in
        (gravityForce
            |> Vec2.add (Debug.log "Drag: " dragForce)
            |> Vec2.add (Debug.log "Lift" liftForce)
        , [ DebugArrow "drag" "red" model.kitePos dragForce
        , DebugArrow "lift" "blue" model.kitePos liftForce

        ])


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
    2


forceTransfer : Model -> Float2 -> Float2
forceTransfer model forcesKite =
    let
        tether =
            (Vec2.sub model.kitePos model.anchorPos)

        distanceToKite =
            Vec2.length tether
    in
        if distanceToKite >= model.tetherLength then
            Vec2.scale -(((Vec2.dot forcesKite tether)) / (Vec2.lengthSquared tether)) tether
        else
            ( 0, 0 )


correctKitePos : Model -> Float2 -> Float2
correctKitePos model proposedPosition =
    let
        tether =
            (Vec2.sub proposedPosition model.anchorPos)

        distanceToKite =
            Vec2.length tether
    in
        if distanceToKite >= model.tetherLength then
            Vec2.scale model.tetherLength (Vec2.normalize tether)
                |> Vec2.add model.anchorPos
        else
            proposedPosition
