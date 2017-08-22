(* =========================================================================  *)
(* FILE          : hhsFeature.sml                                             *)
(* DESCRIPTION   : Features for machine learning on terms                     *)
(* AUTHOR        : (c) Thibault Gauthier, University of Innsbruck             *)
(* DATE          : 2017                                                       *)
(* ========================================================================== *)

structure hhsFeature :> hhsFeature =
struct

open HolKernel boolLib Abbrev hhsTools

val ERR = mk_HOL_ERR "hhsFeature"

val hhs_hofea_flag = ref true
(* top features are slow to produce and print *)
val hhs_notopfea_flag = ref true 
  
fun size_of_term t =
       if is_abs t
    then let val (v,t') = dest_abs t in 1 + size_of_term t' end
  else if is_comb t
    then let val (t1,t2) = dest_comb t in size_of_term t1 + size_of_term t2 end
  else if is_var t orelse is_const t
    then 1
  else raise ERR "size_of_term" ""

fun gen_all t = list_mk_forall ((free_vars_lr t),t)

(* ----------------------------------------------------------------------
   Extracting features of a term
   ---------------------------------------------------------------------- *)

val (atoml: term list ref) = ref []
val (atoml_top: term list ref) = ref []

fun atoms tm = 
  (
  atoml_top := tm :: !atoml_top;
  if is_var tm orelse is_const tm then atoml := tm :: (!atoml)
  else if is_eq tm  then 
    (atoms (lhs tm); atoms (rhs tm))
  else if is_conj tm orelse is_disj tm orelse is_imp_only tm then
    (atoms (lhand tm); atoms (rand tm))
  else if is_neg tm      then atoms  (rand tm)
  else if is_forall tm   then binder (dest_forall tm)
  else if is_exists tm   then binder (dest_exists tm)
  else if is_abs tm      then atoml := tm :: (!atoml)
  else if is_comb tm     then atoml := tm :: (!atoml)
  else raise ERR "atoms" ""
  )
and binder (_,tm) = atoms tm

fun atoms_of_term tm = 
  (atoml_top := []; atoml := []; atoms tm; (!atoml, !atoml_top))

val (subterml: term list ref) = ref []

fun subterms tm =
  (
  subterml := tm :: (!subterml);
  if is_var tm orelse is_const tm then () 
  else if is_comb tm then
    if !hhs_hofea_flag then
      (subterms (rand tm); subterms (rator tm))
    else
      let val (oper,argl) = strip_comb tm in
        app subterms (oper :: argl)
      end
  else if is_abs tm then
    subterms (snd (dest_abs tm))
  else raise ERR "subterms" ""
  )

fun subterms_of_term tm = 
  (subterml := []; subterms tm; !subterml)

fun all_types tm =
  let val l = find_terms (fn x => is_const x orelse is_var x) tm in
    map type_of l
  end

fun zeroed_type ty =
  if is_vartype ty then ["T"]
  else
    let 
      val {Args,Thy,Tyop} = dest_thy_type ty
      val s = Thy ^ "." ^ Tyop ^ ".t"
    in
      if null Args then [s]
      else s :: (List.concat (map zeroed_type Args))
    end

fun string_of_const tm =
  let val {Thy,Name,Ty} = dest_thy_const tm in
    Thy ^ "." ^ Name ^ ".c"
  end


fun zeroed_term tm =
  if is_var tm then "A"
  else if is_const tm then string_of_const tm
  else if is_comb tm then
    "(" ^ zeroed_term (rator tm) ^ " " ^ zeroed_term (rand tm) ^ ")"
  else if is_abs tm then
    let val (v,t) = dest_abs tm in
      "(Abs " ^ zeroed_term t ^ ")"
    end
  else raise ERR "zeroed_term" ""

val top_sl : string list ref = ref []

fun string_of_top tm =
  if is_var tm then "P"
  else if is_const tm then 
    let val {Thy,Name,Ty} = dest_thy_const tm in
      Thy ^ "." ^ Name ^ ".c"
    end
  else if is_eq tm  then
    ("(Eq " ^ string_of_top (lhs tm) ^ " " ^ string_of_top (rhs tm) ^ ")")
  else if is_conj tm then
    (
    top_sl := "Conj" :: !top_sl;
    ("(Conj " ^ string_of_top (lhand tm) ^ " " ^ string_of_top (rand tm) ^ ")")
    )
  else if is_disj tm then 
    (
    top_sl := "Disj" :: !top_sl;
    ("(Disj " ^ string_of_top (lhand tm) ^ " " ^ string_of_top (rand tm) ^ ")")
    )
  else if is_imp_only tm then
    (
    top_sl := "Imp" :: !top_sl;
    ("(Imp " ^ string_of_top (lhand tm) ^ " " ^ string_of_top (rand tm) ^ ")")
    )
  else if is_neg tm      then 
    (
   top_sl := "Neg" :: !top_sl;
    ("(Neg " ^ string_of_top (rand tm) ^ ")")
    )
  else if is_forall tm   then binder_top "Forall" (dest_forall tm)
  else if is_exists tm   then binder_top "Exists" (dest_exists tm)
  else if is_abs tm      then "P"
  else if is_comb tm     then "P"
  else raise ERR "atoms" ""
and binder_top s (v,tm) = 
  (
  top_sl := s :: !top_sl;
   "(" ^ s ^ " " ^ string_of_top tm ^ ")"
  )

fun fea_of_term tm =
  if size_of_term tm > 2000
  then
    let 
      val constl         = find_terms is_const tm
      val const_sl       = map string_of_const constl
    in
      mk_string_set const_sl
    end
  else
    let 
      val varl           = find_terms is_var tm
      val varl_sl        = map (fst o dest_var) varl
      val constl         = find_terms is_const tm
      val const_sl       = map string_of_const constl
      val typel          = all_types tm
      val type_sl        = List.concat (map zeroed_type typel)
      val (tml, top_tml) = atoms_of_term tm
      val top_tml'       = if !hhs_notopfea_flag then [] else top_tml
      val _              = top_sl := []
      val toptml_sl      = map string_of_top top_tml' (* modifies top_sl *)
      val subterml       = List.concat (map subterms_of_term tml)
      val subterm_sl     = map zeroed_term subterml
    in
      filter (fn x => x <> "P" andalso 
                      x <> "A" andalso
                      x <> "T") 
      (mk_string_set 
         (type_sl @ varl_sl @ const_sl @ (!top_sl) @ toptml_sl @ subterm_sl))
    end

(*---------------------------------------------------------------------------
 * Produce goal features.
 *---------------------------------------------------------------------------*)

fun string_of_goal (asl,w) =
  String.concatWith "\n" (map term_to_string (w :: asl))

fun fea_of_goal (asl,w) = 
  let 
    val asl_sl1 = List.concat (map fea_of_term asl)
    val asl_sl2 = map (fn x => x ^ ".h") asl_sl1
    val w_sl   = map (fn x => x ^ ".w") (fea_of_term w)
  in
    mk_string_set (w_sl @ asl_sl2)
  end
  handle _ => raise ERR "fea_of_goal" (string_of_goal (asl,w))
    

end (* struct *)
