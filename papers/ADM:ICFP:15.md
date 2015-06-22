---
type: draft
arxiv: 1506.05043
tags: Term Rewriting, Complexity Analysis, Runtime Complexity Analysis, Higher-Order, OCaml, Automation
copyright: ACM
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
