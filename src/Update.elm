module Update exposing (update)

import Types exposing (..)
import Msg
import Time
import GameConstants
import LevelGenerator
import Random
import Vector2 as Vec2 exposing (Float2)
import Char

update : Msg.Msg -> Model -> ( Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.Frame time ->
            if model.paused then 
                model ! []
            else
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

        Msg.KeyPress code ->
            (case Char.fromCode code of
                'q' ->
                    { model | windSpeed = model.windSpeed - 0.5}
                'w' ->
                    { model | windSpeed = model.windSpeed + 0.5}
                'a' ->
                    { model | kiteLiftCoefficient = model.kiteLiftCoefficient - 0.05}
                's' ->
                    { model | kiteLiftCoefficient = model.kiteLiftCoefficient + 0.05}
                'd' ->
                    { model | kiteDragCoefficient = model.kiteDragCoefficient - 0.05}
                'f' ->
                    { model | kiteDragCoefficient = model.kiteDragCoefficient + 0.05}
                'o' ->
                    { model | debugArrowsScale = model.debugArrowsScale - 0.05}
                'p' ->
                    { model | debugArrowsScale = model.debugArrowsScale + 0.05}
                'k' ->
                    { model | physicsTimeWarp = max (model.physicsTimeWarp - 0.05) 0.05}
                'l' ->
                    { model | physicsTimeWarp = model.physicsTimeWarp + 0.05}
                'n' ->
                    { model | physicsFrameSkip = max (model.physicsFrameSkip - 0.5) 0.5}
                'm' ->
                    { model | physicsFrameSkip = model.physicsFrameSkip + 0.5}
                ' ' ->
                    { model | paused = not model.paused}
                'v' ->
                    (updatePhysics (GameConstants.physicsUpdateTime * model.physicsTimeWarp) model)
                'x' ->
                    jumpPressed model
                _ -> model
            ) ! []       


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
    else if timeAccumulator > GameConstants.physicsUpdateTime * model.physicsFrameSkip then
        updatePhysicsWrapper
            (timeAccumulator - GameConstants.physicsUpdateTime * model.physicsFrameSkip)
            (updatePhysics (GameConstants.physicsUpdateTime * model.physicsTimeWarp) model)
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
                | playerVelocity = Vec2.add model.playerVelocity (Vec2.scale (timeStep / GameConstants.playerMass) forcesPlayer)
                , kiteVelocity = Vec2.add model.kiteVelocity (Vec2.scale (timeStep / GameConstants.kiteMass) forcesKite)
            }

        modelWithImpulse =
            {-let 
                (playerImpulse, kiteImpulse) = tetherImpulse modelWithForces
            in
                { modelWithForces 
                    | playerVelocity = Vec2.add playerImpulse modelWithForces.playerVelocity
                    , kiteVelocity = Vec2.add kiteImpulse modelWithForces.kiteVelocity
                }-}
            modelWithForces

        kitePosWithImpulse =
            Vec2.add modelWithImpulse.kitePos (Vec2.scale timeStep modelWithImpulse.kiteVelocity)

        playerPosWithImpulse =
            Vec2.add modelWithImpulse.playerPos (Vec2.scale timeStep modelWithImpulse.playerVelocity)

        ( correctKitePos, correctKiteVelocity ) =
            correctKiteForTether modelWithImpulse timeStep kitePosWithImpulse modelWithImpulse.kiteVelocity
                |> correctForWater |> correctForMaxVelocity

        ( correctPlayerPos, correctPlayerVelocity ) =
            ( playerPosWithImpulse, modelWithImpulse.playerVelocity )
                |> correctForJumpState modelWithImpulse.jumpState
                |> correctForWater |> correctForMaxVelocity
    in
        { modelWithImpulse
            | kitePos = correctKitePos
            , kiteVelocity = correctKiteVelocity
            , playerPos = correctPlayerPos
            , playerVelocity = correctPlayerVelocity
            , jumpState = updateJumpState modelWithImpulse timeStep
            , totalTime = model.totalTime + timeStep
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
            Vec2.scale GameConstants.kiteMass GameConstants.gravity

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
                --TODO use both components of air velocity, use them to compute lift coeff
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
            Vec2.scale GameConstants.playerMass GameConstants.gravity

        playerY = 
            Vec2.getY model.playerPos

        frictionForce =
            if (playerY < GameConstants.waterLevelY + GameConstants.waterFrictionTolerance) then
                let
                    velocityX =
                        Vec2.getX model.playerVelocity

                    sign =
                        if velocityX > 0 then
                            -1
                        else
                            1
                    smoothingCoefficient =
                        if playerY < GameConstants.waterLevelY then 
                            1
                        else 
                            1 - ((playerY - GameConstants.waterLevelY) / GameConstants.waterFrictionTolerance)
                in
                    ( sign * velocityX ^ 2 * smoothingCoefficient * (coefficientOfFriction model), 0 )
            else
                ( 0, 0 )
    in
        gravityForce
            |> Vec2.add frictionForce


coefficientOfFriction : Model -> Float
coefficientOfFriction model =
    3


coefficientOfDrag : Model -> Float
coefficientOfDrag model =
    case model.jumpState of
        None ->
            model.kiteDragCoefficient
        Preparing time ->
            model.kiteDragCoefficient * 0.5
        _ ->
             model.kiteDragCoefficient 


coefficientOfLift : Model -> Float
coefficientOfLift model =
    case model.jumpState of
        None ->
            model.kiteLiftCoefficient
        _ ->
            model.kiteLiftCoefficient * 2.5


forceTransferKite : Model -> Float2 -> Float2 -> Float2
forceTransferKite model forcesKite forcesPlayer =
    let
        tether =
            (Vec2.sub model.kitePos model.playerPos)

        distanceToKite =
            Vec2.length tether

        rampEnd = model.tetherLength - GameConstants.tetherForceTransferTolerance
        rampStart = rampEnd - GameConstants.tetherForceTransferRamp
    in
        let
            distanceFactor =
                if distanceToKite >= rampStart then
                    (distanceToKite - rampStart) * 100
                else 
                    0
                --(2 ^ ((distanceToKite - rampEnd) * 10))
                {-if distanceToKite >= rampEnd then
                    (((distanceToKite - rampEnd) * 3) ^ 2) * 2 + 1
                else if distanceToKite < rampStart then
                    0
                else
                    ((distanceToKite - rampStart) / (rampEnd - rampStart))
                -}
            {-magnitudeKite =
                ((Vec2.dot forcesKite tether)) / (Vec2.lengthSquared tether)

            magnitudePlayer =
                ((Vec2.dot forcesPlayer tether)) / (Vec2.lengthSquared tether)
-}
            magnitudeTotal =
                --max 0 (magnitudeKite - magnitudePlayer)
                30
        in
            Vec2.scale (-magnitudeTotal * distanceFactor)
             (Vec2.normalize tether)


correctKiteForTether : Model -> Float -> Float2 -> Float2 -> ( Float2, Float2 )
correctKiteForTether model timeStep proposedPosition proposedVelocity =
    let
        tether =
            (Vec2.sub proposedPosition model.playerPos)

        distanceToKite =
            Vec2.length tether
    in
        {-if distanceToKite >= model.tetherLength then
            let
                newPosition =
                    Vec2.scale model.tetherLength (Vec2.normalize tether)
                        |> Vec2.add model.playerPos
            in
                ( newPosition
                , Vec2.scale
                    (1 / timeStep) 
                    (Vec2.sub newPosition proposedPosition)
                    |> Vec2.add proposedVelocity
                )
        else -}
            ( proposedPosition, proposedVelocity )


correctForWater : ( Float2, Float2 ) -> ( Float2, Float2 )
correctForWater ( pos, velocity ) =
    if Vec2.getY pos < GameConstants.waterLevelY then
        ( ( Vec2.getX pos, GameConstants.waterLevelY ), ( Vec2.getX velocity, GameConstants.waterLevelY ) )
    else
        ( pos, velocity )

correctForMaxVelocity : ( Float2, Float2 ) -> ( Float2, Float2 )
correctForMaxVelocity ( pos, velocity ) =
    if Vec2.lengthSquared velocity > GameConstants.maxVelocitySquared then
        ( pos, Vec2.scale GameConstants.maxVelocity (Vec2.normalize velocity))
    else
        ( pos, velocity )

correctForJumpState : JumpState -> ( Float2, Float2 ) -> ( Float2, Float2 )
correctForJumpState jumpState ( pos, velocity ) =
    case jumpState of 
        Rising -> ( pos, velocity )
        Descending -> ( pos, velocity )
        _ ->
            ( (Vec2.getX pos, GameConstants.waterLevelY), (Vec2.getX velocity, 0))

jumpPressed: Model -> Model 
jumpPressed model = 
    let
        newJumpState = 
            case model.jumpState of
                None -> Preparing GameConstants.maxJumpPreparingTime
                _ -> model.jumpState
    in
        { model | jumpState = newJumpState }

updateJumpState: Model -> Float -> JumpState
updateJumpState model timeStep =
    case model.jumpState of
        None -> None
        Preparing time -> 
            if 
                time < 0 ||
                 ((Vec2.getX model.playerPos) > (Vec2.getX model.kitePos) - 1 )             
            then
                Rising
            else
                Preparing (time - timeStep)
        Rising ->
            if Vec2.getY model.playerVelocity < 0 then
                Descending
            else
                Rising
        Descending ->
            if Vec2.getY model.playerPos < GameConstants.waterLevelY + 0.01 then
                None
            else
                Descending

debugArrowForce : String -> String -> Float2 -> Float2 -> DebugArrow
debugArrowForce name color start vector =
    DebugArrow name color start (Vec2.scale 0.1 vector)
