module Spec.Bins where

import           Test.HUnit                     ( assertEqual
                                                , (@?)
                                                , (@?=)
                                                , Assertion
                                                )
import           Data.Sort                      ( sort )
import           Spec.Utils

import           Monad.PrM               hiding ( fmap , map, (++), return )
import           Bins.Bins

p, q :: Double
p    = 0.5
q    = 0.625

coupling :: Double -> Double -> PrM (Bool, Bool)
coupling p q = [((True, True), p), ((False, True), q - p), ((False, False), 1 - q)]

mockbins :: PrM (Bool, Bool) -> Int -> PrM (Int, Int)
mockbins _ 0 = return ((0, 0), 1)
mockbins c n = do
  ((xl, xr), px) <- c
  ((yl, yr), py) <- mockbins c (n - 1)
  return ((yl + toInt xl, yr + toInt xr), px * py)
  where toInt x = if x then 1 else 0

binsIter1 = sort [ ((1, 1), p)
                 , ((0, 1), q - p)
                 , ((0, 0), 1 - q)
                 ]

binsIter2 = sort [ ((2, 2), p ^ 2)
                 , ((1, 2), 2 * p * (q - p))
                 , ((1, 1), 2 * p * (1 - q))
                 , ((0, 2), (q - p) ^ 2)
                 , ((0, 1), 2 * (q - p) * (1 - q))
                 , ((0, 0), (1 - q) ^ 2)
                 ]

unit_mockbins_1_it :: Assertion
unit_mockbins_1_it =
  bins @?= binsIter1
 where
  bins = clean $ mockbins (coupling p q) 1

unit_mockbins_2_it :: Assertion
unit_mockbins_2_it = 
  bins @?= binsIter2
 where
  bins = clean $ mockbins (coupling p q) 2
  
unit_bins_1_it :: Assertion
unit_bins_1_it = do
  resl @?= clean (map (\((a, _), p) -> (fromIntegral a, p)) binsIter1)
  resr @?= clean (map (\((_, b), p) -> (fromIntegral b, p)) binsIter1)
 where
  resl = clean $ bins p 1
  resr = clean $ bins q 1

unit_bins_2_it :: Assertion
unit_bins_2_it = do
  resl @?= clean (map (\((a, _), p) -> (fromIntegral a, p)) binsIter2)
  resr @?= clean (map (\((_, b), p) -> (fromIntegral b, p)) binsIter2)
 where
  resl = clean $ bins p 2
  resr = clean $ bins q 2
  
unit_exp_dist_mockbins :: Assertion
unit_exp_dist_mockbins =
  expDist == fromIntegral n * (q - p)
    @? "want: E[dist (bins p n) (bins q n)] <= n * (q - p), got: " ++  show expDist
 where
  n       = 10
  bins    = mockbins (coupling p q) n
  expDist = expect (\(a, b) -> fromIntegral (b - a)) bins

