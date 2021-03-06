{-# OPTIONS --safe --without-K #-}
open import Prelude

module Generics.Reflection.Connection where

open import Utils.Reflection
open import Utils.Error as Err

open import Generics.Description
open import Generics.Recursion  
open import Generics.Algebra

open import Generics.Reflection.Telescope
open import Generics.Reflection.Name
open import Generics.Reflection.Uncurry
open import Generics.Reflection.Recursion

private
  pattern `DataC x y     = def₂ (quote DataC) x y
  pattern `datac a b c d = con₄ (quote datac) a b c d
  pattern `FoldC x y     = def₂ (quote FoldC) x y
  pattern `IndC  x y     = def₂ (quote IndC)  x y
  pattern `Algs  x y     = def₂ (quote Algs)  x y
  pattern `Coalgs x y    = def₂ (quote Coalgs) x y
  pattern `toN            = proj (quote (DataC.toN))
  pattern `fromN          = proj (quote (DataC.fromN))
  pattern `fromN-toN      = proj (quote (DataC.fromN-toN))
  pattern `toN-fromN      = proj (quote (DataC.toN-fromN))
  pattern `FoldC-equation = proj (quote (FoldC.equation))
  pattern `IndC-equation  = proj (quote (IndC.equation))

module _ (pars : ℕ) where
  conToClause : (c : Name) → TC (Telescope × Vars)
  conToClause c = < forgetTypes , cxtToVars 0 (`refl , `refl) > <$> getConTelescope c pars

  consToClauses : (cs : Names) → TC (List (Telescope × Name × Vars))
  consToClauses []       = ⦇ [] ⦈
  consToClauses (c ∷ cs) = do
    `Γ , (t , p) , args ← conToClause c
    cls                 ← consToClauses cs
    return $ (`Γ , c , (`inl t , `inl p) , args)
      ∷ ((λ (`Γ , c , (t , p) , args) → `Γ , c , (`inr t , `inr p) , args) <$> cls)

  module _ (cs : Names) where
    genFromCons :  (Telescope × Name × Vars → Clause) → TC Clauses
    genFromCons f = map f <$> consToClauses cs

    genToNT = genFromCons λ where
      (`Γ , c , (_ , p) , args , _) → `Γ ⊢ vArg `toN ∷ [ vArg p ] `=
        con c (hUnknowns pars <> args)

    genFromNT = genFromCons λ where
      (Γ , c , (t , _) , _ , args) → Γ ⊢ vArg `fromN ∷ [ vArg (con c args) ] `= t

    genFromN-toNT = genFromCons λ where
      (Γ , _ , (_ , p) , _) → Γ ⊢ vArg `fromN-toN ∷ [ vArg p ] `= `refl

    genToN-fromNT = genFromCons λ where
      (Γ , c , _ , _ , args) → Γ ⊢ vArg `toN-fromN ∷ [ vArg (con c args) ] `= `refl

    genFoldC-equation = pat-lam₀ <$> genFromCons λ where
      (Γ , c , (_ , p) , _) → Γ ⊢ vArg `FoldC-equation ∷ vArg p ∷ [] `= `refl

    genIndC-equation = pat-lam₀ <$> genFromCons λ where
      (Γ , c , (_ , p) , _) → Γ ⊢ vArg `IndC-equation ∷ vArg p ∷ [] `= `refl
  
genDataCT : (D : DataD) (N : DataT D) → Tactic
genDataCT D N hole = do
  `D ← quoteωTC D
  `N ← quoteωTC N

  `Ds ← formatErrorParts [ termErr `D ]
  `Ns ← formatErrorParts [ termErr `N ]
  let msg = "<An instance of DataC " <> `Ds <> " " <> `Ns <> ">"
  dataC ← freshName msg

  d ← DataToNativeName  D N
  pars , cs ← getDataDefinition d

  toN       ← genToNT       pars cs
  fromN     ← genFromNT     pars cs
  fromN-toN ← genFromN-toNT pars cs 
  toN-fromN ← genToN-fromNT pars cs 

  noConstraints $ define (vArg dataC) (`DataC `D `N) (toN <> fromN <> fromN-toN <> toN-fromN)
  unify hole (def₀ dataC)
  where open DataD D

genFoldCT' : (P : FoldP) (f : FoldT P) → Tactic
genFoldCT' P f hole = do
  `P ← quoteωTC P
  `f ← quoteωTC f
  hole ← checkType hole $ `FoldC `P `f

  d ← FoldPToNativeName P
  pars , cs ← getDataDefinition d

  genFoldC-equation pars cs  >>= unify hole

genFoldCT : (P : FoldP) → Name → Tactic
genFoldCT P d hole = do
  `P ← quoteωTC P
  `t ← uncurryFoldP P d
  hole ← checkType hole $ `FoldC `P `t

  d ← FoldPToNativeName P
  pars , cs ← getDataDefinition d

  genFoldC-equation pars cs >>= unify hole

genIndCT' : (P : IndP) (f : IndT P) → Tactic
genIndCT' P f hole = do
  `P ← quoteωTC P
  `f ← quoteωTC f 
  hole ← checkType hole $ `IndC `P `f

  d ← IndPToNativeName P
  pars , cs ← getDataDefinition d

  genIndC-equation pars cs  >>= unify hole

genIndCT : (P : IndP) → Name → Tactic
genIndCT P d hole = do
  `P ← quoteωTC P
  `t ← uncurryIndP P d
  hole ← checkType hole $ `IndC `P `t

  d ← IndPToNativeName P
  pars , cs ← getDataDefinition d
  
  genIndC-equation pars cs >>= unify hole

macro
  genDataC : (D : DataD) (N : DataT D) → Tactic
  genDataC = genDataCT

  genFoldC' : (P : FoldP) (f : FoldT P) → Tactic
  genFoldC' = genFoldCT'

  genFoldC : (P : FoldP) → Name → Tactic
  genFoldC = genFoldCT

  genIndC' : (P : IndP) (f : IndT P) → Tactic
  genIndC' = genIndCT'

  genIndC : (P : IndP) → Name → Tactic
  genIndC = genIndCT
