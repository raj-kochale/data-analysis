{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Redundant return" #-}
{-# HLINT ignore "Move brackets to avoid $" #-}
{-# LANGUAGE DeriveGeneric #-}

module Main where

import Prelude
import qualified Data.ByteString.Lazy as BL
import GetWeather ( Weather(..), Location(..), Current(..), getWeatherData )
import GoogleLLM ( generateContent )
import Data.List (find,intercalate)
import Data.List.Split (splitOn)
import Data.Maybe (fromMaybe)
import Data.Time
import GHC.Generics
import Data.Aeson (FromJSON, decode, encode, ToJSON, Value)
import qualified Data.ByteString.Char8 as C
import Data.ByteString (split)


data MealPreference = MealPreference
  { time :: String
  , preferred_cuisines :: [String]
  } deriving (Show, Generic)

instance FromJSON MealPreference

data FoodPreferences = FoodPreferences {
  temperature :: String,
  preferred_foods :: [String]
} deriving (Show, Generic)

instance FromJSON FoodPreferences

data MyJSON = MyJSON {
  candidates :: [Candidate]
} deriving (Show, Generic)

instance FromJSON MyJSON

data Candidate = Candidate {
  parts :: [Part]
} deriving (Show, Generic)

instance FromJSON Candidate

data Part = Part {
  text :: String
} deriving (Show, Generic)

instance FromJSON Part

-- get json valus of preferred cuisine from json file
getPreferredCuisines :: String -> IO (Maybe [String])
getPreferredCuisines time = do
    contents <- BL.readFile "data/meal_preferences.json"
    let preferences = decode contents :: Maybe [MealPreference]
    return (lookup time (maybe [] (map (\p -> (Main.time p, preferred_cuisines p))) preferences))

-- get json values of preferred foods from json file
getFoodPreferences :: String -> IO (Maybe FoodPreferences)
getFoodPreferences filename = do
  contents <- BL.readFile "data/food_preferences.json"
  let preferences = decode contents :: Maybe [FoodPreferences]
  return (find (\p -> temperature p == "Below 10°C") (fromMaybe [] preferences))

jsonFile :: FilePath
jsonFile = "data/meal_preferences.json"

getJSON :: IO BL.ByteString
getJSON = BL.readFile jsonFile

splitDateAndTime :: String -> String
splitDateAndTime dateTime = last $ splitOn " " dateTime

main :: IO ()
main = do
    weather <- getWeatherData
    case weather of
        Just w -> do
            let currentTime = localtime $ location w
            let dateTime = currentTime
            let time = splitDateAndTime dateTime
            let currentTemp = temp_c $ current w
            putStrLn $ "Current Temperature: " ++ show currentTemp
            -- Get preferred cuisines
            let time = currentTime
            let timeRange
                  | time >= "06:00" && time <= "10:00" = "06:00 - 10:00"
                  | time >= "10:00" && time <= "11:00" = "10:00 - 11:00"
                  | time >= "11:00" && time <= "14:00" = "11:00 - 14:00"
                  | time >= "15:00" && time <= "18:00" = "15:00 - 18:00"
                  | time >= "18:00" && time <= "21:00" = "18:00 - 21:00"
                  | otherwise = "NA"
            cuisines <- getPreferredCuisines timeRange
            let flatCuisines = concat cuisines
            putStrLn $ "Preferred cuisines: " ++ intercalate ", " flatCuisines
            -- Get preferred_foods from the weather data based on the current temperature 
            let temp
                  | currentTemp < 10 = "Below 10°C"
                  | currentTemp >= 10 && currentTemp < 20 = "10°C - 25°C"
                  | currentTemp >= 20 && currentTemp < 30 = "Above 25°C"
                  | otherwise = "NA"
            prefs <- getFoodPreferences "Below 10°C"
            case prefs of
                Just p -> do
                    putStrLn $ "Preferred Foods: " ++ show (preferred_foods p)
                    
            -- Request for the Billboard top artists by the Google LLM
            resContent <- generateContent "Give billboard top 10 artists their hometown's famous food"

            -- Write the content to a file
            let lazyContent = BL.fromStrict resContent
            BL.writeFile "data/billboard_top_artists.json" lazyContent

            -- Request for the content generated by the Google LLM
            resContent <- generateContent $ "Please suggest me " ++ intercalate ", " flatCuisines ++
                case prefs of
                    Just p -> do
                        show (preferred_foods p)
                    
            -- Write the content to a file
            let lazyContent = BL.fromStrict resContent
            BL.writeFile "data/GoogleLLM.json" lazyContent

