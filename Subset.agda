{-
  This module contains the definition of Subset and its operations.

  Steven Cheung 2015.
  Version 9-12-2015
-}

module Subset where

open import Util
open import Level
open import Data.Bool hiding (_≟_)
open import Relation.Nullary
open import Relation.Binary.PropositionalEquality
open import Data.Sum
open import Data.Product
open import Data.Empty

-- General Subset
Subset : ∀ {α} → Set α → {ℓ : Level} → Set (α ⊔ suc ℓ)
Subset A {ℓ} = A → Set ℓ

-- Empty set
Ø : ∀ {α}{A : Set α} → Subset A
Ø = λ _ → ⊥

-- Singleton
⟦_⟧ : ∀ {α}{A : Set α} → A → Subset A
⟦ a ⟧ = λ b → a ≡ b

-- Membership
infix 10 _∈_
_∈_ : ∀ {α ℓ}{A : Set α} → A → Subset A → Set ℓ
a ∈ p = p a

-- Decidable
Decidable : ∀ {α ℓ}{A : Set α} → Subset A {ℓ} → Set (α ⊔ ℓ)
Decidable as = ∀ a → Dec (a ∈ as)

-- Membership decider
infix 10 _∈?_
_∈?_ : ∀ {α ℓ}{A : Set α} → (a : A) → (as : Subset A {ℓ}) → {{dec : Decidable as}} → Dec (a ∈ as)
(a ∈? as) {{dec}} = dec a

decidableToBool : ∀ {α ℓ}{A : Set α}{as : Subset A {ℓ}} → Decidable as → A → Bool
decidableToBool dec a with dec a
decidableToBool dec a | yes a∈p = true
decidableToBool dec a | no  a∉p = false


{- Here we define the operations on set -}

-- Intersection
infix 11 _⋂_
_⋂_ : ∀ {α β ℓ}{A : Set α} → Subset A {β} → Subset A {ℓ} → Subset A {β ⊔ ℓ}
as ⋂ bs = λ a → a ∈ as × a ∈ bs

-- Union
infix 11 _⋃_
_⋃_ : ∀ {α β ℓ}{A : Set α} → Subset A {β} → Subset A {ℓ} → Subset A {β ⊔ ℓ}
as ⋃ bs = λ a → a ∈ as ⊎ a ∈ bs

-- Subset
infix 10 _⊆_
_⊆_ : ∀ {α β ℓ}{A : Set α} → Subset A {β} → Subset A {ℓ} → Set (α ⊔ β ⊔ ℓ)
as ⊆ bs = ∀ a → a ∈ as → a ∈ bs

-- Superset
infix 10 _⊇_
_⊇_ : ∀ {α β ℓ}{A : Set α} → Subset A {β} → Subset A {ℓ} → Set (α ⊔ β ⊔ ℓ)
as ⊇ bs = bs ⊆ as

-- Equality
infix 0 _≈_
_≈_ : ∀ {α β ℓ}{A : Set α} → Subset A {β} → Subset A {ℓ} → Set (α ⊔ β ⊔ ℓ)
as ≈ bs = (as ⊆ bs) × (as ⊇ bs)

-- Reflexivity of ≈
≈-refl : ∀ {α ℓ}{A : Set α}{as : Subset A {ℓ}} → as ≈ as
≈-refl = (λ a a∈as → a∈as) , (λ a a∈as → a∈as)

-- Symmetry of ≈
≈-sym : ∀ {α β ℓ}{A : Set α}{as : Subset A {β}}{bs : Subset A {ℓ}} → as ≈ bs → bs ≈ as
≈-sym (as⊆bs , as⊇bs) = as⊇bs , as⊆bs

-- Transitivity of ≈
≈-trans : ∀ {α β γ ℓ}{A : Set α}{as : Subset A {β}}{bs : Subset A {ℓ}}{cs : Subset A {γ}} → as ≈ bs → bs ≈ cs → as ≈ cs
≈-trans (as⊆bs , as⊇bs) (bs⊆cs , bs⊇cs) = (λ a a∈as → bs⊆cs a (as⊆bs a a∈as)) , (λ a a∈cs → as⊇bs a (bs⊇cs a a∈cs))

-- Equality and decidability
Decidable-lem₁ : ∀ {α β ℓ}{A : Set α}{as : Subset A {β}}{bs : Subset A {ℓ}} → as ≈ bs → Decidable as → Decidable bs
Decidable-lem₁ (as⊆bs , as⊇bs) dec a with dec a
... | yes a∈as = yes (as⊆bs a a∈as)
... | no  a∉as = no  (λ a∈bs → a∉as (as⊇bs a a∈bs))



open import Data.List
open import Data.Bool
-- List representation
toList : ∀ {α ℓ}{A : Set α} → (as : Subset A {ℓ}) → Decidable as → List A → List A
toList as dec []       = []
toList as dec (x ∷ xs) with dec x
... | yes _ = x ∷ toList as dec xs
... | no  _ = toList as dec xs
