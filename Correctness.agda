{-
  This module contains the following proofs:
    ∀e∈RegExp.  L(e)   = L(regexToε-NFA e)
    ∀nfa∈ε-NFA. L(nfa) = L(remove-ε-step nfa)
    ∀nfa∈NFA.   L(nfa) = L(powerset-construction dfa)
    ∀dfa∈DFA.   L(dfa) = L(minimise dfa)

    ∀e∈RegExp.  L(e)   = L(regexToMDFA e)

  Steven Cheung
  Version 15-03-2016
-}
open import Util
module Correctness (Σ : Set)(dec : DecEq Σ) where

open import Function
open import Data.Product hiding (Σ)

open import Subset
open import RegularExpression Σ dec
open import eNFA Σ dec
open import NFA Σ dec
open import DFA Σ dec
open import Translation Σ dec

{- ∀e∈RegExp. L(e) = L(regexToε-NFA e) -}
Lᴿ≈Lᵉᴺ : ∀ e → Lᴿ e ≈ Lᵉᴺ (regexToε-NFA e)
Lᴿ≈Lᵉᴺ e = Lᴿ⊆Lᵉᴺ e , Lᴿ⊇Lᵉᴺ e
  where
    open import Correctness.RegExpToe-NFA Σ dec


{- ∀nfa∈ε-NFA. L(nfa) = L(remove-ε-step nfa) -}
Lᵉᴺ≈Lᴺ : ∀ nfa → Lᵉᴺ nfa ≈ Lᴺ (remove-ε-step nfa)
Lᵉᴺ≈Lᴺ nfa = Lᵉᴺ⊆Lᴺ nfa , Lᵉᴺ⊇Lᴺ nfa
  where
    open import Correctness.e-NFAtoNFA Σ dec


{- ∀nfa∈NFA. L(nfa) = L(powerset-construction dfa) -}
Lᴺ≈Lᴰ : ∀ nfa → Lᴺ nfa ≈ Lᴰ (powerset-construction nfa)
Lᴺ≈Lᴰ nfa = Lᴺ⊆Lᴰ nfa , Lᴺ⊇Lᴰ nfa
  where
    open import Correctness.NFAtoDFA Σ dec


{- ∀dfa∈DFA.   L(dfa) = L(minimise dfa) -}
Lᴰ≈Lᴹ : ∀ dfa → Lᴰ dfa ≈ Lᴰ ((proj₁ ∘ minimise) dfa)
Lᴰ≈Lᴹ = Minimise.Lᴰ≈Lᴹ
  where
    open import Correctness.DFAtoMDFA Σ dec


{- ∀e∈RegExp.  L(e)   = L(regexToMDFA e) -}
Lᴿ≈Lᴹ : ∀ e → Lᴿ e ≈ Lᴰ (regexToMDFA e)
Lᴿ≈Lᴹ e = ≈-trans (Lᴿ≈Lᵉᴺ e) (≈-trans (Lᵉᴺ≈Lᴺ ε-nfa) (≈-trans (Lᴺ≈Lᴰ nfa) (Lᴰ≈Lᴹ dfa)))
  where
    ε-nfa : ε-NFA
    ε-nfa = regexToε-NFA e
    nfa : NFA
    nfa = remove-ε-step ε-nfa
    dfa : DFA
    dfa = powerset-construction nfa
    mdfa : DFA
    mdfa = (proj₁ ∘ minimise) dfa
