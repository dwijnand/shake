
-- | A bag of elements that you can pull at either deterministically or randomly.
module General.Bag(
    Bag, Randomly,
    emptyPure, emptyRandom,
    insert, remove
    ) where

import qualified Data.HashMap.Strict as Map
import System.Random

-- Monad for random (but otherwise pure) computations
type Randomly a = IO a

data Bag a
    = BagPure [a]
    | BagRandom {-# UNPACK #-} !Int (Map.HashMap Int a)
      -- HashMap has O(n) Map.size so we record it separately

emptyPure :: Bag a
emptyPure = BagPure []

emptyRandom :: Bag a
emptyRandom = BagRandom 0 Map.empty

insert :: a -> Bag a -> Bag a
insert x (BagPure xs) = BagPure $ x:xs
insert x (BagRandom n mp) = BagRandom (n+1) $ Map.insert n x mp

remove :: Bag a -> Randomly (Maybe (a, Bag a))
remove (BagPure []) = return Nothing
remove (BagPure (x:xs)) = return $ Just (x, BagPure xs)
remove (BagRandom n mp)
    | n == 0 = return Nothing
    | n == 1 = return $ Just (mp Map.! 0, emptyRandom)
    | otherwise = do
        i <- randomRIO (0, n-1)
        let mp2 | i == n-1 = Map.delete i mp
                | otherwise = Map.insert i (mp Map.! (n-1)) $ Map.delete (n-1) mp
        return $ Just (mp Map.! i, BagRandom (n-1) mp2)
