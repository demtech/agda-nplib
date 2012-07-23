module Data.Bits where

-- cleanup
import Level
open import Category.Applicative
open import Category.Monad
open import Data.Nat.NP hiding (_==_)
open import Data.Nat.Properties
open import Data.Nat.DivMod
open import Data.Bool.NP hiding (_==_)
open import Data.Bool.Properties using (not-involutive)
open import Data.Maybe.NP
import Data.Fin as Fin
open Fin using (Fin; zero; suc; #_; inject₁; inject+; raise) renaming (_+_ to _+ᶠ_)
import Data.Vec.NP as V
open V hiding (_⊛_; rewire; rewireTbl; sum) renaming (map to vmap)
open import Data.Vec.N-ary.NP
open import Data.Unit using (⊤)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Product using (_×_; _,_; uncurry; proj₁; proj₂)
open import Function.NP hiding (_→⟨_⟩_)
import Relation.Binary.PropositionalEquality.NP as ≡
open ≡
open import Algebra.FunctionProperties
import Data.List as L

open import Data.Bool.NP public using (_xor_)
open V public using ([]; _∷_; head; tail; replicate; RewireTbl)

Bit : Set
Bit = Bool

module Defs where
  0b = false
  1b = true
module Patterns where
  pattern 0b = false
  pattern 1b = true
open Patterns

Bits : ℕ → Set
Bits = Vec Bit

_→ᵇ_ : ℕ → ℕ → Set
i →ᵇ o = Bits i → Bits o

0ⁿ : ∀ {n} → Bits n
0ⁿ = replicate 0b

-- Warning: 0ⁿ {0} ≡ 1ⁿ {0}
1ⁿ : ∀ {n} → Bits n
1ⁿ = replicate 1b

0∷_ : ∀ {n} → Bits n → Bits (suc n)
0∷ xs = 0b ∷ xs

-- can't we make these pattern aliases?
1∷_ : ∀ {n} → Bits n → Bits (suc n)
1∷ xs = 1b ∷ xs

_!_ : ∀ {a n} {A : Set a} → Vec A n → Fin n → A
_!_ = flip lookup

_==ᵇ_ : (b₀ b₁ : Bit) → Bool
b₀ ==ᵇ b₁ = not (b₀ xor b₁)

_==_ : ∀ {n} (bs₀ bs₁ : Bits n) → Bool
[] == [] = true
(b₀ ∷ bs₀) == (b₁ ∷ bs₁) = (b₀ ==ᵇ b₁) ∧ bs₀ == bs₁

infixr 5 _⊕_
_⊕_ : ∀ {n} (bs₀ bs₁ : Bits n) → Bits n
_⊕_ = zipWith _xor_

vnot : ∀ {n} → Endo (Bits n)
vnot = _⊕_ 1ⁿ

vnot∘vnot≗id : ∀ {n} → vnot {n} ∘ vnot ≗ id
vnot∘vnot≗id [] = refl
vnot∘vnot≗id (x ∷ xs) rewrite not-involutive x = cong (_∷_ x) (vnot∘vnot≗id xs)

⊕-assoc : ∀ {n} → Associative _≡_ (_⊕_ {n})
⊕-assoc [] [] [] = refl
⊕-assoc (x ∷ xs) (y ∷ ys) (z ∷ zs) rewrite ⊕-assoc xs ys zs | Xor°.+-assoc x y z = refl

⊕-comm  : ∀ {n} → Commutative _≡_ (_⊕_ {n})
⊕-comm [] [] = refl
⊕-comm (x ∷ xs) (y ∷ ys) rewrite ⊕-comm xs ys | Xor°.+-comm x y = refl

⊕-left-identity : ∀ {n} → LeftIdentity _≡_ 0ⁿ (_⊕_ {n})
⊕-left-identity [] = refl
⊕-left-identity (x ∷ xs) rewrite ⊕-left-identity xs = refl

⊕-right-identity : ∀ {n} → RightIdentity _≡_ 0ⁿ (_⊕_ {n})
⊕-right-identity [] = refl
⊕-right-identity (x ∷ xs) rewrite ⊕-right-identity xs | proj₂ Xor°.+-identity x = refl

⊕-≡ : ∀ {n} (x : Bits n) → x ⊕ x ≡ 0ⁿ
⊕-≡ [] = refl
⊕-≡ (x ∷ xs) rewrite ⊕-≡ xs | proj₂ Xor°.-‿inverse x = refl

⊕-≢ : ∀ {n} (x : Bits n) → x ⊕ vnot x ≡ 1ⁿ
⊕-≢ x = x ⊕ vnot x   ≡⟨ refl ⟩
         x ⊕ (1ⁿ ⊕ x) ≡⟨ cong (_⊕_ x) (⊕-comm 1ⁿ x) ⟩
         x ⊕ (x ⊕ 1ⁿ) ≡⟨ sym (⊕-assoc x x 1ⁿ) ⟩
         (x ⊕ x) ⊕ 1ⁿ ≡⟨ cong (flip _⊕_ 1ⁿ) (⊕-≡ x) ⟩
         0ⁿ ⊕ 1ⁿ       ≡⟨ ⊕-left-identity 1ⁿ ⟩
         1ⁿ ∎ where open ≡-Reasoning

msb : ∀ k {n} → Bits (k + n) → Bits k
msb = take

lsb : ∀ {n} k → Bits (n + k) → Bits k
lsb {n} k rewrite ℕ°.+-comm n k = reverse ∘ msb k ∘ reverse

msb₂ : ∀ {n} → Bits (2 + n) → Bits 2
msb₂ = msb 2

lsb₂ : ∀ {n} → Bits (2 + n) → Bits 2
lsb₂ = reverse ∘ msb 2 ∘ reverse

#1 : ∀ {n} → Bits n → Fin (suc n)
#1 [] = zero
#1 (0b ∷ bs) = inject₁ (#1 bs)
#1 (1b ∷ bs) = suc (#1 bs)

#0 : ∀ {n} → Bits n → Fin (suc n)
#0 = #1 ∘ vmap not

private
 module M {a} {A : Set a} {M : Set a → Set a} (appl : RawApplicative M) where
  open RawApplicative appl

  replicateM : ∀ {n} → M A → M (Vec A n)
  replicateM {n = zero}  _ = pure []
  replicateM {n = suc n} x = pure _∷_ ⊛ x ⊛ replicateM x

open M public

allBitsL : ∀ n → L.List (Bits n)
allBitsL _ = replicateM rawIApplicative (toList (0b ∷ 1b ∷ []))
  where open RawMonad L.monad

allBits : ∀ n → Vec (Bits n) (2^ n)
allBits zero    = [] ∷ []
allBits (suc n) = vmap 0∷_ bs ++ vmap 1∷_ bs
  where bs = allBits n

module Search {i} {I : Set i} (`1 : I) (`2*_ : I → I)
              {a} {A : I → Set a} (_·_ : ∀ {m} → A m → A m → A (`2* m)) where

  `2^_ : ℕ → I
  `2^_ = fold `1 `2*_

  search : ∀ {n} → (Bits n → A `1) → A (`2^ n)
  search {zero}  f = f []
  search {suc n} f = search (f ∘ 0∷_) · search (f ∘ 1∷_)

search′ : ∀ {n a} {A : ℕ → Set a} → (∀ {m} → A m → A m → A (2* m)) → (Bits n → A 1) → A (2^ n)
search′ {n} {a} {A} op f = Search.search 1 2*_ {a} {A} (λ {m} → op {m}) f

search : ∀ {n a} {A : Set a} → (A → A → A) → (Bits n → A) → A
search {n} {a} {A} _·_ f = search′ {n} {a} {const A} _·_ f

#⟨_⟩ᶠ : ∀ {n} → (Bits n → Bool) → Fin (suc (2^ n))
#⟨ pred ⟩ᶠ = countᶠ pred (allBits _)

sum : ∀ {n} → (Bits n → ℕ) → ℕ
sum = search _+_

sum-const : ∀ n x → sum {n} (const x) ≡ ⟨2^ n * x ⟩
sum-const zero    _ = refl
sum-const (suc n) x = cong₂ _+_ (sum-const n x) (sum-const n x)

#⟨_⟩ : ∀ {n} → (Bits n → Bool) → ℕ
#⟨ pred ⟩ = sum (λ x → if pred x then 1 else 0)

#⟨⟩-spec : ∀ {n} (pred : Bits n → Bool) → #⟨ pred ⟩ ≡ Fin.toℕ #⟨ pred ⟩ᶠ
#⟨⟩-spec {zero}  pred with pred []
... | true = refl
... | false = refl
#⟨⟩-spec {suc n} pred rewrite count-++ pred (vmap 0∷_ (allBits n)) (vmap 1∷_ (allBits n))
                            | #⟨⟩-spec {n} (pred ∘ 0∷_)
                            | #⟨⟩-spec {n} (pred ∘ 1∷_)
                            | count-∘ 0∷_ pred (allBits n)
                            | count-∘ 1∷_ pred (allBits n) = refl

ext-# : ∀ {c} {f g : Bits c → Bit} → f ≗ g → #⟨ f ⟩ᶠ ≡ #⟨ g ⟩ᶠ
ext-# f≗g = ext-countᶠ f≗g (allBits _)

find? : ∀ {n a} {A : Set a} → (Bits n →? A) →? A
find? = search (M?._∣_ _)

findB : ∀ {n} → (Bits n → Bool) →? Bits n
findB pred = find? (λ x → if pred x then just x else nothing)

sucBCarry : ∀ {n} → Bits n → Bits (1 + n)
sucBCarry [] = 0b ∷ []
sucBCarry (0b ∷ xs) = 0b ∷ sucBCarry xs
sucBCarry (1b ∷ xs) with sucBCarry xs
... | 0b ∷ bs = 0b ∷ 1b ∷ bs
... | 1b ∷ bs = 1b ∷ 0b ∷ bs

sucB : ∀ {n} → Bits n → Bits n
sucB = tail ∘ sucBCarry

_[mod_] : ℕ → ℕ → Set
a [mod b ] = DivMod' a b

proj : ∀ {a} {A : Set a} → A × A → Bit → A
proj (x₀ , x₁) 0b = x₀
proj (x₀ , x₁) 1b = x₁

rewire : ∀ {i o} → (Fin o → Fin i) → i →ᵇ o
rewire = V.rewire

rewireTbl : ∀ {i o} → RewireTbl i o → i →ᵇ o
rewireTbl = V.rewireTbl

module ReversedBits where
  sucRB : ∀ {n} → Bits n → Bits n
  sucRB [] = []
  sucRB (0b ∷ xs) = 1b ∷ xs
  sucRB (1b ∷ xs) = 0b ∷ sucRB xs

toFin : ∀ {n} → Bits n → Fin (2 ^ n)
toFin         []        = zero
toFin         (0b ∷ xs) = inject+ _ (toFin xs)
toFin {suc n} (1b ∷ xs) = raise (2 ^ n) (inject+ 0 (toFin xs))

{-
toℕ : ∀ {n} → Bits n → ℕ
toℕ = Fin.toℕ ∘ toFin
-}

toℕ : ∀ {n} → Bits n → ℕ
toℕ         []        = zero
toℕ         (0b ∷ xs) = toℕ xs
toℕ {suc n} (1b ∷ xs) = 2 ^ n + toℕ xs

fromℕ : ∀ {n} → ℕ → Bits n
fromℕ = fold 0ⁿ sucB

fromFin : ∀ {n} → Fin (2 ^ n) → Bits n
fromFin = fromℕ ∘ Fin.toℕ

lookupTbl : ∀ {n a} {A : Set a} → Bits n → Vec A (2 ^ n) → A
lookupTbl         []         (x ∷ []) = x
lookupTbl         (0b ∷ key) tbl      = lookupTbl key (take _ tbl)
lookupTbl {suc n} (1b ∷ key) tbl      = lookupTbl key (take (2 ^ n) (drop (2 ^ n) tbl))

funFromTbl : ∀ {n a} {A : Set a} → Vec A (2 ^ n) → (Bits n → A)
funFromTbl = flip lookupTbl

tblFromFun : ∀ {n a} {A : Set a} → (Bits n → A) → Vec A (2 ^ n)
-- tblFromFun f = tabulate (f ∘ fromFin)
tblFromFun {zero} f = f [] ∷ []
tblFromFun {suc n} f = tblFromFun {n} (f ∘ 0∷_) ++ tblFromFun {n} (f ∘ 1∷_) ++ []

funFromTbl∘tblFromFun : ∀ {n a} {A : Set a} (fun : Bits n → A) → funFromTbl (tblFromFun fun) ≗ fun
funFromTbl∘tblFromFun {zero} f [] = refl
funFromTbl∘tblFromFun {suc n} f (0b ∷ xs)
  rewrite take-++ (2 ^ n) (tblFromFun {n} (f ∘ 0∷_)) (tblFromFun {n} (f ∘ 1∷_) ++ []) =
    funFromTbl∘tblFromFun {n} (f ∘ 0∷_) xs
funFromTbl∘tblFromFun {suc n} f (1b ∷ xs)
  rewrite drop-++ (2 ^ n) (tblFromFun {n} (f ∘ 0∷_)) (tblFromFun {n} (f ∘ 1∷_) ++ [])
        | take-++ (2 ^ n) (tblFromFun {n} (f ∘ 1∷_)) [] =
    funFromTbl∘tblFromFun {n} (f ∘ 1∷_) xs

tblFromFun∘funFromTbl : ∀ {n a} {A : Set a} (tbl : Vec A (2 ^ n)) → tblFromFun {n} (funFromTbl tbl) ≡ tbl
tblFromFun∘funFromTbl {zero} (x ∷ []) = refl
tblFromFun∘funFromTbl {suc n} tbl
  rewrite tblFromFun∘funFromTbl {n} (take _ tbl)
        | tblFromFun∘funFromTbl {n} (take (2 ^ n) (drop (2 ^ n) tbl))
        | take-them-all (2 ^ n) (drop (2 ^ n) tbl)
        | take-drop-lem (2 ^ n) tbl
   = refl

{-
sucB-lem : ∀ {n} x → toℕ {2 ^ n} (sucB x) [mod 2 ^ n ] ≡ (suc (toℕ x)) [mod 2 ^ n ]
sucB-lem x = {!!}

-- sucB-lem : ∀ {n} x → (sucB (fromℕ x)) [mod 2 ^ n ] ≡ fromℕ ((suc x) [mod 2 ^ n ])

toℕ∘fromℕ : ∀ {n} x → toℕ (fromℕ {n} x) ≡ x
toℕ∘fromℕ zero = {!!}
toℕ∘fromℕ (suc x) = {!toℕ∘fromℕ x!}

toℕ∘fromFin : ∀ {n} (x : Fin (2 ^ n)) → toℕ (fromFin x) ≡ Fin.toℕ x
toℕ∘fromFin x = {!!}

toFin∘fromFin : ∀ {n} (x : Fin (2 ^ n)) → toFin (fromFin x) ≡ x
toFin∘fromFin x = {!!}

-- _ᴮ : (s : String) {pf : IsBitString s} → Bits (length s)
-- _ᴮ =
-}

always : ∀ n → Bits n → Bit
always _ _ = 1b
never  : ∀ n → Bits n → Bit
never _ _ = 0b

search-·-ε≡ε : ∀ {a} {A : Set a} ε (_·_ : A → A → A)
                 (ε·ε : ε · ε ≡ ε) n → search {n} _·_ (const ε) ≡ ε
search-·-ε≡ε ε _·_ ε·ε = go
  where
    go : ∀ n → search {n} _·_ (const ε) ≡ ε
    go zero = refl
    go (suc n) rewrite go n = ε·ε

#never≡0 : ∀ n → #⟨ never n ⟩ ≡ 0
#never≡0 = search-·-ε≡ε _ _ refl

#always≡2^_ : ∀ n → #⟨ always n ⟩ ≡ 2^ n
#always≡2^_ zero = refl
#always≡2^_ (suc n) = cong₂ _+_ pf pf where pf = #always≡2^ n

==-comm : ∀ {n} (xs ys : Bits n) → xs == ys ≡ ys == xs
==-comm [] [] = refl
==-comm (x ∷ xs) (x₁ ∷ ys) rewrite Xor°.+-comm x x₁ | ==-comm xs ys = refl

countᵇ : Bit → ℕ
countᵇ b = if b then 1 else 0

#⟨==_⟩ : ∀ {n} (xs : Bits n) → #⟨ _==_ xs ⟩ ≡ 1
#⟨== [] ⟩ = refl
#⟨==_⟩ {suc n} (true ∷ xs)  rewrite #never≡0 n | #⟨== xs ⟩ = refl
#⟨==_⟩ {suc n} (false ∷ xs) rewrite #never≡0 n | #⟨== xs ⟩ = refl

≗-cong-search : ∀ {n a} {A : Set a} op {f g : Bits n → A} → f ≗ g → search op f ≡ search op g
≗-cong-search {zero}  op f≗g = f≗g []
≗-cong-search {suc n} op f≗g = cong₂ op (≗-cong-search op (f≗g ∘ 0∷_))
                                        (≗-cong-search op (f≗g ∘ 1∷_))

≗-cong-# : ∀ {n} (f g : Bits n → Bit) → f ≗ g → #⟨ f ⟩ ≡ #⟨ g ⟩
≗-cong-# f g f≗g = ≗-cong-search _+_ (cong countᵇ ∘ f≗g)

#-+ : ∀ {n a b} (f : Bits (suc n) → Bit) → #⟨ f ∘ 0∷_ ⟩ ≡ a → #⟨ f ∘ 1∷_ ⟩ ≡ b → #⟨ f ⟩ ≡ a + b
#-+ f f0 f1 rewrite f0 | f1 = refl

take-∷ : ∀ {m a} {A : Set a} n x (xs : Vec A (n + m)) → take (suc n) (x ∷ xs) ≡ x ∷ take n xs
take-∷ n x xs with splitAt n xs
take-∷ _ _ ._ | _ , _ , refl = refl

drop-∷ : ∀ {m a} {A : Set a} n x (xs : Vec A (n + m)) → drop (suc n) (x ∷ xs) ≡ drop n xs
drop-∷ n x xs with splitAt n xs
drop-∷ _ _ ._ | _ , _ , refl = refl

==-refl : ∀ {n} (xs : Bits n) → (xs == xs) ≡ 1b
==-refl [] = refl
==-refl (true ∷ xs) = ==-refl xs
==-refl (false ∷ xs) = ==-refl xs

_|∨|_ : ∀ {n} → (f g : Bits n → Bit) → Bits n → Bit
_|∨|_ f g x = f x ∨ g x

_|∧|_ : ∀ {n} → (f g : Bits n → Bit) → Bits n → Bit
_|∧|_ f g x = f x ∧ g x

#-take-drop : ∀ m n (f : Bits m → Bit) (g : Bits n → Bit)
                → #⟨ (f ∘ take m) |∧| (g ∘ drop m) ⟩ ≡ #⟨ f ⟩ * #⟨ g ⟩
#-take-drop zero n f g with f []
... | true rewrite ℕ°.+-comm #⟨ g ⟩ 0 = refl
... | false = #never≡0 n
#-take-drop (suc m) n f g = trans (#-+ {a = #⟨ f ∘ 0∷_ ⟩ * #⟨ g ⟩} ((f ∘ take (suc m)) |∧| (g ∘ drop (suc m)))
                                  (trans (≗-cong-# ((f ∘ take (suc m)) |∧| (g ∘ drop (suc m)) ∘ 0∷_)
                                                ((f ∘ 0∷_ ∘ take m) |∧| (g ∘ drop m))
                                                (λ x → cong₂ (λ x y → f x ∧ g y) (take-∷ m 0b x) (drop-∷ m 0b x)))
                                       (#-take-drop m n (f ∘ 0∷_) g))
                                  (trans (≗-cong-# ((f ∘ take (suc m)) |∧| (g ∘ drop (suc m)) ∘ 1∷_)
                                                ((f ∘ 1∷_ ∘ take m) |∧| (g ∘ drop m))
                                                (λ x → cong₂ (λ x y → f x ∧ g y) (take-∷ m 1b x) (drop-∷ m 1b x)))
                                       (#-take-drop m n (f ∘ 1∷_) g)))
                           (sym (proj₂ ℕ°.distrib #⟨ g ⟩ #⟨ f ∘ 0∷_ ⟩ #⟨ f ∘ 1∷_ ⟩))

#-drop-take : ∀ m n (f : Bits n → Bit) (g : Bits m → Bit)
                → #⟨ (f ∘ drop m) |∧| (g ∘ take m) ⟩ ≡ #⟨ f ⟩ * #⟨ g ⟩
#-drop-take m n f g =
           #⟨ (f ∘ drop m) |∧| (g ∘ take m) ⟩
         ≡⟨ ≗-cong-# ((f ∘ drop m) |∧| (g ∘ take m)) ((g ∘ take m) |∧| (f ∘ drop m)) (λ x → Bool°.+-comm (f (drop m x)) _) ⟩
           #⟨ (g ∘ take m) |∧| (f ∘ drop m) ⟩
         ≡⟨ #-take-drop m n g f ⟩
           #⟨ g ⟩ * #⟨ f ⟩
         ≡⟨ ℕ°.*-comm #⟨ g ⟩ _ ⟩
           #⟨ f ⟩ * #⟨ g ⟩
         ∎
  where open ≡-Reasoning

#-take : ∀ m n (f : Bits m → Bit) → #⟨ f ∘ take m {n} ⟩ ≡ 2^ n * #⟨ f ⟩
#-take m n f = #⟨ f ∘ take m {n} ⟩
             ≡⟨ #-drop-take m n (always n) f ⟩
               #⟨ always n ⟩ * #⟨ f ⟩
             ≡⟨ cong (flip _*_ #⟨ f ⟩) (#always≡2^ n) ⟩
               2^ n * #⟨ f ⟩
             ∎
  where open ≡-Reasoning

#-drop : ∀ m n (f : Bits m → Bit) → #⟨ f ∘ drop n ⟩ ≡ 2^ n * #⟨ f ⟩
#-drop m n f = #⟨ f ∘ drop n ⟩
             ≡⟨ #-take-drop n m (always n) f ⟩
               #⟨ always n ⟩ * #⟨ f ⟩
             ≡⟨ cong (flip _*_ #⟨ f ⟩) (#always≡2^ n) ⟩
               2^ n * #⟨ f ⟩
             ∎
  where open ≡-Reasoning

#⟨_==⟩ : ∀ {n} (xs : Bits n) → #⟨ flip _==_ xs ⟩ ≡ 1
#⟨ xs ==⟩ = trans (≗-cong-# (flip _==_ xs) (_==_ xs) (flip ==-comm xs)) #⟨== xs ⟩

#⇒ : ∀ {n} (f g : Bits n → Bit) → (∀ x → T (f x) → T (g x)) → #⟨ f ⟩ ≤ #⟨ g ⟩
#⇒ {zero} f g f⇒g with f [] | g [] | f⇒g []
... | true  | true  | _ = s≤s z≤n
... | true  | false | p = ⊥-elim (p _)
... | false | _     | _ = z≤n
#⇒ {suc n} f g f⇒g = #⇒ (f ∘ 0∷_) (g ∘ 0∷_) (f⇒g ∘ 0∷_)
                +-mono #⇒ (f ∘ 1∷_) (g ∘ 1∷_) (f⇒g ∘ 1∷_)

#-∧-∨ᵇ : ∀ x y → countᵇ (x ∧ y) + countᵇ (x ∨ y) ≡ countᵇ x + countᵇ y
#-∧-∨ᵇ true y rewrite ℕ°.+-comm (countᵇ y) 1 = refl
#-∧-∨ᵇ false y = refl

#-∧-∨ : ∀ {n} (f g : Bits n → Bit) → #⟨ f |∧| g ⟩ + #⟨ f |∨| g ⟩ ≡ #⟨ f ⟩ + #⟨ g ⟩
#-∧-∨ {zero} f g = #-∧-∨ᵇ (f []) (g [])
#-∧-∨ {suc n} f g =
  trans
    (trans
       (helper #⟨ (f ∘ 0∷_) |∧| (g ∘ 0∷_) ⟩
               #⟨ (f ∘ 1∷_) |∧| (g ∘ 1∷_) ⟩
               #⟨ (f ∘ 0∷_) |∨| (g ∘ 0∷_) ⟩
               #⟨ (f ∘ 1∷_) |∨| (g ∘ 1∷_) ⟩)
       (cong₂ _+_ (#-∧-∨ (f ∘ 0∷_) (g ∘ 0∷_))
                  (#-∧-∨ (f ∘ 1∷_) (g ∘ 1∷_))))
    (helper #⟨ f ∘ 0∷_ ⟩ #⟨ g ∘ 0∷_ ⟩ #⟨ f ∘ 1∷_ ⟩ #⟨ g ∘ 1∷_ ⟩)
    where open SemiringSolver
          helper : ∀ x y z t → x + y + (z + t) ≡ x + z + (y + t)
          helper = solve 4 (λ x y z t → x :+ y :+ (z :+ t) := x :+ z :+ (y :+ t)) refl

#∨' : ∀ {n} (f g : Bits n → Bit) → #⟨ f |∨| g ⟩ ≤ #⟨ f ⟩ + #⟨ g ⟩
#∨' {zero} f g with f []
... | true  = s≤s z≤n
... | false = ℕ≤.refl
#∨' {suc _} f g = ℕ≤.trans (#∨' (f ∘ 0∷_) (g ∘ 0∷_) +-mono
                             #∨' (f ∘ 1∷_) (g ∘ 1∷_))
                    (ℕ≤.reflexive
                      (helper #⟨ f ∘ 0∷_ ⟩ #⟨ g ∘ 0∷_ ⟩ #⟨ f ∘ 1∷_ ⟩ #⟨ g ∘ 1∷_ ⟩))
    where open SemiringSolver
          helper : ∀ x y z t → x + y + (z + t) ≡ x + z + (y + t)
          helper = solve 4 (λ x y z t → x :+ y :+ (z :+ t) := x :+ z :+ (y :+ t)) refl

#∨ : ∀ {m n o} {f g : Bits o → Bit} → #⟨ f ⟩ ≤ m → #⟨ g ⟩ ≤ n → #⟨ (λ x → f x ∨ g x) ⟩ ≤ (m + n)
#∨ {m} {n} {o} {f} {g} pf pg = ℕ≤.trans (#∨' f g) (pf +-mono pg)

∧⇒∨ : ∀ x y → T (x ∧ y) → T (x ∨ y)
∧⇒∨ true y = _
∧⇒∨ false y = λ ()

#∧ : ∀ {m n o} {f g : Bits o → Bit} → #⟨ f ⟩ ≤ m → #⟨ g ⟩ ≤ n → #⟨ f |∧| g ⟩ ≤ (m + n)
#∧ {f = f} {g} pf pg = ℕ≤.trans (#⇒ (f |∧| g) (f |∨| g) (λ x → ∧⇒∨ (f x) (g x))) (#∨ {f = f} pf pg)

|de-morgan| : ∀ {n} (f g : Bits n → Bit) → f |∨| g ≗ not ∘ ((not ∘ f) |∧| (not ∘ g))
|de-morgan| f g x with f x
... | true = refl
... | false = sym (not-involutive _)

search-de-morgan : ∀ {n} op (f g : Bits n → Bit) → search op (f |∨| g) ≡ search op (not ∘ ((not ∘ f) |∧| (not ∘ g)))
search-de-morgan op f g = ≗-cong-search op {-(f |∨| g) (not ∘ ((not ∘ f) |∧| (not ∘ g)))-} (|de-morgan| f g)

search-comm :
  ∀ {n a b}
    {A : Set a} {B : Set b}
    (_+_ : A → A → A)
    (_*_ : B → B → B)
    (f : A → B)
    (p : Bits n → A)
    (hom : ∀ x y → f (x + y) ≡ f x * f y)
    → f (search _+_ p) ≡ search _*_ (f ∘ p)
search-comm {zero} _+_ _*_ f p hom = refl
search-comm {suc n} _+_ _*_ f p hom =
   trans (hom _ _)
         (cong₂ _*_ (search-comm {n} _+_ _*_ f (p ∘ 0∷_) hom)
                    (search-comm _+_ _*_ f (p ∘ 1∷_) hom))

[0↔_] : ∀ {n} → Fin n → Bits n → Bits n
[0↔_] {zero}  i xs = xs
[0↔_] {suc n} i xs = lookup i xs ∷ tail (xs [ i ]≔ head xs)

[0↔1] : Bits 2 → Bits 2
[0↔1] = [0↔ suc zero ]

[0↔1]-spec : [0↔1] ≗ (λ { (x ∷ y ∷ []) → y ∷ x ∷ [] })
[0↔1]-spec (x ∷ y ∷ []) = refl

open Defs public
