{-# OPTIONS --safe #-}

module Generics.Safe.Ornament where

open import Prelude
open import Generics.Safe.Description

private variable
  A : Set ℓ
  rb rb' : RecB
  cb cb' : ConB
  cbs cbs' : ConBs

module _ {I : Set ℓⁱ} {J : Set ℓʲ} (e : I → J) where

  infixr 5 _∷_
  infix  5 ∺_

  data RecO : RecD I rb → RecD J rb' → Setω where
    ι : ∀ {i j} (eq : e i ≡ j) → RecO (ι i) (ι j)
    π : {D : A → RecD I rb} {E : A → RecD J rb}
        (O : (a : A) → RecO (D a) (E a)) → RecO (π A D) (π A E)

  data ConO : ConD I cb → ConD J cb' → Setω where
    ι : ∀ {i j} (eq : e i ≡ j) → ConO (ι i) (ι j)
    σ : {D : A → ConD I cb} {E : A → ConD J cb'}
        (O : (a : A) → ConO (D a) (E a)) → ConO (σ A D) (σ A E)
    Δ : {D : A → ConD I cb} {E : ConD J cb'}
        (O : (a : A) → ConO (D a)  E   ) → ConO (σ A D)      E
    ∇ : {D : ConD I cb} {E : A → ConD J cb'}
        (a : A)   (O : ConO  D    (E a)) → ConO      D  (σ A E)
    ρ : {R : RecD I rb} {S : RecD J rb} {D : ConD I cb} {E : ConD J cb'}
        (O : RecO R S) (O' : ConO D E) → ConO (ρ R D) (ρ S E)

  data ConOs : ConDs I cbs → ConDs J cbs' → Setω where
    []  : ConOs [] []
    _∷_ : {D : ConD I cb} {E : ConD J cb'}
          {Ds : ConDs I cbs} {Es : ConDs J cbs'}
          (O : ConO D E) (Os : ConOs Ds (E ∷ Es)) → ConOs (D ∷ Ds) (E ∷ Es)
    ∺_  : {E : ConD J cb} {Ds : ConDs I cbs} {Es : ConDs J cbs'}
                         (Os : ConOs Ds      Es ) → ConOs      Ds  (E ∷ Es)

module _ {I : Set ℓⁱ} {J : Set ℓʲ} {e : I → J} where

  eraseʳ : {D : RecD I rb} {E : RecD J rb} (O : RecO e D E)
           {X : J → Set ℓ} → ⟦ D ⟧ʳ (λ i → X (e i)) → ⟦ E ⟧ʳ X
  eraseʳ (ι eq) x  = subst _ eq x
  eraseʳ (π  O) xs = λ a → eraseʳ (O a) (xs a)

  eraseᶜ : {D : ConD I cb} {E : ConD J cb'} (O : ConO e D E)
           {X : J → Set ℓˣ} {i : I} → ⟦ D ⟧ᶜ (λ i' → X (e i')) i → ⟦ E ⟧ᶜ X (e i)
  eraseᶜ (ι eq  ) eq'      = trans (sym eq) (cong _ eq')
  eraseᶜ (σ   O ) (a , xs) = a , eraseᶜ (O a) xs
  eraseᶜ (Δ   O ) (a , xs) =     eraseᶜ (O a) xs
  eraseᶜ (∇ a O )      xs  = a , eraseᶜ  O    xs
  eraseᶜ (ρ O O') (x , xs) = eraseʳ O x , eraseᶜ O' xs

  eraseᶜˢ : {Ds : ConDs I cbs} {Es : ConDs J cbs'} (Os : ConOs e Ds Es)
            {X : J → Set ℓˣ} {i : I} → ⟦ Ds ⟧ᶜˢ (λ i' → X (e i')) i → ⟦ Es ⟧ᶜˢ X (e i)
  eraseᶜˢ (O ∷ Os) (inl xs) = inl (eraseᶜ  O  xs)
  eraseᶜˢ (O ∷ Os) (inr xs) =      eraseᶜˢ Os xs
  eraseᶜˢ (  ∺ Os)      xs  = inr (eraseᶜˢ Os xs)

record PDataO (D E : PDataD) : Setω where
  field
    param  : ⟦ PDataD.Param D ⟧ᵗ → ⟦ PDataD.Param E ⟧ᵗ
    index  : (p : ⟦ PDataD.Param D ⟧ᵗ)
           → ⟦ PDataD.Index D p ⟧ᵗ → ⟦ PDataD.Index E (param p) ⟧ᵗ
    applyP : (p : ⟦ PDataD.Param D ⟧ᵗ)
           → ConOs (index p) (PDataD.applyP D p) (PDataD.applyP E (param p))

record DataO (D E : DataD) : Setω where
  field
    levels : DataD.Levels D → DataD.Levels E
    applyL : (ℓs : DataD.Levels D)
           → PDataO (DataD.applyL D ℓs) (DataD.applyL E (levels ℓs))

eraseᵖᵈ : {D E : PDataD} (O : PDataO D E) (p : ⟦ PDataD.Param D ⟧ᵗ)
        → let q = PDataO.param O p; index = PDataO.index O p in
          {X : ⟦ PDataD.Index E q ⟧ᵗ → Set ℓ} {i : ⟦ PDataD.Index D p ⟧ᵗ}
        → ⟦ D ⟧ᵖᵈ p (λ i' → X (index i')) i → ⟦ E ⟧ᵖᵈ q X (index i)
eraseᵖᵈ O p = eraseᶜˢ (PDataO.applyP O p)

eraseᵈ : {D E : DataD} (O : DataO D E) (ℓs : DataD.Levels D)
       → let ℓs' = DataO.levels O ℓs
             Dᵐ  = DataD.applyL D ℓs
             Eᵐ  = DataD.applyL E ℓs'
             Oᵐ  = DataO.applyL O ℓs in
         (p : ⟦ PDataD.Param Dᵐ ⟧ᵗ)
       → let q = PDataO.param Oᵐ p; index = PDataO.index Oᵐ p in
         {X : ⟦ PDataD.Index Eᵐ q ⟧ᵗ → Set ℓ} {i : ⟦ PDataD.Index Dᵐ p ⟧ᵗ}
       → ⟦ D ⟧ᵈ ℓs p (λ i' → X (index i')) i → ⟦ E ⟧ᵈ ℓs' q X (index i)
eraseᵈ O ℓs p = eraseᶜˢ (PDataO.applyP (DataO.applyL O ℓs) p)
