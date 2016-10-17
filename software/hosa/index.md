---
title: HOSA: Sized-type inference for higher-order functional programs
---


HoSA performs inference of sized-types for higher-order functional programs,
as explained in our paper.


# Installation
## Download
HoSA is open source and can be downloaded from its [github page](https://github.com/mzini/hosa/tree/polymorph).

## Requirements
HoSA is implemented in [Haskell](https://www.haskell.org/) and relies on a recent version of the
[Glasgow Haskell Compiler](https://www.haskell.org/ghc/). 

## Install
The easiest way to install HoSA is via [stack](https://docs.haskellstack.org/en/stable/README/).
To instal HoSA via stack, navigate to the source distribution folder in a terminal and type:

~~~~~~~
stack install
~~~~~~~

This will install HoSA together with all its requirements.


# Usage
HoSA is invoked by the command line by

~~~~~~~
hosa <file>
~~~~~~~

where <file> is the functional program that should be analysed.
For additional command line flags, type

~~~~~~~
hosa --help
~~~~~~~

In particular the flag `-a time` allows to switch on runtime complexity analysis
via code-ticking.
HoSA is still under development and features currently just a very rudimentary
parser for higher-order programs, see the
[example folder](https://github.com/mzini/hosa/tree/polymorph/examples)
for the syntax of input programs.

## An Example

~~~~~~~
$ cat examples/product.atrs 
foldr f b [] = b;
foldr f b (l : ls) = f l (foldr f b ls);

lam1 n m l = (n,m) : l;
lam2 ms n l = foldr (lam1 n) l ms;
product ns ms = foldr (lam2 ms) [] ns;

$ hosa examples/product.atrs
Input program:
  foldr :: (β -> α -> α) -> α -> L(β) -> α
  foldr f b ((:) l ls) = f l (foldr f b ls)
  foldr f b [] = b
  
  lam1 :: β -> α -> L((β,α)) -> L((β,α))
  lam1 n m l = (:) (n,m) l
  
  lam2 :: L(α) -> β -> L((β,α)) -> L((β,α))
  lam2 ms n l = foldr (lam1 n) l ms
  
  product :: L(β) -> L(α) -> L((β,α))
  product ns ms = foldr (lam2 ms) [] ns
  
  where
    (:) :: α -> L(α) -> L(α)
    [] :: L(α)

Calling-context annotated program:
  foldr :: (γ -> L((β,α)) -> L((β,α))) -> L((β,α)) -> L(γ) -> L((β,α))
  foldr f b ((:) l ls) = f l (foldr f b ls)
  foldr f b [] = b
  
  lam1 :: β -> α -> L((β,α)) -> L((β,α))
  lam1 n m l = (:) (n,m) l
  
  lam2 :: L(α) -> β -> L((β,α)) -> L((β,α))
  lam2 ms n l = foldr (lam1 n) l ms
  
  product :: L(β) -> L(α) -> L((β,α))
  product ns ms = foldr (lam2 ms) [] ns
  
  where
    (:) :: α -> L(α) -> L(α)
    [] :: L(α)

Sized-type annotated program:
  foldr :: ∀ x2 x3 x4.(∀ x1.α -> L[x1]((β,γ)) -> L[x1+x2]((β,γ))) -> L[x3]((β,γ)) -> L[x4](α) -> L[x2*x4+x3]((β,γ))
  foldr f b ((:) l ls) = f l (foldr f b ls)
  foldr f b [] = b
  
  lam1 :: ∀ x1.α -> β -> L[x1]((α,β)) -> L[1+x1]((α,β))
  lam1 n m l = (:) (n,m) l
  
  lam2 :: ∀ x1 x2.L[x1](α) -> β -> L[x2]((β,α)) -> L[x1+x2]((β,α))
  lam2 ms n l = foldr (lam1 n) l ms
  
  product :: ∀ x1 x2.L[x1](α) -> L[x2](β) -> L[1+x1*x2]((α,β))
  product ns ms = foldr (lam2 ms) [] ns
  
  where
    (:) :: ∀ x1.α -> L[x1](α) -> L[1+x1](α)
    [] :: L[1](α)
~~~~~~~

What is happening here:

  * As a first step, HoSA performs standard Hindley Milner type inference on the supplied program.

  * HoSA then specialises the types of functions to specific call-sites, resulting in a
    /calling-context annotated program/. This enables the size annotation of polymorphic
    arguments. E.g., above the most general type of 'foldr' has been refined

    to

    ~~~~~~~
    (γ -> L((β,α)) -> L((β,α))) -> L((β,α)) -> L(γ) -> L((β,α))
    ~~~~~~~

    In the presence of multiple calls to the same function, HoSA collects the specialised
    types of each call site and computes a suitable specialisation via anti-unification.
    HoSA can also specialise function calls itself, e.g., when the type obtained this way is
    still too general. This behaviour is controlled with the flag `-c <num>` where `<num>` gives
    the depth of the specialisation.

  * Finally, on the resulting program sized-type inference is performed. 
