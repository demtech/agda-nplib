module Data.List.Properties.NP where

open import Type hiding (★)
open import Data.List.Properties public
open import Data.List
open import Data.Nat
import Relation.Binary.PropositionalEquality.NP as ≡
open ≡ using (_≡_;_≢_;_with-≡_)

replicate-++ : ∀ {a} {A : ★ a} {x : A} m n → replicate m x ++ replicate n x ≡ replicate (m + n) x
replicate-++ zero     _  = ≡.refl
replicate-++ (suc m)  n  = ≡.cong₂ _∷_ ≡.refl (replicate-++ m n)

++-assoc : ∀ {a} {A : ★ a} (xs ys zs : List A) → (xs ++ ys) ++ zs ≡ xs ++ (ys ++ zs)
++-assoc []       _  _                             = ≡.refl
++-assoc (x ∷ xs) ys zs rewrite ++-assoc xs ys zs  = ≡.refl
