{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Redundant return" #-}


module Main where

import SerpAPI ( getFromSerpApi )
import Prelude
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Lazy as BL
import GetWeather ( Weather(..), Location(..), Current(..), getWeatherData )
import ParsePreferences ( FoodPreferences(..), getFoodPreferences )
import GoogleLLM ( generateContent )


-- import GoogleLLM (generateContent)


jsonFile :: FilePath
jsonFile = "data/meal_preferences.json"

getJSON :: IO BL.ByteString
getJSON = BL.readFile jsonFile

main :: IO ()
main = do
    weather <- getWeatherData
    case weather of
        Just w -> do
            putStrLn $ "Current Time in New York: " ++ (localtime $ location w)
            putStrLn $ "Current Temperature in New York: " ++ (show $ temp_c $ current w)
        Nothing -> putStrLn "Could not get weather data"
    
    -- Request for the Billboard top 10 artists and their hometown
    resArtists <- getFromSerpApi "Billboard top 10 artists and their hometown"
    -- Convert resArtists into a JSON ByteString
    let jsonArtists = Aeson.encode resArtists
    -- Write the JSON ByteString to a file
    BL.writeFile "data/top_artists.json" jsonArtists

    -- Get food preferences
    prefs <- getFoodPreferences
    case prefs of
        Just p -> do
            putStrLn $ "Preferred Foods: " ++ show (preferred_foods p)
            putStrLn $ "Preferred Cuisines: " ++ show (preferred_cuisines p)
            putStrLn $ "Max Calories: " ++ show (max_calories p)
        Nothing -> putStrLn "Could not get food preferences"


    -- -- Request for the current time in New York
    -- resTime <- getFromSerpApi "current Time in New York in 24 hour format"    
    -- -- Convert resTime into a JSON ByteString
    -- let jsonTime = Aeson.encode resTime
    -- -- Write the JSON ByteString to a file
    -- BL.writeFile "data/real_time_output.json" jsonTime
    -- -- Request for the current temperature in New York
    -- resTemp <- getFromSerpApi "current temperature in New York in degrees Celsius"
    -- -- Convert resTemp into a JSON ByteString
    -- let jsonTemp = Aeson.encode resTemp
    -- -- Write the JSON ByteString to a file
    -- BL.writeFile "data/real_time_temperature.json" jsonTemp


    -- Generate content using the Google LLM API
    generateContent >>= \content -> do
        print content
        