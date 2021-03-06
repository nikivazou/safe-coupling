-----------------------------------------------------------------
-- | Distance as a desugared type class -------------------------
-----------------------------------------------------------------

{-@ LIQUID "--reflection" @-}
{-@ LIQUID "--ple-local"  @-}

module Data.Dist where

import Prelude hiding (max)
import Language.Haskell.Liquid.ProofCombinators
import Misc.ProofCombinators
import Data.List

-----------------------------------------------------------------
-- | class Dist a -----------------------------------------------
-----------------------------------------------------------------
data Dist a = Dist { 
    dist           :: a -> a -> Double 
  , distEq         :: a -> a -> () 
  , triangularIneq :: a -> a -> a -> ()
  , symmetry       :: a -> a -> ()
  }


{-@ data Dist a = Dist { 
    dist           :: a -> a -> {v:Double | 0.0 <= v } 
  , distEq         :: a:a -> b:a -> {dist a b = 0 <=> a = b}
  , triangularIneq :: x:a -> y:a -> z:a -> {dist x z <= dist x y + dist y z}
  , symmetry       :: a:a -> b:a -> {dist a b = dist b a}
  } @-}

-- TODO: define this 
-- distFun :: Dist b -> Dist (a -> b)

-----------------------------------------------------------------
-- | instance Dist Double ---------------------------------------
-----------------------------------------------------------------

{-@ reflect distDouble@-}
distDouble :: Dist Double
distDouble = Dist distD distEqD triangularIneqD symmetryD

{-@ ple distEqD @-}
{-@ reflect distEqD @-}
distEqD :: Double -> Double -> ()
{-@ distEqD :: x:Double -> y:Double -> {distD x y == 0 <=> x = y} @-}
distEqD _ _ = () 

{-@ ple triangularIneqD @-}
{-@ reflect triangularIneqD @-}
{-@ triangularIneqD :: a:Double -> b:Double -> c:Double -> { distD a c <= distD a b + distD b c} @-}
triangularIneqD :: Double -> Double -> Double -> ()
triangularIneqD _ _ _ = ()

{-@ ple symmetryD @-}
{-@ reflect symmetryD @-}
{-@ symmetryD :: a:Double -> b:Double -> {distD a b = distD b a} @-}
symmetryD :: Double -> Double -> () 
symmetryD _ _ = ()

{-@ reflect distD @-}
{-@ distD :: Double -> Double -> {d:Double | 0.0 <= d } @-}
distD :: Double -> Double -> Double 
distD x y = if x <= y then y - x else x - y 

-----------------------------------------------------------------
-- | instance Dist a => Dist (List a) ---------------------------
-----------------------------------------------------------------
-- Note the proof obligations hold, but this is not a real metric
-- since the two lists should have the same len
-- The following cannot type check 
-- listDist :: Dist a -> Dist (List a)
-- listDist d = Dist (distList d) (distListEq d) (distListTri d) (distListSym d)

{-@ type ListEq a XS = {ys:[a] | len ys == len XS } @-}

{-@ reflect distList @-}
{-@ distList :: Dist a -> x:List a -> y:ListEq a {x} 
                       -> {d:Double | 0 <= d } @-}
distList :: Dist a -> List a -> List a -> Double
distList d [] _ = 0
distList d _ [] = 0
distList d (x : xs) (y : ys) = max (dist d x y) (distList d xs ys)

{-@ ple distListEq @-}
{-@ distListEq :: d:Dist a -> x:List a -> { distList d x x == 0 } @-}
distListEq :: Dist a -> List a -> ()
distListEq d [] = () 
distListEq d (x : xs) = distEq d x x ? distListEq d xs

{-@ ple distListSym @-}
{-@ distListSym :: d:Dist a -> x:List a -> y:ListEq a {x} -> { distList d x y == distList d y x } @-}
distListSym :: Dist a -> List a -> List a -> ()
distListSym d [] _ = () 
distListSym d _ [] = () 
distListSym d (x : xs) (y : ys) = symmetry d x y ? distListSym d xs ys


{-@ ple distListTri @-}
{-@ distListTri :: d:Dist a -> x:List a -> y:ListEq a {x} -> z:ListEq a {x}
                -> { distList d x z <= distList d x y + distList d y z } @-}
distListTri :: Dist a -> List a -> List a -> List a -> ()
distListTri d x@[] y z = assert (distList d x z <= distList d x y + distList d y z)
distListTri d x y z@[] = assert (distList d x z <= distList d x y + distList d y z)
distListTri d (x : xs) (y : ys) (z : zs) 
  = triangularIneq d x y z ? distListTri d xs ys zs 

-----------------------------------------------------------------
-- | Linearity on Doubles 
-- | Does not type check forall a, so cannot just get axiomatized
-----------------------------------------------------------------

{-@ ple linearity @-}
{-@ linearity :: k:{Double | 0 <= k } -> l:Double -> a:Double -> b:Double 
                     -> { distD (k * a + l) (k * b + l) = k * distD a b} @-}
linearity :: Double -> Double -> Double -> Double -> ()
linearity k l a b
  | a <= b    = assert (k * a + l <= k * b + l) 
  | otherwise = assert (distD (k * a + l) (k * b + l) == k * distD a b)
                  ? assert (k * a + l >= k * b + l) 
