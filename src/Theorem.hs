{-@ LIQUID "--reflection"     @-}
{-@ LIQUID "--fast"           @-}
{-@ LIQUID "--no-termination" @-}
{-@ LIQUID "--ple-local"      @-}

module Theorem where

import           Prelude                 hiding ( head
                                                , tail
                                                , sum
                                                )
import           Data.Functor.Identity
import           Language.Haskell.Liquid.ProofCombinators
import           Monad.Distr 
import           Data.Dist 
import           SGD 


{-@ assume relationalupdatep :: z1:DataPoint -> α1:StepSize -> f1:LossFunction 
                             -> z2:DataPoint -> {α2:StepSize|α1 = α2} -> {f2:LossFunction|f1 = f2} 
                             -> ws1:Weight -> ws2:Weight -> 
                            {dist (update z1 α1 f1 ws1) (update z2  α2 f2 ws2) = dist ws1 ws2 + 2.0 * α1} @-}
relationalupdatep :: DataPoint -> StepSize -> LossFunction -> DataPoint -> StepSize -> LossFunction -> Weight  -> Weight -> ()
relationalupdatep _ _ _ _ _ _ _ _ = ()


{-@ assume relationalupdateq :: z1:DataPoint -> ws1:Weight -> α1:StepSize -> f1:LossFunction -> 
                                  {z2:DataPoint|z1 = z2} -> ws2:Weight -> {α2:StepSize|α1 = α2} -> {f2:LossFunction|f1 = f2} -> 
                                    {dist (update z1 α1 f1 ws1) (update z2 α2 f2 ws2) = dist ws1 ws2} @-}
relationalupdateq ::  DataPoint -> Weight -> StepSize -> LossFunction -> DataPoint -> Weight -> StepSize -> LossFunction -> ()
relationalupdateq = undefined


{-@ reduce :: p:Double -> ws1:Weight -> ws2:Weight -> {p * dist ws1 ws2 + (1 - p) * dist ws1 ws2 = dist ws1 ws2} @-}
reduce :: Double -> Weight -> Weight -> ()
reduce _ _ _ = ()

{-@ reflect sum @-}
{-@ sum :: StepSizes -> {v:StepSize | 0.0 <= v } @-}
sum :: StepSizes -> Double
sum SSEmp       = 0
sum (SS a as) = a + sum as

{-@ reflect estab @-}
{-@ estab :: DataSet -> StepSizes -> {v:Double | 0.0 <= v} @-}
estab :: DataSet -> StepSizes -> Double
estab zs as = 2.0 / (lend zs) * sum as

{-@ ple estabEmp @-}
estabEmp :: DataSet -> () 
{-@ estabEmp :: zs:DataSet -> {estab zs SSEmp == 0.0} @-}
estabEmp zs = 
      estab zs SSEmp 
  === 2.0 / (lend zs) * sum SSEmp
  *** QED 

{-@ ple estabconsR @-}
{-@ measure Theorem.estabconsR  :: DataSet -> StepSize -> StepSizes -> ()  @-}
{-@ estabconsR :: zs:{DataSet | lend zs /= 0} -> x:StepSize -> xs:StepSizes 
                    -> { estab zs (SS x xs) == 2.0 * x * (one / lend zs) + estab zs xs } @-}
estabconsR :: DataSet -> StepSize -> StepSizes -> () 
estabconsR zs x xs 
  =   estab zs (SS x xs)
  ==. 2.0 / (lend zs) * sum (SS x xs)
  ==. 2.0 * x * (one / lend zs) + estab zs xs 
  *** QED 



-- {-@ reflect upd @-}
-- {-@ upd :: zs:{DataSet | 1 < len zs  && 1 < lend zs } -> Weight -> StepSize -> ss:StepSizes -> LossFunction -> DataPoint 
--        -> Distr Weight / [ sslen ss, 1 ] @-}
-- upd ::  DataSet -> Weight -> StepSize -> StepSizes -> LossFunction -> DataPoint -> Distr Weight
-- upd zs w0 α a f z' = update z' w0 α f (sgd zs  a f)

{-
a1 ~ a2 | true
f1 ~ f2 | forall x1 x2. expDist (r1 x1) (r2 x2) <= deltaneq
f1 ~ f2 | forall x. expDist (r1 x) (r2 x) <= deltaeq
___________________________________________________________
bind a1 f1 ~ bind a2 f2 | 1/|S| deltaneq + |S|-1/|S| deltaeq 
-}

{-
a1 ~ a2 | true
f1 ~ f2 | forall ws1 ws2. expDist (f1 ws1) (f2 ws2) <=
     dist ws1 ws2 + estab zs1 α1
___________________________________________________________
             bind a1 f1 ~ bind a2 f2 | 1/|S| deltaneq 
                                      + |S|-1/|S| deltaeq 
-}




{-@ ple thm @-}
{-@ thm :: zs1:DataSet -> ws1:Weight -> α1:StepSizes -> f1:LossFunction -> 
           zs2:{DataSet | lend zs1 == lend zs2 && tail zs1 = tail zs2} -> 
            ws2:Weight -> {α2:StepSizes| α2 = α1} -> {f2:LossFunction|f1 = f2} -> 
            { expDist (sgd zs1 ws1 α1 f1) (sgd zs2 ws2 α2 f2) <= dist ws1 ws2 + estab zs1 α1} @-}
thm :: DataSet -> Weight -> StepSizes -> LossFunction -> DataSet -> Weight -> StepSizes -> LossFunction -> ()
thm zs1 ws1 α1@SSEmp f1 zs2 ws2 α2@SSEmp f2 =
  expDist (sgd zs1 ws1 α1 f1) (sgd zs2 ws2 α2 f2)
    === expDist (ppure ws1) (ppure ws2)
        ? relationalppure ws1 ws2
    === dist ws1 ws2
        ? estabEmp zs1 
    === dist ws1 ws2 + estab zs1 α1
    *** QED 

thm zs1 ws1 as1@(SS α1 a1) f1 zs2 ws2 as2@(SS α2 a2) f2 =
  expDist (sgd zs1 ws1 as1 f1) (sgd zs2 ws2 as2 f2)
    === expDist
          (choice (one / lend zs1) (bind uhead1 sgdRec1) (bind utail1 sgdRec1))
          (choice (one / lend zs2) (bind uhead2 sgdRec2) (bind utail2 sgdRec2))
    ?   relationalchoice (one / lend zs1) (bind uhead1 sgdRec1) (bind utail1 sgdRec1)
                         (one / lend zs2) (bind uhead2 sgdRec2) (bind utail2 sgdRec2)

    =<= (one / lend zs1) * (expDist (bind uhead1 sgdRec1) (bind uhead2 sgdRec2)) 
        + (1 - (one / lend zs1)) * (expDist (bind utail1 sgdRec1) (bind utail2 sgdRec2))
        ?   leftId (head zs1) sgdRec1 
        ?   leftId (head zs2) sgdRec2 

    =<= (one / lend zs1) * (expDist (sgdRec1 (head zs1)) (sgdRec2 (head zs2))) 
        + (1 - (one / lend zs1)) * (expDist (bind utail1 sgdRec1) (bind utail2 sgdRec2))
    
    =<= (one / lend zs1) * (expDist (bind (sgd zs1 ws1 a1 f1) pureUpd1) 
                                    (bind (sgd zs2 ws2 a2 f2) pureUpd2)) 
        + (1 - (one / lend zs1)) * (expDist (bind utail1 sgdRec1) (bind utail2 sgdRec2))
        ? pureUpdateEq (head zs1) α1 f1
        ? pureUpdateEq (head zs2) α2 f2

    =<= (one / lend zs1) * (expDist (bind (sgd zs1 ws1 a1 f1) (ppure . update (head zs1) α1 f1 )) 
                                    (bind (sgd zs2 ws2 a2 f2) (ppure . update (head zs2) α2 f2 ))) 
        + (1 - (one / lend zs1)) * (expDist (bind utail1 sgdRec1) (bind utail2 sgdRec2))

        ?   relUnitBindTry (2 * α1) (update (head zs1) α1 f1) (sgd zs1 ws1 a1 f1) 
                           (update (head zs2) α2 f2) (sgd zs2 ws2 a2 f2) 
                           (relationalupdatep (head zs1) α1 f1 (head zs2) α2 f2) 
        
    =<= (one / lend zs1) * (expDist (sgd zs1 ws1 a1 f1)  
                                    (sgd zs2 ws2 a2 f2) + (2.0 * α1)) 
        + (1 - (one / lend zs1)) * (expDist (bind utail1 sgdRec1) (bind utail2 sgdRec2))

         ? thm zs1 ws1 a1 f1 zs2 ws2 a2 f2
         ? assert (expDist (sgd zs1 ws1 a1 f1) (sgd zs2 ws2 a2 f2) <= dist ws1 ws2 + estab zs1 a1)
    =<= (one / lend zs1) * (dist ws1 ws2 + estab zs1 a1 + (2.0 * α1)) 
        + (1 - (one / lend zs1)) * (expDist (bind utail1 sgdRec1) (bind utail2 sgdRec2))
        ? expDistBind (dist ws1 ws2 + estab zs1 a1) sgdRec1 utail1 sgdRec2 utail2
                     (lemma zs1 ws1 α1 a1 f1 zs2 ws2 α2 a2 f2)
        ? assert (expDist (bind utail1 sgdRec1) (bind utail2 sgdRec2) <= dist ws1 ws2 + estab zs1 a1)
    =<= (one / lend zs1) * (dist ws1 ws2 + estab zs1 a1 + (2.0 * α1)) 
        + (1 - (one / lend zs1)) * (dist ws1 ws2 + estab zs1 a1)

    =<= (one / lend zs1) * (dist ws1 ws2 + estab zs1 a1 + (2.0 * α1)) 
            + (1 - (one / lend zs1)) * (dist ws1 ws2 + estab zs1 a1)

    =<= dist ws1 ws2 + 2.0 * α1 * (one / lend zs1) + estab zs1 a1
        ?   estabconsR zs1 α1 a1
                            
    =<= dist ws1 ws2 + estab zs1 (SS α1 a1)
    =<= dist ws1 ws2 + estab zs1 as1
    *** QED
 where
  pureUpd1 = pureUpdate (head zs1) α1 f1
  pureUpd2 = pureUpdate (head zs2) α2 f2
  sgdRec1 = sgdRecUpd zs1 ws1 α1 a1 f1
  sgdRec2 = sgdRecUpd zs2 ws2 α2 a2 f2
  uhead1 = ppure (head zs1)
  utail1 = unif (tail zs1)
  uhead2 = ppure (head zs2)
  utail2 = unif (tail zs2)
thm zs1 ws1 _ f1 zs2 ws2 _ f2 = ()


{-@ assert :: {b:Bool | b} -> () @-}
assert :: Bool -> ()
assert _ = ()

{-@ assume lemma :: zs1:DataSet -> ws1:Weight -> α1:StepSize -> a1:StepSizes -> f1:LossFunction -> 
             zs2:{DataSet | lend zs1 == lend zs2 && tail zs1 = tail zs2} -> 
             ws2:Weight -> α2:StepSize -> {a2:StepSizes| a2 = a1} -> {f2:LossFunction|f1 = f2} -> 
             x:DataPoint -> 
            { expDist (sgdRecUpd zs1 ws1 α1 a1 f1 x) (sgdRecUpd zs2 ws2 α2 a2 f2 x) <= dist ws1 ws2 + estab zs1 a1} @-}
lemma :: DataSet -> Weight -> StepSize -> StepSizes -> LossFunction -> DataSet -> Weight -> StepSize ->  StepSizes -> LossFunction -> DataPoint -> ()
lemma _ _ _ _ _ _ _ _ _ _ _ = ()


{-@ assume pureUpdateEq :: zs:DataPoint -> a:StepSize -> f:LossFunction
               -> {pureUpdate zs a f == ppure . update zs a f} @-}
pureUpdateEq :: DataPoint -> StepSize -> LossFunction -> ()
pureUpdateEq zs a f = () 