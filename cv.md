---
title: Curriculum Vitae of Martin Avanzini
webpage: http://cl-informatik.uibk.ac.at/users/zini
email: martin.avanzini@uibk.ac.at
address: Schnatzenbichl 3, A-6063 Rum
---
\newcommand{\HL}[1]{\hfill\textit{#1}\newline}
\define{DATE}{$if(html)$<span class="date">#1</span><br></br>$endif$\HL{#1}}
\define{BR}{$if(html)$</br>$endif$\newline}

# Research Interests {-}
- Functional programming
- Rewriting
- Static program analysis
- Complexity analysis
- Implicit computational complexity


# Higher Education {-}

- **PhD Degree in Computer Science.** \DATE{2013}
  Institute of Computer Science, University of Innsbruck, Austria.\BR{}
  Thesis *Verifying Polytime Computability Automatically*, supervised by Georg Moser.
- **Master's Degree in Computer Science.** \DATE{2009}
  Institute of Computer Science, University of Innsbruck, Austria.\BR{}
  Master Thesis *Automation of Polynomial Path Orders*, supervised by Georg Moser. 
- **Bachelor's Degree in Computer Science.** \DATE{2007}
  Institute of Computer Science, University of Innsbruck, Austria.\BR{}
  Bachelor Thesis *Termination Analysis for Scheme using S-Expression Rewrite Systems*,
  supervised by Nao Hirokawa and *Scheme Programs with Polynomially Bounded Evaluation Length*
  supervised by Georg Moser.
- **Diploma Höhere Technische Lehranstalt.** \DATE{2001}
   Civil Engineering, Htl Trenkwalderstraße, Innsbruck, Austria.

# Awards {-}

- **Proposed for the Heinz Zemanek Price.** \DATE{October, 2016}
  The *Heinz Zemanek price* is awarded every 3 years by the *Austrian Computer Society (OCG)* to young researchers
  for outstanding PhD dissertations. I was nominated by the University of Innsbruck for this price,
  and also passed the final selection (8 persons) from the OCG.

- **Kurt Gödel Medal.** \DATE{August, 2014}
   Our *Tyrolean Complexity tool* was distinguished with the prestigious *Kurt Gödel Medal* as best tool
   for the complexity analysis of term rewrite systems
   at the *FLoC Olympic Games*, held during the *Vienna Summer of Logic*. 

- **European Summer School in Logics, Languages and Computation.** \DATE{August, 2008}
   My work received second place in *Springer best paper awards*.

# Scholarships and Projects {-}

$for(projects)$
- **$role$.** \DATE{$start$ -- $end$}
  [*$title$*]($url$).\BR{}
  $type$$if(number)$ (project number $number$)$endif$. *$where$*.
$endfor$

# Scientific Activities {-}

- **PC member.** \DATE{2017}
  [17th International Workshop on Logic and Computational Complexity](http://www.cs.swansea.ac.uk/lcc/), Reykjavik, Island.
- **PC member.** \DATE{2014} 
  [5th Workshop on Developments in Implicit Computational Complexity](http://dice14.tcs.ifi.lmu.de/), Grenoble, France. 
- **Invited speaker.** \DATE{2013} 
  [15th International Workshop on Logic and Computational Complexity](http://www.cs.swansea.ac.uk/lcc2014/), Torino, Italy. 
- **Invited speaker.** \DATE{2013} 
  [3rd Workshop on Proof Theory and Rewriting](http://www.jaist.ac.jp/~hirokawa/pr2013/), Kanazawa, Japan. 

# Software Development {-}

The following gives a short list of most important software projects that I was involved in. If not mentioned otherwise,
I am (among) the main developer(s).
Details can be found at my [software page](http://cl-informatik.uibk.ac.at/users/zini/software.html).
$for(tools)$
$if(oncv)$- $body$$endif$
$endfor$
$for(libs)$
$if(oncv)$- $body$$endif$
$endfor$
