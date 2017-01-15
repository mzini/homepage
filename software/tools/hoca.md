---
title: Higher Order Complexity Analysis (HOCA)
external: http://cbr.uibk.ac.at/tools/hoca
license: MIT
language: haskell
paper: ADM:ICFP:15
github: ComputationWithBoundedResources/hoca
short: Frontend for analysing the runtime complexity of OCaml programs through first-order tools
oncv: true
---

HOCA is an abbreviation for *Higher-Order Complexity Analysis*,
and is meant as a laboratory for the automated complexity analysis
of higher-order functional programs.
HOCA translates a pure subset of [OCaml](http://caml.inria.fr) to term rewrite systems,
in a complexity reflecting manner. Complexity certificates such as
the ones obtained by first order provers like [TCT](http://cl-informatik.uibk.ac.at/software/tct),
can be relayed (asymptotically) back to the OCaml program.
