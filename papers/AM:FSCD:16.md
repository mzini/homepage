---
type: conference
tags: Program Analysis, Graph Rewriting, Complexity Analysis, Runtime Complexity Analysis
accepted: 1st International Conference on Formal Structures for Computation and Deduction (FSCD)
---

Term rewriting has been used as a formal model to reason about the complexity of logic, functional, and imperative programs.
In contrast to term rewriting, term graph rewriting permits sharing of common sub-expressions, and consequently
is able to capture more closely reasonable implementations of rule based languages.
However, the automated complexity analysis of term graph rewriting has received little to no attention. 

With this work, we provide first steps towards overcoming this situation. We present adaptions 
of two prominent complexity techniques from term rewriting, viz, the interpretation method and dependency tuples. 
Our adaptions are non-trivial, in the sense that they can observe not only term but also graph structures, i.e.\ take sharing 
into account. In turn, the developed methods allow us to more precisely estimate the runtime complexity of programs 
where sharing of sub-expressions is essential.
