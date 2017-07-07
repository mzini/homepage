---
type: article
title: Automating Sized-Type Inference for Complexity Analysis
journal: pacmpl
volume: 1
authors: M. Avanzini and U. {Dal Lago}
year: 2017
publisher: acm
tags: Complexity Analysis, Higher-Order, Automation, Sized-Types
doi: 10.1145/3110287
schroedinger: yes
copyright: cc
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
