-- src/SimpleJSON.hs
-- Tipo de dados algébrico para representar os valores possíveis
module SimpleJSON
  ( JValue(..)
  , getString
  , getInt
  , getDouble
  , getBool
  , getObject
  , getArray
  , isNull
  ) where

-- AST do JSON
data JValue = JNull
            | JBool Bool
            | JNumber Double
            | JString String
            | JArray [JValue]
            | JObject [(String, JValue)]
            deriving (Eq, Show)

-- Accessors (funções seguras de extração)
getString :: JValue -> Maybe String
getString (JString s) = Just s
getString _           = Nothing

getInt :: JValue -> Maybe Int
getInt (JNumber n) = Just (truncate n)
getInt _           = Nothing

getDouble :: JValue -> Maybe Double
getDouble (JNumber n) = Just n
getDouble _           = Nothing

getBool :: JValue -> Maybe Bool
getBool (JBool b) = Just b
getBool _         = Nothing

getObject :: JValue -> Maybe [(String, JValue)]
getObject (JObject o) = Just o
getObject _           = Nothing

getArray :: JValue -> Maybe [JValue]
getArray (JArray a) = Just a
getArray _          = Nothing

isNull :: JValue -> Bool
isNull JNull = True
isNull _     = False