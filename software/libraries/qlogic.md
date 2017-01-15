---
title: QLogic
license: GPL
external: http://cl-informatik.uibk.ac.at/software/tct/projects/qlogic/
language: haskell
github: mzini/qlogic
short: High-level abstraction to SAT-solvers
---
This is a Haskell library for dealing with propositional logic. In particular, it provides the following features:

- Translation of diophantine constraints to propositional formulas
- Translation of common arithmetical functions over Integers and Naturals to propositional formulas
- A general interface to SAT-solvers, including efficient translation of arbitrary formulas to CNF.

This library underlies the [Tyrolean Complexity Tool, Version 2](http://cl-informatik.uibk.ac.at/software/tct), it has
been deprecated in favor of [SLogic](https://github.com/ComputationWithBoundedResources/slogic).