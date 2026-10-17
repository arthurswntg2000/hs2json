{-# LANGUAGE TemplateHaskell #-}
module Main (main) where

import Prelude hiding ((<>))
import Control.Monad (unless, liftM, liftM2)
import Data.List (intersperse)
import System.Exit (exitFailure)
import Test.QuickCheck

import Prettify (Doc(..), empty, char, double, concatDoc, punctuate, fill, nest, text, line, compact, pretty, (<>))
import PrettyJSON (renderJValue)
import SimpleJSON (JValue(..))
import QuickTestes

genTexto :: Gen String
genTexto = listOf (elements ['a' .. 'z'])

-- gerador de documentos aleatórios (capítulo 8)
instance Arbitrary Doc where
  arbitrary =
    oneof [ return Empty
          , liftM  Char   arbitrary
          , liftM  Text   arbitrary
          , return Line
          , liftM2 Concat arbitrary arbitrary
          , liftM2 Union  arbitrary arbitrary
          , liftM2 Nest   arbitrary arbitrary ]

-- empty é a identidade de (<>), dos dois lados
prop_empty_id :: Doc -> Bool
prop_empty_id x =
    empty <> x == x
  &&
    x <> empty == x

-- operadores básicos de documentos
prop_char :: Char -> Bool
prop_char c   = char c   == Char c

prop_text :: String -> Bool
prop_text s   = text s   == if null s then Empty else Text s

prop_line :: Bool
prop_line     = line     == Line

prop_double :: Double -> Bool
prop_double d = double d == text (show d)

-- concatDoc contra um modelo sobre listas
prop_concatDoc :: [Doc] -> Bool
prop_concatDoc xs = concatDoc xs == glue xs
    where
        glue []     = empty
        glue (d:ds) = d <> glue ds

-- punctuate contra um modelo: intercalar e depois eliminar os Empty espalhados
-- (a versão ingênua, só com intersperse, falha por causa dos Empty)
prop_punctuate' :: Doc -> [Doc] -> Bool
prop_punctuate' s xs = punctuate s xs == combine (intersperse s xs)
    where
        combine []           = []
        combine [x]          = [x]
        combine (x:Empty:ys) = x : combine ys
        combine (Empty:y:ys) = y : combine ys
        combine (x:y:ys)     = x `Concat` y : combine ys

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

return []
runTests :: IO Bool
runTests = $quickCheckAll

main :: IO ()
main = do
  passou <- runTests
  resultados <- sequence
    [ -- ordenação (capítulo 8); prop_minimum falha de propósito, fica de fora
      quickCheckResult (prop_idempotent  :: [Integer] -> Bool)
    , quickCheckResult (prop_minimum'    :: [Integer] -> Property)
    , quickCheckResult (prop_ordered     :: [Integer] -> Bool)
    , quickCheckResult (prop_permutation :: [Integer] -> Bool)
    , quickCheckResult (prop_maximum     :: [Integer] -> Property)
    , quickCheckResult (prop_append      :: [Integer] -> [Integer] -> Property)
    , quickCheckResult (prop_sort_model  :: [Integer] -> Bool)
    ]
  unless (passou && all isSuccess resultados) exitFailure