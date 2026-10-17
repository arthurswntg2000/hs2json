module PrettyJSON
  ( renderJValue
  ) where

import Prelude hiding ((<>))
import Numeric (showHex)
import Data.Char (ord)
import Data.Bits (shiftR, (.&.))
import SimpleJSON (JValue(..))
import Prettify (Doc, text, double, char, (<>), fsep, concatDoc, enclose, punctuate, nest)

renderJValue :: JValue -> Doc
renderJValue (JBool True)  = text "true"
renderJValue (JBool False) = text "false"
renderJValue JNull         = text "null"
renderJValue (JNumber num) = double num
renderJValue (JString str) = stringDoc str
renderJValue (JArray ary)  = series '[' ']' renderJValue ary
renderJValue (JObject obj) = series '{' '}' field obj
  where field (name, val)  = stringDoc name
                          <> text ": "
                          <> renderJValue val

-- Os itens quebrados em várias linhas ficam indentados 2 espaços.
series :: Char -> Char -> (a -> Doc) -> [a] -> Doc
series open close item = enclose open close
                       . nest 2
                       . fsep
                       . punctuate (char ',')
                       . map item

stringDoc :: String -> Doc
stringDoc = enclose '"' '"' . concatDoc . map oneChar

oneChar :: Char -> Doc
oneChar c = case lookup c simpleEscapes of
              Just ch -> text ch
              Nothing | mustEscape c -> hexEscape c
                      | otherwise    -> char c
  where mustEscape ch = ch < ' ' || ch == '\x7f' || ch > '\xff'

simpleEscapes :: [(Char, String)]
simpleEscapes = zipWith ch "\b\n\f\r\t\\\"" "bnfrt\\\""
  where ch a b = (a, ['\\', b])

hexEscape :: Char -> Doc
hexEscape c
  | a < 0x10000 = smallHex a
  | otherwise   = astral (a - 0x10000)
  where a = ord c

smallHex :: Int -> Doc
smallHex n = text "\\u"
          <> text (replicate (4 - length hex) '0')
          <> text hex
  where hex = showHex n ""

astral :: Int -> Doc
astral n = smallHex (a + 0xd800) <> smallHex (b + 0xdc00)
  where a = (n `shiftR` 10) .&. 0x3ff
        b = n .&. 0x3ff