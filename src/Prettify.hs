module Prettify
  ( Doc(..)
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
  , fill
  , nest
  ) where

import Prelude hiding ((<>))

data Doc = Empty
         | Char Char
         | Text String
         | Line
         | Concat Doc Doc
         | Union Doc Doc
         | Nest Int Doc
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

-- Exercício 2: indentação.
-- 'nest i d' aumenta em i espaços a indentação das quebras de linha dentro de d.
nest :: Int -> Doc -> Doc
nest i d = Nest i d

-- Exercício 1: preenche com espaços até a largura dada (em colunas).
-- Se o documento já é mais largo, não acrescenta nada.
fill :: Int -> Doc -> Doc
fill width d = d <> text (replicate (width - docWidth d) ' ')

-- Coluna em que o documento termina, partindo da coluna 0.
-- Usa a primeira alternativa (achatada) de cada Union e ignora a indentação.
docWidth :: Doc -> Int
docWidth d = go 0 [d]
  where
    go col []     = col
    go col (x:xs) =
      case x of
        Empty      -> go col xs
        Char _     -> go (col + 1) xs
        Text s     -> go (col + length s) xs
        Line       -> go 0 xs
        Concat a b -> go col (a : b : xs)
        Nest _ a   -> go col (a : xs)
        Union a _  -> go col (a : xs)

-- Layout compacto (sem indentação e sem escolher largura)
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
            Nest _ a     -> transform (a:z)
            Union _ b    -> transform (b:z)

-- Combinadores para formatação bonita (pretty)
softline :: Doc
softline = group line

group :: Doc -> Doc
group d = flatten d `Union` d

flatten :: Doc -> Doc
flatten (Concat a b) = Concat (flatten a) (flatten b)
flatten (Nest _ d)   = flatten d
flatten Line         = Char ' '
flatten (Union a _)  = flatten a
flatten other        = other

-- Sem espaço sobrando no final: [a, b] e não [a, b ]
fsep :: [Doc] -> Doc
fsep []     = empty
fsep [d]    = d
fsep (d:ds) = d </> fsep ds

(</>) :: Doc -> Doc -> Doc
x </> y = x <> softline <> y

-- Pretty printer respeitando a largura máxima e a indentação.
-- A lista de trabalho guarda pares (indentação atual, documento).
pretty :: Int -> Doc -> String
pretty width x = best 0 [(0, x)]
  where
    best :: Int -> [(Int, Doc)] -> String
    best _ [] = ""
    best col ((i, d) : ds) =
      case d of
        Empty      -> best col ds
        Char c     -> c : best (col + 1) ds
        Text s     -> s ++ best (col + length s) ds
        Line       -> '\n' : replicate i ' ' ++ best i ds
        Concat a b -> best col ((i, a) : (i, b) : ds)
        Nest j a   -> best col ((i + j, a) : ds)
        Union a b  -> nicest col (best col ((i, a) : ds))
                                 (best col ((i, b) : ds))

    nicest :: Int -> String -> String -> String
    nicest col a b
      | (width - col) `fits` a = a
      | otherwise              = b

    fits :: Int -> String -> Bool
    fits w _ | w < 0 = False
    fits _ ""        = True
    fits _ ('\n':_)  = True
    fits w (_:cs)    = fits (w - 1) cs