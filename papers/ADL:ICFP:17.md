---
type: draft
title: Complexity Analysis by Polymorphic Sized Type Inference and Constraint Solving
authors: M. Avanzini and U. {Dal Lago}
year: 2017
submitted: ICFP
tags: Complexity Analysis, Higher-Order, Automation, Sized-Types
---

This paper introduces a new methodology for the complexity analysis
of higher-order functional programs, which is based on three
ingredients: a powerful type system for size analysis and a sound
type inference procedure for it, a ticking monadic transformation
and constraint solving. Noticeably, the presented methodology can be
fully automated, and is able to analyse a series of examples which
cannot be handled by most competitor methodologies. This is possible
due to various key ingredients, and in particular an abstract index
language and index polymorphism at higher ranks. A prototype
implementation is available.
