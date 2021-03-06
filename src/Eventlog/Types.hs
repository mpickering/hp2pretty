{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Eventlog.Types(module Eventlog.Types, HeapProfBreakdown(..), ClosureType) where

import Data.Text (Text)
import Data.Map (Map)
import Data.Aeson
import Data.Hashable
import Data.Word
import GHC.RTS.Events (HeapProfBreakdown(..))
import GHC.Exts.Heap.ClosureTypes
import Numeric
import qualified Data.Text as T

data Header =
  Header
  { hJob         :: Text
  , hDate        :: Text
  , hHeapProfileType :: Maybe HeapProfBreakdown
  , hSamplingRate :: Text
  , hSampleUnit  :: Text
  , hValueUnit   :: Text
  , hCount       :: Int
  , hProgPath    :: Maybe FilePath
  } deriving Show


-- The bucket is a key to uniquely identify a band
newtype Bucket = Bucket Text
                  deriving (Show, Ord, Eq)
                  deriving newtype (ToJSON, Hashable)


data BucketInfo = BucketInfo { shortDescription :: Text -- For the legend and hover
                             , longDescription :: Maybe [Word32]
                             , bucketTotal :: Double
                             , bucketStddev :: Double
                             , bucketGradient :: !(Maybe (Double, Double, Double))
                             } deriving Show

data CostCentre = CC { cid :: Word32
                     , label :: Text
                     , modul :: Text
                     , loc :: Text } deriving Show

data Sample = Sample Bucket Double deriving Show

data HeapSample = HeapSample Double Word64 deriving Show

data Frame = Frame Double [Sample] deriving Show

-- | A trace we also want to show on the graph
data Trace = Trace Double Text deriving Show

data HeapInfo = HeapInfo { heapSizeSamples :: [HeapSample]
                         , blocksSizeSamples :: [HeapSample]
                         , liveBytesSamples :: [HeapSample]
                         } deriving Show

data ProfData = ProfData { profHeader :: Header
                         , profTotals :: (Map Bucket BucketInfo)
                         , profCCMap  :: Map Word32 CostCentre
                         , profFrames :: [Frame]
                         , profTraces :: [Trace]
                         , profHeap   :: HeapInfo
                         , profItl    :: Map InfoTablePtr InfoTableLoc } deriving Show

data InfoTableLoc = InfoTableLoc { itlName :: !Text
                                 , itlClosureDesc :: !ClosureType
                                 , itlTyDesc :: !Text
                                 , itlLbl :: !Text
                                 , itlModule :: !Text
                                 , itlSrcLoc :: !Text } deriving Show

data InfoTablePtr = InfoTablePtr Word64 deriving (Eq, Ord)

instance Show InfoTablePtr where
  show (InfoTablePtr p) =  "0x" ++ showHex p ""

toItblPointer :: Bucket -> InfoTablePtr
toItblPointer (Bucket t) =
    let s = drop 2 (T.unpack t)
        w64 = case readHex s of
                ((n, ""):_) -> n
                _ -> error (show t)
    in InfoTablePtr w64
