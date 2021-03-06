module Main exposing (..)

import Html
--import TimeTravel.Html.App as App

import Update
import View
import Msg exposing (Msg)
import Init exposing (..)
import Types exposing(..)
import Platform.Sub
import AnimationFrame
import Keyboard

main =
    Html.program
        { init = init
        , view = View.view
        , update = Update.update
        , subscriptions = subscriptions
        }

subscriptions : Model -> Platform.Sub.Sub Msg.Msg 
subscriptions _ = 
    Platform.Sub.batch [
        AnimationFrame.diffs Msg.Frame        
        , Keyboard.presses Msg.KeyPress
        ]
    


-- MODEL
