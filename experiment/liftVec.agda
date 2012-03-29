open import Data.Nat using (ℕ ; suc ; zero)
open import Data.Fin using (Fin)
open import Data.Vec
open import Relation.Binary.PropositionalEquality

module liftVec where 
module single (A : Set)(_+_ : A -> A -> A)where

  data Tm : Set where
    var : Tm
    cst : A -> Tm
    fun : Tm -> Tm -> Tm

  eval : Tm -> A -> A
  eval var x = x
  eval (cst c) x = c
  eval (fun tm tm') x = eval tm x + eval tm' x 
  
  veval : {m : ℕ} -> Tm -> Vec A m -> Vec A m 
  veval var xs = xs
  veval (cst x) xs = replicate x
  veval (fun tm tm') xs = zipWith _+_ (veval tm xs) (veval tm' xs)

  record Fm : Set where
    constructor _=='_
    field
      lhs : Tm
      rhs : Tm

  s[_] : Fm -> Set
  s[ lhs ==' rhs ] = (x : A) → eval lhs x ≡ eval rhs x
  
  v[_] : Fm -> Set
  v[ lhs ==' rhs ] = {m : ℕ}(xs : Vec A m) → veval lhs xs ≡ veval rhs xs

  lemma1 : (t : Tm) -> veval t [] ≡ []
  lemma1 var = refl
  lemma1 (cst x) = refl
  lemma1 (fun t t') rewrite lemma1 t | lemma1 t' = refl

  lemma2 : {m : ℕ}(x : A)(xs : Vec A m)(t : Tm) -> veval t (x ∷ xs) ≡ eval t x ∷ veval t xs
  lemma2 _ _ var = refl
  lemma2 _ _ (cst c) = refl
  lemma2 x xs (fun t t') rewrite lemma2 x xs t | lemma2 x xs t' = refl

  prf : (t : Fm) → s[ t ] → v[ t ]
  prf (lhs ==' rhs) pr [] rewrite lemma1 lhs | lemma1 rhs = refl
  prf (l ==' r) pr (x ∷ xs) rewrite lemma2 x xs l | lemma2 x xs r = cong₂ (_∷_) (pr x) (prf (l ==' r) pr xs)

module multi {nrVar : ℕ}(A : Set)(_+_ : A -> A -> A) where

  sEnv : Set
  sEnv = Vec A nrVar

  vEnv : ℕ -> Set
  vEnv m = Vec (Vec A m) nrVar

  Var : Set
  Var = Fin nrVar

  _!_ : {X : Set} -> Vec X nrVar -> Var -> X
  E ! v = lookup v E

  data Tm : Set where
    var : Fin nrVar -> Tm
    cst : A -> Tm
    fun : Tm -> Tm -> Tm

  eval : Tm -> sEnv -> A
  eval (var x) G = G ! x
  eval (cst c) G = c
  eval (fun t t') G = eval t G + eval t' G 

  veval : {m : ℕ} -> Tm -> vEnv m -> Vec A m
  veval (var x) G = G ! x
  veval (cst c) G = replicate c
  veval (fun t t') G = zipWith _+_ (veval t G) (veval t' G)

  lemma1 : {xs : Vec (Vec A 0) nrVar} (t : Tm) -> veval t xs ≡ []
  lemma1 {xs} (var x) with xs ! x
  ... | [] = refl
  lemma1 (cst x) = refl
  lemma1 {xs} (fun t t') rewrite lemma1 {xs} t | lemma1 {xs} t' = refl

  lemVar : {m n : ℕ}(G : Vec (Vec A (suc m)) n)(i : Fin n) -> lookup i G ≡ lookup i (map head G) ∷ lookup i (map tail G)
  lemVar [] ()
  lemVar ((x ∷ G) ∷ G₁) Data.Fin.zero = refl
  lemVar (G ∷ G') (Data.Fin.suc i) = lemVar G' i

  lemma2 : {n : ℕ}(xs : vEnv (suc n))(t : Tm) -> veval t xs ≡ eval t (map head xs) ∷ veval t (map tail xs)
  lemma2 G (var x) = lemVar G x 
  lemma2 _ (cst x) = refl
  lemma2 G (fun t t') rewrite lemma2 G t | lemma2 G t' = refl

  s[_==_] : Tm -> Tm -> Set
  s[ l == r ] = (G : Vec A nrVar) -> eval l G ≡ eval r G

  v[_==_] : Tm -> Tm -> Set
  v[ l == r ] = {m : ℕ}(G : Vec (Vec A m) nrVar) -> veval l G ≡ veval r G

  prf : (l r : Tm) -> s[ l == r ] -> v[ l == r ]
  prf l r pr {zero} G rewrite lemma1 {G} l | lemma1 {G} r = refl
  prf l r pr {suc m} G rewrite lemma2 G l | lemma2 G r = cong₂ _∷_ (pr (replicate head ⊛ G)) (prf l r pr (map tail G))

module Forall (A : Set) where

  module N = Data.Nat

  NPred : ℕ -> Set₁
  NPred 0 = Set
  NPred (N.suc n) = A -> NPred n 

  NFun : (n : ℕ) -> NPred n -> Set
  NFun zero P = P
  NFun (suc n) P = (x : A) → NFun n (P x)

  
  NApply : {m n : ℕ} -> Vec A n -> Vec (Fin n) m -> NPred m -> Set 
  NApply xs [] P = P
  NApply xs (x ∷ ys) P = NApply xs ys (P (lookup x xs))


  NVec : {n : ℕ} -> NPred n -> Set
  NVec {n} P = (xs : Vec A n) -> NApply xs (tabulate (\ x -> x)) P

  Build : {n : ℕ}{P : NPred n} -> NFun n P -> NVec P
  Build {n} f xs = go (tabulate (λ x → x)) f where 
    go : {m : ℕ}{P : NPred m}(ys : Vec (Fin n) m)(f : NFun m P) -> NApply xs ys P
    go [] f = f
    go (x ∷ ys) f = go ys (f (lookup x xs)) 

module example where

  open import Data.Bool
  import Data.Bool.Properties
  open Data.Fin

  open import Algebra

  module Xor = CommutativeRing Data.Bool.Properties.commutativeRing-xor-∧ 

  coolTheorem : {m : ℕ} -> (xs ys : Vec Bool m) -> zipWith _xor_ xs ys ≡ zipWith _xor_ ys xs
  coolTheorem xs ys = prf l r (lemma) (xs ∷ (ys ∷ [])) where
    open multi {2} Bool _xor_ 

    open Forall Bool
 
    l = (fun (var zero) (var (suc zero)))
    r =  (fun (var (suc zero)) (var zero))

    Thm : NPred 2
    Thm = λ x y → x xor y ≡ y xor x

    Prf : NFun 2 Thm
    Prf true true = refl
    Prf true false = refl
    Prf false true = refl
    Prf false false = refl

    lem  : NVec Thm
    lem = Build Prf 
 
    lemma : (G : Vec Bool 2) -> lookup zero G xor lookup (suc zero) G
                              ≡ lookup (suc zero) G xor lookup zero G
    lemma (true ∷ true ∷ G) = refl
    lemma (true ∷ false ∷ G) = refl
    lemma (false ∷ true ∷ G) = refl
    lemma (false ∷ false ∷ G) = refl

open import Data.Bool
open Forall Bool
