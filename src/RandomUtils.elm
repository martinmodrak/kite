module RandomUtils exposing (
        fixedGenerator
        , listMemberGenerator
        , exponentialGenerator
        , listOfGeneratorsToGeneratorOfList
    )

import Random
import Utils

fixedGenerator : a -> Random.Generator a
fixedGenerator value =
    --I do not consume the bool, but there is no way to create my own primitive generator
    Random.map (\_ -> value) Random.bool



--explicit head to always have something to return


listMemberGenerator : a -> List a -> Random.Generator a
listMemberGenerator listHead listTail =
    let
        numElements =
            (List.length listTail) + 1
    in
        Random.int 0 (numElements - 1)
            |> Random.map
                (\index ->
                    if index == 0 then
                        listHead
                    else
                        case Utils.listGet (index - 1) listTail of
                            Just x ->
                                x

                            Nothing ->
                                listHead
                )


listOfGeneratorsToGeneratorOfList : List (Random.Generator a) -> Random.Generator (List a)
listOfGeneratorsToGeneratorOfList listOfGenerators =
    case listOfGenerators of
        head :: tail ->
            Random.andThen
                (\list -> Random.map (\x -> x :: list) head)
                (listOfGeneratorsToGeneratorOfList tail)

        [] ->
            fixedGenerator []


exponentialInverseCDF : Float -> Float -> Float
exponentialInverseCDF mean y =
    -mean * logBase e (1 - y)


exponentialGenerator : Float -> Float -> Random.Generator Float
exponentialGenerator minimum mean =
    let
        distributionMean =
            mean - minimum
    in
        Random.map (exponentialInverseCDF distributionMean >> (+) minimum) (Random.float 0 1)
