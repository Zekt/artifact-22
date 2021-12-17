{-# OPTIONS --safe #-}

module Generics.Safe.Ornament.Promotion where

open import Prelude
open import Generics.Safe.Algebra
open import Generics.Safe.Description
open import Generics.Safe.Ornament
open import Generics.Safe.Recursion

ornAlg : ∀ {D E N} → DataO D E → DataC E N → Alg D
ornAlg {N = N} O C = record
  { Carrier = λ ℓs ps is → let Oᵖ = DataO.applyL O ℓs
                           in N (erase# (DataO.LevelO  O    ) ℓs)
                                (eraseᵗ (PDataO.ParamO Oᵖ   ) ps)
                                (eraseᵗ (PDataO.IndexO Oᵖ ps) is)
  ; apply = DataC.toN C ∘ eraseᵈ O }