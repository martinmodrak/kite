module GameConstants exposing(..)

import Matrix3 
import Vector2 exposing (Float2)

physicsUpdateTime: Float
physicsUpdateTime = 0.04

physicsTimeWarp : Float
physicsTimeWarp = 0.1

maxTimeAccumulator: Float
maxTimeAccumulator = 1

kiteWeight: Float
kiteWeight = 0.1

playerWeight: Float
playerWeight = 2

tetherForceTransferTolerance: Float
tetherForceTransferTolerance = 0.1

waterLevelY: Float
waterLevelY = 0

gravity: Float2
gravity = (0, -10)

windDirection: Float2
windDirection = (1, 0)

viewMatrix: Matrix3.Float3x3
viewMatrix = ((100,  0   , 400),
              (0   , -100, 600),
              (0   ,  0   , 1  ))