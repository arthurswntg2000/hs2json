module Prettify
  ( Doc
  , empty
  , char
  , text
  , double
  , line
  , (<>)
  , concatDoc
  , enclose
  , fsep
  , punctuate
  , compact
  , pretty
  , softline
  , group
  , string
  ) where

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

string :: String -> Doc
string = text

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

-- Layout compact (sem quebras de linha/espaços extras)
compact :: Doc -> String
compact d = transform [d]
  where transform [] = ""
        transform (ds:z) =
          case ds of
            Empty        -> transform z
            Char c       -> c : transform z
            Text s       -> s ++ transform z
            Line         -> '\n' : transform z
            Concat a b   -> transform (a:b:z)
            Union _ b    -> transform (b:z)

-- Combinadores para formatação bonita (pretty)
softline :: Doc
softline = group line

group :: Doc -> Doc
group d = flatten d `Union` d

flatten :: Doc -> Doc
flatten (Concat a b) = Concat (flatten a) (flatten b)
flatten Line         = Char ' '
flatten (Union a _)  = flatten a
flatten other        = other

fsep :: [Doc] -> Doc
fsep = foldr (</>) empty

(</>) :: Doc -> Doc -> Doc
x </> y = x <> softline <> y

-- Pretty printer respeitando a largura máxima (width)
pretty :: Int -> Doc -> String
pretty width x = best 0 [x]
  where best col (d:ds) =
          case d of
            Empty        -> best col ds
            Char c       -> c : best (col + 1) ds
            Text s       -> s ++ best (col + length s) ds
            Line         -> '\n' : best 0 ds
            Concat a b   -> best col (a:b:ds)
            Union a b    -> nicest col (best col (a:ds)) (best col (b:ds))
        best _ [] = ""

        nicest col a b
          | (width - col) `fits` a = a
          | otherwise              = b

        fits w _ | w < 0 = False
        fits _ ""        = True
        fits _ ('\n':_)  = True
        fits w (c:cs)    = fits (w - 1) cs