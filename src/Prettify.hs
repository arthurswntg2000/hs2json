module Prettify where

import Prelude hiding ((<>))

data Doc = Empty
         | Char Char
         | Text String
         | Line
         | Concat Doc Doc
         | Union Doc Doc
         deriving (Show, Eq)

empty :: Doc
empty = Empty

char :: Char -> Doc
char = Char

text :: String -> Doc
text "" = Empty
text s  = Text s

double :: Double -> Doc
double n = text (show n)

line :: Doc
line = Line

(<>) :: Doc -> Doc -> Doc
Empty <> y = y
x <> Empty = x
x <> y     = Concat x y

concatDoc :: [Doc] -> Doc
concatDoc = foldr (<>) empty

enclose :: Char -> Char -> Doc -> Doc
enclose left right d = char left <> d <> char right

punctuate :: Doc -> [Doc] -> [Doc]
punctuate _ []     = []
punctuate _ [d]    = [d]
punctuate p (d:ds) = (d <> p) : punctuate p ds

fsep :: [Doc] -> Doc
fsep = concatDoc

string :: String -> Doc
string = text