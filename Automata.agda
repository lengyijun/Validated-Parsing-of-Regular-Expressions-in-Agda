{-
  Here the Automata and its operations are defined according to:
    The Theory of Parsing, Translation and Compiling (Vol. 1 : Parsing)
    Section 2.2: Regular sets, their generators, and their recognizers
      by Alfred V. Aho and Jeffery D. Ullman

  Steven Cheung 2015.
  Version 10-01-2016
-}

module Automata (Σ : Set) where

open import Data.List
open import Data.Bool
open import Relation.Binary.PropositionalEquality
open import Relation.Nullary
open import Data.Sum
open import Data.Product hiding (Σ)
open import Data.Unit
open import Data.Empty
open import Data.Nat

open import Util
open import Subset
open import Subset.DecidableSubset renaming (_∈_ to _∈ᵈ_ ; Ø to ø ; _⋃_ to _⋃ᵈ_ ; _⊆_ to _⊆ᵈ_ ; _⊇_ to _⊇ᵈ_ ; _≈_ to _≈ᵈ_ ; ⟦_⟧ to ⟦_⟧ᵈ)
open import Language Σ hiding (Ø ; _⋃_)

-- Nondeterministic finite automata with ε-step
-- section 2.2.3: Finite Automata
record ε-NFA : Set₁ where
  field
    Q  : Set
    δ  : Q → Σᵉ → DecSubset Q
    q₀ : Q
    F  : DecSubset Q
    Q? : DecEq Q
    It : List Q

-- section 2.2.3: Finite Automata
module ε-NFA-Operations (N : ε-NFA) where
  open ε-NFA N
  open ≡-Reasoning

  -- a move from (q , aw) to (q' , w)
  infix 7 _⊢_
  _⊢_ : (Q × Σᵉ × Σᵉ*) → (Q × Σᵉ*) → Set
  (q , aᵉ , wᵉ) ⊢ (q' , wᵉ') = wᵉ ≡ wᵉ' × q' ∈ᵍ δ q aᵉ

  -- k moves from (q , w) to (q' , w')
  infix 7 _⊢ᵏ_─_
  _⊢ᵏ_─_ : (Q × Σᵉ*) → ℕ → (Q × Σᵉ*) → Set
  (q , wᵉ) ⊢ᵏ zero    ─ (q' , wᵉ')
    = q ≡ q' × wᵉ ≡ wᵉ'
  (q , wᵉ) ⊢ᵏ (suc n) ─ (q' , wᵉ')
    = Σ[ p ∈ Q ] Σ[ aᵉ ∈ Σᵉ ] Σ[ uᵉ ∈ Σᵉ* ]
      ( wᵉ ≡ aᵉ ∷ uᵉ × (q , aᵉ , uᵉ) ⊢ (p , uᵉ) × (p , uᵉ) ⊢ᵏ n ─ (q' , wᵉ') )

  -- alternative definition of ⊢ᵏ
  infix 7 _⊢ᵏ₂_─_
  _⊢ᵏ₂_─_ : (Q × Σᵉ*) → ℕ → (Q × Σᵉ*) → Set
  (q , wᵉ) ⊢ᵏ₂ zero ─ (q' , wᵉ')
    = (q , wᵉ) ⊢ᵏ zero ─ (q' , wᵉ')
  (q , wᵉ) ⊢ᵏ₂ (suc n) ─ (q' , wᵉ')
    = Σ[ p ∈ Q ] Σ[ aᵉ ∈ Σᵉ ]
      ( (q , wᵉ) ⊢ᵏ n ─ (p , aᵉ ∷ wᵉ') × (p , aᵉ , wᵉ') ⊢ (q' , wᵉ') )
 
  -- transitive closure of ⊢
  infix 7 _⊢*_
  _⊢*_ : (Q × Σᵉ*) → (Q × Σᵉ*) → Set
  (q , wᵉ) ⊢* (q' , wᵉ') = Σ[ n ∈ ℕ ] (q , wᵉ) ⊢ᵏ n ─ (q' , wᵉ')

  -- alternative definition of ⊢*, we will later prove that ⊢*₂ is equivalent to ⊢*
  infix 7 _⊢*₂_
  _⊢*₂_ : (Q × Σᵉ*) → (Q × Σᵉ*) → Set
  (q , wᵉ) ⊢*₂ (q' , wᵉ') = Σ[ n ∈ ℕ ] Σ[ m ∈ ℕ ] Σ[ p ∈ Q ] Σ[ uᵉ ∈ Σᵉ* ]
                            ((q , wᵉ) ⊢ᵏ n ─ (p , uᵉ) × (p , uᵉ) ⊢ᵏ m ─ (q' , wᵉ'))

  -- ε closure
  infix 7 _→εᵏ_─_
  _→εᵏ_─_ : Q → ℕ → Q → Set
  q →εᵏ zero  ─ q' = q ≡ q'
  q →εᵏ suc n ─ q' = Σ[ p ∈ Q ] ( p ∈ᵍ δ q E × p →εᵏ n ─ q' )

  infix 7 _→ε*_
  _→ε*_ : Q → Q → Set
  q →ε* q' = Σ[ n ∈ ℕ ] q →εᵏ n ─ q'

  →εᵏ-lem₁ : ∀ q n p q'
             → q →εᵏ n ─ p
             → q' ∈ᵍ δ p E
             → q →εᵏ suc n ─ q'
  →εᵏ-lem₁ q zero    .q q' refl q'∈δpE = q' , q'∈δpE , refl
  →εᵏ-lem₁ q (suc n)  p q' (p₁ , p∈δqE , prf) q'∈δpE = p₁ , p∈δqE , →εᵏ-lem₁ p₁ n p q' prf q'∈δpE

  data Reachable : Q → Set where
    step : {q : Q} → ∀ p → q →ε* p → Reachable q

  Reachable? : {q : Q} → Q → List (Reachable q) → Bool
  Reachable? q' []              = false
  Reachable? q' (step p _ ∷ rs) = decEqToBool Q? q' p ∨ Reachable? q' rs

  one-state : {q : Q} → List (Reachable q) → List Q → (q' : Q) → q →ε* q' → List (Reachable q)
  one-state rs []       q' q→ε*q' = []
  one-state rs (p ∷ ps) q' q→ε*q' with Reachable? p rs
  one-state rs (p ∷ ps) q' q→ε*q'      | true  = one-state rs ps q' q→ε*q'
  one-state rs (p ∷ ps) q' q→ε*q'      | false with p ∈ᵈ δ q' E | inspect (δ q' E) p
  one-state rs (p ∷ ps) q' (n , q→εᵏq') | false | true  | [ p∈δq'E ]
    = step p (suc n , (→εᵏ-lem₁ _ n q' p q→εᵏq' p∈δq'E)) ∷ one-state (step p (suc n , (→εᵏ-lem₁ _ n q' p q→εᵏq' p∈δq'E)) ∷ rs) ps q' (n , q→εᵏq')
  one-state rs (p ∷ ps) q' q→ε*q'      | false | false | [ p∉δq'E ] = one-state rs ps q' q→ε*q'

  one-step : {q : Q} → List (Reachable q) → List (Reachable q) → List (Reachable q)
  one-step rs []                   = []
  one-step rs (step p q→ε*p ∷ rs') = one-state rs It p q→ε*p ++ one-step (one-state rs It p q→ε*p ++ rs) rs'

  n-step : {q : Q} → ℕ → List (Reachable q) → List (Reachable q)
  n-step zero    rs = rs
  n-step (suc n) rs with one-step rs rs
  n-step (suc n) rs | [] = rs
  n-step (suc n) rs | _  = n-step n (one-step rs rs)

  ε-closure : Q → DecSubset Q
  ε-closure q = λ q' → Reachable? q' (n-step (length It) (step q (zero , refl) ∷ []))
  
  ⊢ε-decider : List Q → Q → Σ → DecSubset Q
  ⊢ε-decider []       q a = ø
  ⊢ε-decider (p ∷ ps) q a = λ q' → (p ∈ᵈ ε-closure q ∧ q' ∈ᵈ δ p (α a)) ∨ q' ∈ᵈ ⊢ε-decider ps q a

  infix 7 _⊢ε_─_
  _⊢ε_─_ : Q → Σ → Q → Bool
  q ⊢ε a ─ q' = ⊢ε-decider It q a q'
      
  ⊢εF-decider : List Q → DecSubset Q
  ⊢εF-decider []       = ø
  ⊢εF-decider (p ∷ ps) = λ q → (p ∈ᵈ ε-closure q ∧ p ∈ᵈ F) ∨ q ∈ᵈ ⊢εF-decider ps

  infix 7 _⊢εF
  _⊢εF : DecSubset Q
  q ⊢εF = q ∈ᵈ ⊢εF-decider It


  {- below are the proofs of ⊢ᵏ ⇔ ⊢ᵏ₂ -}
  find-p : ∀ q wᵉ n q' wᵉ'
           → (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ')
           → Q
  find-p q ._ zero    .p  .uᵉ  (p , a , uᵉ , refl , prf₁ , (refl , refl)) = q
  find-p q ._ (suc n)  q'  wᵉ' (p , a , uᵉ , refl , prf₁ , prf₂)          = find-p p uᵉ n q' wᵉ' prf₂
  
  find-a : ∀ q wᵉ n q' wᵉ'
           → (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ')
           → Σᵉ
  find-a q ._ zero    .p  .uᵉ  (p , aᵉ , uᵉ , refl , prf₁ , (refl , refl)) = aᵉ
  find-a q ._ (suc n)  q'  wᵉ' (p , aᵉ , uᵉ , refl , prf₁ , prf₂)          = find-a p uᵉ n q' wᵉ' prf₂
  
  ⊢ᵏ₂-lem₈ : ∀ q wᵉ n q' wᵉ'
             → (prf : (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ'))
             → Σ[ p ∈ Q ] Σ[ a ∈ Σᵉ ] ( p ≡ find-p q wᵉ n q' wᵉ' prf × a ≡ find-a q wᵉ n q' wᵉ' prf × (p , a , wᵉ') ⊢ (q' , wᵉ') )
  ⊢ᵏ₂-lem₈ q ._ zero    .p  .uᵉ  (p , a , uᵉ , refl , prf₁ , (refl , refl)) = q , a , refl , refl , prf₁
  ⊢ᵏ₂-lem₈ q ._ (suc n)  q'  wᵉ' (p , a , uᵉ , refl , prf₁ , prf₂)          = ⊢ᵏ₂-lem₈ p uᵉ n q' wᵉ' prf₂
  
  ⊢ᵏ₂-lem₇ : ∀ q wᵉ n q' wᵉ' p a
             → (prf : (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ'))
             → p ≡ find-p q wᵉ n q' wᵉ' prf
             → a ≡ find-a q wᵉ n q' wᵉ' prf
             → (q , wᵉ) ⊢ᵏ n ─ (p , a ∷ wᵉ')
  ⊢ᵏ₂-lem₇ q ._ zero    .p' .uᵉ  p a (p' , a' , uᵉ , refl , prf₁ , (refl , refl)) p≡q a≡a'
    = sym p≡q , cong (λ a → a ∷ uᵉ) (sym a≡a')
  ⊢ᵏ₂-lem₇ q ._ (suc n)  q'  wᵉ' p a (p' , a' , uᵉ , refl , prf₁ ,          prf₂) p≡p a≡a
    = p' , a' , uᵉ , refl , prf₁ , ⊢ᵏ₂-lem₇ p' uᵉ n q' wᵉ' p a prf₂ p≡p a≡a
  
  ⊢ᵏ₂-lem₆ : ∀ q wᵉ n q' wᵉ'
             → (prf : (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ'))
             → Σ[ p ∈ Q ] Σ[ a ∈ Σᵉ ] ( p ≡ find-p q wᵉ n q' wᵉ' prf × a ≡ find-a q wᵉ n q' wᵉ' prf × (q , wᵉ) ⊢ᵏ n ─ (p , a ∷ wᵉ') )
  ⊢ᵏ₂-lem₆ q wᵉ n q' wᵉ' prf = p , a , refl , refl , ⊢ᵏ₂-lem₇ q wᵉ n q' wᵉ' p a prf refl refl
    where
      p : Q
      p = find-p q wᵉ n q' wᵉ' prf
      a : Σᵉ
      a = find-a q wᵉ n q' wᵉ' prf
  
  ⊢ᵏ₂-lem₅ : ∀ q wᵉ n q' wᵉ'
             → (prf : (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ'))
             → Σ[ p ∈ Q ] Σ[ a ∈ Σᵉ ] (p ≡ find-p q wᵉ n q' wᵉ' prf × a ≡ find-a q wᵉ n q' wᵉ' prf × (q , wᵉ) ⊢ᵏ n ─ (p , a ∷ wᵉ') × (p , a , wᵉ') ⊢ (q' , wᵉ'))
  ⊢ᵏ₂-lem₅ q wᵉ n q' wᵉ' prf with ⊢ᵏ₂-lem₆ q wᵉ n q' wᵉ' prf | ⊢ᵏ₂-lem₈ q wᵉ n q' wᵉ' prf
  ... | p₁ , a₁ , p₁≡p , a₁≡a , prf₁ |  p₂ , a₂ , p₂≡p , a₂≡a , prf₂ = p₁ , a₁ , p₁≡p , a₁≡a , prf₁ , prf₂''
    where
      prf₂' : (p₁ , a₂ , wᵉ') ⊢ (q' , wᵉ')
      prf₂' = subst (λ p₁ → (p₁ , a₂ , wᵉ') ⊢ (q' , wᵉ')) (trans p₂≡p (sym p₁≡p)) prf₂
      prf₂'' : (p₁ , a₁ , wᵉ') ⊢ (q' , wᵉ')
      prf₂'' = subst (λ a₁ → (p₁ , a₁ , wᵉ') ⊢ (q' , wᵉ')) (trans a₂≡a (sym a₁≡a)) prf₂'

  ⊢ᵏ₂-lem₄ : ∀ q wᵉ n q' wᵉ'
             → (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ')
             → (q , wᵉ) ⊢ᵏ₂ suc n ─ (q' , wᵉ')
  ⊢ᵏ₂-lem₄ q wᵉ n q' wᵉ' prf with ⊢ᵏ₂-lem₅ q wᵉ n q' wᵉ' prf
  ... | p' , a' , p≡p' , a≡a' , prf₁ = p , a , prf₁''
    where
      p : Q
      p = find-p q wᵉ n q' wᵉ' prf
      a : Σᵉ
      a = find-a q wᵉ n q' wᵉ' prf
      prf₁' : (q , wᵉ) ⊢ᵏ n ─ (p , a' ∷ wᵉ') × (p , a' , wᵉ') ⊢ (q' , wᵉ')
      prf₁' = subst (λ p → (q , wᵉ) ⊢ᵏ n ─ (p , a' ∷ wᵉ') × (p , a' , wᵉ') ⊢ (q' , wᵉ')) p≡p' prf₁
      prf₁'' : (q , wᵉ) ⊢ᵏ n ─ (p , a ∷ wᵉ') × (p , a , wᵉ') ⊢ (q' , wᵉ')
      prf₁'' = subst (λ a → (q , wᵉ) ⊢ᵏ n ─ (p , a ∷ wᵉ') × (p , a , wᵉ') ⊢ (q' , wᵉ')) a≡a' prf₁'

  ⊢ᵏ₂-lem₉ : ∀ {q wᵉ n p a q' wᵉ'}
             → (q , wᵉ) ⊢ᵏ n ─ (p , a ∷ wᵉ')
             → (p , a , wᵉ') ⊢ (q' , wᵉ')
             → (q , wᵉ) ⊢ᵏ suc n ─ (q' , wᵉ')
  ⊢ᵏ₂-lem₉ {.p} {._} {zero}  {p} {a} {q'} {wᵉ'} (refl , refl) prf = q' , a , wᵉ' , refl , prf , (refl , refl)
  ⊢ᵏ₂-lem₉ {q}  {._} {suc n} {p} {a} {q'} {wᵉ'} (p₁ , a₁ , u₁ , refl , prf₁ , prf₂) prf₃ = p₁ , a₁ , u₁ , refl , prf₁ , ⊢ᵏ₂-lem₉ {p₁} {u₁} {n} {p} {a} {q'} {wᵉ'} prf₂ prf₃
  
  ⊢ᵏ₂-lem₃ : ∀ {q wᵉ n q' wᵉ'}
             → (q , wᵉ) ⊢ᵏ₂ n ─ (q' , wᵉ')
             → (q , wᵉ) ⊢ᵏ n ─ (q' , wᵉ')
  ⊢ᵏ₂-lem₃ {q} {wᵉ} {zero}  {.q} {.wᵉ} (refl , refl) = refl , refl
  ⊢ᵏ₂-lem₃ {q} {wᵉ} {suc n} {q'} {wᵉ'} (p , a , prf₁ , prf₂) = ⊢ᵏ₂-lem₉ {q} {wᵉ} {n} {p} {a} {q'} {wᵉ'} prf₁ prf₂

  ⊢ᵏ₂-lem₂ : ∀ {q wᵉ n q' wᵉ'}
             → (q , wᵉ) ⊢ᵏ n ─ (q' , wᵉ')
             → (q , wᵉ) ⊢ᵏ₂ n ─ (q' , wᵉ')
  ⊢ᵏ₂-lem₂ {q} {wᵉ} {zero}  {.q} {.wᵉ} (refl , refl) = refl , refl
  ⊢ᵏ₂-lem₂ {q} {wᵉ} {suc n} {q'} {wᵉ'} prf           = ⊢ᵏ₂-lem₄ q wᵉ n q' wᵉ' prf

  ⊢ᵏ₂-lem₁ : ∀ {q wᵉ n q' wᵉ'}
             → (q , wᵉ) ⊢ᵏ n ─ (q' , wᵉ') ⇔ (q , wᵉ) ⊢ᵏ₂ n ─ (q' , wᵉ')
  ⊢ᵏ₂-lem₁ {q} {wᵉ} {n} {q'} {wᵉ'} = ⊢ᵏ₂-lem₂ {q} {wᵉ} {n} {q'} {wᵉ'} , ⊢ᵏ₂-lem₃ {q} {wᵉ} {n} {q'} {wᵉ'}
  {- above are the proofs of ⊢ᵏ ⇔ ⊢ᵏ₂ -}

  {- below are the proofs of ⊢* ⇔ ⊢*₂ -}
  ⊢*-lem₄ : ∀ q wᵉ n p uᵉ m q' wᵉ'
            → (q , wᵉ) ⊢ᵏ n ─ (p , uᵉ)
            → (p , uᵉ) ⊢ᵏ m ─ (q' , wᵉ')
            → (q , wᵉ) ⊢ᵏ n + m ─ (q' , wᵉ')
  ⊢*-lem₄ .p wᵉ zero     p .wᵉ m q'  wᵉ' (refl , refl) prf
    = prf
  ⊢*-lem₄  q wᵉ (suc n)  p  uᵉ m q'  wᵉ' (r , a , vᵉ , prf₁ , prf₂ , prf₃) prf₄
    = r , a , vᵉ , prf₁ , prf₂ , ⊢*-lem₄ r vᵉ n p uᵉ m q' wᵉ' prf₃ prf₄

  ⊢*-lem₃ : ∀ {q wᵉ q' wᵉ'}
            → (q , wᵉ) ⊢*  (q' , wᵉ')
            → (q , wᵉ) ⊢*₂ (q' , wᵉ')
  ⊢*-lem₃ {q} {wᵉ} {q'} {wᵉ'} (n , prf)
    = n , zero , q' , wᵉ' , prf , (refl , refl)
  
  ⊢*-lem₂ : ∀ {q wᵉ q' wᵉ'}
            → (q , wᵉ) ⊢*₂ (q' , wᵉ')
            → (q , wᵉ) ⊢*  (q' , wᵉ')
  ⊢*-lem₂ {q} {wᵉ} {q'} {wᵉ'} (n , m , p , uᵉ , prf₁ , prf₂)
    = n + m , ⊢*-lem₄ q wᵉ n p uᵉ m q' wᵉ' prf₁ prf₂
  
  ⊢*-lem₁ : ∀ {q wᵉ q' wᵉ'}
            → (q , wᵉ) ⊢* (q' , wᵉ') ⇔ (q , wᵉ) ⊢*₂ (q' , wᵉ')
  ⊢*-lem₁ = ⊢*-lem₃ , ⊢*-lem₂
  {- above are the proofs of ⊢* ⇔ ⊢*₂ -}
  
-- Language denoted by a ε-NFA
-- section 2.2.3: Finite Automata
-- L(nfa) = { w | ∃wᵉ∈Σᵉ*. w ≡ toΣ* wᵉ ∧ ∃q∈F. (q₀ , wᵉ) ⊢* (q , []) }
Lᵉᴺ : ε-NFA → Language
Lᵉᴺ nfa = λ w → Σ[ wᵉ ∈ Σᵉ* ] (w ≡ toΣ* wᵉ × Σ[ q ∈ Q ] (q ∈ᵍ F × (q₀ , wᵉ) ⊢* (q , [])))
  where
    open ε-NFA nfa
    open ε-NFA-Operations nfa
  


-- Nondeterministic finite automata w/o ε-step
-- section 2.2.3: Finite Automata
record NFA : Set₁ where
  field
    Q  : Set
    Q? : DecEq Q
    δ  : Q → Σ → DecSubset Q
    q₀ : Q
    F  : DecSubset Q
    It : List Q

module NFA-Operations (N : NFA) where
  open NFA N

  -- a move from (q , aw) to (q' , w)
  infix 7 _⊢_
  _⊢_ : (Q × Σ × Σ*) → (Q × Σ*) → Set
  (q , a , w) ⊢ (q' , w') = w ≡ w' × q' ∈ᵍ δ q a
  
  -- k moves from (q , w) to (q' , w')
  infix 7 _⊢ᵏ_─_
  _⊢ᵏ_─_ : (Q × Σ*) → ℕ → (Q × Σ*) → Set
  (q , w) ⊢ᵏ zero    ─ (q' , w')
    = q ≡ q' × w ≡ w'
  (q , w) ⊢ᵏ (suc n) ─ (q' , w')
    = Σ[ p ∈ Q ] Σ[ a ∈ Σ ] Σ[ u ∈ Σ* ]
      (w ≡ a ∷ u × (q , a , u) ⊢ (p , u) × (p , u) ⊢ᵏ n ─ (q' , w'))
                                  
  -- transitive closure of ⊢
  infix 7 _⊢*_
  _⊢*_ : (Q × Σ*) → (Q × Σ*) → Set
  (q , w) ⊢* (q' , w') = Σ[ n ∈ ℕ ] (q , w) ⊢ᵏ n ─ (q' , w')
  
  
-- Language denoted by a NFA
-- section 2.2.3: Finite Automata
Lᴺ : NFA → Language
Lᴺ nfa = λ w → Σ[ q ∈ Q ] (q ∈ᵍ F × (q₀ , w) ⊢* (q , []))
  where
    open NFA nfa
    open NFA-Operations nfa



-- Deterministic finite automata
-- section 2.2.3: Finite Automata
record DFA : Set₁ where
  field
    Q  : Set
    δ  : Q → Σ → Q
    q₀ : Q
    F  : DecSubset Q
  
module DFA-Operations (D : DFA) where
  open DFA D

  δ* : Q → Σ* → Q
  δ* q []      = q
  δ* q (a ∷ w) = δ* (δ q a) w
  
  δ₀ : Σ* → Q
  δ₀ w = δ* q₀ w

  lem₁ : ∀ q w u → δ* q (w ++ u) ≡ δ* (δ* q w) u
  lem₁ q []      u = refl
  lem₁ q (a ∷ w) u = lem₁ (δ q a) w u
  

-- Language denoted by a DFA
Lᴰ : DFA → Language
Lᴰ dfa = λ w → δ₀ w ∈ᵍ F
  where
    open DFA dfa
    open DFA-Operations dfa


{- ∀dfa∈DFA. L(dfa) is decidable -}
Dec-Lᴰ : ∀ dfa → Decidable (Lᴰ dfa)
Dec-Lᴰ dfa w with (δ₀ w) ∈ᵈ F
 where
  open DFA dfa
  open DFA-Operations dfa
... | true  = yes refl
... | false = no (λ ())
