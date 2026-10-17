module Main where

import SimpleJSON
import PrettyJSON
import Prettify

main :: IO ()
main = do
  let value = JObject [("nome", JString "Arthur e Andre"), ("disciplina", JString "Haskell"), ("notas", JArray [JNumber 10.0, JNumber 9.5])]
  let doc = renderJValue value

  putStrLn "=== Impressao Compacta ==="
  putStrLn (compact doc)

  putStrLn "\n=== Impressao Pretty (largura 20) ==="
  putStrLn (pretty 20 doc)

  putStrLn "\n=== Impressao Pretty (largura 80) ==="
  putStrLn (pretty 80 doc)