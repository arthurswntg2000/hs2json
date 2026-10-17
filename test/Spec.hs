{-# LANGUAGE TemplateHaskell #-}
module Main (main) where

import Prelude hiding ((<>))
import Control.Monad (unless, liftM, liftM2)
import Data.List (intersperse)
import System.Exit (exitFailure)
import Test.QuickCheck

import Prettify (Doc(..), empty, char, double, concatDoc, punctuate, fill, nest, text, line, compact, pretty, (<>))
import PrettyJSON (renderJValue)
import SimpleJSON (JValue(..), getString, getInt, getDouble, getBool, getObject, getArray, isNull)
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

-- gerador de JValue (capítulo 9): a profundidade é limitada por sized e o
-- comprimento das listas por resize (n `div` 2); sem o resize, o listOf usa
-- o tamanho ambiente do QuickCheck e a árvore cresce até travar a memória
instance Arbitrary JValue where
  arbitrary = sized genJValue

genJValue :: Int -> Gen JValue
genJValue n
  | n <= 0    = folha
  | otherwise = oneof [ folha
                      , JArray  <$> resize (n `div` 2) (listOf (genJValue (n `div` 2)))
                      , JObject <$> resize (n `div` 2) (listOf campo) ]
  where
    campo = (,) <$> arbitrary <*> genJValue (n `div` 2)
    folha = oneof [ return JNull
                  , JBool   <$> arbitrary
                  , JNumber <$> genNumero
                  , JString <$> arbitrary ]

genNumero :: Gen Double
genNumero = arbitrary `suchThat` (\d -> not (isNaN d || isInfinite d))

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

-- compact de um documento de texto puro devolve a própria string (capítulo 9)
prop_compact_text :: String -> Bool
prop_compact_text s = compact (text s) == s

-- pretty de um documento sem softline não depende da largura (exercício 1 do capítulo 9)
prop_pretty_text :: Int -> String -> Bool
prop_pretty_text w s = pretty w (text s) == s

-- accessors: cada um devolve o conteúdo certo para o seu construtor
prop_getString :: String -> Bool
prop_getString s = getString (JString s) == Just s

prop_getBool :: Bool -> Bool
prop_getBool b = getBool (JBool b) == Just b

prop_getDouble :: Property
prop_getDouble = forAll genNumero $ \d -> getDouble (JNumber d) == Just d

prop_getInt :: Property
prop_getInt = forAll (choose (-100000, 100000)) $ \n -> getInt (JNumber (fromIntegral n)) == Just n

-- accessors: com o construtor errado, devolvem Nothing
prop_accessorsCoerentes :: JValue -> Bool
prop_accessorsCoerentes v =
  case v of
    JNull       -> isNull v && nenhum [s, i, d, b, o, a]
    JBool x     -> not (isNull v) && getBool v == Just x && nenhum [s, i, d, o, a]
    JNumber x   -> not (isNull v) && getDouble v == Just x && getInt v /= Nothing && nenhum [s, b, o, a]
    JString x   -> not (isNull v) && getString v == Just x && nenhum [i, d, b, o, a]
    JArray xs   -> not (isNull v) && getArray v == Just xs && nenhum [s, i, d, b, o]
    JObject xs  -> not (isNull v) && getObject v == Just xs && nenhum [s, i, d, b, a]
  where
    s = fmap (const ()) (getString v)
    i = fmap (const ()) (getInt v)
    d = fmap (const ()) (getDouble v)
    b = fmap (const ()) (getBool v)
    o = fmap (const ()) (getObject v)
    a = fmap (const ()) (getArray v)
    nenhum = all (== Nothing)

prop_isNull :: JValue -> Bool
prop_isNull v = isNull v == (v == JNull)

-- escapes: a saída de uma string não tem caractere de controle, DEL nem acima de \xff
prop_escapesSeguros :: String -> Bool
prop_escapesSeguros s = all seguro out && take 1 out == "\"" && take 1 (reverse out) == "\""
  where out        = compact (renderJValue (JString s))
        seguro c   = c >= ' ' && c /= '\x7f' && c <= '\xff'

-- escapes: casos conhecidos
prop_escapesConhecidos :: Property
prop_escapesConhecidos =
  once (   render "a\nb"   == "\"a\\nb\""
        && render "a\tb"   == "\"a\\tb\""
        && render "a\"b"   == "\"a\\\"b\""
        && render "a\\b"   == "\"a\\\\b\""
        && render "\233"   == "\"\233\""
        && render "\1234"  == "\"\\u04d2\""
        && render "\128512" == "\"\\ud83d\\ude00\"" )
  where render = compact . renderJValue . JString

-- layout: pretty (em qualquer largura) e compact só diferem em espaços e quebras de linha
-- (dentro de strings JSON as quebras são escapadas, então \n na saída é sempre layout)
prop_layoutEquivalente :: JValue -> Property
prop_layoutEquivalente v =
  forAll (choose (1, 100)) $ \w ->
    semLayout (pretty w d) == semLayout (compact d)
  where d          = renderJValue v
        semLayout  = filter (`notElem` " \n")

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