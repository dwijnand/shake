{-# LANGUAGE TupleSections #-}

module General.Timing(resetTimings, addTiming, printTimings) where

import Data.IORef
import System.IO.Unsafe
import Numeric.Extra
import System.Time.Extra

{-# NOINLINE timer #-}
timer :: IO Seconds
timer = unsafePerformIO offsetTime


{-# NOINLINE timings #-}
timings :: IORef [(Seconds, String)] -- number of times called, newest first
timings = unsafePerformIO $ newIORef []


resetTimings :: IO ()
resetTimings = do
    now <- timer
    writeIORef timings [(now, "Start")]


-- | Print all withTiming information and clear the information.
printTimings :: IO ()
printTimings = do
    now <- timer
    old <- atomicModifyIORef timings ([(now, "Start")],)
    putStr $ unlines $ showTimings now $ reverse old


addTiming :: String -> IO ()
addTiming msg = do
    now <- timer
    atomicModifyIORef timings $ \ts -> ((now,msg):ts, ())


showTimings :: Seconds -> [(Seconds, String)] -> [String]
showTimings _ [] = []
showTimings stop times = showGap $
    [(a ++ "  ", showDP 3 b ++ "s  " ++ showPerc b ++ "  " ++ progress b) | (a,b) <- xs] ++
    [("Total", showDP 3 sm ++ "s  " ++ showPerc sm ++ "  " ++ replicate 25 ' ')]
    where
        a // b = if b == 0 then 0 else a / b
        showPerc x = let s = show $ floor $ x * 100 // sm in replicate (3 - length s) ' ' ++ s ++ "%"
        progress x = let i = floor $ x * 25 // mx in replicate i '=' ++ replicate (25-i) ' '
        mx = maximum $ map snd xs
        sm = sum $ map snd xs
        xs = [ (name, stop - start)
             | ((start, name), stop) <- zip times $ map fst (drop 1 times) ++ [stop]]


showGap :: [(String,String)] -> [String]
showGap xs = [a ++ replicate (n - length a - length b) ' ' ++ b | (a,b) <- xs]
    where n = maximum [length a + length b | (a,b) <- xs]
