-- src/QuickTestes.hs
{-# OPTIONS_GHC -Wno-x-partial #-}
module QuickTestes where

import Data.List (sort, (\\))
import Test.QuickCheck

-- Ordenação clássica: elegante, mas não é in-place.
qsort :: Ord a => [a] -> [a]
qsort []     = []
qsort (x:xs) = qsort lhs ++ [x] ++ qsort rhs
    where lhs = filter  (< x) xs
          rhs = filter (>= x) xs

-- Idempotência: ordenar duas vezes dá o mesmo que ordenar uma.
prop_idempotent xs = qsort (qsort xs) == qsort xs

-- Esta propriedade FALHA de propósito (head de lista vazia).
-- Serve para ver o contraexemplo no GHCi; não entra na suíte de testes.
prop_minimum xs = head (qsort xs) == minimum xs

-- Versão correta: descarta a lista vazia com (==>).
prop_minimum' xs = not (null xs) ==> head (qsort xs) == minimum xs

-- A saída está ordenada.
prop_ordered xs = ordered (qsort xs)
    where ordered []       = True
          ordered [x]      = True
          ordered (x:y:ys) = x <= y && ordered (y:ys)

-- A saída é uma permutação da entrada.
prop_permutation xs = permutation xs (qsort xs)
    where permutation as bs = null (as \\ bs) && null (bs \\ as)

-- O último elemento é o máximo.
prop_maximum xs =
    not (null xs) ==>
        last (qsort xs) == maximum xs

-- O mínimo da concatenação é o menor dos mínimos.
prop_append xs ys =
    not (null xs) ==>
    not (null ys) ==>
        head (qsort (xs ++ ys)) == min (minimum xs) (minimum ys)

-- Teste contra um modelo: a nossa ordenação deve se comportar como Data.List.sort.
prop_sort_model xs = sort xs == qsort xs