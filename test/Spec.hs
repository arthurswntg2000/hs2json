module Main (main) where

import Prelude hiding ((<>))
import Control.Monad (unless)
import System.Exit (exitFailure)
import Test.QuickCheck

import Prettify (fill, nest, text, line, compact, pretty, (<>))
import PrettyJSON (renderJValue)
import SimpleJSON (JValue(..))

genTexto :: Gen String
genTexto = listOf (elements ['a' .. 'z'])

-- fill: o resultado tem max n (tamanho do texto) colunas
prop_fillLargura :: Property
prop_fillLargura =
  forAll genTexto $ \s ->
  forAll (choose (0, 40)) $ \n ->
    length (compact (fill n (text s))) == max n (length s)

-- fill não mexe num documento que já é mais largo que o limite
prop_fillNaoCorta :: Property
prop_fillNaoCorta =
  forAll genTexto $ \s ->
    compact (fill (length s - 1) (text s)) == s

-- nest indenta as linhas seguintes
prop_nestIndenta :: Property
prop_nestIndenta =
  once (pretty 80 (text "a" <> nest 4 (line <> text "b")) == "a\n    b")

exemplo :: JValue
exemplo = JObject [("nome", JString "Arthur"), ("notas", JArray [JNumber 10, JNumber 9.5])]

-- nest 0 não muda o resultado, em qualquer largura
prop_nestZero :: Property
prop_nestZero =
  forAll (choose (1, 100)) $ \w ->
    pretty w (nest 0 d) == pretty w d
  where d = renderJValue exemplo

-- strings JSON saem entre aspas
prop_stringsComAspas :: Property
prop_stringsComAspas =
  once (compact (renderJValue (JString "oi")) == "\"oi\"")

main :: IO ()
main = do
  resultados <- sequence
    [ quickCheckResult prop_fillLargura
    , quickCheckResult prop_fillNaoCorta
    , quickCheckResult prop_nestIndenta
    , quickCheckResult prop_nestZero
    , quickCheckResult prop_stringsComAspas
    ]
  unless (all isSuccess resultados) exitFailure