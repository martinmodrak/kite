module GameConstants exposing(..)

import Vector2 exposing (Float2)

physicsUpdateTime: Float
physicsUpdateTime = 0.02

maxTimeAccumulator: Float
maxTimeAccumulator = 1

kiteMass: Float
kiteMass = 1

playerMass: Float
playerMass = 7.5

tetherRestitution: Float
tetherRestitution = 0.65

tetherForceTransferTolerance: Float
tetherForceTransferTolerance = 0.05

tetherForceTransferRamp : Float
tetherForceTransferRamp = 0.1

velocityCorrectionDamping: Float
velocityCorrectionDamping =
    1

maxVelocity: Float
maxVelocity = 50

maxVelocitySquared: Float
maxVelocitySquared = maxVelocity ^ 2

waterLevelY: Float
waterLevelY = 0

gravity: Float2
gravity = (0, -10)

windDirection: Float2
windDirection = (1, 0)

viewScaleX : Float
viewScaleX = 100

viewScaleY : Float
viewScaleY = -100

playerPosOnScreen : Float2
playerPosOnScreen = 
    (400, 500)

{-
windBase : Float
windBase = 15

windFluctuation : Float
windFluctuation = 2
-}

waterFrictionTolerance : Float
waterFrictionTolerance = 0.1