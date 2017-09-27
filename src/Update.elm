module Update exposing (update)

import Types exposing (..)
import Msg
import Time
import GameConstants
import LevelGenerator
import Random
import Vector2 as Vec2 exposing (Float2)


update : Msg.Msg -> Model -> ( Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.Frame time ->
            let
                baseUpdate =
                    updatePhysicsWrapper (model.timeAccumulator + (Time.inSeconds time)) model
            in
                if Vec2.getX model.playerPos > 10 then
                    (baseUpdate |> moveGraphics -10 10)
                        ! [ Random.generate Msg.AddGraphics (LevelGenerator.graphicsGenerator 10 20) ]
                else
                    baseUpdate ! []

        Msg.AddGraphics graphics ->
            { model | graphics = model.graphics ++ graphics } ! []


moveGraphics : Float -> Float -> Model -> Model
moveGraphics cutOff move model =
    let 
        moveVec = \(x,y) -> (x - move, y)
    in
    { model
        | playerPos = moveVec model.playerPos,
        kitePos = moveVec model.kitePos,
        windIndicatorX = model.windIndicatorX - move,
        graphics =
            model.graphics
                |> List.filter (\x -> (Vec2.getX x.pos) + (Vec2.getX x.size) > cutOff)
                |> List.map (\x -> { x | pos = moveVec x.pos })
    }


updatePhysicsWrapper : Float -> Model -> Model
updatePhysicsWrapper timeAccumulator model =
    if timeAccumulator > GameConstants.maxTimeAccumulator then
        updatePhysicsWrapper GameConstants.maxTimeAccumulator model
    else if timeAccumulator > GameConstants.physicsUpdateTime then
        updatePhysicsWrapper
            (timeAccumulator - GameConstants.physicsUpdateTime)
            (updatePhysics (GameConstants.physicsUpdateTime * GameConstants.physicsTimeWarp) model)
    else
        { model | timeAccumulator = timeAccumulator }


updatePhysics : Float -> Model -> Model
updatePhysics timeStep model =
    let
        ( forcesKiteBeforeTransfer, debugArrowsForce ) =
            forcesOnKite model

        forcesPlayerBeforeTransfer =
            forcesOnPlayer model

        forceTransfer =
            forceTransferKite model forcesKiteBeforeTransfer forcesPlayerBeforeTransfer

        forcesKite =
            Vec2.add forceTransfer forcesKiteBeforeTransfer

        forcesPlayer =
            Vec2.sub forcesPlayerBeforeTransfer forceTransfer

        --symplectic Euler - update velocity before updating position
        modelWithForces =
            { model
                | playerVelocity = Vec2.add model.playerVelocity (Vec2.scale (timeStep / GameConstants.playerWeight) forcesPlayer)
                , kiteVelocity = Vec2.add model.kiteVelocity (Vec2.scale (timeStep / GameConstants.kiteWeight) forcesKite)
            }

        modelWithImpulse =
            modelWithForces

        kitePosWithImpulse =
            Vec2.add modelWithImpulse.kitePos (Vec2.scale timeStep modelWithImpulse.kiteVelocity)

        playerPosWithImpulse =
            Vec2.add modelWithImpulse.playerPos (Vec2.scale timeStep modelWithImpulse.playerVelocity)

        ( correctKitePos, correctKiteVelocity ) =
            correctKiteForTether modelWithImpulse timeStep kitePosWithImpulse modelWithImpulse.kiteVelocity
                |> correctForWater

        ( correctPlayerPos, correctPlayerVelocity ) =
            ( playerPosWithImpulse, modelWithImpulse.playerVelocity )
                |> correctForWater
    in
        { modelWithImpulse
            | kitePos = correctKitePos
            , kiteVelocity = correctKiteVelocity
            , playerPos = correctPlayerPos
            , playerVelocity = correctPlayerVelocity
            , totalTime = model.totalTime + timeStep
            , windSpeed = 5 + (sin model.totalTime * 2)
            , windIndicatorX =
                if (model.windIndicatorX > 10) then
                    -10
                else
                    model.windIndicatorX + model.windSpeed * timeStep
            , debugArrows =
                [ DebugArrow "velocity" "green" model.kitePos correctKiteVelocity
                , DebugArrow "playerVelocity" "green" model.playerPos correctPlayerVelocity
                , DebugArrow "relativeVelocity" "gold" model.kitePos (Vec2.sub correctKiteVelocity correctPlayerVelocity)
                , debugArrowForce "transfer" "pink" model.playerPos (Vec2.scale -1 forceTransfer)
                , debugArrowForce "kiteBeforeTransfer" "cyan" model.kitePos forcesKiteBeforeTransfer
                , debugArrowForce "playerBeforeTransfer" "cyan" model.playerPos forcesPlayerBeforeTransfer
                ]
                    ++ debugArrowsForce
        }


forcesOnKite : Model -> ( Float2, List DebugArrow )
forcesOnKite model =
    let
        kiteY =
            (Vec2.getY model.kitePos)

        gravityForce =
            Vec2.scale GameConstants.kiteWeight GameConstants.gravity

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
            |> Vec2.add dragForce
            |> Vec2.add liftForce
        , [ debugArrowForce "drag" "red" model.kitePos dragForce
          , debugArrowForce "lift" "blue" model.kitePos liftForce
          ]
        )


forcesOnPlayer : Model -> Float2
forcesOnPlayer model =
    let
        gravityForce =
            Vec2.scale GameConstants.playerWeight GameConstants.gravity

        frictionForce =
            if (Vec2.getY model.playerPos < GameConstants.waterLevelY + 0.1) then
                let
                    velocityX =
                        Vec2.getX model.playerVelocity

                    sign =
                        if velocityX > 0 then
                            -1
                        else
                            1
                in
                    ( sign * velocityX ^ 2 * (coefficientOfFriction model), 0 )
            else
                ( 0, 0 )
    in
        gravityForce
            |> Vec2.add frictionForce


coefficientOfFriction : Model -> Float
coefficientOfFriction model =
    5


coefficientOfDrag : Model -> Float
coefficientOfDrag model =
    1


coefficientOfLift : Model -> Float
coefficientOfLift model =
    1


forceTransferKite : Model -> Float2 -> Float2 -> Float2
forceTransferKite model forcesKite forcesPlayer =
    let
        tether =
            (Vec2.sub model.kitePos model.playerPos)

        distanceToKite =
            Vec2.length tether
    in
        let
            distanceFactor =
                if distanceToKite >= model.tetherLength then
                    1
                else if distanceToKite < model.tetherLength - GameConstants.tetherForceTransferTolerance then
                    0
                else
                    ((GameConstants.tetherForceTransferTolerance - model.tetherLength + distanceToKite) / GameConstants.tetherForceTransferTolerance) ^ 2

            magnitudeKite =
                ((Vec2.dot forcesKite tether)) / (Vec2.lengthSquared tether)

            magnitudePlayer =
                ((Vec2.dot forcesPlayer tether)) / (Vec2.lengthSquared tether)

            magnitudeTotal =
                max 0 (magnitudeKite - magnitudePlayer)
        in
            Vec2.scale (-magnitudeTotal * distanceFactor) (Vec2.normalize tether)


correctKiteForTether : Model -> Float -> Float2 -> Float2 -> ( Float2, Float2 )
correctKiteForTether model timeStep proposedPosition proposedVelocity =
    let
        tether =
            (Vec2.sub proposedPosition model.playerPos)

        distanceToKite =
            Vec2.length tether
    in
        if distanceToKite >= model.tetherLength then
            let
                newPosition =
                    Vec2.scale model.tetherLength (Vec2.normalize tether)
                        |> Vec2.add model.playerPos
            in
                ( newPosition
                , Vec2.scale
                    (1 / timeStep)
                    (Debug.log "Correction" (Vec2.sub newPosition proposedPosition))
                    |> Vec2.add proposedVelocity
                )
        else
            ( proposedPosition, proposedVelocity )


correctForWater : ( Float2, Float2 ) -> ( Float2, Float2 )
correctForWater ( pos, velocity ) =
    if Vec2.getY pos < GameConstants.waterLevelY then
        ( ( Vec2.getX pos, GameConstants.waterLevelY ), ( Vec2.getX velocity, GameConstants.waterLevelY ) )
    else
        ( pos, velocity )


debugArrowForce : String -> String -> Float2 -> Float2 -> DebugArrow
debugArrowForce name color start vector =
    DebugArrow name color start (Vec2.scale 0.1 vector)
