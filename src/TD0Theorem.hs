{-@ LIQUID "--reflection"     @-}
{-@ LIQUID "--fast"           @-}
{-@ LIQUID "--no-termination" @-}
{-@ LIQUID "--ple-local"      @-}

module TD0Theorem where

import           Monad.Distr
import           Data.Dist
import           Data.List

import           Prelude                 hiding ( map
                                                , repeat
                                                , foldr
                                                , fmap
                                                , mapM
                                                )

import           Language.Haskell.Liquid.ProofCombinators
import           Monad.Distr 
import           Data.Dist 
import           TD0

{-@ relationalact :: π:_ -> r:_ -> p:_ -> v1:_ -> {v2:_|llen v1 = llen v2} -> 
                        {expDistList (act π r p v1) (act π r p v2) <= k * expDistList v1 v2} @-}
relationalact :: PolicyMap -> RewardFunction -> TransitionFunction -> DistrValueFunction -> DistrValueFunction -> ()
relationalact π r p v1 v2 
    =   expDistList (act π r p v1) (act π r p v2)
        ? relationalmap v1 v2 (local π r p v1) undefined
    =<= k * expDistList v1 v2
    *** QED

{-@ relationalmap :: xs1:_ -> {xs2:_|llen xs2 = llen xs1} -> f:_ -> 
                        (x1:_ -> x2:_ -> {expDist (f x1) (f x2) <= k * expDist x1 x2}) ->
                        {expDistList (map f xs1) (map f xs2) <= k * expDistList xs1 xs2} @-}
relationalmap :: List a -> List a -> (a -> b) -> (a -> a -> ()) -> ()
relationalmap xs1 xs2 f = undefined


{-@ relationalsample :: π:_ -> r:_ -> p:_ -> v1:_ -> {v2:_|llen v1 = llen v2} -> {i:State|i < llen v1} -> 
                    {expDist (sample π r p i v1) (sample π r p i v2) <= k * dist (at v1 i) (at v2 i)} @-}
relationalsample :: PolicyMap -> RewardFunction -> TransitionFunction -> ValueFunction -> ValueFunction -> State -> ()
relationalsample π r p v1 v2 i
    =   expDist (sample π r p i v1) (sample π r p i v2) 
    === expDist (bind (π `at` i) (sample' r p v1 i)) (bind (π `at` i) (sample' r p v2 i))
        ?   expDistBind m (sample' r p v1 i) (π `at` i)
                          (sample' r p v2 i) (π `at` i)
                          (lemma1 r p v1 v2 i)
    =<= m
    *** QED
  where m = k * dist (v1 `at` i) (v2 `at` i)

{-@ lemma1 :: r:_ -> p:_ -> v1:_ -> {v2:_|llen v1 = llen v2} -> {i:State|i < llen v1} -> 
                a:_ -> {expDist (sample' r p v1 i a) (sample' r p v2 i a) <= k * dist (at v1 i) (at v2 i)} @-}
lemma1 :: RewardFunction -> TransitionFunction -> ValueFunction -> ValueFunction -> State -> Action -> ()
lemma1 r p v1 v2 i a 
    =   expDist (sample' r p v1 i a) (sample' r p v2 i a)
    === expDist (bind ((r `at` i) a) (sample'' p v1 i a)) (bind ((r `at` i) a) (sample'' p v2 i a))
        ?   expDistBind m (sample'' p v1 i a) ((r `at` i) a)
                          (sample'' p v2 i a) ((r `at` i) a)
                          (lemma2 p v1 v2 i a)
    =<= m
    *** QED
  where m = k * dist (at v1 i) (at v2 i)

{-@ lemma2 :: p:_ -> v1:_ -> {v2:_|llen v1 = llen v2} -> {i:State|i < llen v1} -> a:_ ->
                rw:_ -> {expDist (sample'' p v1 i a rw) (sample'' p v2 i a rw) <= k * dist (at v1 i) (at v2 i)} @-}
lemma2 :: TransitionFunction -> ValueFunction -> ValueFunction -> State -> Action -> Reward -> ()
lemma2 p v1 v2 i a rw 
    =   expDist (sample'' p v1 i a rw) (sample'' p v2 i a rw)
    === expDist (bind ((p `at` i) a) (update v1 i rw)) (bind ((p `at` i) a) (update v2 i rw))
        ?   expDistBind m (update v1 i rw) ((p `at` i) a)
                          (update v2 i rw) ((p `at` i) a)
                          (lemma3 v1 v2 i a rw)
    =<= m
    *** QED
  where m = k * dist (at v1 i) (at v2 i)

{-@ lemma3 :: v1:_ -> {v2:_|llen v1 = llen v2} -> {i:State|i < llen v1} -> a:_ -> rw:_ -> 
                {j:State|j < llen v1} -> {expDist (update v1 i rw j) (update v2 i rw j) <= k * dist (at v1 i) (at v2 i)} @-}
lemma3 :: ValueFunction -> ValueFunction -> State -> Action -> Reward -> State -> ()
lemma3 v1 v2 i a rw j 
    =   expDist (update v1 i rw j) (update v2 i rw j)
    === expDist (ppure ((1 - α) * v1 `at` i + α * (rw + γ * v1 `at` j))) 
                (ppure ((1 - α) * v2 `at` i + α * (rw + γ * v2 `at` j)))
        ? expDistPure ((1 - α) * v1 `at` i + α * (rw + γ * v1 `at` j))
                      ((1 - α) * v2 `at` i + α * (rw + γ * v2 `at` j))
    {- === dist ((1 - α) * v1 `at` i + α * (rw + γ * v1 `at` j))
             ((1 - α) * v2 `at` i + α * (rw + γ * v2 `at` j))
        ?   triangularIneq -- | a + b - c - d | <= | a - c| + | b - d |
                           -- | a + b | <= | a | + | b |
    =<= dist ((1 - α) * v1 `at` i) ((1 - α) * v2 `at` i) 
        + dist (α * (rw + γ * v1 `at` j)) (α * (rw + γ * v2 `at` j))
        ?   linearity
    === (1 - α) * dist (v1 `at` i) (v2 `at` i)
        + α * γ * dist (v1 `at` j) (v2 `at` j)
        ?   distLTMax
    =<= (1 - α + α * γ) * maxDist v1 v2
    === k * maxDist v1 v2
    -}
    *** QED
