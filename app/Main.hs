module Main where

import SimpleJSON
import PrettyJSON

main :: IO ()
main = do
  print (renderJValue (JBool True))
  print (renderJValue (JNumber 42.0))
  print (renderJValue (JArray [JBool True, JNumber 1.0]))
  print (renderJValue (JObject [("foo", JNumber 1.0), ("bar", JBool False)]))