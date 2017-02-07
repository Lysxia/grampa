{-# LANGUAGE FlexibleContexts, FlexibleInstances, MultiParamTypeClasses, RecordWildCards, ScopedTypeVariables #-}
module Comparisons where

import Control.Applicative
import Data.Monoid ((<>))

import qualified Rank2
import Text.Grampa
import Utilities (symbol)

class ComparisonDomain c e where
   greaterThan :: c -> c -> e
   lessThan :: c -> c -> e
   equal :: c -> c -> e
   greaterOrEqual :: c -> c -> e
   lessOrEqual :: c -> c -> e

instance Ord c => ComparisonDomain c Bool where
   greaterThan a b = a > b
   lessThan a b = a < b
   equal a b = a == b
   greaterOrEqual a b = a >= b
   lessOrEqual a b = a <= b

instance ComparisonDomain [Char] [Char] where
   lessThan = infixJoin "<"
   lessOrEqual = infixJoin "<="
   equal = infixJoin "=="
   greaterOrEqual = infixJoin ">="
   greaterThan = infixJoin ">"

infixJoin :: String -> String -> String -> String
infixJoin rel a b = a <> rel <> b

data Comparisons c e f =
   Comparisons{test :: f e,
               term :: f c}
   deriving (Show)

instance Rank2.Functor (Comparisons c e) where
   fmap f g = g{test= f (test g),
                term= f (term g)}

instance Rank2.Apply (Comparisons c e) where
   ap g h = Comparisons{test= test g `Rank2.apply` test h,
                        term= term g `Rank2.apply` term h}

instance Rank2.Applicative (Comparisons c e) where
   pure f = Comparisons f f

instance Rank2.Distributive (Comparisons c e) where
   distributeM f = Comparisons{test= f >>= test,
                               term= f >>= term}
   distributeWith w f = Comparisons{test= w (test <$> f),
                                    term= w (term <$> f)}

instance Rank2.Foldable (Comparisons c e) where
   foldMap f g = f (test g) <> f (term g)

instance Rank2.Traversable (Comparisons c e) where
   traverse f g = Comparisons 
                  <$> f (test g)
                  <*> f (term g)

comparisons :: (ComparisonDomain c e) => GrammarBuilder (Comparisons c e) g String
comparisons Comparisons{..} =
   Comparisons{
      test= lessThan <$> term <* symbol "<" <*> term
            <|> lessOrEqual <$> term <* symbol "<=" <*> term
            <|> equal <$> term <* symbol "==" <*> term
            <|> greaterOrEqual <$> term <* symbol ">=" <*> term
            <|> greaterThan <$> term <* symbol ">" <*> term,
      term= empty}
