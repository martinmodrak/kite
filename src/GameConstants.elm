module GameConstants exposing(..)

import Matrix3 
import Vector2 exposing (Float2)

physicsUpdateTime = 0.04

maxTimeAccumulator = 1

kiteWeight = 1

gravity: Float2
gravity = (0, -10)

viewMatrix: Matrix3.Float3x3
viewMatrix = ((100,  0   , 400),
              (0   , -100, 600),
              (0   ,  0   , 1  ))