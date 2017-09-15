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

        modelWithForces =
            { model
                | kitePos = Vec2.add model.kitePos (Vec2.scale timeStep model.kiteVelocity)
                , kiteVelocity = Vec2.add model.kiteVelocity (Vec2.scale timeStep forcesKite)
            }

        modelWithImpulse =
            { modelWithForces
                | kiteVelocity =
                    Vec2.add modelWithForces.kiteVelocity
                        (Vec2.scale timeStep (impulseOnKite modelWithForces))
            }
    in
        modelWithImpulse


forcesOnKite : Model -> Float2
forcesOnKite model =
     GameConstants.gravity


impulseOnKite : Model -> Float2
impulseOnKite model =
    let
        kiteY =
            (Vec2.getY model.kitePos)
    in
        if kiteY < 0 then
            ( 0, -10*kiteY )
        else
            ( 0, 0 )
