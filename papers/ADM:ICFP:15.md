---
type: conference
title: "Analysing the Complexity of Functional Programs: Higher-Order Meets First-Order"
authors: M. Avanzini and U. {Dal Lago} and G. Moser
proceedings: icfp20
year: 2015
pages: 152--164
publisher: acm
arxiv: 1506.05043
doi: 10.1145/2784731.2784753
tags: Term Rewriting, Complexity Analysis, Runtime Complexity Analysis, Higher-Order, OCaml, Automation
copyright: acm
schroedinger: yes
---

We show how the complexity of *higher-order* functional programs can
be analysed automatically by applying program transformations to a
defunctionalised versions of them, and feeding the result to
existing tools for the complexity analysis of *first-order term rewrite systems*.
This is done while carefully analysing complexity
preservation and reflection of the employed transformations such that
the complexity of the obtained term rewrite system reflects
on the complexity of the initial program. Further, we
describe suitable strategies for the application of the studied
transformations and provide ample experimental data for assessing
the viability of our method.
