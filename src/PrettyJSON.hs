module PrettyJSON
  ( renderJValue
  ) where

import SimpleJSON (JValue(..))

renderJValue :: JValue -> String
renderJValue JNull         = "null"
renderJValue (JBool True)  = "true"
renderJValue (JBool False) = "false"
renderJValue (JNumber num) = show num
renderJValue (JString str) = show str
renderJValue _             = "<complex value>" 