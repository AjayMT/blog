---
layout: post
title:  "Proving Pythagoras' Theorem with Similar Triangles"
date:   2020-08-18 00:00:00 -0500
categories: math
---

(Disclaimer: This is not a rigorous or detailed proof, I am only
trying to provide a simple explanation.)

My favorite proof of Pythagoras' familiar theorem (\\(a^2 + b^2 = c^2\\)) is based on
similar triangles.

To prove this statement, we first have to define *similarity*:

<p style="text-align:center;">
Triangles \(ABC\) and \(DEF\) are similar (denoted \(ABC \sim DEF\)) iff
\(\angle A = \angle D \land \angle B = \angle E \land \angle C = \angle F\).
</p>

In other words, two triangles are similar when their corresponding angles
are equal.

Notice that the order of vertices of each triangle is important: $$ABC$$,
$$BCA$$ and $$ACB$$ are all different triangles in the context of similarity.

Similar trangles exhibit an important property that relates the lengths of their
sides:

$$\triangle ABC \sim \triangle DEF \iff \frac{AB}{DE} = \frac{BC}{EF} = \frac{CA}{FD}$$

That is, the ratios of the lengths of corresponding sides of similar triangles
are equal. For the sake of completeness, I have included a proof of this statement
below.

<details>
<summary>Proof</summary>

<p>The proof of this statement depends on Euclid's fifth axiom, which is more simply
stated as Playfair's Postulate:</p>

<p style="text-align:center;">
Given a line and a point not on the line, there is exactly one parallel to the
given line through the point.
</p>

<p>We start by assuming that two triangles \(ABC\) and \(DEF\) are similar. If they
are congruent, the ratios of corresponding sides are all 1 and we are done.</p>

<p>We will assume without loss of generality that segment \(DE\) is shorter than
segment \(AB\).</p>

<p>We can place \(DEF\) atop \(ABC\) such that \(D\) lies on \(A\), \(E\)
lies on segment \(AB\) and \(F\) lies on segment \(CA\).</p>

<p style="text-align:center;">
<img src="/blog/assets/triangle-1.png" width="300em" />
</p>

<p>Euclid's fifth postulate and the fact that
\(\angle FEB + \angle ABC = 180^{\circ}\)
imply that \(EF\) and \(BC\) are parallel.</p>
<p>We will connect points \(B\) and \(F\) and construct a
perpendicular to \(AB\) from \(F\) intersecting at point \(G\):</p>

<p style="text-align:center;">
<img src="/blog/assets/triangle-2.png" width="300em" />
</p>

<p>Now we consider the areas of \(\triangle BFE\) and \(\triangle AFE\):</p>

$$
\frac{Area(BFE)}{Area(AFE)} = \frac{(\frac{1}{2})(FG)(BE)}{(\frac{1}{2})(FG)(AE)} = \frac{BE}{AE}
$$

<p>By a similar process (drawing a perpendicular from \(E\) to \(CA\)) we can show that:</p>

$$
\frac{Area(CFE)}{Area(AFE)} = \frac{CF}{AF}
$$

<p>Since triangles \(BFE\) and \(CFE\) share base \(FE\) and have the same height
(perpendicular to \(FE\)), we have:</p>

$$
\frac{Area(CFE)}{Area(AFE)} = \frac{Area(BFE)}{Area(AFE)}
$$

<p>Which implies:</p>

$$
\frac{BE}{AE} = \frac{CF}{AF} \implies \frac{AE}{AB} = \frac{AF}{AC}
$$

<p>This completes the proof of the forward implication.</p>
</details>
