---
type: thesis
tags: Term Rewriting, Complexity Analysis, Runtime Complexity Analysis, Path Orders, ICC, Predicative Recursion, Automation, TCT, Invariance
---

We strive to advance the field of complexity analysis from 
a theoretical and practical perspective. 
We use *term rewrite systems* machine model, 
which is a formal model of computation close to first order functional programs. 
A term rewrite system, the program, consists of a collection of directed equations, so called rewrite rules. 
Computation in this model is performed by successively applying equations from left to right.

The runtime complexity of a rewrite system, which relates the sizes of the inputs 
to the maximal number of steps in such computations, forms a natural cost model.
In the first part of this work 
we argue that this cost model is indeed reasonable. 
Our *polytime invariance theorem* states that 
algorithms expressed as rewrite systems admit implementations on a conventional model of computation, 
the Turing machine, such that the computational complexity of this implementation is 
tightly related to runtime complexity of the underlying rewrite systems.

In the second part we present a novel technique 
to analyse the runtime complexity of rewrite systems. 
If this analysis is successful, we can deduce that the runtime complexity of the analysed
rewrite system is bounded by a polynomial, whose degree can be precisely inferred.
The described technique is
purely syntactical, and as a consequence its automation is feasible. 
Beyond this practical application, the technique
yields a resource free characterisation of the class of functions computable in polynomial 
time. 
Hence our method has also ramifications in the context of *implicit computational complexity theory*. 
We then generalise this technique so that exponential bounds can be inferred. 
In turn, this provides a resource free characterisation of the *exponential time computable functions*.

We have designed the fully automatic complexity analyser [TCT](http://cl-informatik.uibk.ac.at/software/tct), the *Tyrolean Complexity Tool*. 
TCT is a competitive tool that integrates a majority of the techniques known for the automated polytime 
complexity analysis. The final part of this work is concerned with this implementation and its underlying 
theoretical framework.
