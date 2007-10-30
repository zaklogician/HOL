structure Prekind :> Prekind =
struct

open HolKernel optmonad;
infix >> >-;


val TCERR = mk_HOL_ERR "Prekind";

 datatype prekind0
    = Varkind of string
    | Typekind
    | Arrowkind of prekind * prekind
    | UVarkind of prekind option ref
 and prekind = PK of prekind0 locn.located

fun eq0 (Varkind s)                (Varkind s')                = s=s'
  | eq0 (Typekind)                 (Typekind)                  = true
  | eq0 (Arrowkind(kd1,kd2))       (Arrowkind(kd1',kd2'))      = eq kd1 kd1' andalso eq kd2 kd2'
  | eq0 (UVarkind (r as ref NONE)) (UVarkind (r' as ref NONE)) = r=r'
  | eq0 (UVarkind (ref(SOME kd)))  (UVarkind (ref(SOME kd')) ) = eq kd kd'
  | eq0 _                          _                           = false
and eq  (PK (value,locn))          (PK (value',locn'))         = eq0 value value'

val typ = PK (Typekind, locn.Loc_None)

fun ((kd1 as PK(_,loc1)) ==> (kd2 as PK(_,loc2))) =
    PK(Arrowkind(kd1,kd2),
       locn.between loc1 loc2)

fun mk_arity 0 = typ
  | mk_arity n = if n > 0 then typ ==> mk_arity (n - 1)
                 else raise TCERR "mk_arity" "negative arity"

fun kindvars (PK (kd, loc)) =
  case kd of
    Varkind s => [s]
  | Typekind  => []
  | Arrowkind (kd1, kd2) => Lib.union (kindvars kd1) (kindvars kd2)
  | UVarkind (ref NONE) => []
  | UVarkind (ref (SOME k')) => kindvars k'

fun uvars_of (PK(ty, loc)) =
    case ty of
      UVarkind r => [r]
    | Arrowkind (kd1, kd2) => Lib.union (uvars_of kd1) (uvars_of kd2)
    | _ => []

fun new_uvar () = PK (UVarkind(ref NONE), locn.Loc_None)

infix ref_occurs_in

fun r ref_occurs_in (PK(value, locn)) =
  case value of
    Varkind _ => false
  | Typekind  => false
  | Arrowkind(kd1, kd2) => r ref_occurs_in kd1 orelse r ref_occurs_in kd2
  | UVarkind (r' as ref NONE) => r = r'
  | UVarkind (r' as ref (SOME k)) => r = r' orelse r ref_occurs_in k

infix ref_equiv
fun r ref_equiv (PK(value, locn)) =
  case value of
    UVarkind (r' as ref NONE) => r = r'
  | UVarkind (r' as ref (SOME k)) => r = r' orelse r ref_equiv k
  | _ => false

  fun has_free_uvar (PK(pkd,_)) =
    case pkd of
      UVarkind (ref NONE)        => true
    | UVarkind (ref (SOME pkd')) => has_free_uvar pkd'
    | Varkind _              => false
    | Typekind               => false
    | Arrowkind(kd1, kd2)    => has_free_uvar kd1 orelse has_free_uvar kd2


fun unsafe_bind f r value =
  if r ref_equiv value
  then ok
  else if r ref_occurs_in value orelse isSome (!r)
       then fail
    else (fn acc => (((r, !r)::acc, SOME ()) before r := SOME value))


(* first argument is a function which performs a binding between a
   pretype reference and another pretype, updating some sort of environment
   (the 'a), returning the new alpha and a unit option, SOME () for a
   success, and a NONE, if not.

   To further complicate things, the bind argument also gets a copy of
   gen_unify to call, if it should choose.
*)
(* this will need changing *)
(* eta-expansion *is* necessary *)
fun gen_unify bind (kd1 as PK(k1,locn1)) (kd2 as PK(k2,locn2)) e = let
  val gen_unify = gen_unify bind
in
  case (k1, k2) of
    (UVarkind (r as ref NONE), _) => bind gen_unify r kd2
  | (UVarkind (r as ref (SOME k1)), k2) => gen_unify k1 kd2
  | (_, UVarkind _) => gen_unify kd2 kd1
  | (Varkind s1, Varkind s2) => if s1 = s2 then ok else fail
  | (Typekind, Typekind) => ok
  | (Arrowkind(kd11, kd12), Arrowkind(kd21, kd22)) =>
       gen_unify kd11 kd21 >> gen_unify kd12 kd22 >> return ()
  | _ => fail
 end e

val unsafe_unify = gen_unify unsafe_bind

fun unify k1 k2 =
  case (gen_unify unsafe_bind k1 k2 [])
   of (bindings, SOME ()) => ()
    | (_, NONE) => raise TCERR "unify" "unify failed";

fun can_unify k1 k2 = let
  val (bindings, result) = gen_unify unsafe_bind k1 k2 []
  val _ = app (fn (r, oldvalue) => r := oldvalue) bindings
in
  isSome result
end

local
  fun (r ref_equiv (PK(value, locn))) env =
       case value of
         UVarkind (r' as ref NONE) =>
              r = r' orelse
              let in
                case Lib.assoc1 r' env
                 of NONE => false
                  | SOME (_, v) => (r ref_equiv v) env
              end
         | UVarkind (ref (SOME k)) => (r ref_equiv k) env
         | _ => false

      fun (r ref_occurs_in (PK(value, locn))) env =
        case value
         of UVarkind (r' as ref NONE) =>
              r = r' orelse
              let in
                case Lib.assoc1 r' env
                 of NONE => false
                  | SOME (_, v) => (r ref_occurs_in v) env
              end
          | UVarkind (ref (SOME k)) => (r ref_occurs_in k) env
          | Arrowkind(kd1,kd2) => (r ref_occurs_in kd1) env orelse
                                  (r ref_occurs_in kd2) env
          | _ => false
in
fun safe_bind unify r value env =
  case Lib.assoc1 r env
   of SOME (_, v) => unify v value env
    | NONE =>
        if (r ref_equiv value) env then ok env else
        if (r ref_occurs_in value) env then fail env
        else ((r,value)::env, SOME ())
end


fun safe_unify t1 t2 = gen_unify safe_bind t1 t2

(* needs changing *)
fun apply_subst subst (pk as PK (pkd, locn)) =
  case pkd of
    Varkind _ => pk
  | Typekind  => pk
  | Arrowkind(kd1, kd2) => PK (Arrowkind(apply_subst subst kd1, apply_subst subst kd2), locn)
  | UVarkind (ref (SOME k)) => apply_subst subst k
  | UVarkind (r as ref NONE) =>
      case (Lib.assoc1 r subst) of
        NONE => pk
      | SOME (_, value) => apply_subst subst value

(*---------------------------------------------------------------------------*
 * Passes over a kind, turning all of the kind variables into fresh          *
 * UVarkinds, but doing so consistently by using an env, which is an alist       *
 * from variable names to kind variable refs.                                *
 *---------------------------------------------------------------------------*)

local fun replace s env =
        case Lib.assoc1 s env
         of NONE =>
              let val r = new_uvar()
              in ((s, r)::env, SOME r)
              end
          | SOME (_, r) => (env, SOME r)
in
(* needs changing *)
fun rename_kv (kd as PK(kd0, locn)) =
  case kd0 of
    Varkind s => replace s
  | Arrowkind (kd1, kd2) =>
      rename_kv kd1 >-
      (fn kd1' => rename_kv kd2 >-
      (fn kd2' => return (PK(Arrowkind(kd1', kd2'), locn))))
  | _ => return kd

fun rename_kindvars kd = valOf (#2 (rename_kv kd []))
end

fun fromKind k =
  (*if Kind.is_varkind k then
    PK(Varkind (dest_varkind_opr k), locn.Loc_None)
  else*) if k = Kind.typ then
    PK(Typekind, locn.Loc_None)
  else (* if Kind.is_app_kind k then *) let
      val (kd1, kd2) = Kind.kind_dom_rng k
    in
      PK(Arrowkind(fromKind kd1, fromKind kd2), locn.Loc_None)
    end
  (* else raise TCERR "fromKind" "Unexpected sort of kind" *)

fun remove_made_links (kd as PK(kd0,locn)) =
  case kd0 of
    UVarkind(ref (SOME kd')) => remove_made_links kd'
  | Arrowkind(kd1, kd2) => PK(Arrowkind(remove_made_links kd1, remove_made_links kd2), locn)
  | _ => kd

val kindvariant = Lexis.gen_variant Lexis.tyvar_vary

(* needs changing *)
fun generate_new_name r used_so_far =
  let val result = kindvariant used_so_far "''a"
      val _ = r := SOME (PK(Varkind result, locn.Loc_None))
  in
    (result::used_so_far, SOME ())
  end

(* needs changing *)
(* eta-expansion (see "env" after end below) *is* necessary *)
fun replace_null_links (PK(kd,_)) env = let
in
  case kd of
    UVarkind (r as ref NONE) => generate_new_name r
  | UVarkind (ref (SOME kd)) => replace_null_links kd
  | Arrowkind (kd1,kd2) => replace_null_links kd1 >> replace_null_links kd2 >> ok
  | Varkind _ => ok
  | Typekind  => ok
end env

fun clean (PK(ty, locn)) =
  case ty of
    Varkind s => Kind.typ
  | Typekind => Kind.typ
  | Arrowkind(kd1,kd2) => Kind.==>(clean kd1, clean kd2)
  | _ => raise Fail "Don't expect to see links remaining at this stage"

fun toKind kd =
  let val _ = replace_null_links kd (kindvars kd)
  in
    clean (remove_made_links kd)
  end

fun chase (PK(Arrowkind(_, kd), _)) = kd
  | chase (PK(UVarkind(ref (SOME kd)), _)) = chase kd
  | chase _ = raise Fail "chase applied to non-function kind"

end;
