---
title: IsaFoR/CeTA
license: GPL
external: http://cl-informatik.uibk.ac.at/software/ceta/
language: haskell
paper: AST:RTA:15
short: A formally verified tool for checking termination, confluence and complexity proofs. I have contributed the formalisation of dependency tuples
oncv: true
---

*CeTA* is a tool that certifies proofs of non-functional properties of rewrite systems, such as termination, confluence, and complexity,
provided by automated tools that support the [certification problem format](http://cl-informatik.uibk.ac.at/software/cpf/) format. It mainly consists of two parts.

* An [Isabelle/HOL](https://isabelle.in.tum.de/) formalization of some current termination techniques, as part of the library IsaFoR.

* An automatically generated Haskell program (using the code-generation feature of Isabelle) to certify proofs.


