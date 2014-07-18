#!/usr/bin/runghc -O2

import Codec.Wav ( exportFile, importFile )
import Data.Audio ( Audio(Audio) )
import Data.Array.Unboxed ( UArray, listArray, elems )
import Data.Int ( Int32, Int16 )
import Data.Maybe ( fromMaybe, fromJust )
import System.IO (FilePath)
import Data.List (unfoldr, foldl')
import qualified Data.Dequeue as DD
import Data.Array.Base (IArray)
import Debug.Trace (trace)
import Control.Arrow ((>>>))
import System.Environment (getArgs)

-- split the wav file by silence

type SampleType = Int16
runningAverageWindow = 4410*3
recordHighThreshold = 2.0 :: Double
recordLowThesgold = 1.5 :: Double
samplesBefore = 8820*5
samplesAfter = 4410*5


data AudioHeader = AudioHeader { rate :: !Int, channels :: !Int }

-- I'm not currently familiar with Haskell arrays, so just using lists
data ParserState = ParserState { 
             header :: !AudioHeader
            ,currentSerialNo :: !Int
            ,inputSamples :: ![SampleType] 
            ,accumulatedSamples :: !(DD.BankersDequeue SampleType)
            ,volume :: ![Double]
            ,inMiddleOfFragment :: !Bool
            }
newParserState header' samples' volume' = ParserState { 
             header = header'
            ,currentSerialNo = 0
            ,inputSamples = samples'
            ,accumulatedSamples = DD.empty
            ,volume = volume'
            ,inMiddleOfFragment = False
            }

data OutputBlock = OutputBlock { dat :: !(Audio SampleType), serialNo :: !(Int) }

--deque2Array :: (DD.Dequeue dq) => dq a -> UArray i a
deque2Array :: (DD.Dequeue dq) => dq SampleType -> UArray Int SampleType
deque2Array x = listArray (0, DD.length x) $ dequeAsList x
    where
    dequeAsList x = DD.takeFront (DD.length x) x

--makeAudioFromDequeAndHeader :: (DD.Dequeue d) => AudioHeader -> d a -> Audio a
makeAudioFromDequeAndHeader :: (DD.Dequeue d) => AudioHeader -> d SampleType -> Audio SampleType
makeAudioFromDequeAndHeader he deq = Audio (rate he) (channels he) $ deque2Array deq

addToBuffer :: (DD.Dequeue dq) => Maybe Int -> dq a -> a -> dq a
addToBuffer Nothing d x                     = DD.pushBack d x
addToBuffer (Just n) d x | DD.length d < n  = DD.pushBack d x
                         | otherwise        = snd $ DD.popFront $ DD.pushBack d x

maybeTrace _ x = x
--maybeTrace = trace

handleASample :: ParserState -> Maybe (Maybe OutputBlock, ParserState)
handleASample ps@(ParserState he sn [         ] acc vols inmid) | (DD.length acc) == 0   =  maybeTrace "F" $ Nothing
handleASample ps@(ParserState he sn [         ] acc vols inmid) | otherwise              =  maybeTrace "E" $ Just (if inmid then Just ob else Nothing, nps)
            where
            ob  = OutputBlock { dat = makeAudioFromDequeAndHeader he acc, serialNo = sn}
            nps = ps{accumulatedSamples = DD.empty}
handleASample ps@(ParserState he sn (sample:ss) acc (vol:vols) False) = maybeTrace (concat [". ", show vol])  $ Just (Nothing, nps)
            where
            nps = ps{
                        inMiddleOfFragment =  vol > recordHighThreshold
                       ,inputSamples = ss
                       ,volume = vols
                       ,accumulatedSamples = addToBuffer (Just samplesBefore) acc sample
            }
handleASample ps@(ParserState he sn (sample:ss) acc (vol:vols) True) 
        | vol > recordLowThesgold = maybeTrace (concat ["= ", show vol])  $ let
            nps = ps{
                        inMiddleOfFragment = True
                       ,inputSamples = ss
                       ,volume = vols
                       ,accumulatedSamples = addToBuffer Nothing acc sample
            } in Just (Nothing, nps)
        | otherwise = maybeTrace "*" $ Just (Just ob, nps)
            where
            (additionalLookaheadSamples, remainingSamples) = splitAt samplesAfter ss
            remainingVolumes = drop samplesAfter vols
            allSamplesDequeue = foldl' (\d el -> DD.pushBack d el) acc additionalLookaheadSamples
            ob = OutputBlock { dat = makeAudioFromDequeAndHeader he allSamplesDequeue, serialNo = sn}
            nps = ps{
                        inMiddleOfFragment = False
                       ,inputSamples = remainingSamples
                       ,volume = remainingVolumes
                       ,accumulatedSamples = DD.empty
                       ,currentSerialNo= sn + 1
            }


runningAverage :: (Num a, Fractional a) => Int -> [a] -> [Maybe a]
runningAverage n' list = unfoldr raImpl (DD.empty, 0, list)
    where
    n :: (Num a, Fractional a) => a
    n =  fromIntegral n'
    raImpl :: (Num a, Fractional a) => (DD.BankersDequeue a, a, [a]) -> Maybe (Maybe a, (DD.BankersDequeue a, a, [a]))
    raImpl (_, _, []) = Nothing
    raImpl (delayer, accumulator, (x:xs)) | DD.length delayer < n'   =  Just (Nothing, (DD.pushBack delayer x, accumulator + x, xs))
                                          | otherwise                =  Just (Just $ newaccumulator / n, (newdelayer, newaccumulator, xs))
                                                                            where
                                                                            (outsider', newdelayer') = DD.popFront delayer
                                                                            newdelayer = DD.pushBack newdelayer' x
                                                                            outsider = fromJust outsider'
                                                                            newaccumulator = accumulator - outsider + x

inMain :: FilePath -> IO ()
inMain path = do
  maybeAudio <- importFile path
  case maybeAudio :: Either String (Audio SampleType) of
    Left s -> putStrLn $ "wav decoding error: " ++ s
    Right (Audio rate channels samples) -> do
      -- putStrLn $ "rate = " ++ show rate
      -- putStrLn $ "channels: " ++ show channels
      let samples' = elems samples
      let multiplier = 100.0 / (fromIntegral $ (maxBound  :: SampleType))
      let samples'' = map (fromIntegral >>> (* multiplier) >>> abs) samples'
      let volume = map (fromMaybe (0.0 :: Double)) $ runningAverage runningAverageWindow samples''
      let blocksToSave = unfoldr handleASample $ newParserState AudioHeader{rate = rate, channels = channels} samples' volume
      (flip mapM_) blocksToSave $ \x -> case x of
                                            Just b -> do
                                                let fn = concat ["sample", (show $ serialNo b), ".wav"]
                                                putStrLn $ concat ["Exporting ", fn]
                                                exportFile fn (dat b)
                                            Nothing -> return ()

main = do
    args <- getArgs
    if args == [] || args == ["--help"] then do
        putStrLn "Split wav file by silence to sample%d.wav"
        putStrLn "Usage: splitter filename.wav"
        putStrLn "Adjust parameters in the source code"
    else
        inMain $ head args
