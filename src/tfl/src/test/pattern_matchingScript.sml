(*---------------------------------------------------------------------------
 * Pattern matching extensions.
 *---------------------------------------------------------------------------*)

open HolKernel boolLib Parse Defn bossLib

val _ = new_theory "pattern_matching"

val def = Hol_defn;

(*---------------------------------------------------------------------------
 * Normal patterns
 *---------------------------------------------------------------------------*)
val _ = def "f" `(f(x,y) = x+y)`;

val _ = def "f1" `(f1 0 = 1) /\
         (f1 (SUC n) = 2)`;

(*---------------------------------------------------------------------------
 * Omitted patterns
 *---------------------------------------------------------------------------*)
val _ = def "f2"
   `(f2 0 = 1)`;

val _ = def "f3"
   `(f3 (CONS h t) = (h:'a))`;

val _ = def "f4"
    `(f4 [a;b] = a) /\
     (f4 [b]   = b)`;

val _ = def "f5" `(f5 (0,0) = 0)`;

val _ = def "f6"
  `(f6 (0,0) = 0) /\
   (f6 (0,SUC x) = x) /\
   (f6 (SUC x, y) = y+x)`;

val _ = def "f7"
  `(f7 (SUC 0, CONS h t) = 1) /\
   (f7 (SUC(SUC n), CONS h1 (CONS h2 t)) = (h1:num))`;

val _ = def "f8"
  `(f8 (SUC(SUC n),CONS h1 (CONS h2 t)) = (h1:num))`;

val _ = def "f9"
 `(f9 (CONS h1 (CONS h2 t)) = t) /\
  (f9 x = (x:'a list))`;

(*---------------------------------------------------------------------------
 * Overlapping patterns
 *---------------------------------------------------------------------------*)
val _ = def "g"
  `(g (x,0) = 1) /\
   (g (0,x) = 2)`;

val _ = def "g1"
  `(g1 (0,x) = x) /\
   (g1 (x,0) = x)`;

val _ = def "g2"
  `(g2 ([]:'a list, CONS a (CONS b x)) = 1) /\
   (g2 (CONS a (CONS b x),    y)       = 2) /\
   (g2 (z,          CONS a y)          = 3)`;

val _ = def "g3"
  `(g3 (x,y,0) = 1) /\
   (g3 (x,0,y) = 2) /\
   (g3 (0,x,y) = 3)`;

val _ = def "g4"
  `(g4 (0,y,z) = 1) /\
   (g4 (x,0,z) = 2) /\
   (g4 (x,y,0) = 3)`;

val _ = def "g5"
  `(g5(0,x,y,z) = 1) /\
   (g5(w,0,y,z) = 2) /\
   (g5(w,x,0,z) = 3) /\
   (g5(w,x,y,0) = 4)`;

val _ = def "g6"
  `(g6 (0,w,x,y,z) = 1) /\
   (g6 (v,0,x,y,z) = 2) /\
   (g6 (v,w,0,y,z) = 3) /\
   (g6 (v,w,x,0,z) = 4) /\
   (g6 (v,w,x,y,0) = 5)`;

val _ = def "g7"
  `(g7 [x; 0] = x) /\
   (g7 [SUC v] = 1) /\
   (g7 z = 2)`;

val _ = def "g8"
  `(g8 (CONS h1 (CONS h2 (CONS h3 (CONS h4 (CONS h5 h6))))) =
      CONS [h1;h2;h3;h4;h5] [h6]) /\
   (g8 x = [x:'a list])`;

val _ = def "g9"
   `(g9 (CONS h1 (CONS h2 (CONS h3 (CONS h4 (CONS h5 h6))))) =
           CONS [h1;h2;h3;h4;h5] [h6]) /\
    (g9 [] = []) /\
    (g9 x = [x])`;

(* Normal *)
val _ = def "g10"
  `(g10 (SUC(SUC x)) = 1) /\
   (g10 (SUC x) = 2) /\
   (g10 0 = 3)`;

(*---------------------------------------------------------------------------
 * Unaccessible patterns
 *---------------------------------------------------------------------------*)
val _ = def "h"
  `(h (x:num) = 1) /\
   (h x = 2)`;

val _ = def "h1"
  `(h1 (x:num,0) = 1) /\
   (h1 (x,SUC y) = 2) /\
   (h1 (x,y) = 3) /\
   (h1 (0,SUC q) = 3)`;

val _ = def "h2"
  `(h2 (x,0) = 1) /\
   (h2 (0,x) = 2) /\
   (h2 (0,0) = 3) /\
   (h2 (x,y) = 4)`;

val _ = export_theory()
