module Main where

import SimpleJSON
import PrettyJSON

main :: IO ()
main = do
  putStrLn (renderJValue (JBool True))
  putStrLn (renderJValue (JNumber 42.0))
  putStrLn (renderJValue JNull)