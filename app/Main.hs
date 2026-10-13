module Main where

import SimpleJSON

main :: IO ()
main = print (JObject [("foo", JNumber 1.0), ("bar", JBool False)])