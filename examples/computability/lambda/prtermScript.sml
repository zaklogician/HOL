open HolKernel boolLib bossLib Parse

open prnlistTheory numpairTheory pure_dBTheory
open enumerationsTheory primrecfnsTheory
open rich_listTheory arithmeticTheory

fun Store_thm (trip as (n,t,tac)) = store_thm trip before export_rewrites [n]

val _ = new_theory "prterm"

val prtermrec_def = tDefine "prtermrec" `
  prtermrec v c a list =
    case list of
       [] -> v []
    || n::t ->
        if n MOD 3 = 0 then v (n DIV 3 :: t) : num
        else if n MOD 3 = 1 then
          let t1 = nfst (n DIV 3) in
          let t2 = nsnd (n DIV 3)
          in
            c (t1 :: t2 ::
               prtermrec v c a (t1::t) :: prtermrec v c a (t2::t) :: t)
        else
          let t0 = n DIV 3
          in
            a (t0 :: prtermrec v c a (t0::t) :: t)`
  (WF_REL_TAC `measure (HD o SND o SND o SND)` THEN
   SRW_TAC [][] THEN
   `0 < n` by (Cases_on `n` THEN FULL_SIMP_TAC (srw_ss()) []) THENL [
     MATCH_MP_TAC LESS_EQ_LESS_TRANS THEN Q.EXISTS_TAC `n DIV 3` THEN
     SRW_TAC [][DIV_LESS, nsnd_le],
     MATCH_MP_TAC LESS_EQ_LESS_TRANS THEN Q.EXISTS_TAC `n DIV 3` THEN
     SRW_TAC [][DIV_LESS, nfst_le],
     SRW_TAC [][DIV_LESS]
   ])

val prK = prove(
  ``0 < m ⇒ primrec (λl. n) m``,
  `(λl:num list. n) = K n` by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][]);
val _ = augment_srw_ss [rewrites [prK]]

val prCOND = prove(
  ``primrec f n ∧ primrec g n ∧ primrec (nB o P) n ∧ pr_predicate (nB o P) ⇒
    primrec (λl. if P l then f l else g l) n``,
  STRIP_TAC THEN
  `(λl. if P l then f l else g l) = pr_cond (nB o P) f g`
     by SRW_TAC [][pr_cond_def, FUN_EQ_THM] THEN
  SRW_TAC [][]);

val pr_eq = prove(
  ``primrec f n ∧ primrec g n ⇒ primrec (λl. nB (f l = g l)) n``,
  STRIP_TAC THEN
  `(λl. nB (f l = g l)) = Cn pr_eq [f; g]`
     by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][primrec_rules]);

val prproj = prove(
  ``i < n ⇒ primrec (λl. proj i l) n``,
  SRW_TAC [boolSimps.ETA_ss][primrec_rules]);
val _ = augment_srw_ss [rewrites [prproj]]
val _ = temp_overload_on ("'", ``λl i. proj i l``)

val primrec_cn = List.nth(CONJUNCTS primrec_rules, 3)

val prMOD = prove(
  ``0 < n ∧ primrec f m ⇒ primrec (λl. f l MOD n) m``,
  STRIP_TAC THEN
  `(λl. f l MOD n) = Cn pr_mod [f; K n]`
     by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][] THEN MATCH_MP_TAC primrec_cn THEN SRW_TAC [][] THEN
  METIS_TAC [primrec_K, primrec_nzero])

val prDIV = prove(
  ``0 < n ∧ primrec f m ⇒ primrec (λl. f l DIV n) m``,
  STRIP_TAC THEN
  `(λl. f l DIV n) = Cn pr_div [f; K n]` by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][] THEN MATCH_MP_TAC primrec_cn THEN SRW_TAC [][] THEN
  METIS_TAC [primrec_K, primrec_nzero]);

val prf2 = prove(
  ``primrec (pr2 f) 2 ∧ primrec g n ∧ primrec h n ⇒
    primrec (λl. f (g l) (h l)) n``,
  STRIP_TAC THEN
  `(λl. f (g l) (h l)) = Cn (pr2 f) [g; h]` by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][primrec_rules]);
fun i2 q = GEN_ALL (Q.INST [`f` |-> q] prf2)

fun intro2 q = HO_MATCH_MP_TAC (i2 q)
val intro = HO_MATCH_MP_TAC

val prf1 = prove(
  ``primrec g n ∧ primrec (pr1 f) 1 ⇒ primrec (λl. f (g l)) n``,
  STRIP_TAC THEN
  `(λl. f (g l)) = Cn (pr1 f) [g]` by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][primrec_rules]);
fun i1 q = GEN_ALL (Q.INST [`f` |-> q] prf1)


val prCn1 = prove(
  ``primrec f 1 ∧ primrec g n ⇒ primrec (λl. f [g l]) n``,
  STRIP_TAC THEN
  `(λl. f [g l]) = Cn f [g]` by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][primrec_rules]);

val prCn2 = prove(
  ``primrec f 2 ∧ primrec g n ∧ primrec h n ⇒ primrec (λl. f [g l; h l]) n``,
  STRIP_TAC THEN
  `(λl. f [g l; h l]) = Cn f [g; h]` by SRW_TAC [][FUN_EQ_THM] THEN
  SRW_TAC [][primrec_rules]);

val prCn3 = prove(
  ``primrec f 3 ∧ primrec g1 n ∧ primrec g2 n ∧ primrec g3 n ⇒
    primrec (λl. f [g1 l; g2 l; g3 l]) n``,
  STRIP_TAC THEN
  `(λl. f [g1 l; g2 l; g3 l]) = Cn f [g1; g2; g3]`
      by SRW_TAC [][FUN_EQ_THM, Cn_def] THEN
  SRW_TAC [][primrec_rules]);

val prCn4 = prove(
  ``primrec f 4 ∧ primrec g1 n ∧ primrec g2 n ∧ primrec g3 n ∧ primrec g4 n ⇒
    primrec (λl. f [g1 l; g2 l; g3 l; g4 l]) n``,
  STRIP_TAC THEN
  `(λl. f [g1 l; g2 l; g3 l; g4 l]) = Cn f [g1; g2; g3; g4]`
      by SRW_TAC [][FUN_EQ_THM, Cn_def] THEN
  SRW_TAC [][primrec_rules]);

val prCn5 = prove(
  ``primrec f 5 ∧ primrec g1 n ∧ primrec g2 n ∧ primrec g3 n ∧ primrec g4 n ∧
    primrec g5 n ⇒
    primrec (λl. f [g1 l; g2 l; g3 l; g4 l; g5 l]) n``,
  STRIP_TAC THEN
  `(λl. f [g1 l; g2 l; g3 l; g4 l; g5 l]) = Cn f [g1; g2; g3; g4; g5]`
      by SRW_TAC [][FUN_EQ_THM, Cn_def] THEN
  SRW_TAC [][primrec_rules]);

val prpred = prove(
  ``pr_predicate (λl. nB (P l))``,
  SRW_TAC [][pr_predicate_def]);

val NTL_def = Define`(NTL [] = []) ∧ (NTL ((h:num)::t) = t)`

val strong_primrec_ind = IndDefLib.derive_strong_induction(primrec_rules,
                                                           primrec_ind)

val GENLIST_CONS = prove(
  ``GENLIST f (SUC n) = f 0 :: (GENLIST (f o SUC) n)``,
  Induct_on `n` THEN SRW_TAC [][GENLIST, SNOC]);
val GENLIST1 = prove(``GENLIST f 1 = [f 0]``,
                     SIMP_TAC bool_ss [ONE, GENLIST, SNOC]);
val MAP_EQ_GENLIST = prove(
  ``MAP f l = GENLIST (λi. f (EL i l)) (LENGTH l)``,
  Induct_on `l` THEN1 SRW_TAC [][GENLIST] THEN
  SRW_TAC [][GENLIST_CONS, combinTheory.o_DEF]);

val TAKE_EQ_GENLIST = store_thm(
  "TAKE_EQ_GENLIST",
  ``n ≤ LENGTH l ⇒ (TAKE n l = GENLIST (λi. l ' i) n)``,
  Q.ID_SPEC_TAC `n` THEN Induct_on `l` THEN SRW_TAC [][GENLIST] THEN
  `∃m. n = SUC m` by (Cases_on `n` THEN SRW_TAC [][]) THEN
  FULL_SIMP_TAC (srw_ss()) [GENLIST_CONS, combinTheory.o_DEF]);

val swap2_def = Define`
  (swap2 f [] = f [0; 0]) ∧
  (swap2 f [n] = f [0; n]) ∧
  (swap2 f (h1::h2::t) = f (h2::h1::t))
`;

val primrec_swap2 = store_thm(
  "primrec_swap2",
  ``2 ≤ n ∧ primrec f n ⇒ primrec (swap2 f) n``,
  STRIP_TAC THEN
  Q_TAC SUFF_TAC `swap2 f = Cn f (proj 1 :: proj 0 ::
                                  GENLIST (λi. proj (i + 2)) (n - 2))`
  THENL [
    DISCH_THEN SUBST1_TAC THEN MATCH_MP_TAC primrec_cn THEN
    SRW_TAC [ARITH_ss][LENGTH_GENLIST, primrec_rules, EVERY_GENLIST, ADD1],

    SIMP_TAC (srw_ss()) [FUN_EQ_THM] THEN Q.X_GEN_TAC `l` THEN
    `(l = []) ∨ ∃m ms. l = m::ms` by (Cases_on `l` THEN SRW_TAC [][]) THENL [
      SRW_TAC [][Cn_def, MAP_GENLIST, combinTheory.o_DEF, swap2_def] THEN
      Cases_on `n = 2` THEN1 SRW_TAC [][GENLIST] THEN
      `2 < n` by DECIDE_TAC THEN
      IMP_RES_THEN (Q.SPEC_THEN `[0; 0]` MP_TAC) primrec_short THEN
      SRW_TAC [ARITH_ss][ADD1, combinTheory.K_DEF],

      `(ms = []) ∨ ∃p ps. ms = p::ps` by (Cases_on `ms` THEN SRW_TAC [][])
      THENL [
        SRW_TAC [][Cn_def, MAP_GENLIST, combinTheory.o_DEF, swap2_def] THEN
        Cases_on `n = 2` THEN1 SRW_TAC [][GENLIST] THEN
        `2 < n` by DECIDE_TAC THEN
        IMP_RES_THEN (Q.SPEC_THEN `[0; m]` MP_TAC) primrec_short THEN
        SRW_TAC [ARITH_ss][ADD1, combinTheory.K_DEF],

        SRW_TAC [][Cn_def, MAP_GENLIST, combinTheory.o_DEF, swap2_def] THEN
        SRW_TAC [ARITH_ss][] THEN
        `n ≤ LENGTH (p::m::ps) ∨ LENGTH (p::m::ps) < n` by DECIDE_TAC THENL [
          IMP_RES_THEN (Q.SPEC_THEN `p::m::ps` MP_TAC)
                       primrec_arg_too_long THEN
          FULL_SIMP_TAC(srw_ss() ++ ARITH_ss) [ADD1, TAKE_EQ_GENLIST],

          IMP_RES_THEN (Q.SPEC_THEN `p::m::ps` MP_TAC) primrec_short THEN
          SRW_TAC [ARITH_ss][ADD1] THEN AP_TERM_TAC THEN SRW_TAC [][] THEN
          FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [ADD1] THEN
          ASM_SIMP_TAC (srw_ss() ++ ARITH_ss)
                       [listTheory.LIST_EQ_REWRITE, LENGTH_GENLIST,
                        EL_GENLIST] THEN
          Q.X_GEN_TAC `i` THEN STRIP_TAC THEN
          Cases_on `i < LENGTH ps` THEN1
            SRW_TAC [ARITH_ss][EL_APPEND1, proj_def] THEN
          `LENGTH ps ≤ i` by DECIDE_TAC THEN
          SRW_TAC [ARITH_ss][EL_APPEND2, EL_GENLIST, proj_def]
        ]
      ]
    ]
  ]);

val primrec_cons = store_thm(
  "primrec_cons",
  ``primrec f n ⇒ primrec (λl. f (c::l)) n``,
  STRIP_TAC THEN
  `0 < n` by IMP_RES_TAC primrec_nzero THEN
  Q_TAC SUFF_TAC
        `(λl. f (c::l)) = Cn f (K c :: GENLIST proj (n - 1))`
  THENL [
    DISCH_THEN SUBST1_TAC THEN
    SRW_TAC [ARITH_ss][LENGTH_GENLIST, ADD1, EVERY_GENLIST, primrec_rules],

    SIMP_TAC (srw_ss()) [FUN_EQ_THM] THEN Q.X_GEN_TAC `l` THEN
    SRW_TAC [][Cn_def, MAP_GENLIST, combinTheory.o_DEF] THEN
    `n ≤ LENGTH l + 1 ∨ LENGTH l + 1 < n` by DECIDE_TAC THENL [
      IMP_RES_THEN (Q.SPEC_THEN `c::l` MP_TAC) primrec_arg_too_long THEN
      SRW_TAC [ARITH_ss][ADD1, TAKE_EQ_GENLIST],

      IMP_RES_THEN (Q.SPEC_THEN `c::l` MP_TAC) primrec_short THEN
      SRW_TAC [ARITH_ss][ADD1] THEN AP_TERM_TAC THEN
      ASM_SIMP_TAC (srw_ss() ++ ARITH_ss)
                   [listTheory.LIST_EQ_REWRITE, LENGTH_GENLIST, EL_GENLIST]
                   THEN
      Q.X_GEN_TAC `i` THEN STRIP_TAC THEN
      `i < LENGTH l ∨ LENGTH l ≤ i` by DECIDE_TAC THEN
      SRW_TAC [ARITH_ss][proj_def, EL_APPEND1, EL_APPEND2, EL_GENLIST]
    ]
  ]);


val fcons_ntl2 = store_thm(
  "fcons_ntl2",
  ``primrec f n ∧ primrec g (n + 2) ⇒
    primrec (λl. f (g l :: NTL (NTL l))) (n + 2)``,
  STRIP_TAC THEN
  `0 < n` by METIS_TAC [primrec_nzero] THEN
  Q.MATCH_ABBREV_TAC `primrec h (n + 2)` THEN
  Q_TAC SUFF_TAC `h = Cn f (g::GENLIST (λi. proj (i + 2)) (n - 1))`
  THEN1
    (DISCH_THEN SUBST1_TAC THEN
     MATCH_MP_TAC primrec_cn THEN
     SRW_TAC [ARITH_ss][LENGTH_GENLIST, EVERY_GENLIST, ADD1,
                        primrec_rules]) THEN
  Q.UNABBREV_TAC `h` THEN SIMP_TAC (srw_ss()) [FUN_EQ_THM] THEN
  Q.X_GEN_TAC `l` THEN SRW_TAC [][Cn_def,MAP_GENLIST, combinTheory.o_ABS_R] THEN
  Q.PAT_ASSUM `primrec g (n + 2)` (K ALL_TAC) THEN
  Cases_on `LENGTH (NTL (NTL l)) + 1 < n` THENL [
    IMP_RES_THEN (Q.SPEC_THEN `g l :: NTL (NTL l)` MP_TAC) primrec_short THEN
    SRW_TAC [ARITH_ss][ADD1] THEN AP_TERM_TAC  THEN SRW_TAC [][] THEN
    ASM_SIMP_TAC (srw_ss() ++ ARITH_ss) [listTheory.LIST_EQ_REWRITE,
                                         LENGTH_GENLIST, EL_GENLIST] THEN
    Q.X_GEN_TAC `i` THEN STRIP_TAC THEN
    Cases_on `l` THEN1 SRW_TAC [][EL_GENLIST, proj_def, NTL_def] THEN
    SRW_TAC [ARITH_ss][NTL_def] THEN
    Cases_on `t` THEN1 SRW_TAC [][EL_GENLIST, proj_def, NTL_def] THEN
    SRW_TAC [ARITH_ss][NTL_def, proj_def, EL_APPEND1, EL_APPEND2,
                       EL_GENLIST],

    IMP_RES_THEN (Q.SPEC_THEN `g l :: NTL (NTL l)` MP_TAC)
                 primrec_arg_too_long THEN
    SRW_TAC [ARITH_ss][ADD1, TAKE_EQ_GENLIST] THEN AP_TERM_TAC THEN
    SRW_TAC [][] THEN
    ASM_SIMP_TAC (srw_ss() ++ ARITH_ss) [listTheory.LIST_EQ_REWRITE,
                                         LENGTH_GENLIST, EL_GENLIST] THEN
    Cases_on `l` THEN FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [NTL_def] THEN
    Cases_on `t` THEN FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [NTL_def]
  ]);


val primrec_consNTL = store_thm(
  "primrec_consNTL",
  ``primrec f n ⇒ primrec (λl. f (c::NTL l)) n``,
  STRIP_TAC THEN
  `0 < n` by METIS_TAC [primrec_nzero] THEN
  Q_TAC SUFF_TAC
    `(λl. f (c::NTL l)) = Cn f (K c::GENLIST (λi. proj (i + 1)) (n - 1))`
  THENL [
    DISCH_THEN SUBST1_TAC THEN
    MATCH_MP_TAC primrec_cn THEN
    SRW_TAC [ARITH_ss][LENGTH_GENLIST, ADD1, EVERY_GENLIST, primrec_rules],

    SIMP_TAC (srw_ss()) [FUN_EQ_THM] THEN Q.X_GEN_TAC `l` THEN
    SRW_TAC [][Cn_def, MAP_GENLIST, combinTheory.o_DEF] THEN
    `LENGTH l < n ∨ n ≤ LENGTH l` by DECIDE_TAC THENL [
       IMP_RES_THEN (Q.SPEC_THEN `c::NTL l` MP_TAC) primrec_short THEN
       `(l = []) ∨ ∃h t. l = h::t` by (Cases_on `l` THEN SRW_TAC [][]) THENL [
          SRW_TAC [][NTL_def] THEN
          `(n = 1) ∨ 1 < n` by DECIDE_TAC THEN
          SRW_TAC [][GENLIST, combinTheory.K_DEF],

          SRW_TAC [][NTL_def,ADD1] THEN
          FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [ADD1] THEN
          AP_TERM_TAC THEN
          SRW_TAC [][] THEN
          ASM_SIMP_TAC (srw_ss() ++ ARITH_ss)
                       [listTheory.LIST_EQ_REWRITE, LENGTH_GENLIST,
                        EL_GENLIST] THEN
          Q.X_GEN_TAC `i` THEN STRIP_TAC THEN
          `i < LENGTH t ∨ LENGTH t ≤ i` by DECIDE_TAC THEN
          ASM_SIMP_TAC (srw_ss() ++ ARITH_ss)[EL_APPEND1, EL_APPEND2, proj_def,
                                              EL_GENLIST]
       ],

       IMP_RES_THEN (Q.SPEC_THEN `c::NTL l` MP_TAC) primrec_arg_too_long THEN
       `LENGTH (NTL l) = LENGTH l - 1`
          by (Cases_on `l` THEN
              FULL_SIMP_TAC (srw_ss() ++ARITH_ss) [NTL_def]) THEN
       ASM_SIMP_TAC (srw_ss() ++ ARITH_ss) [TAKE_EQ_GENLIST] THEN
       DISCH_THEN (K ALL_TAC) THEN
       Cases_on `l` THEN FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [NTL_def]
     ]
   ]);

val nlist_of_append = store_thm(
  "nlist_of_append",
  ``nlist_of (l1 ++ l2) = napp (nlist_of l1) (nlist_of l2)``,
  Induct_on `l1` THEN SRW_TAC [][]);

val nlist_of11 = Store_thm(
  "nlist_of11",
  ``∀l1 l2. (nlist_of l1 = nlist_of l2) ⇔ (l1 = l2)``,
  Induct THEN SRW_TAC [][] THEN Cases_on `l2` THEN SRW_TAC [][]);

val nlist_of_onto = store_thm(
  "nlist_of_onto",
  ``∀n. ∃l. nlist_of l = n``,
  intro nlist_ind THEN SRW_TAC [][] THENL [
    Q.EXISTS_TAC `[]` THEN SRW_TAC [][],
    Q.EXISTS_TAC `h::l` THEN SRW_TAC [][]
  ]);

val napp_nil2 = Store_thm(
  "napp_nil2",
  ``∀l1. napp l1 nnil = l1``,
  intro nlist_ind THEN SRW_TAC [][]);

val napp_ASSOC = store_thm(
  "napp_ASSOC",
  ``napp l1 (napp l2 l3) = napp (napp l1 l2) l3``,
  MAP_EVERY Q.ID_SPEC_TAC [`l3`, `l2`, `l1`] THEN
  intro nlist_ind THEN SRW_TAC [][])

val napp11 = Store_thm(
  "napp11",
  ``((napp l1 l2 = napp l1 l3) ⇔ (l2 = l3)) ∧
    ((napp l2 l1 = napp l3 l1) ⇔ (l2 = l3))``,
  MAP_EVERY
      (fn (nq, lq) => Q.SPEC_THEN nq (Q.X_CHOOSE_THEN lq (SUBST1_TAC o SYM))
                                  nlist_of_onto)
      [(`l3`,`ll3`), (`l2`,`ll2`), (`l1`,`ll1`)] THEN
  SRW_TAC [][GSYM nlist_of_append]);

val Pr1_def = Define`
  Pr1 n f = Cn (Pr (K n) (Cn f [proj 0; proj 1]))
               [proj 0; K 0]
`;

val Pr1_correct = Store_thm(
  "Pr1_correct",
  ``(Pr1 n f [0] = n) ∧
    (Pr1 n f [SUC m] = f [m; Pr1 n f [m]])``,
  SRW_TAC [][Pr1_def]);

val primrec_Pr1 = Store_thm(
  "primrec_Pr1",
  ``primrec f 2 ⇒ primrec (Pr1 n f) 1``,
  SRW_TAC [][Pr1_def, primrec_rules, alt_Pr_rule]);

val prtermrec1_def = Define`
  prtermrec1 v c a =
   (λl. nel (l ' 0)
            (Pr (λl. ncons (v [0; l ' 0]) nnil)
              (λl.
                 let n = l ' 0 + 1 in
                 let r = l ' 1 in
                 let p = l ' 2 in
                 let m = n MOD 3
                 in
                   if m = 0 then napp r (ncons (v [n DIV 3; p]) nnil)
                   else if m = 1 then
                     let t1 = nfst (n DIV 3) in
                     let t2 = nsnd (n DIV 3) in
                     let r1 = nel t1 r in
                     let r2 = nel t2 r
                     in
                       napp r (ncons (c [t1; t2; r1; r2; p]) nnil)
                   else
                     let t0 = n DIV 3 in
                     let r0 = nel t0 r
                     in
                       napp r (ncons (a [t0; r0; p]) nnil))
              l))`

val nfst_snd_div3 = Store_thm(
  "nfst_snd_div3",
  ``0 < n ⇒ nfst (n DIV 3) < n ∧ nsnd (n DIV 3) < n``,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC LESS_EQ_LESS_TRANS THEN
  Q.EXISTS_TAC `n DIV 3` THEN
  SRW_TAC [ARITH_ss][DIV_LESS, nfst_le, nsnd_le])

val prtermrec1_correct = store_thm(
  "prtermrec1_correct",
  ``prtermrec1 v c a [n; p] = prtermrec v c a [n; p]``,
  SRW_TAC [][prtermrec1_def] THEN
  Q.MATCH_ABBREV_TAC `nel n (f [n; p]) = prtermrec v c a [n; p]` THEN
  Q_TAC SUFF_TAC
    `∀n p. f [n; p] = nlist_of (GENLIST (λi. prtermrec v c a [i; p])
                                        (n + 1))`
    THEN1 SRW_TAC [][nel_nlist_of, LENGTH_GENLIST, EL_GENLIST] THEN
  Induct THEN1
    (SRW_TAC [][Abbr`f`, GENLIST1, Once prtermrec_def]) THEN
  SRW_TAC [][Abbr`f`, LET_THM, ADD_CLAUSES, GENLIST, SNOC_APPEND,
             nlist_of_append, NTL_def]
  THENL [
    SRW_TAC [ARITH_ss][Once prtermrec_def, SimpRHS, LET_THM],
    SRW_TAC [ARITH_ss][Once prtermrec_def, SimpRHS, LET_THM, DIV_LESS] THEN
    SRW_TAC [ARITH_ss][nel_nlist_of, EL_GENLIST, LENGTH_GENLIST],
    SRW_TAC [ARITH_ss][Once prtermrec_def, SimpRHS, LET_THM] THEN
    SRW_TAC [ARITH_ss][nel_nlist_of, DIV_LESS, LENGTH_GENLIST, EL_GENLIST]
  ]);

val primrec_termrec = Store_thm(
  "primrec_prtermrec",
  ``primrec v 2 ∧ primrec c 5 ∧ primrec a 3 ⇒
    primrec (prtermrec1 v c a) 2``,
  SRW_TAC [][prtermrec1_def] THEN
  intro2 `nel` THEN SRW_TAC [ARITH_ss][] THEN
  SRW_TAC [boolSimps.ETA_ss][] THEN
  MATCH_MP_TAC alt_Pr_rule THEN
  SRW_TAC [][LET_THM] THEN1
    SRW_TAC [][prCn2, i2 `ncons`] THEN
  intro prCOND THEN SRW_TAC [][prpred, combinTheory.o_ABS_R] THENL [
    intro2 `napp` THEN SRW_TAC [ARITH_ss][] THEN
    intro2 `ncons` THEN SRW_TAC [ARITH_ss][] THEN
    intro prCn2 THEN SRW_TAC [][] THEN
    SRW_TAC [][prDIV, i2 `$+`],

    intro prCOND THEN
    SRW_TAC [][prpred, combinTheory.o_ABS_R] THENL [
      intro2 `napp` THEN SRW_TAC [][] THEN
      intro2 `ncons` THEN SRW_TAC [][prK] THEN
      intro prCn5 THEN SRW_TAC [][] THEN
      SRW_TAC [][i1 `nfst`, prDIV, i2 `$+`, i1 `nsnd`] THEN
      intro2 `nel` THEN
      SRW_TAC [][i1 `nfst`, prDIV, i2 `$+`, i1 `nsnd`],

      intro2 `napp` THEN SRW_TAC [][] THEN
      intro2 `ncons` THEN SRW_TAC [][] THEN
      intro prCn3 THEN
      SRW_TAC [][i2 `nel`, i2 `$+`, prDIV],

      SRW_TAC [][pr_eq, prMOD, i2 `$+`]
    ],

    SRW_TAC [][pr_eq, prMOD, i2 `$+`]
  ]);

val MOD3_thm = prove(
  ``((3 * n) MOD 3 = 0) ∧
    ((3 * n + r) MOD 3 = r MOD 3)``,
  Q.SPEC_THEN `3` (MP_TAC o ONCE_REWRITE_RULE [arithmeticTheory.MULT_COMM])
              arithmeticTheory.MOD_TIMES THEN
  SRW_TAC [][] THEN
  METIS_TAC [DECIDE ``0 < 3``, arithmeticTheory.MULT_COMM,
             arithmeticTheory.MOD_EQ_0]);
val DIV3_thm = prove(
  ``((3 * n) DIV 3 = n) ∧
    ((3 * n + r) DIV 3 = n + r DIV 3)``,
  ONCE_REWRITE_TAC [MULT_COMM] THEN
  SRW_TAC [][ADD_DIV_ADD_DIV, MULT_DIV]);


val prtermrec1_thm = Store_thm(
  "prtermrec1_thm",
  ``(prtermrec1 v c a [dBnum (dV i); p] = v [i; p]) ∧
    (prtermrec1 v c a [dBnum (dAPP t1 t2); p] =
      c [dBnum t1; dBnum t2;
         prtermrec1 v c a [dBnum t1; p]; prtermrec1 v c a [dBnum t2; p]; p]) ∧
    (prtermrec1 v c a [dBnum (dABS t); p] =
      a [dBnum t; prtermrec1 v c a [dBnum t; p]; p])``,
  SRW_TAC [][prtermrec1_correct] THEN
  SRW_TAC [][SimpLHS, Once prtermrec_def, LET_THM, dBnum_def, MOD3_thm,
             DIV3_thm]);

val prtermrec0_def = Define`
  prtermrec0 v c a = Cn (prtermrec1 (Cn v [proj 0])
                                    (Cn c [proj 0; proj 1; proj 2; proj 3])
                                    (Cn a [proj 0; proj 1]))
                        [proj 0; K 0]
`;

val primrec_prtermrec0 = Store_thm(
  "primrec_prtermrec0",
  ``primrec v 1 ∧ primrec c 4 ∧ primrec a 2 ⇒ primrec (prtermrec0 v c a) 1``,
  SRW_TAC [][prtermrec0_def] THEN MATCH_MP_TAC primrec_cn THEN
  SRW_TAC [][primrec_rules]);

val prtermrec0_thm = Store_thm(
  "prtermrec0_thm",
  ``(prtermrec0 v c a [dBnum (dV i)] = v [i]) ∧
    (prtermrec0 v c a [dBnum (dAPP t1 t2)] =
       c [dBnum t1; dBnum t2; prtermrec0 v c a [dBnum t1];
          prtermrec0 v c a [dBnum t2]]) ∧
    (prtermrec0 v c a [dBnum (dABS t)] =
       a [dBnum t; prtermrec0 v c a [dBnum t]])``,
  SRW_TAC [][prtermrec0_def, Cn_def]);

val pr_is_abs_def = Define`
  pr_is_abs = (λl. nB (l ' 0 MOD 3 = 2))
`;

val primrec_is_abs = Store_thm(
  "primrec_is_abs",
  ``primrec pr_is_abs 1``,
  SRW_TAC [][pr_is_abs_def, prMOD, pr_eq]);

val pr_is_abs_thm = Store_thm(
  "pr_is_abs_thm",
  ``(pr_is_abs [dBnum (dABS t)] = 1) ∧
    (pr_is_abs [dBnum (dAPP t1 t2)] = 0) ∧
    (pr_is_abs [dBnum (dV i)] = 0)``,
  SRW_TAC [][pr_is_abs_def, dBnum_def, MOD3_thm]);

val pr_is_abs_correct = store_thm(
  "pr_is_abs_correct",
  ``pr_is_abs [n] = nB (is_dABS (numdB n))``,
  SRW_TAC [][pr_is_abs_def, Once numdB_def] THEN
  `n MOD 3 < 3` by SRW_TAC [][MOD_LESS] THEN DECIDE_TAC);

val pr_bnf_def = Define`
  pr_bnf =
  prtermrec0 (K 1)
             (λl. let t1 = l ' 0 in
                  let r1 = l ' 2 in
                  let r2 = l ' 3
                  in
                    r1 * r2 * (1 - pr_is_abs [t1]))
             (proj 1)
`;

val primrec_pr_bnf = Store_thm(
  "primrec_pr_bnf",
  ``primrec pr_bnf 1``,
  SIMP_TAC (srw_ss()) [pr_bnf_def] THEN
  intro primrec_prtermrec0 THEN SRW_TAC [][primrec_rules] THEN
  SRW_TAC [][LET_THM] THEN
  intro2 `$*` THEN
  SRW_TAC [][i2 `$*`, prK] THEN
  intro2 `$-` THEN
  SRW_TAC [][prCn1, primrec_is_abs]);


val pr_bnf_correct = Store_thm(
  "pr_bnf_correct",
  ``pr_bnf [n] = nB (bnf (toTerm (numdB n)))``,
  `∃d. n = dBnum d` by METIS_TAC [dBnum_onto] THEN
  SRW_TAC [][pr_bnf_def, LET_THM] THEN
  Induct_on `d` THEN SRW_TAC [][pr_is_abs_correct, CONJ_ASSOC]);

val max_abs_def = Define`
  (max_abs (dV i) = 0) ∧
  (max_abs (dAPP t1 t2) = MAX (max_abs t1) (max_abs t2)) ∧
  (max_abs (dABS t) = 1 + max_abs t)
`;
val _ = export_rewrites ["max_abs_def"]

val primrec_MAX = Store_thm(
  "primrec_max",
  ``primrec (pr2 MAX) 2``,
  intro primrec_pr2 THEN
  Q.EXISTS_TAC `pr_cond (Cn pr_le [proj 0; proj 1]) (proj 1) (proj 0)` THEN
  SRW_TAC [][primrec_rules] THEN
  ASM_SIMP_TAC (srw_ss() ++ ARITH_ss) [MAX_DEF]);

val primrec_max_abs = Store_thm(
  "primrec_max_abs",
  ``primrec (pr1 (max_abs o numdB)) 1``,
  MATCH_MP_TAC primrec_pr1 THEN
  Q.EXISTS_TAC `prtermrec0 (K 0) (Cn (pr2 MAX) [proj 2; proj 3])
                               (Cn succ [proj 1])` THEN
  SRW_TAC [][] THENL [
    MATCH_MP_TAC primrec_prtermrec0 THEN SRW_TAC [][primrec_rules],
    `∃d. n = dBnum d` by METIS_TAC [dBnum_onto] THEN SRW_TAC [][] THEN
    Induct_on `d` THEN SRW_TAC [ARITH_ss][]
  ]);

(* ----------------------------------------------------------------------
    primitive recursive "lift"

    Recall the defining equations
       lift (dV i) k = if i < k then dV i else dV (i + 1)
       lift (dAPP s t) k = dAPP (lift s k) (lift t k)
       lift (dABS s) k = dABS (lift s (k + 1))
   ---------------------------------------------------------------------- *)

val maxf_def = Define`
  (maxf f 0 = f 0) ∧
  (maxf f (SUC n) = MAX (f (SUC n)) (maxf f n))
`;

val LE_maxf = store_thm(
  "LE_maxf",
  ``∀n m. m ≤ n ⇒ f m ≤ maxf f n``,
  Induct THEN SRW_TAC [][maxf_def] THEN
  `m ≤ n ∨ (m = SUC n)` by DECIDE_TAC THEN SRW_TAC [][]);

val primrec_maxf = Store_thm(
  "primrec_maxf",
  ``primrec (pr1 f) 1 ⇒ primrec (pr1 (maxf f)) 1``,
  STRIP_TAC THEN MATCH_MP_TAC primrec_pr1 THEN
  Q.EXISTS_TAC `
    Pr1 (f 0) (Cn (pr2 MAX) [Cn (pr1 f) [Cn succ [proj 0]]; proj 1])
  ` THEN CONJ_TAC THEN1 (MATCH_MP_TAC primrec_Pr1 THEN
                         SRW_TAC [][primrec_rules]) THEN
  Induct_on `n` THEN SRW_TAC [][maxf_def]);

val pr_lift_def = Define`
  pr_lift =
  (λns. let t = ns ' 0 in
        let k = ns ' 1 in
        let mx = pr1 (max_abs o numdB) [t] + k + 1
        in
          nel k
          (prtermrec1
             (λl. Pr (λl. let i = l ' 0
                          in
                            ncons (3 * (i + 1)) nnil)
                  (λl. let i = l ' 2 in
                       let k = l ' 0 + 1 in
                       let r = l ' 1
                       in
                         if ¬(k ≤ i) then napp r (ncons (3 * i) nnil)
                         else napp r (ncons (3 * (i + 1)) nnil))
                  [l ' 1; l ' 0])
             (λl. let t1 = l ' 0 in
                  let t2 = l ' 1 in
                  let r1 = l ' 2 in
                  let r2 = l ' 3 in
                  let gmx = l ' 4 in
                  let mx = MAX ((max_abs o numdB) t1) ((max_abs o numdB) t2)
                  in
                    Pr (λl. ncons
                              (3 * npair (nel 0 (l ' 0)) (nel 0 (l ' 1)) + 1)
                              nnil)
                       (λl. let r = l ' 1 in
                            let i = l ' 0 + 1 in
                            let rt1 = nel i (l ' 2) in
                            let rt2 = nel i (l ' 3)
                            in
                              napp r (ncons (3 * npair rt1 rt2 + 1) nnil))
                       [gmx - mx; r1; r2])
           (λl. let t = l ' 0 in
                let r = l ' 1 in
                let gmx = l ' 2 in
                let mx = (max_abs o numdB) t + 1
                in
                  Pr
                    (λl. ncons (3 * nel 1 (l ' 0) + 2) nnil)
                    (λl. let r = l ' 1 in
                         let i = l ' 0 + 2 in
                         let rt = nel i (l ' 2)
                         in
                           napp r (ncons (3 * rt + 2) nnil))
                    [gmx - mx; r])
           [t; mx]))
`;

val nsnd_le' = nsnd_le |> Q.INST [`n` |-> `x ⊗ y`]
                       |> SIMP_RULE (srw_ss()) []

val pr_lift_correct = Store_thm(
  "pr_lift_correct",
  ``pr_lift [tn; k] = dBnum (lift (numdB tn) k)``,
  SRW_TAC [][pr_lift_def] THEN
  `∃d. tn = dBnum d` by METIS_TAC [dBnum_onto] THEN
  SRW_TAC [][LET_THM] THEN FULL_SIMP_TAC (srw_ss()) [] THEN
  Q.MATCH_ABBREV_TAC `nel k (prtermrec1 v c a [dBnum d; mx]) =
                      dBnum (lift d k)` THEN
  Q_TAC SUFF_TAC `
    ∀d. max_abs d < mx ⇒
        (prtermrec1 v c a [dBnum d; mx] =
         nlist_of (GENLIST (λi. dBnum (lift d i)) (mx - max_abs d + 1)))
  ` THEN1 SRW_TAC [ARITH_ss][LENGTH_GENLIST, EL_GENLIST, nel_nlist_of,
                             Abbr`mx`] THEN
  Q.X_GEN_TAC `dd` THEN Induct_on `dd` THEN SRW_TAC [][] THENL [
    SRW_TAC [][Abbr`v`, NOT_LESS_EQUAL] THEN
    REPEAT (FIRST_X_ASSUM (K ALL_TAC)) THEN Induct_on `mx` THEN
    SRW_TAC [][GENLIST1, dBnum_def, ADD_CLAUSES, GENLIST, SNOC_APPEND,
               nlist_of_append],

    FULL_SIMP_TAC (srw_ss()) [] THEN Q.UNABBREV_TAC `c` THEN
    REPEAT (FIRST_X_ASSUM (K ALL_TAC)) THEN
    SRW_TAC [][] THEN
    Q.MATCH_ABBREV_TAC `Pr zf sf [M;
                                  nlist_of (GENLIST gf (ddn + 1));
                                  nlist_of (GENLIST gf' (ddn' + 1))] =
                        nlist_of (GENLIST gfr (M + 1))` THEN
    `M ≤ ddn ∧ M ≤ ddn'`
      by (MAP_EVERY Q.UNABBREV_TAC [`M`, `ddn`, `ddn'`] THEN
          SRW_TAC [ARITH_ss][MAX_DEF]) THEN
    MAP_EVERY markerLib.RM_ABBREV_TAC ["M", "ddn", "ddn'"] THEN
    Induct_on `M` THENL [
      SRW_TAC [ARITH_ss][nel_nlist_of, LENGTH_GENLIST, GENLIST1, Abbr`zf`,
                         dBnum_def, GENLIST_CONS, GSYM ADD1, Abbr`gf`,
                         Abbr`gf'`, Abbr`gfr`],
      REPEAT STRIP_TAC THEN
      FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [] THEN
      SRW_TAC [ARITH_ss]
              [Abbr`sf`, Abbr`gf`, Abbr`gf'`, Abbr`gfr`, ADD_CLAUSES,
               GENLIST, SNOC_APPEND, nlist_of_append, nel_nlist_of,
               LENGTH_GENLIST, EL_GENLIST, dBnum_def]
    ],

    FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [] THEN
    Q.UNABBREV_TAC `a` THEN markerLib.RM_ALL_ABBREVS_TAC THEN
    Q.PAT_ASSUM `prtermrec1 X Y Z L = FOO` (K ALL_TAC) THEN
    SRW_TAC [][] THEN
    Q.MATCH_ABBREV_TAC `Pr zf sf [M; nlist_of (GENLIST gf M1)] =
                        nlist_of (GENLIST gfr M2)` THEN
    `M2 = M + 1` by SRW_TAC [ARITH_ss][Abbr`M2`, Abbr`M`] THEN
    Q.RM_ABBREV_TAC `M2` THEN POP_ASSUM SUBST_ALL_TAC THEN
    `M + 2 ≤ M1` by SRW_TAC [ARITH_ss][Abbr`M`, Abbr`M1`] THEN
    Q.RM_ABBREV_TAC `M1` THEN
    Q.RM_ABBREV_TAC `M` THEN Induct_on `M` THEN
    SRW_TAC [ARITH_ss][Abbr`zf`, Abbr`sf`, Abbr`gf`, Abbr`gfr`] THENL [
      ASM_SIMP_TAC (bool_ss ++ ARITH_ss) [nel_nlist_of, LENGTH_GENLIST,
                                          EL_GENLIST, GENLIST1] THEN
      SRW_TAC [][dBnum_def],

      SRW_TAC [ARITH_ss][GENLIST, ADD_CLAUSES, dBnum_def, SNOC_APPEND,
                         nel_nlist_of, LENGTH_GENLIST, EL_GENLIST,
                         nlist_of_append]
    ]
  ]);

val primrec_not = Store_thm(
  "primrec_not",
  ``primrec (λl. nB (f l)) n ⇒ primrec (λl. nB (¬f l)) n``,
  STRIP_TAC THEN IMP_RES_TAC primrec_nzero THEN
  Q_TAC SUFF_TAC `(λl. nB (¬ f l)) = Cn (pr2 $-) [K 1; (λl. nB (f l))]`
  THEN1 SRW_TAC [][primrec_rules] THEN
  SRW_TAC [][FUN_EQ_THM]);

val primrec_le = Store_thm(
  "primrec_le",
  ``primrec f n ∧ primrec g n ⇒ primrec (λl. nB (f l ≤ g l)) n``,
  STRIP_TAC THEN IMP_RES_TAC primrec_nzero THEN
  Q_TAC SUFF_TAC `(λl. nB (f l ≤ g l)) = Cn pr_le [f; g]` THEN1
    SRW_TAC [][primrec_rules] THEN
  SRW_TAC [][FUN_EQ_THM]);

val prmxabs = SIMP_RULE (srw_ss()) [] (i1 `max_abs o numdB`)

val primrec_pr_lift = Store_thm(
  "primrec_pr_lift",
  ``primrec pr_lift 2``,
  SRW_TAC [][LET_THM, pr_lift_def] THEN
  intro2 `nel` THEN SRW_TAC [][] THEN
  intro prCn2 THEN SRW_TAC [][] THENL [
    MATCH_MP_TAC primrec_termrec THEN SRW_TAC [][] THENL [
      intro prCn2 THEN SRW_TAC [][] THEN
      MATCH_MP_TAC alt_Pr_rule THEN
      SRW_TAC [][i2 `ncons`, i2 `$+`, i2 `$*`] THEN
      intro prCOND THEN
      SRW_TAC [][combinTheory.o_ABS_R, i2 `napp`, i2 `$*`, i2 `ncons`, prpred]
      THENL [
        intro2 `napp` THEN
        SRW_TAC [][i2 `ncons`, i2 `$+`, i2 `$*`],
        SRW_TAC [][i2 `$+`]
      ],

      intro prCn3 THEN SRW_TAC [][] THENL [
        MATCH_MP_TAC alt_Pr_rule THEN SRW_TAC [][] THENL [
          intro2 `ncons` THEN SRW_TAC [][prK] THEN
          intro2 `$+` THEN
          SRW_TAC [][i2 `$+`, i2 `$*`, i2 `npair`, i2 `nel`],
          intro2 `napp` THEN SRW_TAC [][] THEN
          intro2 `ncons` THEN SRW_TAC [][] THEN
          intro2 `$+` THEN SRW_TAC [][] THEN
          intro2 `$*` THEN SRW_TAC [][] THEN
          SRW_TAC [][i2 `$+`, i2 `$*`, i2 `npair`, i2 `nel`]
        ],
        intro2 `$-` THEN SRW_TAC [][] THEN
        intro2 `MAX` THEN SRW_TAC [][] THEN
        SRW_TAC [][prmxabs]
      ],

      intro prCn2 THEN
      SRW_TAC [][prmxabs, i2 `$-`, i2 `$+`] THEN
      MATCH_MP_TAC alt_Pr_rule THEN SRW_TAC [][] THENL [
        intro2 `ncons` THEN
        SRW_TAC [][i2 `nel`, i2 `$*`, i2 `$+`],
        intro2 `napp` THEN SRW_TAC [][] THEN
        intro2 `ncons` THEN SRW_TAC [][] THEN
        intro2 `$+` THEN SRW_TAC [][] THEN
        SRW_TAC [][i2 `nel`, i2 `$+`, i2 `$*`]
      ]
    ],

    SRW_TAC [][prmxabs, i2 `$+`]
  ]);

val lift_larger = prove(
  ``∀t i. dBnum t ≤ dBnum (lift t i)``,
  Induct THEN SRW_TAC [][dBnum_def] THEN
  REPEAT (FIRST_X_ASSUM (Q.SPEC_THEN `i` MP_TAC)) THEN
  SRW_TAC [][LESS_EQ_LESS_EQ_MONO, npair_def]);

(* ----------------------------------------------------------------------
    de Bruijn Substitution à la Shankar, Huet and Nipkow:

      nsub s k (dV i) =
        if k < i then dV (i − 1) else if i = k then s else dV i

      nsub s k (dAPP t u) = dAPP (nsub s k t) (nsub s k u)

      nsub s k (dABS t) = dABS (nsub (lift s 0) (k + 1) t)
   ---------------------------------------------------------------------- *)

val primrec_FUNPOW = Store_thm(
  "primrec_FUNPOW",
  ``primrec (pr1 f) 1 ∧ primrec g n ∧ primrec cf n ⇒
    primrec (λl. FUNPOW f (cf l) (g l)) n``,
  STRIP_TAC THEN IMP_RES_TAC primrec_nzero THEN
  Q_TAC SUFF_TAC `(λl. FUNPOW f (cf l) (g l)) =
                  (λl. Pr (proj 0) (Cn (pr1 f) [proj 1]) [cf l; g l])`
  THEN1 (SRW_TAC [][] THEN MATCH_MP_TAC prCn2 THEN
         SRW_TAC [][primrec_rules]) THEN
  SRW_TAC [][FUN_EQ_THM] THEN
  Q.ABBREV_TAC `m = cf l` THEN Q.RM_ABBREV_TAC `m` THEN
  Induct_on `m` THEN1 SRW_TAC [][FUNPOW] THEN
  SRW_TAC [][FUNPOW_SUC]);

val scopesz_def = Define`
  scopesz sk t = let s = nfst sk in
                 let k = nsnd sk in
                 let mxa = max_abs (numdB t) in
                 let mxs = FUNPOW (λt. dBnum (lift (numdB t) 0)) mxa s in
                 let mxk = k + mxa
                 in
                   mxs ⊗ mxk
`;


val pr_nsub_def = Define`
  pr_nsub =
  (λns. let s = ns ' 0 in
        let k = ns ' 1 in
        let t = ns ' 2 in
        let gmx = scopesz (s ⊗ k) t + s ⊗ k + 20
        in
          nel (s ⊗ k)
              (prtermrec1
                 (λvs. let i = vs ' 0 in
                       let gmx = nsnd (vs ' 1) in
                       let sk = nfst (vs ' 1)
                       in
                         Pr (λzs. let i = zs ' 0
                                  in
                                    if i = 0 then ncons 0 0
                                    else if 0 ≤ i then ncons (3 * (i - 1)) 0
                                    else ncons (3 * i) 0)
                            (λss. let n = ss ' 0 + 1 in
                                  let s = nfst n in
                                  let k = nsnd n in
                                  let rs = ss ' 1 in
                                  let i = ss ' 2 in
                                  let r = if i = k then s
                                          else if k ≤ i then 3 * (i - 1)
                                          else 3 * i
                                  in
                                    napp rs (ncons r nnil))
                            [gmx - sk; i])
                 (λcs. let t1 = cs ' 0 in
                       let t2 = cs ' 1 in
                       let r1s = cs ' 2 in
                       let r2s = cs ' 3 in
                       let sk = nfst (cs ' 4) in
                       let gmx = nsnd (cs ' 4) in
                       let mx = scopesz sk (3 * (t1 ⊗ t2) + 1)
                       in
                         Pr
                           (λzs.
                              ncons (3 * nel 0 (zs ' 0) ⊗ nel 0 (zs ' 1) + 1)
                                    0)
                           (λss. let i = ss ' 0 + 1 in
                                 let r = ss ' 1 in
                                 let r1 = nel i (ss ' 2) in
                                 let r2 = nel i (ss ' 3)
                                 in
                                   napp r (ncons (3 * (r1 ⊗ r2) + 1) 0))
                           [gmx - mx; r1s; r2s])
                 (λabs. let t = abs ' 0 in
                        let rs = abs ' 1 in
                        let sk = nfst (abs ' 2) in
                        let gmx = nsnd (abs ' 2) in
                        let mx = scopesz sk (3 * t + 2)
                        in
                          Pr (λzs.
                                ncons (3 * nel (3 ⊗ 1) rs + 2) 0)
                             (λss. let sk = ss ' 0 + 1 in
                                   let r = ss ' 1 in
                                   let rs = ss ' 2 in
                                   let s = nfst sk in
                                   let k = nsnd sk in
                                   let j = pr_lift [s; 0] ⊗ (k + 1) in
                                   let recresult = nel j rs
                                   in
                                     napp r (ncons (3 * recresult + 2) 0))
                             [gmx - mx; rs])
                 [t; (s ⊗ k) ⊗ gmx]))
`;

val npair_le_mono = store_thm(
  "npair_le_mono",
  ``x ≤ y ∧ a ≤ b ⇒ x ⊗ a ≤ y ⊗ b``,
  SRW_TAC [][npair_def, LESS_EQ_LESS_EQ_MONO]);

val npair_lt_mono = store_thm(
  "npair_lt_mono",
  ``x < y ∧ a ≤ b ∨ x ≤ y ∧ a < b ⇒ x ⊗ a < y ⊗ b``,
  SRW_TAC [ARITH_ss][LESS_OR_EQ] THEN
  SRW_TAC [][npair_def] THENL [
    `tri (x + a) ≤ tri (y + b)` by SRW_TAC [ARITH_ss][] THEN
    DECIDE_TAC,
    `tri (x + a) ≤ tri (y + b)` by SRW_TAC [ARITH_ss][] THEN
    DECIDE_TAC,
    `tri (x + a) ≤ tri (x + b)` by SRW_TAC [ARITH_ss][] THEN
    DECIDE_TAC
  ]);

val funpow_le = prove(
  ``(∀x. x ≤ f x) ∧ m ≤ n ⇒ FUNPOW f m x ≤ FUNPOW f n x``,
  STRIP_TAC THEN
  `n = n - m + m` by DECIDE_TAC THEN
  POP_ASSUM SUBST1_TAC THEN
  REWRITE_TAC [FUNPOW_ADD] THEN
  Q.ABBREV_TAC `X = FUNPOW f m x` THEN
  Q.ABBREV_TAC `N = n - m` THEN
  markerLib.RM_ALL_ABBREVS_TAC THEN Q.ID_SPEC_TAC `X` THEN Induct_on `N` THEN
  SRW_TAC [][] THEN SRW_TAC [][FUNPOW_SUC] THEN
  MATCH_MP_TAC LESS_EQ_TRANS THEN Q.EXISTS_TAC `FUNPOW f N X` THEN
  SRW_TAC [][]);

val scopesz_lt0 = prove(
  ``scopesz sk (dBnum d1) ≤ scopesz sk (dBnum (dAPP d1 d2)) ∧
    scopesz sk (dBnum d2) ≤ scopesz sk (dBnum (dAPP d1 d2))``,
  SRW_TAC [][scopesz_def, LET_THM, dBnum_def] THEN
  MATCH_MP_TAC npair_le_mono THEN SRW_TAC [][] THEN
  MATCH_MP_TAC funpow_le THEN SRW_TAC [][] THEN
  Q.SPEC_THEN `numdB x` MP_TAC lift_larger THEN SRW_TAC [][]);

val scopesz_lt1 = prove(
  ``scopesz sk (dBnum (dAPP d1 d2)) ≤ M ⇒
      scopesz sk (dBnum d1) ≤ M ∧ scopesz sk (dBnum d2) ≤ M``,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC LESS_EQ_TRANS THEN
  Q.EXISTS_TAC `scopesz sk (dBnum (dAPP d1 d2))` THEN
  SRW_TAC [][scopesz_lt0]);

val _ = temp_overload_on (
  "sklift",
  ``λn. dBnum (lift (numdB (nfst n)) 0) ⊗ (nsnd n + 1)``);

val scopesz_lt2 = prove(
  ``scopesz sk (dBnum d) < scopesz sk (dBnum (dABS d))``,
  SRW_TAC [][scopesz_def, LET_THM, dBnum_def] THEN
  MATCH_MP_TAC (GEN_ALL npair_lt_mono) THEN
  SRW_TAC [ARITH_ss][] THEN DISJ2_TAC THEN
  MATCH_MP_TAC funpow_le THEN SRW_TAC [][] THEN
  Q.SPEC_THEN `numdB x` MP_TAC lift_larger THEN SRW_TAC [][]);

val tri_sub1 = prove(
  ``(tri (n + 1) - tri n = n + 1) ∧
    (tri (SUC n) - tri n = SUC n)``,
  SRW_TAC [][tri_def, GSYM ADD1]);

val SUBSET_FINITE_I =
    SIMP_RULE (srw_ss() ++ boolSimps.DNF_ss) [AND_IMP_INTRO]
              pred_setTheory.SUBSET_FINITE

val _ = temp_add_rule {fixity = Closefix,
                  term_name = "lterange",
                  block_style = (AroundEachPhrase, (PP.INCONSISTENT, 2)),
                  paren_style = OnlyIfNecessary,
                  pp_elements = [TOK "{", HardSpace 1, TM, BreakSpace(1,0),
                                 TOK "<..", BreakSpace(1,0), TM, HardSpace 1,
                                 TOK "}"]}
val _ = overload_on ("lterange", ``λm n. { i | m < i ∧ i ≤ n}``)

val tri_sub = prove(
  ``tri n - tri m = SUM_SET { m <.. n }``,
  Induct_on `n` THEN SRW_TAC [][] THEN
  SRW_TAC [boolSimps.CONJ_ss][pred_setTheory.SUM_SET_THM] THEN
  SRW_TAC [][tri_def] THEN
  Cases_on `m ≤ n` THENL [
    `{ m <.. SUC n} = (SUC n) INSERT { m <.. n}`
       by SRW_TAC [ARITH_ss][pred_setTheory.EXTENSION] THEN
    POP_ASSUM SUBST1_TAC THEN
    `FINITE { m <.. n}`
       by (MATCH_MP_TAC SUBSET_FINITE_I THEN Q.EXISTS_TAC `count (n + 1)` THEN
           SRW_TAC [ARITH_ss][pred_setTheory.SUBSET_DEF,
                              pred_setTheory.FINITE_COUNT,
                              pred_setTheory.IN_COUNT]) THEN
    SRW_TAC [][pred_setTheory.SUM_SET_THM] THEN
    `SUC n ∉ {m <.. n}` by SRW_TAC [][] THEN
    FULL_SIMP_TAC (srw_ss()) [pred_setTheory.DELETE_NON_ELEMENT] THEN
    `tri m ≤ tri n` by SRW_TAC [ARITH_ss][] THEN
    DECIDE_TAC,

    `{ m <.. SUC n} = {}`
       by SRW_TAC [ARITH_ss][pred_setTheory.EXTENSION] THEN
    `SUC n ≤ m` by DECIDE_TAC THEN
    `tri (SUC n) ≤ tri m` by SRW_TAC [][] THEN
    POP_ASSUM MP_TAC THEN REWRITE_TAC [tri_def] THEN
    SRW_TAC [ARITH_ss][pred_setTheory.SUM_SET_THM]
  ]);

val npair_subx = prove(
  ``x₁ ⊗ y - x₂ ⊗ y = SUM_SET {x₂ + y <.. x₁ + y}``,
  SRW_TAC [][npair_def] THEN
  `∀x y z. (x + y) - (z + y) = x - z` by DECIDE_TAC THEN
  SRW_TAC [][tri_sub]);

val npair_suby = prove(
  ``x ⊗ y₁ - x ⊗ y₂ = SUM_SET { x + y₂ <.. x + y₁ } + (y₁ - y₂)``,
  SRW_TAC [][npair_def] THEN
  Cases_on `y₂ ≤ y₁` THENL [
    `tri (x + y₂) ≤ tri (x + y₁)` by SRW_TAC [][] THEN
    `tri (x + y₁) - tri (x + y₂) = SUM_SET { x + y₂ <.. x + y₁ }`
       by SRW_TAC [][tri_sub] THEN
    DECIDE_TAC,
    `¬(tri (x + y₂) ≤ tri (x + y₁))` by SRW_TAC [][] THEN
    `{ x + y₂ <.. x + y₁ } = {}` by
       SRW_TAC [ARITH_ss][pred_setTheory.EXTENSION] THEN
    SRW_TAC [ARITH_ss][pred_setTheory.SUM_SET_THM]
  ]);

val npair_sub = prove(
  ``a ≤ x ∧ b ≤ y ⇒ (x ⊗ y − a ⊗ b = SUM_SET { a + b <.. x + y } + (y - b))``,
  SRW_TAC [][npair_def] THEN
  `tri (a + b) ≤ tri (x + y)` by SRW_TAC [ARITH_ss][] THEN
  Q.MATCH_ABBREV_TAC `LHS = RHS` THEN
  `LHS = (tri (x + y) − tri (a + b)) + (y - b)`
     by SRW_TAC [ARITH_ss][Abbr`LHS`] THEN
  markerLib.UNABBREV_ALL_TAC THEN SRW_TAC [][tri_sub])

val FINITE_rangelte = prove(
  ``FINITE { x <.. y }``,
  MATCH_MP_TAC SUBSET_FINITE_I THEN Q.EXISTS_TAC `count (y + 1)` THEN
  SRW_TAC [ARITH_ss]
          [pred_setTheory.FINITE_COUNT, pred_setTheory.SUBSET_DEF,
           pred_setTheory.IN_COUNT]);

val SUM_SET_range_removetop = prove(
  ``lo < hi ⇒ (SUM_SET { lo <.. hi } = hi + SUM_SET { lo <.. (hi − 1)})``,
  STRIP_TAC THEN
  `({ lo <.. hi } = hi INSERT { lo <.. hi − 1 }) ∧ hi ∉ { lo <.. hi − 1 }`
     by SRW_TAC [ARITH_ss][pred_setTheory.EXTENSION] THEN
  SRW_TAC [][pred_setTheory.SUM_SET_THM, FINITE_rangelte] THEN
  FULL_SIMP_TAC (srw_ss()) [pred_setTheory.DELETE_NON_ELEMENT]);

val CARD_rangelte = prove(
  ``CARD { x <.. y } = y − x``,
  Induct_on `y` THEN1 SRW_TAC [ARITH_ss, boolSimps.CONJ_ss][] THEN
  Cases_on `x < SUC y` THENL [
    `{x <.. SUC y} = SUC y INSERT {x <.. y}`
       by SRW_TAC [ARITH_ss][pred_setTheory.EXTENSION] THEN
    `SUC y ∉ {x <.. y}` by SRW_TAC [][pred_setTheory.EXTENSION] THEN
    SRW_TAC [ARITH_ss][FINITE_rangelte],

    `{x <.. SUC y} = {}` by SRW_TAC [ARITH_ss][pred_setTheory.EXTENSION] THEN
    SRW_TAC [ARITH_ss][]
  ]);

val rangelte_empty = prove(
  ``hi ≤ lo ⇒ ({ lo <.. hi } = {})``,
  SRW_TAC [ARITH_ss][pred_setTheory.EXTENSION]);

val rangelte0 = prove(
  ``{ lo <.. 0 } = {}``,
  SRW_TAC [][rangelte_empty]);

val SUM_SET_extract = prove(
  ``SUM_SET { x + y <.. x + z } = (z - y) * x + SUM_SET {y <.. z}``,
  Induct_on `z` THEN1 SRW_TAC [][rangelte_empty] THEN
  Cases_on `SUC z ≤ y` THEN1
    SRW_TAC [ARITH_ss][rangelte_empty, pred_setTheory.SUM_SET_THM] THEN
  `y < SUC z ∧ x + y < x + SUC z` by DECIDE_TAC THEN
  SRW_TAC [(* put ARITH_ss here for BAD PERF *)]
          [SUM_SET_range_removetop,
           DECIDE ``x + SUC y − 1 = x + y``] THEN
  `x * y ≤ x * z` by SRW_TAC [ARITH_ss][] THEN
  SRW_TAC [ARITH_ss][LEFT_SUB_DISTRIB, MULT_CLAUSES]);

val SUM_SET_0arg1 = prove(
  ``SUM_SET { 0 <.. n } = tri n``,
  Induct_on `n` THEN
  SRW_TAC [][tri_def, pred_setTheory.SUM_SET_THM,
             rangelte_empty, SUM_SET_range_removetop]);

val _ = temp_overload_on ("sknlift",
                          ``FUNPOW (λt. dBnum (lift (numdB t) 0))``)

val scopesz_sub = prove(
  ``scopesz sk (dBnum (dABS d)) - scopesz sk (dBnum d) =
    SUM_SET {
      max_abs d + nsnd sk + sknlift (max_abs d) (nfst sk) <..
      max_abs d + nsnd sk + sknlift (max_abs d + 1) (nfst sk) + 1} + 1``,
  SRW_TAC [][scopesz_def, LET_THM, dBnum_def] THEN
  `sknlift (max_abs d) (nfst sk) ≤ sknlift (1 + max_abs d) (nfst sk)`
    by (MATCH_MP_TAC funpow_le THEN SRW_TAC [ARITH_ss][] THEN
        Q.SPEC_THEN `numdB x` MP_TAC lift_larger THEN SRW_TAC [][]) THEN
  SRW_TAC [ARITH_ss][npair_sub]);

val nfstsnd0 = Store_thm(
  "nfstsnd0",
  ``(nfst 0 = 0) ∧ (nsnd 0 = 0)``,
  METIS_TAC [nfst_le, nsnd_le, DECIDE ``x ≤ 0 ⇔ (x = 0)``])

val sknlift_0 = prove(
  ``sknlift n 0 = 3 * n``,
  Induct_on `n` THEN1 SRW_TAC [][FUNPOW] THEN
  SRW_TAC [][FUNPOW_SUC] THEN
  SRW_TAC [ARITH_ss][Once numdB_def, DIV3_thm, MOD3_thm, dBnum_def]);

val SUM_SET_range_lowerbound = prove(
  ``lo < hi ⇒ hi ≤ SUM_SET { lo <.. hi}``,
  SRW_TAC [][SUM_SET_range_removetop]);

val sknlift_le = prove(
  ``t ≤ sknlift n t``,
  Induct_on `n` THEN1 SRW_TAC [][] THEN
  SRW_TAC [][FUNPOW_SUC] THEN MATCH_MP_TAC LESS_EQ_TRANS THEN
  Q.EXISTS_TAC `sknlift n t` THEN SRW_TAC [][] THEN
  METIS_TAC [lift_larger, dBnumdB]);

val sknlift_notle = prove(
  ``y < x ⇒ ¬(sknlift n x ≤ y)``,
  REPEAT STRIP_TAC THEN
  `x ≤ sknlift n x` by SRW_TAC [][sknlift_le] THEN
  DECIDE_TAC);

val sknlift_le10 = prove(
  ``sknlift (n + 1) t ≤ 10 ⇔
      (t = 0) ∧ n < 3 ∨ (t = 2) ∨ (t = 3) ∧ n < 2 ∨
      (t = 5) ∨ (t = 6) ∧ (n = 0) ∨ (t = 8)``,
  EQ_TAC THENL [
    STRIP_TAC THEN
    `t ≤ 10` by (MATCH_MP_TAC LESS_EQ_TRANS THEN
                 Q.EXISTS_TAC `sknlift (n + 1) t` THEN
                 SRW_TAC [][sknlift_le]) THEN
    `t ∈ count 11` by SRW_TAC [ARITH_ss][pred_setTheory.IN_COUNT] THEN
    ASSUME_TAC (EVAL ``count 11``) THEN
    MAP_EVERY (fn n => ASSUME_TAC (EVAL
     ``dBnum (lift (numdB ^(numSyntax.mk_numeral (Arbnum.fromInt n))) 0)``))
              [10,9,7,6,4,3,1] THEN
    FULL_SIMP_TAC (srw_ss()) [] THEN
    FULL_SIMP_TAC (srw_ss()) [GSYM ADD1, sknlift_0, FUNPOW, sknlift_notle]
    THENL [
      Cases_on `n` THEN SRW_TAC [][] THEN
      FULL_SIMP_TAC (srw_ss()) [FUNPOW, sknlift_notle],
      Cases_on `n` THEN
      FULL_SIMP_TAC (srw_ss()) [FUNPOW] THEN
      Cases_on `n'` THEN
      FULL_SIMP_TAC (srw_ss()) [FUNPOW, sknlift_notle],

      `3 * SUC n < 12` by DECIDE_TAC THEN
      `12 = 3 * 4` by SRW_TAC [][] THEN
      `SUC n < 4` by METIS_TAC [LT_MULT_LCANCEL] THEN
      DECIDE_TAC
    ],

    SRW_TAC [][] THENL [
      `(n = 0) ∨ (n = 1) ∨ (n = 2)` by DECIDE_TAC THEN
      SRW_TAC [][] THEN EVAL_TAC,

      Q_TAC SUFF_TAC `∀n. sknlift n 2 = 2` THEN1 SRW_TAC [][] THEN
      Induct THEN1 EVAL_TAC THEN SRW_TAC [][FUNPOW_SUC] THEN EVAL_TAC,

      `(n = 0) ∨ (n = 1)` by DECIDE_TAC THEN SRW_TAC [][] THEN
      EVAL_TAC,

      Q_TAC SUFF_TAC `∀n. sknlift n 5 = 5` THEN1 SRW_TAC [][] THEN
      Induct THEN1 EVAL_TAC THEN SRW_TAC [][FUNPOW_SUC] THEN EVAL_TAC,

      EVAL_TAC,

      Q_TAC SUFF_TAC `∀n. sknlift n 8 = 8` THEN1 SRW_TAC [][] THEN
      Induct THEN1 EVAL_TAC THEN SRW_TAC [][FUNPOW_SUC] THEN EVAL_TAC
    ]
  ]);

(*val pr_nsub_correct = Store_thm(
  "pr_nsub_correct",
  ``pr_nsub [s; k; t] = dBnum (nsub (numdB s) k (numdB t))``,
  SRW_TAC [][pr_nsub_def] THEN
  `∃d. t = dBnum d` by METIS_TAC [dBnum_onto] THEN
  SRW_TAC [][LET_THM] THEN FULL_SIMP_TAC (srw_ss()) [] THEN
  Q.MATCH_ABBREV_TAC `nel (s ⊗ k) (prtermrec1 v c a [dBnum d; (s ⊗ k) ⊗ gmx]) =
                      dBnum (nsub (numdB s) k d)` THEN
  Q_TAC SUFF_TAC `
    ∀dd. scopesz (s ⊗ k) (dBnum dd) ≤ scopesz (s ⊗ k) (dBnum d) ⇒
         (prtermrec1 v c a [dBnum dd; (s ⊗ k) ⊗ gmx] =
          nlist_of (GENLIST (λi. dBnum (nsub (numdB (nfst i)) (nsnd i) dd))
                            (gmx - scopesz (s ⊗ k) (dBnum dd) + 1)))
  ` THEN1 SRW_TAC [ARITH_ss][LENGTH_GENLIST, EL_GENLIST, nel_nlist_of,
                             Abbr`gmx`] THEN
  Induct_on `dd` THEN SRW_TAC [][] THENL [
    SRW_TAC [][Abbr`v`] THEN
    SRW_TAC [][scopesz_def, LET_THM] THEN
    Q.MATCH_ABBREV_TAC `Pr zf sf [M; n] = nlist_of (GENLIST gf (M + 1))` THEN
    MAP_EVERY Q.RM_ABBREV_TAC [`M`, `a`, `c`, `gmx`] THEN
    Induct_on `M` THEN
    SRW_TAC [ARITH_ss][Abbr`zf`, Abbr`sf`, Abbr`gf`, dBnum_def, GENLIST1]
    THENL [
      Q.PAT_ASSUM `Pr ZZ SS LL = RR` (K ALL_TAC) THEN
      SRW_TAC [][ADD_CLAUSES, GENLIST, SNOC_APPEND, nlist_of_append],

      Q.PAT_ASSUM `Pr ZZ SS LL = RR` (K ALL_TAC) THEN
      SRW_TAC [][ADD_CLAUSES, GENLIST, SNOC_APPEND, nlist_of_append,
                 dBnum_def] THEN DECIDE_TAC,

      Q.PAT_ASSUM `Pr ZZ SS LL = RR` (K ALL_TAC) THEN
      SRW_TAC [][ADD_CLAUSES, GENLIST, SNOC_APPEND, nlist_of_append,
                 dBnum_def] THEN DECIDE_TAC
    ],

    MAP_EVERY Q.RM_ABBREV_TAC [`v`, `a`] THEN
    `scopesz (s ⊗ k) (dBnum dd) ≤ scopesz (s ⊗ k) (dBnum (dAPP dd dd')) ∧
     scopesz (s ⊗ k) (dBnum dd') ≤ scopesz (s ⊗ k) (dBnum (dAPP dd dd'))`
       by SRW_TAC [][scopesz_lt0] THEN
    FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [] THEN
    SRW_TAC [][Abbr`c`] THEN
    REPEAT (Q.PAT_ASSUM `prtermrec1 VV CC AA LL = RR` (K ALL_TAC)) THEN
    `3 * (dBnum dd ⊗ dBnum dd') + 1 = dBnum (dAPP dd dd')`
      by SRW_TAC [][dBnum_def] THEN
    Q.MATCH_ABBREV_TAC `Pr zf sf [M; nlist_of (GENLIST gf1 M1);
                                  nlist_of (GENLIST gf2 M2)] =
                        nlist_of (GENLIST gfr M3)` THEN
    `M3 = M + 1` by SRW_TAC [ARITH_ss][Abbr`M3`, Abbr`M`] THEN
    Q.RM_ABBREV_TAC `M3` THEN POP_ASSUM SUBST_ALL_TAC THEN
    `M < M1 ∧ M < M2 ∧ 0 < M1 ∧ 0 < M2`
      by SRW_TAC [ARITH_ss][Abbr`M`, Abbr`M1`, Abbr`M2`] THEN
    MAP_EVERY Q.RM_ABBREV_TAC [`M`, `M1`, `M2`] THEN
    Induct_on `M` THEN
    SRW_TAC [][Abbr`gf1`, Abbr`gf2`, Abbr`gfr`, Abbr`zf`, Abbr`sf`] THENL [
      ASM_SIMP_TAC bool_ss [nel_nlist_of, LENGTH_GENLIST, EL_GENLIST] THEN
      SRW_TAC [][GENLIST1, dBnum_def],

      FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [] THEN
      Q.PAT_ASSUM `Pr ZZ FF LL = RR` (K ALL_TAC) THEN
      SRW_TAC [ARITH_ss][GENLIST, ADD_CLAUSES, nel_nlist_of, LENGTH_GENLIST,
                         EL_GENLIST, SNOC_APPEND, nlist_of_append, dBnum_def]
    ],

    MAP_EVERY Q.RM_ABBREV_TAC [`v`, `c`] THEN
    `scopesz (s ⊗ k) (dBnum dd) < scopesz (s ⊗ k) (dBnum (dABS dd))`
       by SRW_TAC [][scopesz_lt2] THEN
    FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [] THEN
    SRW_TAC [][Abbr`a`] THEN
    Q.PAT_ASSUM `pretermrec1 VV CC AA LL = RR` (K ALL_TAC) THEN
    Q.MATCH_ABBREV_TAC `Pr zf sf [M; nlist_of (GENLIST gf M1)] =
                        nlist_of (GENLIST gfr M2)` THEN
    `3 * dBnum dd + 2 = dBnum (dABS dd)` by SRW_TAC [][dBnum_def] THEN
    FULL_SIMP_TAC (srw_ss()) [] THEN POP_ASSUM (K ALL_TAC) THEN
    `M2 = M + 1` by SRW_TAC [ARITH_ss][Abbr`M`, Abbr`M2`] THEN
    Q.RM_ABBREV_TAC `M2` THEN POP_ASSUM SUBST_ALL_TAC THEN
    `3 ⊗ 1 < M1`
      by SRW_TAC [ARITH_ss][Abbr`M1`, Abbr`gmx`, EVAL ``3 ⊗ 1``] THEN
    Q.RM_ABBREV_TAC `M1` THEN
    Q.RM_ABBREV_TAC `M` THEN Induct_on `M` THENL [
      SRW_TAC [][Abbr`zf`, Abbr`gf`, Abbr`gfr`, GENLIST1] THEN
      SRW_TAC [][Once numdB_def, SimpRHS] THEN
      SRW_TAC [][dBnum_def] THEN
      SRW_TAC [][nel_nlist_of, LENGTH_GENLIST, EL_GENLIST] THEN
      SRW_TAC [][Once numdB_def],

      SRW_TAC [][Abbr`sf`, Abbr`gf`, Abbr`gfr`] THEN
      Q.PAT_ASSUM `Pr ZZ SS LL = RR` (K ALL_TAC) THEN
      SRW_TAC [][ADD_CLAUSES, GENLIST, SNOC_APPEND, nlist_of_append]












      SRW_TAC [][GENLIST1, dBnum_def, nfst0] THEN FULL_SIMP_TAC (srw_ss()) [dBnum_def]


val primrec_pr_nsub = Store_thm(
  "primrec_pr_nsub",
  ``primrec pr_nsub 3``,
  SRW_TAC [][LET_THM, pr_nsub_def] THEN intro2 `npair` THEN
  SRW_TAC [][prmxabs] THEN intro primrec_FUNPOW THEN
  SRW_TAC [][prmxabs] THEN intro primrec_pr1 THEN
  Q.EXISTS_TAC `Cn pr_lift [proj 0; K 0]` THEN SRW_TAC [][primrec_rules]);
*)
val _ = export_theory()
