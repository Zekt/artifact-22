{-# OPTIONS --safe --with-K #-}

module Generics.SimpleContainer.Any where

open import Prelude hiding (lookupAny)
open import Prelude.Sum as Sum
import Prelude.List as List
open import Generics.Telescope
open import Generics.Description
open import Generics.Ornament.Description
open import Generics.Algebra
open import Generics.Recursion
open import Generics.SimpleContainer
open import Examples.Nat

private variable
  rb : RecB
  cb cb' : ConB
  cbs cbs' cbs'' : ConBs

hereConB : ConB → Level → Level → ConB
hereConB []            ℓᵈ ℓ = inl ℓ ∷ []
hereConB (inl ℓ' ∷ cb) ℓᵈ ℓ = inl ℓ' ∷ hereConB cb ℓᵈ ℓ
hereConB (inr rb ∷ cb) ℓᵈ ℓ = inl (max-ℓ rb ⊔ ℓᵈ) ∷ hereConB cb ℓᵈ ℓ

hereODᶜ' : {I : Set ℓⁱ} (D : ConD I cb) {N : Carrierᶜ D ℓᵈ} (toN : Algᶜ D N) (X : Set ℓ)
         → ConOD (Σ[ i ∈ I ] N i × ⊤) (const tt) (ι tt) (hereConB cb ℓᵈ ℓ)
hereODᶜ' (ι i  ) toN X = Δ X λ _ → ι (i , toN refl , tt) refl
hereODᶜ' (σ A D) toN X = Δ A λ a → hereODᶜ' (D a) (curry toN a) X
hereODᶜ' (ρ D E) toN X = Δ (⟦ D ⟧ʳ _) λ ns → hereODᶜ' E (curry toN ns) X

hereODᶜ : {I : Set ℓⁱ} (D : ConD I cb) (sb : SCᵇ cb) {El : Set ℓᵉ} (sc : SCᶜ D sb El)
          {N : Carrierᶜ D ℓᵈ} (toN : Algᶜ D N) (P : El → Set ℓ)
        → Any (λ x → Σ[ ℓ' ∈ Level ] x ≡ (inl ℓ' , true)) (allToList sb)
        → ConOD (Σ[ i ∈ I ] N i × ⊤) (const tt) (ι tt) (hereConB cb ℓᵈ ℓ)
hereODᶜ (σ A D) (false ∷ sb) sc toN P (there i) =
  Δ A λ a → hereODᶜ (D a) sb (sc a) (curry toN a) P i
hereODᶜ (σ A D) (true ∷ sb) (refl ,ωω sc) toN P (here  _) =
  Δ A λ a → hereODᶜ' (D a) (curry toN a) (P a)
hereODᶜ (σ A D) (true ∷ sb) (refl ,ωω sc) toN P (there i) =
  Δ A λ a → hereODᶜ (D a) sb (sc a) (curry toN a) P i
hereODᶜ (ρ D E) (_ ∷ sb) sc toN P (there i) =
  Δ (⟦ D ⟧ʳ _) λ ns → hereODᶜ E sb sc (curry toN ns) P i

hereConBs' : (cb : ConB) → SCᵇ cb → ConB → ConBs → ConBs
hereConBs' []           _           cb' tl = tl
hereConBs' (inl _ ∷ cb) (false ∷ s) cb' tl =       hereConBs' cb s cb' tl
hereConBs' (inl _ ∷ cb) (true  ∷ s) cb' tl = cb' ∷ hereConBs' cb s cb' tl
hereConBs' (inr _ ∷ cb) (_     ∷ s) cb' tl =       hereConBs' cb s cb' tl

hereODᶜˢ' : (cb : ConB) (sb : SCᵇ cb) {I : Set ℓⁱ} {N : I → Set ℓᵈ}
          → (Any (λ x → Σ[ ℓ' ∈ Level ] x ≡ (inl ℓ' , true)) (allToList sb)
            → ConOD (Σ[ i ∈ I ] N i × ⊤) (const tt) (ι tt) cb')
          → {E : ConDs ⊤ cbs'} → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) (ι tt ∷ E) cbs
          → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) (ι tt ∷ E) (hereConBs' cb sb cb' cbs)
hereODᶜˢ' []           _            ODs Tl = Tl
hereODᶜˢ' (inl _ ∷ cb) (false ∷ sb) ODs Tl = hereODᶜˢ' cb sb (λ i → ODs (there i)) Tl
hereODᶜˢ' (inl _ ∷ cb) (true  ∷ sb) ODs Tl = ODs (here (_ , refl))
                                           ∷ hereODᶜˢ' cb sb (λ i → ODs (there i)) Tl
hereODᶜˢ' (inr _ ∷ cb) (_     ∷ sb) ODs Tl = hereODᶜˢ' cb sb (λ i → ODs (there i)) Tl

hereConBs : (cbs : ConBs) → All SCᵇ cbs → Level → Level → ConBs → ConBs
hereConBs []         _        ℓᵈ ℓ acc = acc
hereConBs (cb ∷ cbs) (s ∷ ss) ℓᵈ ℓ acc =
  hereConBs' cb s (hereConB cb ℓᵈ ℓ) (hereConBs cbs ss ℓᵈ ℓ acc)

hereODᶜˢ : {I : Set ℓⁱ} (D : ConDs I cbs) (sbs : All SCᵇ cbs) {El : Set ℓᵉ}
           (scs : SCᶜˢ D sbs El) {N : Carrierᶜˢ D ℓᵈ} (toN : Algᶜˢ D N) (P : El → Set ℓ)
         → {E : ConDs ⊤ cbs''} → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) E cbs'
         → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) (ι tt ∷ E) (hereConBs cbs sbs ℓᵈ ℓ cbs')
hereODᶜˢ []       _          _            toN P Acc = ∺ Acc
hereODᶜˢ (D ∷ Ds) (sb ∷ sbs) (sc ,ωω scs) toN P Acc =
  hereODᶜˢ' _ sb (hereODᶜ D sb sc (toN ∘ inl) P) (hereODᶜˢ Ds sbs scs (toN ∘ inr) P Acc)

thereRecB : RecB → ConB
thereRecB []       = inr [] ∷ []
thereRecB (ℓ ∷ rb) = inl ℓ ∷ thereRecB rb

thereODʳ : {I : Set ℓⁱ} (D : RecD I rb) {N : I → Set ℓ}
         → ⟦ D ⟧ʳ N → ∀ {i} → N i
         → ConOD (Σ[ i ∈ I ] N i × ⊤) (const tt) (ρ (ι tt) (ι tt)) (thereRecB rb)
thereODʳ (ι i  ) n  n' = ρ (ι (_ , n , tt) refl) (ι (_ , n' , tt) refl)
thereODʳ (π A D) ns n' = Δ A λ a → thereODʳ (D a) (ns a) n'

thereConB : ConB → Level → RecB → ConB
thereConB []             ℓᵈ rb = thereRecB rb
thereConB (inl ℓ'  ∷ cb) ℓᵈ rb = inl ℓ' ∷ thereConB cb ℓᵈ rb
thereConB (inr rb' ∷ cb) ℓᵈ rb = inl (max-ℓ rb' ⊔ ℓᵈ) ∷ thereConB cb ℓᵈ rb

thereODᶜ' : {I : Set ℓⁱ} (D : ConD I cb) {N : I → Set ℓᵈ} (toN : Algᶜ D N)
            (R : RecD I rb) → ⟦ R ⟧ʳ N
          → ConOD (Σ[ i ∈ I ] N i × ⊤) (const tt) (ρ (ι tt) (ι tt)) (thereConB cb ℓᵈ rb)
thereODᶜ' (ι i  ) toN R ns = thereODʳ R ns (toN refl)
thereODᶜ' (σ A D) toN R ns = Δ A λ a → thereODᶜ' (D a) (curry toN a) R ns
thereODᶜ' (ρ D E) toN R ns = Δ (⟦ D ⟧ʳ _) λ ns' → thereODᶜ' E (curry toN ns') R ns

thereODᶜ : {I : Set ℓⁱ} (D : ConD I cb) {N : I → Set ℓᵈ} (toN : Algᶜ D N)
         → (j : Any (λ x → Σ[ rb ∈ RecB ] (Sum.[ const ⊥ , rb ≡_ ] x)) cb)
         → ConOD (Σ[ i ∈ I ] N i × ⊤) (const tt) (ρ (ι tt) (ι tt))
                 (thereConB cb ℓᵈ (fst (snd (List.lookupAny j))))
thereODᶜ (σ A D) toN (there j) = Δ A λ a → thereODᶜ (D a) (curry toN a) j
thereODᶜ (ρ D E) toN (here (rb , refl)) =
                                 Δ (⟦ D ⟧ʳ _) λ ns → thereODᶜ' E (curry toN ns) D ns
thereODᶜ (ρ D E) toN (there j) = Δ (⟦ D ⟧ʳ _) λ ns → thereODᶜ  E (curry toN ns) j

thereConBs' : ConB → ConB → Level → ConBs → ConBs
thereConBs' []            cb' ℓᵈ tl = tl
thereConBs' (inl _  ∷ cb) cb' ℓᵈ tl = thereConBs' cb cb' ℓᵈ tl
thereConBs' (inr rb ∷ cb) cb' ℓᵈ tl = thereConB cb' ℓᵈ rb ∷ thereConBs' cb cb' ℓᵈ tl

thereODᶜˢ' :
    (cb : ConB) {I : Set ℓⁱ} {N : I → Set ℓᵈ}
  → ((j : Any (λ x → Σ[ rb ∈ RecB ] (Sum.[ const ⊥ , rb ≡_ ] x)) cb)
    → ConOD (Σ[ i ∈ I ] N i × ⊤) (const tt) (ρ (ι tt) (ι tt))
            (thereConB cb' ℓᵈ (fst (snd (List.lookupAny j)))))
  → {E : ConDs ⊤ cbs'} → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) (ρ (ι tt) (ι tt) ∷ E) cbs
  → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) (ρ (ι tt) (ι tt) ∷ E) (thereConBs' cb cb' ℓᵈ cbs)
thereODᶜˢ' []            ODs Tl = Tl
thereODᶜˢ' (inl ℓ' ∷ cb) ODs Tl = thereODᶜˢ' cb (λ i → ODs (there i)) Tl
thereODᶜˢ' (inr rb ∷ cb) ODs Tl = ODs (here (rb , refl))
                                ∷ thereODᶜˢ' cb (λ i → ODs (there i)) Tl

thereConBs : ConBs → Level → ConBs → ConBs
thereConBs []         ℓᵈ acc = acc
thereConBs (cb ∷ cbs) ℓᵈ acc = thereConBs' cb cb ℓᵈ (thereConBs cbs ℓᵈ acc)

thereODᶜˢ :
    {I : Set ℓⁱ} (D : ConDs I cbs) {N : Carrierᶜˢ D ℓᵈ} (toN : Algᶜˢ D N)
  → {E : ConDs ⊤ cbs'} → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) E cbs'
  → ConODs (Σ[ i ∈ I ] N i × ⊤) (const tt) (ρ (ι tt) (ι tt) ∷ E) (thereConBs cbs ℓᵈ cbs')
thereODᶜˢ []       toN Acc = ∺ Acc
thereODᶜˢ (D ∷ Ds) toN Acc =
  thereODᶜˢ' _ (thereODᶜ D (toN ∘ inl)) (thereODᶜˢ Ds (toN ∘ inr) Acc)

hereConBs'-lemma :
    (f : ConB → Level) (cb : ConB) (sb : SCᵇ cb) (cb' : ConB) (tl : ConBs)
  → maxMap f (hereConBs' cb sb cb' tl) ≡ hasEl? (f cb') cb sb ⊔ maxMap f tl
hereConBs'-lemma f []           []           cb' tl = refl
hereConBs'-lemma f (inl _ ∷ cb) (false ∷ sb) cb' tl = hereConBs'-lemma f cb sb cb' tl
hereConBs'-lemma f (inl _ ∷ cb) (true  ∷ sb) cb' tl = cong (f cb' ⊔_)
                                                     (hereConBs'-lemma f cb sb cb' tl)
hereConBs'-lemma f (inr _ ∷ cb) (_     ∷ sb) cb' tl = hereConBs'-lemma f cb sb cb' tl

max-π-hereConB : (cb : ConB) (ℓᵈ ℓ : Level) → max-π (hereConB cb ℓᵈ ℓ) ≡ 0ℓ
max-π-hereConB []            ℓᵈ ℓ = refl
max-π-hereConB (inl ℓ' ∷ cb) ℓᵈ ℓ = max-π-hereConB cb ℓᵈ ℓ
max-π-hereConB (inr rb ∷ cb) ℓᵈ ℓ = max-π-hereConB cb ℓᵈ ℓ

max-π-hereConBs : (cbs : ConBs) (sbs : All SCᵇ cbs) (ℓᵈ ℓ : Level) (acc : ConBs)
                → maxMap max-π (hereConBs cbs sbs ℓᵈ ℓ acc) ≡ maxMap max-π acc
max-π-hereConBs []         []         ℓᵈ ℓ acc = refl
max-π-hereConBs (cb ∷ cbs) (sb ∷ sbs) ℓᵈ ℓ acc =
  begin
    maxMap max-π (hereConBs (cb ∷ cbs) (sb ∷ sbs) ℓᵈ ℓ acc)
      ≡⟨⟩
    maxMap max-π (hereConBs' cb sb (hereConB cb ℓᵈ ℓ) (hereConBs cbs sbs ℓᵈ ℓ acc))
      ≡⟨ hereConBs'-lemma max-π cb sb (hereConB cb ℓᵈ ℓ) (hereConBs cbs sbs ℓᵈ ℓ acc) ⟩
    hasEl? (max-π (hereConB cb ℓᵈ ℓ)) cb sb ⊔ maxMap max-π (hereConBs cbs sbs ℓᵈ ℓ acc)
      ≡⟨ cong₂ _⊔_ (hasEl?-bound (max-π (hereConB cb ℓᵈ ℓ)) cb sb (max-π-hereConB cb ℓᵈ ℓ))
                   (max-π-hereConBs cbs sbs ℓᵈ ℓ acc) ⟩
    maxMap max-π acc
  ∎ where open ≡-Reasoning

max-σ-hereConB : (cb : ConB) (ℓᵈ ℓ : Level)
               → max-σ (hereConB cb ℓᵈ ℓ) ≡ max-π cb ⊔ max-σ cb ⊔ hasRec? ℓᵈ cb ⊔ ℓ
max-σ-hereConB []            ℓᵈ ℓ = refl
max-σ-hereConB (inl ℓ' ∷ cb) ℓᵈ ℓ = cong (ℓ' ⊔_) (max-σ-hereConB cb ℓᵈ ℓ)
max-σ-hereConB (inr rb ∷ cb) ℓᵈ ℓ = cong (max-ℓ rb ⊔ ℓᵈ ⊔_) (max-σ-hereConB cb ℓᵈ ℓ)

max-σ-hereConBs : (cbs : ConBs) (sbs : All SCᵇ cbs) (ℓᵈ ℓ : Level) (acc : ConBs)
                → maxMap max-σ (hereConBs cbs sbs ℓᵈ ℓ acc)
                ⊑ maxMap max-π cbs ⊔ maxMap max-σ cbs ⊔
                  ℓᵈ ⊔ maxMap (uncurry (hasEl? ℓ)) (allToList sbs) ⊔ maxMap max-σ acc
max-σ-hereConBs []         []         ℓᵈ ℓ acc = refl
max-σ-hereConBs (cb ∷ cbs) (sb ∷ sbs) ℓᵈ ℓ acc =
  let rhs = maxMap max-π (cb ∷ cbs) ⊔ maxMap max-σ (cb ∷ cbs) ⊔
            ℓᵈ ⊔ maxMap (uncurry (hasEl? ℓ)) (allToList (sb ∷ sbs)) ⊔ maxMap max-σ acc in
  begin
    maxMap max-σ (hereConBs (cb ∷ cbs) (sb ∷ sbs) ℓᵈ ℓ acc) ⊔ rhs
      ≡⟨⟩
    maxMap max-σ (hereConBs' cb sb (hereConB cb ℓᵈ ℓ) (hereConBs cbs sbs ℓᵈ ℓ acc)) ⊔ rhs
      ≡⟨ cong (rhs ⊔_)
        (hereConBs'-lemma max-σ cb sb (hereConB cb ℓᵈ ℓ) (hereConBs cbs sbs ℓᵈ ℓ acc)) ⟩
    hasEl? (max-σ (hereConB cb ℓᵈ ℓ)) cb sb ⊔
    maxMap max-σ (hereConBs cbs sbs ℓᵈ ℓ acc) ⊔ rhs
      ≡⟨ cong₂ _⊔_ (cong (λ ℓ' → hasEl? ℓ' cb sb ⊔ rhs) (max-σ-hereConB cb ℓᵈ ℓ))
                   (max-σ-hereConBs cbs sbs ℓᵈ ℓ acc) ⟩
    hasEl? (max-π cb ⊔ max-σ cb ⊔ hasRec? ℓᵈ cb ⊔ ℓ) cb sb ⊔ rhs
      ≡⟨ cong (rhs ⊔_) (hasEl?-dist-⊔ (max-π cb ⊔ max-σ cb ⊔ hasRec? ℓᵈ cb) ℓ cb sb) ⟩
    hasEl? (max-π cb ⊔ max-σ cb ⊔ hasRec? ℓᵈ cb) cb sb ⊔ rhs
      ≡⟨ cong (rhs ⊔_) (hasEl?-bound (max-π cb ⊔ max-σ cb ⊔ hasRec? ℓᵈ cb) cb sb
                         (cong (max-π cb ⊔ max-σ cb ⊔_) (hasRec?-bound ℓᵈ cb))) ⟩
    rhs
  ∎ where open ≡-Reasoning

max-π-thereRecB : (rb : RecB) → max-π (thereRecB rb) ≡ 0ℓ
max-π-thereRecB []       = refl
max-π-thereRecB (ℓ ∷ rb) = max-π-thereRecB rb

max-π-thereConB : (cb : ConB) (ℓᵈ : Level) (rb : RecB)
                → max-π (thereConB cb ℓᵈ rb) ≡ 0ℓ
max-π-thereConB []           ℓᵈ rb = max-π-thereRecB rb
max-π-thereConB (inl _ ∷ cb) ℓᵈ rb = max-π-thereConB cb ℓᵈ rb
max-π-thereConB (inr _ ∷ cb) ℓᵈ rb = max-π-thereConB cb ℓᵈ rb

max-π-thereConBs' : (cb cb' : ConB) (ℓᵈ : Level) (tl : ConBs)
                  → maxMap max-π (thereConBs' cb cb' ℓᵈ tl) ≡ maxMap max-π tl
max-π-thereConBs' []            cb' ℓᵈ tl = refl
max-π-thereConBs' (inl _  ∷ cb) cb' ℓᵈ tl = max-π-thereConBs' cb cb' ℓᵈ tl
max-π-thereConBs' (inr rb ∷ cb) cb' ℓᵈ tl =
  cong₂ _⊔_ (max-π-thereConB cb' ℓᵈ rb) (max-π-thereConBs' cb cb' ℓᵈ tl)

max-π-thereConBs : (cbs : ConBs) (ℓᵈ : Level) (acc : ConBs)
                 → maxMap max-π (thereConBs cbs ℓᵈ acc) ≡ maxMap max-π acc
max-π-thereConBs []         ℓᵈ acc = refl
max-π-thereConBs (cb ∷ cbs) ℓᵈ acc =
  begin
    maxMap max-π (thereConBs (cb ∷ cbs) ℓᵈ acc)
      ≡⟨⟩
    maxMap max-π (thereConBs' cb cb ℓᵈ (thereConBs cbs ℓᵈ acc))
      ≡⟨ max-π-thereConBs' cb cb ℓᵈ (thereConBs cbs ℓᵈ acc) ⟩
    maxMap max-π (thereConBs cbs ℓᵈ acc)
      ≡⟨ max-π-thereConBs cbs ℓᵈ acc ⟩
    maxMap max-π acc
  ∎ where open ≡-Reasoning

max-σ-thereRecB : (rb : RecB) → max-σ (thereRecB rb) ≡ max-ℓ rb
max-σ-thereRecB []       = refl
max-σ-thereRecB (ℓ ∷ rb) = cong (ℓ ⊔_) (max-σ-thereRecB rb)

max-σ-thereConB : (cb : ConB) (ℓᵈ : Level) (rb : RecB)
                → max-σ (thereConB cb ℓᵈ rb)
                ≡ max-π cb ⊔ max-σ cb ⊔ hasRec? ℓᵈ cb ⊔ max-ℓ rb
max-σ-thereConB []            ℓᵈ  rb = max-σ-thereRecB rb
max-σ-thereConB (inl ℓ   ∷ cb) ℓᵈ rb = cong (ℓ ⊔_) (max-σ-thereConB cb ℓᵈ rb)
max-σ-thereConB (inr rb' ∷ cb) ℓᵈ rb = cong (max-ℓ rb' ⊔ ℓᵈ ⊔_) (max-σ-thereConB cb ℓᵈ rb)

max-σ-thereConBs' : (cb cb' : ConB) (ℓᵈ : Level) (cbs : ConBs)
                  → maxMap max-σ (thereConBs' cb cb' ℓᵈ cbs)
                  ⊑ max-π cb ⊔ max-π cb' ⊔ max-σ cb' ⊔ ℓᵈ ⊔ maxMap max-σ cbs
max-σ-thereConBs' []            cb' ℓᵈ cbs = refl
max-σ-thereConBs' (inl ℓ' ∷ cb) cb' ℓᵈ cbs = max-σ-thereConBs' cb cb' ℓᵈ cbs
max-σ-thereConBs' (inr rb ∷ cb) cb' ℓᵈ cbs =
  let rhs = max-ℓ rb ⊔ max-π cb ⊔ max-π cb' ⊔ max-σ cb' ⊔ ℓᵈ ⊔ maxMap max-σ cbs in
  begin
    maxMap max-σ (thereConBs' (inr rb ∷ cb) cb' ℓᵈ cbs) ⊔ rhs
      ≡⟨⟩
    max-σ (thereConB cb' ℓᵈ rb) ⊔ maxMap max-σ (thereConBs' cb cb' ℓᵈ cbs) ⊔ rhs
      ≡⟨ cong (rhs ⊔_) (cong₂ _⊔_
        (max-σ-thereConB cb' ℓᵈ rb) (max-σ-thereConBs' cb cb' ℓᵈ cbs)) ⟩
    hasRec? ℓᵈ cb' ⊔ rhs
      ≡⟨ cong (rhs ⊔_) (hasRec?-bound ℓᵈ cb') ⟩
    rhs
  ∎ where open ≡-Reasoning

max-σ-thereConBs : (cbs : ConBs) (ℓᵈ : Level) (cbs' : ConBs)
                 → maxMap max-σ (thereConBs cbs ℓᵈ cbs')
                 ⊑ maxMap max-π cbs ⊔ maxMap max-σ cbs ⊔ ℓᵈ ⊔ maxMap max-σ cbs'
max-σ-thereConBs []         ℓᵈ cbs' = refl
max-σ-thereConBs (cb ∷ cbs) ℓᵈ cbs' =
  let rhs = max-π cb ⊔ max-σ cb ⊔ maxMap max-π cbs ⊔ maxMap max-σ cbs ⊔
            ℓᵈ ⊔ maxMap max-σ cbs' in
  begin
    maxMap max-σ (thereConBs (cb ∷ cbs) ℓᵈ cbs') ⊔ rhs
      ≡⟨⟩
    maxMap max-σ (thereConBs' cb cb ℓᵈ (thereConBs cbs ℓᵈ cbs')) ⊔ rhs
      ≡⟨ cong (maxMap max-σ (thereConBs' cb cb ℓᵈ (thereConBs cbs ℓᵈ cbs')) ⊔ rhs ⊔_)
        (sym (max-σ-thereConBs cbs ℓᵈ cbs')) ⟩
    maxMap max-σ (thereConBs' cb cb ℓᵈ (thereConBs cbs ℓᵈ cbs')) ⊔
    maxMap max-σ (thereConBs cbs ℓᵈ cbs') ⊔ rhs
      ≡⟨ cong (rhs ⊔_) (max-σ-thereConBs' cb cb ℓᵈ (thereConBs cbs ℓᵈ cbs')) ⟩
    maxMap max-σ (thereConBs cbs ℓᵈ cbs') ⊔ rhs
      ≡⟨ cong (rhs ⊔_) (max-σ-thereConBs cbs ℓᵈ cbs') ⟩
    rhs
  ∎ where open ≡-Reasoning

AnyD-level-inequality :
    (ℓ ℓᵈ : Level) (cbs : ConBs) (sbs : All SCᵇ cbs)
  → maxMap max-π cbs ⊔ maxMap max-σ cbs ⊑ ℓᵈ
  → maxMap max-π (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⊔
    maxMap max-σ (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ []))
  ⊑ ℓᵈ ⊔ maxMap (uncurry (hasEl? ℓ)) (allToList sbs)
AnyD-level-inequality ℓ ℓᵈ cbs sbs ineq =
  let ℓᵉ   = maxMap (uncurry (hasEl? ℓ)) (allToList sbs)
      lhs  = maxMap max-π (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⊔
             maxMap max-σ (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⊔ ℓᵈ ⊔ ℓᵉ
      erhs = maxMap max-π cbs ⊔ maxMap max-σ cbs ⊔ ℓᵈ ⊔ ℓᵉ in
  begin
    lhs
      ≡⟨ cong (lhs ⊔_) (sym ineq) ⟩
    maxMap max-π (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⊔
    maxMap max-σ (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⊔ erhs
      ≡⟨ cong (lhs ⊔ erhs ⊔_) (sym (max-σ-thereConBs cbs ℓᵈ [])) ⟩
    maxMap max-π (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⊔
    maxMap max-σ (hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⊔
    maxMap max-σ (thereConBs cbs ℓᵈ []) ⊔ erhs
      ≡⟨ cong₂ _⊔_ (max-π-hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ []))
                   (max-σ-hereConBs cbs sbs ℓᵈ ℓ (thereConBs cbs ℓᵈ [])) ⟩
    maxMap max-π (thereConBs cbs ℓᵈ []) ⊔ maxMap max-σ (thereConBs cbs ℓᵈ []) ⊔ erhs
      ≡⟨ cong (ℓᵉ ⊔_) (cong₂ _⊔_
        (max-π-thereConBs cbs ℓᵈ []) (max-σ-thereConBs cbs ℓᵈ [])) ⟩
    erhs
      ≡⟨ cong (ℓᵉ ⊔_) ineq ⟩
    ℓᵈ ⊔ ℓᵉ
  ∎ where open ≡-Reasoning

AnyODᵖᵈ : (D : PDataD) → SC D → {N : ∀ ps → Carrierᵖᵈ D ps (PDataD.dlevel D)}
        → (∀ {ps} → Algᵖᵈ D (N ps)) → Level → PDataOD NatPD
AnyODᵖᵈ D S {N} toN ℓ = record
  { alevel = maxMap (uncurry (hasEl? ℓ)) (allToList (SC.pos S))
  ; level-inequality = AnyD-level-inequality
      ℓ (PDataD.dlevel D) (PDataD.struct D) (SC.pos S)(PDataD.level-inequality D)
  ; Param  = [[ ps ∶ PDataD.Param D ]] [ P ∶ (SC.El S ps → Set ℓ) ] []
  ; Index  = λ (ps , _) → [[ is ∶ PDataD.Index D ps ]] [ n ∶ N ps is ] []
  ; applyP = λ (ps , P , _) → let Dᶜˢ = PDataD.applyP D ps in
      hereODᶜˢ Dᶜˢ (SC.pos S) (SC.coe S ps) toN P (thereODᶜˢ Dᶜˢ toN []) }

AnyOD : ∀ {D N} → DataC D N → SCᵈ D → DataOD NatD
AnyOD {D} C S = record
  { #levels = suc (DataD.#levels D)
  ; applyL  = λ (ℓ , ℓs) → AnyODᵖᵈ (DataD.applyL D ℓs) (S ℓs) (DataC.toN C) ℓ }

AnyD : ∀ {D N} → DataC D N → SCᵈ D → DataD
AnyD C S = ⌊ AnyOD C S ⌋ᵈ
