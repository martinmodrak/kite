module GameConstants exposing(..)

import Vector2 exposing (Float2)

physicsUpdateTime: Float
physicsUpdateTime = 0.04

physicsTimeWarp : Float
physicsTimeWarp = 1

maxTimeAccumulator: Float
maxTimeAccumulator = 1

kiteWeight: Float
kiteWeight = 0.1

playerWeight: Float
playerWeight = 2

tetherForceTransferTolerance: Float
tetherForceTransferTolerance = 0.2

velocityCorrectionDamping: Float
velocityCorrectionDamping =
    1

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