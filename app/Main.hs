module Main (main) where

import Prelude hiding ((<>))
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

  putStrLn "\n=== fill 12 e fill 2 (a barra mostra onde o texto termina) ==="
  putStrLn (pretty 80 (fill 12 (text "nome") <> text "|"))
  putStrLn (pretty 80 (fill 2 (text "nome") <> text "|"))

  putStrLn "\n=== nest 4 ==="
  putStrLn (pretty 80 (text "abre" <> nest 4 (line <> text "dentro") <> line <> text "fecha"))