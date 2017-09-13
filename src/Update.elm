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
        forcesKite = forcesOnKite model
    in
        {model | 
            kitePos = Vec2.add model.kitePos model.kiteVelocity,
            kiteVelocity = Vec2.add model.kiteVelocity forcesKite
        }

forcesOnKite: Model -> Float2
forcesOnKite model =
    if (Vec2.getY model.kitePos) < 800 then 
        (0, GameConstants.gravity)
    else
        (0,-GameConstants.gravity)
