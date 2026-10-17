module PrettyJSON
  ( renderJValue
  ) where

import Prelude hiding ((<>))
import Numeric (showHex)
import Data.Char (ord)
import Data.Bits (shiftR, (.&.))
import SimpleJSON (JValue(..))
import Prettify (Doc, string, text, double, char, (<>), fsep, concatDoc, enclose, punctuate)

renderJValue :: JValue -> Doc
renderJValue (JBool True)  = text "true"
renderJValue (JBool False) = text "false"
renderJValue JNull         = text "null"
renderJValue (JNumber num) = double num
renderJValue (JString str) = string str
renderJValue (JArray ary)  = series '[' ']' renderJValue ary
renderJValue (JObject obj) = series '{' '}' field obj
  where field (name, val)  = string name
                          <> text ": "
                          <> renderJValue val

series :: Char -> Char -> (a -> Doc) -> [a] -> Doc
series open close item = enclose open close
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
  where mustEscape char = char < ' ' || char == '\x7f' || char > '\xff'

simpleEscapes :: [(Char, String)]
simpleEscapes = zip " \b\n\r\t\\\"" [" ", "\\b", "\\n", "\\r", "\\t", "\\\\", "\\\""]

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