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
        forcesKite =
            forcesOnKite model

        --symplectic Euler - update velocity before updating position
        modelWithForces =
            { model
                | kiteVelocity = Vec2.add model.kiteVelocity (Vec2.scale timeStep forcesKite)
            }

        modelWithImpulse =
            { modelWithForces
                | kiteVelocity =
                        impulseOnKite modelWithForces
            }
    in
        { modelWithImpulse
            | kitePos = Vec2.add modelWithImpulse.kitePos (Vec2.scale timeStep modelWithImpulse.kiteVelocity)
        }


forcesOnKite : Model -> Float2
forcesOnKite model =
    let 
        kiteY =
            (Vec2.getY model.kitePos)
    in
        if kiteY > 0.001 then
            GameConstants.gravity
        else
            (0, 0)


impulseOnKite : Model -> Float2
impulseOnKite model =
    let
        kiteY =
            (Vec2.getY model.kitePos)
        (kiteVelocityX, kiteVelocityY) =
             model.kiteVelocity
    in
        if  (kiteY < -0.001) && (kiteVelocityY < 0) then
            ( kiteVelocityX, -0.3 * kiteVelocityY)
        else
            model.kiteVelocity
