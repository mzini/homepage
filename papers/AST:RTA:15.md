---
type: conference
title: Certification of Complexity Proofs using CeTA
authors: M. Avanzini and C. Sternagel and R. Thiemann
proceedings: rta26
volume: 36
series: lipics
publisher: dagstuhl
pages: 23--39
year: 2015
doi: 10.4230/LIPIcs.RTA.2015.23
tags: Term Rewriting, Complexity Analysis, Runtime Complexity Analysis, Certification
copyright: cc
schroedinger: yes
---

Nowadays certification is widely employed by automated termination tools for term rewriting,
where certifiers support most available techniques. In complexity analysis, the situation is quite
different. Although tools support certification in principle, current certifiers implement only the
most basic technique, namely, suitably tamed versions of reduction orders. As a consequence,
only a small fraction of the proofs generated by state-of-the-art complexity tools can be certified.
To improve upon this situation, we formalized a framework for the certification of modular
complexity proofs and incorporated it into CeTA. We report on this extension and present the
newly supported techniques (match-bounds, weak dependency pairs, dependency tuples, usable
rules, and usable replacement maps), resulting in a significant increase in the number of certifiable
complexity proofs. During our work we detected conflicts in theoretical results as well as bugs
in existing complexity tools.