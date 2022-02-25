-----------------------------------------------------------------
-- | Expected Distance Specifications for Distr Primitives ------
-----------------------------------------------------------------

{-@ LIQUID "--reflection" @-}
{-@ LIQUID "--ple-local"  @-}

module Monad.Distr.Relational.TCB.EDist where 

import Data.Dist 
import Monad.Distr
import Monad.Distr.Predicates

{-@ measure Monad.Distr.Relational.TCB.EDist.kant :: Dist a -> Dist (Distr a) @-}
{-@ assume kant :: d:Dist a -> {dd:Dist (Distr a) | dd = Monad.Distr.Relational.TCB.EDist.kant d } @-}
kant :: Dist a -> Dist (Distr a)
kant = undefined 

{-@ reflect edist @-}
{-@ edist :: Dist a -> Distr a -> Distr a -> {v:Double | 0 <= v } @-} 
edist :: Dist a -> Distr a -> Distr a -> Double 
edist d = dist (kant d)

{-@ assume pureDist :: d:Dist a -> x1:a -> x2:a 
                    -> { edist d (ppure x1) (ppure x2) = dist d x1 x2} @-}
pureDist :: Dist a -> a -> a -> ()
pureDist _ _ _ = ()

{-@ assume bindDist :: d:Dist b -> m:Double -> p:(a -> a -> Bool)
                    -> f1:(a -> Distr b) -> e1:Distr a 
                    -> f2:(a -> Distr b) -> e2:{Distr a | lift p e1 e2} 
                    -> lemma:(x1:a -> {x2:a| p x1 x2 } 
                             -> { edist d (f1 x1) (f2 x2) <= m}) 
                    -> { edist d (bind e1 f1) (bind e2 f2) <= m } @-}
bindDist :: Dist b ->  Double -> (a -> a -> Bool) -> (a -> Distr b) -> Distr a -> (a -> Distr b) -> Distr a -> (a -> a -> ()) -> ()
bindDist _ _ _ _ _ _ _ _ = ()

{-@ assume pureBindDist :: da:Dist a -> db:Dist b
                        -> m:Double 
                        -> f1:(a -> b) -> e1:Distr a 
                        -> f2:(a -> b) -> e2:Distr a 
                        -> (x1:a -> x2:a -> { dist db (f1 x1) (f2 x2) <= dist da x1 x2 + m}) 
                        -> { edist db (bind e1 (ppure . f1 )) (bind e2 (ppure . f2)) <= edist da e1 e2 + m } @-}
pureBindDist :: Dist a -> Dist b -> Double -> (a -> b) -> Distr a -> (a -> b) ->  Distr a ->  (a -> a -> ()) -> ()
pureBindDist _ _ m f1 e1 f2 e2 t = () 

{-@ assume unifDist :: d:Dist a -> xsl:[a] -> xsr:{[a] | xsl == xsr}
                          -> { edist d (unif xsl) (unif xsr) == 0 } @-}
unifDist :: Dist a -> [a] -> [a] -> ()
unifDist _ _ _ = ()

{-@ assume choiceDist :: d:Dist a -> p:Prob -> e1:Distr a -> e1':Distr a 
                      -> q:{Prob | p = q } -> e2:Distr a -> e2':Distr a 
                      -> { edist d (choice p e1 e1') (choice q e2 e2') <= p * (edist d e1 e2) + (1.0 - p) * (edist d  e1' e2')} @-}
choiceDist :: Dist a -> Prob -> Distr a -> Distr a -> Prob -> Distr a -> Distr a -> ()
choiceDist _ _ _ _ _ _ _ = ()


{-@ predicate BijCoupling X Y = X = Y @-}
{-@ bindDistEq :: d:Dist b -> m:Double 
                      -> f1:(a -> Distr b) -> e1:Distr a 
                      -> f2:(a -> Distr b) -> e2:{Distr a | BijCoupling e1 e2 } 
                      -> (x:a -> { edist d (f1 x) (f2 x) <= m}) 
                      -> { edist d (bind e1 f1) (bind e2 f2) <= m } @-}
bindDistEq :: Eq a => Dist b -> Double -> (a -> Distr b) -> Distr a -> (a -> Distr b) ->  Distr a ->  (a -> ()) -> ()
bindDistEq d m f1 e1 f2 e2 lemma = eqP e1 e2 `const`
  bindDist d m eqP f1 e1 f2 e2 (foo d m f1 f2 lemma)

{-@ foo :: d:Dist b -> m:Double -> f1:(a -> Distr b) -> f2:(a -> Distr b)
        -> (x:a -> {v:() | edist d (f1 x) (f2 x) <= m}) 
        -> (x:a -> y:{a | eqP x y} -> { edist d (f1 x) (f2 y) <= m}) @-} 
foo :: Dist b -> Double -> (a -> Distr b) -> (a -> Distr b) -> (a -> ())
    -> (a -> a -> ())
foo = undefined 