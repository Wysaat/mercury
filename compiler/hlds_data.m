%-----------------------------------------------------------------------------%
% Copyright (C) 1996-2004 The University of Melbourne.
% This file may only be copied under the terms of the GNU General
% Public License - see the file COPYING in the Mercury distribution.
%-----------------------------------------------------------------------------%

% This module defines the part of the HLDS that deals with issues related
% to data and its representation: function symbols, types, insts, modes.

% Main authors: fjh, conway.

:- module hlds__hlds_data.

:- interface.

:- import_module backend_libs.
:- import_module backend_libs__rtti.
:- import_module hlds__hlds_pred.
:- import_module parse_tree__inst.
:- import_module parse_tree__prog_data.

:- import_module bool, list, map, std_util, term.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

	% The symbol table for constructors.
	% This table is used by the type-checker to look
	% up the type of functors/constants.

:- type cons_table	==	map(cons_id, list(hlds_cons_defn)).

:- type cons_id
	--->	cons(sym_name, arity)	% name, arity
		% Tuples have cons_id
		% `cons(unqualified("{}"), Arity)'.

	;	int_const(int)
	;	string_const(string)
	;	float_const(float)
	;	pred_const(pred_id, proc_id, lambda_eval_method)
		% Note that a pred_const represents a closure,
		% not just a code address.
	;	type_ctor_info_const(module_name, string, int)
		% module name, type name, type arity
	;	base_typeclass_info_const(module_name, class_id, int, string)
		% module name of instance declaration
		% (not filled in so that link errors result
		% from overlapping instances),
		% class name and arity,
		% class instance, a string encoding the type
		% names and arities of the arguments to the
		% instance declaration
	;	type_info_cell_constructor(type_ctor)
		% module name, type name, type arity
	;	typeclass_info_cell_constructor
	;	tabling_pointer_const(pred_id, proc_id)
		% The address of the static variable
		% that points to the table that implements
		% memoization, loop checking or the minimal
		% model semantics for the given procedure.
	;	deep_profiling_proc_static(rtti_proc_label)
		% The ProcStatic structure of a procedure,
		% as documented in the deep profiling paper.
	;	table_io_decl(rtti_proc_label).
		% The address of a structure that describes
		% the layout of the answer block used by
		% I/O tabling for declarative debugging.

	% A cons_defn is the definition of a constructor (i.e. a constant
	% or a functor) for a particular type.

:- type hlds_cons_defn --->
	hlds_cons_defn(
		% maybe add tvarset here?
		% you can get the tvarset from the hlds__type_defn.
		cons_exist_tvars	:: existq_tvars,
					% existential type vars
		cons_constraints	:: list(class_constraint),
					% existential class constraints
		cons_args		:: list(constructor_arg),
					% The field names and types of
					% the arguments of this functor
					% (if any)
		cons_type_ctor		:: type_ctor,
					% The result type, i.e. the
					% type to which this
					% cons_defn belongs.
		cons_context		:: prog_context
					% The location of this
					% constructor definition in the
					% original source code
	).

%-----------------------------------------------------------------------------%

:- type ctor_field_table == map(ctor_field_name, list(hlds_ctor_field_defn)).

:- type hlds_ctor_field_defn --->
	hlds_ctor_field_defn(
		field_context	:: prog_context,
				% context of the field definition
		field_status	:: import_status,
		field_type_ctor	:: type_ctor,
				% type containing the field
		field_cons_id	:: cons_id,
				% constructor containing the field
		field_arg_num	:: int
				% argument number (counting from 1)
	).

	%
	% Field accesses are expanded into inline unifications by
	% post_typecheck.m after typechecking has worked out which
	% field is being referred to.
	%
	% Function declarations and clauses are not generated for these
	% because it would be difficult to work out how to mode them.
	%
	% Users can supply type and mode declarations, for example
	% to export a field of an abstract data type or to allow
	% taking the address of a field access function.
	%
:- type field_access_type
	--->	get
	;	set.

%-----------------------------------------------------------------------------%

	% Various predicates for accessing the cons_id type.

	% Given a cons_id and a list of argument terms, convert it into a
	% term. Fails if the cons_id is a pred_const, or type_ctor_info_const.

:- pred cons_id_and_args_to_term(cons_id::in, list(term(T))::in, term(T)::out)
	is semidet.

	% Get the arity of a cons_id, aborting on pred_const and
	% type_ctor_info_const.

:- func cons_id_arity(cons_id) = arity.

	% Get the arity of a cons_id. Return a `no' on those cons_ids
	% where cons_id_arity/2 would normally abort.

:- func cons_id_maybe_arity(cons_id) = maybe(arity).

	% The reverse conversion - make a cons_id for a functor.
	% Given a const and an arity for the functor, create a cons_id.

:- func make_functor_cons_id(const, arity) = cons_id.

	% Another way of making a cons_id from a functor.
	% Given the name, argument types, and type_ctor of a functor,
	% create a cons_id for that functor.

:- func make_cons_id(sym_name, list(constructor_arg), type_ctor) = cons_id.

	% Another way of making a cons_id from a functor.
	% Given the name, argument types, and type_ctor of a functor,
	% create a cons_id for that functor.
	%
	% Differs from make_cons_id in that (a) it requires the sym_name
	% to be already module qualified, which means that it does not
	% need the module qualification of the type, (b) it can compute the
	% arity from any list of the right length.

:- func make_cons_id_from_qualified_sym_name(sym_name, list(_)) = cons_id.

%-----------------------------------------------------------------------------%

:- implementation.

:- import_module parse_tree__prog_util.

:- import_module string, require, varset.

cons_id_and_args_to_term(int_const(Int), [], Term) :-
	term__context_init(Context),
	Term = term__functor(term__integer(Int), [], Context).
cons_id_and_args_to_term(float_const(Float), [], Term) :-
	term__context_init(Context),
	Term = term__functor(term__float(Float), [], Context).
cons_id_and_args_to_term(string_const(String), [], Term) :-
	term__context_init(Context),
	Term = term__functor(term__string(String), [], Context).
cons_id_and_args_to_term(cons(SymName, _Arity), Args, Term) :-
	construct_qualified_term(SymName, Args, Term).

cons_id_arity(cons(_, Arity)) = Arity.
cons_id_arity(int_const(_)) = 0.
cons_id_arity(string_const(_)) = 0.
cons_id_arity(float_const(_)) = 0.
cons_id_arity(pred_const(_, _, _)) =
	func_error("cons_id_arity: can't get arity of pred_const").
cons_id_arity(type_ctor_info_const(_, _, _)) =
	func_error("cons_id_arity: can't get arity of type_ctor_info_const").
cons_id_arity(base_typeclass_info_const(_, _, _, _)) =
	func_error("cons_id_arity: " ++
		"can't get arity of base_typeclass_info_const").
cons_id_arity(type_info_cell_constructor(_)) =
	func_error("cons_id_arity: " ++
		"can't get arity of type_info_cell_constructor").
cons_id_arity(typeclass_info_cell_constructor) =
	func_error("cons_id_arity: " ++
		"can't get arity of typeclass_info_cell_constructor").
cons_id_arity(tabling_pointer_const(_, _)) =
	func_error("cons_id_arity: can't get arity of tabling_pointer_const").
cons_id_arity(deep_profiling_proc_static(_)) =
	func_error("cons_id_arity: " ++
		"can't get arity of deep_profiling_proc_static").
cons_id_arity(table_io_decl(_)) =
	func_error("cons_id_arity: can't get arity of table_io_decl").

cons_id_maybe_arity(cons(_, Arity)) = yes(Arity).
cons_id_maybe_arity(int_const(_)) = yes(0).
cons_id_maybe_arity(string_const(_)) = yes(0).
cons_id_maybe_arity(float_const(_)) = yes(0).
cons_id_maybe_arity(pred_const(_, _, _)) = no.
cons_id_maybe_arity(type_ctor_info_const(_, _, _)) = no.
cons_id_maybe_arity(base_typeclass_info_const(_, _, _, _)) = no.
cons_id_maybe_arity(type_info_cell_constructor(_)) = no.
cons_id_maybe_arity(typeclass_info_cell_constructor) = no.
cons_id_maybe_arity(tabling_pointer_const(_, _)) = no.
cons_id_maybe_arity(deep_profiling_proc_static(_)) = no.
cons_id_maybe_arity(table_io_decl(_)) = no.

make_functor_cons_id(term__atom(Name), Arity) = cons(unqualified(Name), Arity).
make_functor_cons_id(term__integer(Int), _) = int_const(Int).
make_functor_cons_id(term__string(String), _) = string_const(String).
make_functor_cons_id(term__float(Float), _) = float_const(Float).

make_cons_id(SymName0, Args, TypeCtor) = cons(SymName, Arity) :-
	% Use the module qualifier on the SymName, if there is one,
	% otherwise use the module qualifier on the Type, if there is one,
	% otherwise leave it unqualified.
	% XXX is that the right thing to do?
	(
		SymName0 = qualified(_, _),
		SymName = SymName0
	;
		SymName0 = unqualified(ConsName),
		(
			TypeCtor = unqualified(_) - _,
			SymName = SymName0
		;
			TypeCtor = qualified(TypeModule, _) - _,
			SymName = qualified(TypeModule, ConsName)
		)
	),
	list__length(Args, Arity).

make_cons_id_from_qualified_sym_name(SymName, Args) = cons(SymName, Arity) :-
	list__length(Args, Arity).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- interface.

	% The symbol table for types.

:- type type_table	==	map(type_ctor, hlds_type_defn).

	% This is how type, modes and constructors are represented.
	% The parts that are not defined here (i.e. type_param, constructor,
	% type, inst, mode, condition) are represented in the same way as
	% in prog_io.m, and are defined there.

	% An hlds_type_defn holds the information about a type definition.

:- type hlds_type_defn.

:- pred hlds_data__set_type_defn(tvarset::in, list(type_param)::in,
	hlds_type_body::in, import_status::in, need_qualifier::in,
	prog_context::in, hlds_type_defn::out) is det.

:- pred get_type_defn_tvarset(hlds_type_defn::in, tvarset::out) is det.
:- pred get_type_defn_tparams(hlds_type_defn::in, list(type_param)::out)
	is det.
:- pred get_type_defn_body(hlds_type_defn::in, hlds_type_body::out) is det.
:- pred get_type_defn_status(hlds_type_defn::in, import_status::out) is det.
:- pred get_type_defn_need_qualifier(hlds_type_defn::in, need_qualifier::out)
	is det.
:- pred get_type_defn_context(hlds_type_defn::in, prog_context::out) is det.

:- pred set_type_defn_status(import_status::in,
	hlds_type_defn::in, hlds_type_defn::out) is det.
:- pred set_type_defn_body(hlds_type_body::in,
	hlds_type_defn::in, hlds_type_defn::out) is det.
:- pred set_type_defn_tvarset(tvarset::in,
	hlds_type_defn::in, hlds_type_defn::out) is det.

	% An `hlds_type_body' holds the body of a type definition:
	% du = discriminated union, uu = undiscriminated union,
	% eqv_type = equivalence type (a type defined to be equivalent
	% to some other type)

:- type hlds_type_body
	--->	du_type(
					% the ctors for this type
			du_type_ctors		:: list(constructor),

					% their tag values
			du_type_cons_tag_values	:: cons_tag_values,

					% is this type an enumeration?
			du_type_is_enum		:: bool,

					% user-defined equality and
					% comparison preds
			du_type_usereq		:: maybe(unify_compare),

					% is there a `:- pragma reserve_tag'
					% pragma for this type?
			du_type_reserved_tag	:: bool,

					% should the `any' inst be considered
					% `bound' for this type?
			du_type_is_solver_type	:: is_solver_type,

					% are there `:- pragma foreign' type
					% declarations for this type?
			du_type_is_foreign_type	:: maybe(foreign_type_body)
		)
	;	eqv_type(type)
	;	foreign_type(foreign_type_body, is_solver_type)
	;	abstract_type(is_solver_type).

:- type foreign_type_body
	--->	foreign_type_body(
			il	:: foreign_type_lang_body(il_foreign_type),
			c	:: foreign_type_lang_body(c_foreign_type),
			java	:: foreign_type_lang_body(java_foreign_type)
		).

:- type foreign_type_lang_body(T) == maybe(pair(T, maybe(unify_compare))).

	% The `cons_tag_values' type stores the information on how
	% a discriminated union type is represented.
	% For each functor in the d.u. type, it gives a cons_tag
	% which specifies how that functor and its arguments are represented.

:- type cons_tag_values	== map(cons_id, cons_tag).

	% A `cons_tag' specifies how a functor and its arguments (if any)
	% are represented.  Currently all values are represented as
	% a single word; values which do not fit into a word are represented
	% by a (possibly tagged) pointer to memory on the heap.

:- type cons_tag
	--->	string_constant(string)
			% Strings are represented using the MR_string_const()
			% macro; in the current implementation, Mercury
			% strings are represented just as C null-terminated
			% strings.
	;	float_constant(float)
			% Floats are represented using the MR_float_to_word(),
			% MR_word_to_float(), and MR_float_const() macros.
			% The default implementation of these is to
			% use boxed double-precision floats.
	;	int_constant(int)
			% This means the constant is represented just as
			% a word containing the specified integer value.
			% This is used for enumerations and character
			% constants as well as for int constants.
	;	pred_closure_tag(pred_id, proc_id, lambda_eval_method)
			% Higher-order pred closures tags.
			% These are represented as a pointer to
			% an argument vector.
			% For closures with lambda_eval_method `normal',
			% the first two words of the argument vector
			% hold the number of args and the address of
			% the procedure respectively.
			% The remaining words hold the arguments.
	;	type_ctor_info_constant(module_name, string, arity)
			% This is how we refer to type_ctor_info structures
			% represented as global data. The args are
			% the name of the module the type is defined in,
			% and the name of the type, and its arity.
	;	base_typeclass_info_constant(module_name, class_id, string)
			% This is how we refer to base_typeclass_info structures
			% represented as global data. The first argument is the
			% name of the module containing the instance declration,
			% the second is the class name and arity, while the
			% third is the string which uniquely identifies the
			% instance declaration (it is made from the type of
			% the arguments to the instance decl).
	;	tabling_pointer_constant(pred_id, proc_id)
			% This is how we refer to tabling pointer variables
			% represented as global data. The word just contains
			% the address of the tabling pointer of the
			% specified procedure.
	;	deep_profiling_proc_static_tag(rtti_proc_label)
			% This is for constants representing procedure
			% descriptions for deep profiling.
	;	table_io_decl_tag(rtti_proc_label)
			% This is for constants representing the structure
			% that allows us to decode the contents of the memory
			% block containing the headvars of I/O primitives.
	;	single_functor
			% This is for types with a single functor
			% (and possibly also some constants represented
			% using reserved addresses -- see below).
			% For these types, we don't need any tags.
			% We just store a pointer to the argument vector.
	;	unshared_tag(tag_bits)
			% This is for constants or functors which can be
			% distinguished with just a primary tag.
			% An "unshared" tag is one which fits on the
			% bottom of a pointer (i.e.  two bits for
			% 32-bit architectures, or three bits for 64-bit
			% architectures), and is used for just one
			% functor.
			% For constants we store a tagged zero, for functors
			% we store a tagged pointer to the argument vector.
	;	shared_remote_tag(tag_bits, int)
			% This is for functors or constants which
			% require more than just a two-bit tag. In this case,
			% we use both a primary and a secondary tag.
			% Several functors share the primary tag and are
			% distinguished by the secondary tag.
			% The secondary tag is stored as the first word of
			% the argument vector. (If it is a constant, then
			% in this case there is an argument vector of size 1
			% which just holds the secondary tag.)
	;	shared_local_tag(tag_bits, int)
			% This is for constants which require more than a
			% two-bit tag. In this case, we use both a primary
			% and a secondary tag, but this time the secondary
			% tag is stored in the rest of the main word rather
			% than in the first word of the argument vector.
	;	no_tag
			% This is for types with a single functor of arity one.
			% In this case, we don't need to store the functor,
			% and instead we store the argument directly.
	;	reserved_address(reserved_address)
			% This is for constants represented as null pointers,
			% or as other reserved values in the address space.
	;       shared_with_reserved_addresses(list(reserved_address),
				cons_tag).
			% This is for constructors of discriminated union
			% types where one or more of the *other* constructors
			% for that type is represented as a reserved address.
			% Any semidet deconstruction against a constructor
			% represented as a shared_with_reserved_addresses
			% cons_tag must check that the value isn't any of
			% the reserved addresses before testing for the
			% constructor's own cons_tag.

:- type reserved_address
	--->	null_pointer
			% This is for constants which are represented as a
			% null pointer.
	;	small_pointer(int)
			% This is for constants which are represented as a
			% small integer, cast to a pointer.
	;	reserved_object(type_ctor, sym_name, arity).
			% This is for constants which are represented as the
			% address of a specially reserved global variable.


	% The type `tag_bits' holds a primary tag value.

:- type tag_bits	==	int.	% actually only 2 (or maybe 3) bits


	% The type definitions for no_tag types have information
	% mirrored in a separate table for faster lookups.
	% mode_util__mode_to_arg_mode makes heavy use of
	% type_util__type_is_no_tag_type.
:- type no_tag_type
	--->	no_tag_type(
			list(type_param),	% Formal type parameters.
			sym_name,		% Constructor name.
			(type)			% Argument type.
		).

:- type no_tag_type_table == map(type_ctor, no_tag_type).


	% Return the primary tag, if any, for a cons_tag.
	% A return value of `no' means the primary tag is unknown.
	% A return value of `yes(N)' means the primary tag is N.
	% (`yes(0)' also corresponds to the case where there no primary tag.)
:- func get_primary_tag(cons_tag) = maybe(int).

	% Return the secondary tag, if any, for a cons_tag.
	% A return value of `no' means there is no secondary tag.
:- func get_secondary_tag(cons_tag) = maybe(int).

:- implementation.

% In some of the cases where we return `no' here,
% it would probably be OK to return `yes(0)'.
% But it's safe to be conservative...
get_primary_tag(string_constant(_)) = no.
get_primary_tag(float_constant(_)) = no.
get_primary_tag(int_constant(_)) = no.
get_primary_tag(pred_closure_tag(_, _, _)) = no.
get_primary_tag(type_ctor_info_constant(_, _, _)) = no.
get_primary_tag(base_typeclass_info_constant(_, _, _)) = no.
get_primary_tag(tabling_pointer_constant(_, _)) = no.
get_primary_tag(deep_profiling_proc_static_tag(_)) = no.
get_primary_tag(table_io_decl_tag(_)) = no.
get_primary_tag(single_functor) = yes(0).
get_primary_tag(unshared_tag(PrimaryTag)) = yes(PrimaryTag).
get_primary_tag(shared_remote_tag(PrimaryTag, _SecondaryTag)) =
		yes(PrimaryTag).
get_primary_tag(shared_local_tag(PrimaryTag, _)) = yes(PrimaryTag).
get_primary_tag(no_tag) = no.
get_primary_tag(reserved_address(_)) = no.
get_primary_tag(shared_with_reserved_addresses(_ReservedAddresses, TagValue))
		= get_primary_tag(TagValue).

get_secondary_tag(string_constant(_)) = no.
get_secondary_tag(float_constant(_)) = no.
get_secondary_tag(int_constant(_)) = no.
get_secondary_tag(pred_closure_tag(_, _, _)) = no.
get_secondary_tag(type_ctor_info_constant(_, _, _)) = no.
get_secondary_tag(base_typeclass_info_constant(_, _, _)) = no.
get_secondary_tag(tabling_pointer_constant(_, _)) = no.
get_secondary_tag(deep_profiling_proc_static_tag(_)) = no.
get_secondary_tag(table_io_decl_tag(_)) = no.
get_secondary_tag(single_functor) = no.
get_secondary_tag(unshared_tag(_)) = no.
get_secondary_tag(shared_remote_tag(_PrimaryTag, SecondaryTag)) =
		yes(SecondaryTag).
get_secondary_tag(shared_local_tag(_, _)) = no.
get_secondary_tag(no_tag) = no.
get_secondary_tag(reserved_address(_)) = no.
get_secondary_tag(shared_with_reserved_addresses(_ReservedAddresses, TagValue))
		= get_secondary_tag(TagValue).

:- type hlds_type_defn --->
	hlds_type_defn(
		type_defn_tvarset	:: tvarset,
					% Names of type vars (empty
					% except for polymorphic types)
		type_defn_params	:: list(type_param),
					% Formal type parameters
		type_defn_body		:: hlds_type_body,
					% The definition of the type

		type_defn_import_status	:: import_status,
					% Is the type defined in this
					% module, and if yes, is it
					% exported

		type_defn_need_qualifier :: need_qualifier,
					% Do uses of the type and
					% its constructors need
					% to be qualified.

%		type_defn_condition	:: condition,		% UNUSED
%				% Reserved for holding a user-defined invariant
%				% for the type, as in the NU-Prolog's type
%				% checker, which allows `where' conditions on
%				% type definitions.  For example:
%				% :- type sorted_list(T) == list(T)
%				%	where sorted.

		type_defn_context	:: prog_context
					% The location of this type
					% definition in the original
					% source code
	).

hlds_data__set_type_defn(Tvarset, Params, Body, Status,
		NeedQual, Context, Defn) :-
	Defn = hlds_type_defn(Tvarset, Params, Body,
			Status, NeedQual, Context).

hlds_data__get_type_defn_tvarset(Defn, Defn ^ type_defn_tvarset).
hlds_data__get_type_defn_tparams(Defn, Defn ^ type_defn_params).
hlds_data__get_type_defn_body(Defn, Defn ^ type_defn_body).
hlds_data__get_type_defn_status(Defn, Defn ^ type_defn_import_status).
hlds_data__get_type_defn_need_qualifier(Defn, Defn ^ type_defn_need_qualifier).
hlds_data__get_type_defn_context(Defn, Defn ^ type_defn_context).

hlds_data__set_type_defn_body(Body, Defn, Defn ^ type_defn_body := Body).
hlds_data__set_type_defn_tvarset(TVarSet, Defn,
		Defn ^ type_defn_tvarset := TVarSet).
hlds_data__set_type_defn_status(Status, Defn,
		Defn ^ type_defn_import_status := Status).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- interface.

	% The symbol table for insts.

:- type inst_id		==	pair(sym_name, arity).
				% name, arity.

:- type inst_table.

:- type user_inst_table.
:- type user_inst_defns ==	map(inst_id, hlds_inst_defn).

:- type unify_inst_table ==	map(inst_name, maybe_inst_det).

:- type unify_inst_pair	--->	unify_inst_pair(is_live, inst, inst,
					unify_is_real).

:- type merge_inst_table ==	map(pair(inst), maybe_inst).

:- type ground_inst_table == 	map(inst_name, maybe_inst_det).

:- type any_inst_table == 	map(inst_name, maybe_inst_det).

:- type shared_inst_table == 	map(inst_name, maybe_inst).

:- type mostly_uniq_inst_table == map(inst_name, maybe_inst).

:- type maybe_inst	--->	unknown
			;	known(inst).

:- type maybe_inst_det	--->	unknown
			;	known(inst, determinism).

	% An `hlds_inst_defn' holds the information we need to store
	% about inst definitions such as
	%	:- inst list_skel(I) = bound([] ; [I | list_skel(I)].

:- type hlds_inst_defn --->
	hlds_inst_defn(
		inst_varset		:: inst_varset,
					% The names of the inst
					% parameters (if any).
		inst_params		:: list(inst_var),
					% The inst parameters (if any).
					% ([I] in the above example.)
		inst_body		:: hlds_inst_body,
					% The definition of this inst.
%		inst_condition		:: condition,
%					% Unused (reserved for
%					% holding a user-defined
%					% invariant).
		inst_context		:: prog_context,
					% The location in the source
					% code of this inst definition.

		inst_status		:: import_status
					% So intermod.m can tell
					% whether to output this inst.
	).

:- type hlds_inst_body
	--->	eqv_inst(inst)			% This inst is equivalent to
						% some other inst.
	;	abstract_inst.			% This inst is just a forward
						% declaration; the real
						% definition will be filled in
						% later.  (XXX Abstract insts
						% are not really supported.)

%-----------------------------------------------------------------------------%

:- pred inst_table_init(inst_table::out) is det.

:- pred inst_table_get_user_insts(inst_table::in, user_inst_table::out) is det.
:- pred inst_table_get_unify_insts(inst_table::in, unify_inst_table::out)
	is det.
:- pred inst_table_get_merge_insts(inst_table::in, merge_inst_table::out)
	is det.
:- pred inst_table_get_ground_insts(inst_table::in, ground_inst_table::out)
	is det.
:- pred inst_table_get_any_insts(inst_table::in, any_inst_table::out) is det.
:- pred inst_table_get_shared_insts(inst_table::in, shared_inst_table::out)
	is det.
:- pred inst_table_get_mostly_uniq_insts(inst_table::in,
	mostly_uniq_inst_table::out) is det.

:- pred inst_table_set_user_insts(user_inst_table::in,
	inst_table::in, inst_table::out) is det.
:- pred inst_table_set_unify_insts(unify_inst_table::in,
	inst_table::in, inst_table::out) is det.
:- pred inst_table_set_merge_insts(merge_inst_table::in,
	inst_table::in, inst_table::out) is det.
:- pred inst_table_set_ground_insts(ground_inst_table::in,
	inst_table::in, inst_table::out) is det.
:- pred inst_table_set_any_insts(any_inst_table::in,
	inst_table::in, inst_table::out) is det.
:- pred inst_table_set_shared_insts(shared_inst_table::in,
	inst_table::in, inst_table::out) is det.
:- pred inst_table_set_mostly_uniq_insts(mostly_uniq_inst_table::in,
	inst_table::in, inst_table::out) is det.

:- pred user_inst_table_get_inst_defns(user_inst_table::in,
	user_inst_defns::out) is det.
:- pred user_inst_table_get_inst_ids(user_inst_table::in,
	list(inst_id)::out) is det.

:- pred user_inst_table_insert(inst_id::in, hlds_inst_defn::in,
	user_inst_table::in, user_inst_table::out) is semidet.

	% Optimize the user_inst_table for lookups. This just sorts
	% the cached list of inst_ids.
:- pred user_inst_table_optimize(user_inst_table::in, user_inst_table::out)
	is det.

:- implementation.

:- type inst_table
	--->	inst_table(
			inst_table_user		:: user_inst_table,
			inst_table_unify	:: unify_inst_table,
			inst_table_merge	:: merge_inst_table,
			inst_table_ground	:: ground_inst_table,
			inst_table_any		:: any_inst_table,
			inst_table_shared	:: shared_inst_table,
			inst_table_mostly_uniq	:: mostly_uniq_inst_table
		).

:- type user_inst_defns.

:- type user_inst_table
	--->	user_inst_table(
			uinst_table_defns	:: user_inst_defns,
			uinst_table_ids		:: list(inst_id)
				% Cached for efficiency when module
				% qualifying the modes of lambda expressions.
		).

inst_table_init(inst_table(UserInsts, UnifyInsts, MergeInsts, GroundInsts,
			AnyInsts, SharedInsts, NondetLiveInsts)) :-
	map__init(UserInstDefns),
	UserInsts = user_inst_table(UserInstDefns, []),
	map__init(UnifyInsts),
	map__init(MergeInsts),
	map__init(GroundInsts),
	map__init(SharedInsts),
	map__init(AnyInsts),
	map__init(NondetLiveInsts).

inst_table_get_user_insts(InstTable, InstTable ^ inst_table_user).
inst_table_get_unify_insts(InstTable, InstTable ^ inst_table_unify).
inst_table_get_merge_insts(InstTable, InstTable ^ inst_table_merge).
inst_table_get_ground_insts(InstTable, InstTable ^ inst_table_ground).
inst_table_get_any_insts(InstTable, InstTable ^ inst_table_any).
inst_table_get_shared_insts(InstTable, InstTable ^ inst_table_shared).
inst_table_get_mostly_uniq_insts(InstTable,
	InstTable ^ inst_table_mostly_uniq).

inst_table_set_user_insts(UserInsts, InstTable,
	InstTable ^ inst_table_user := UserInsts).
inst_table_set_unify_insts(UnifyInsts, InstTable,
	InstTable ^ inst_table_unify := UnifyInsts).
inst_table_set_merge_insts(MergeInsts, InstTable,
	InstTable ^ inst_table_merge := MergeInsts).
inst_table_set_ground_insts(GroundInsts, InstTable,
	InstTable ^ inst_table_ground := GroundInsts).
inst_table_set_any_insts(AnyInsts, InstTable,
	InstTable ^ inst_table_any := AnyInsts).
inst_table_set_shared_insts(SharedInsts, InstTable,
	InstTable ^ inst_table_shared := SharedInsts).
inst_table_set_mostly_uniq_insts(MostlyUniqInsts, InstTable,
	InstTable ^ inst_table_mostly_uniq := MostlyUniqInsts).

user_inst_table_get_inst_defns(UserInstTable,
	UserInstTable ^ uinst_table_defns).
user_inst_table_get_inst_ids(UserInstTable,
	UserInstTable ^ uinst_table_ids).

user_inst_table_insert(InstId, InstDefn, UserInstTable0, UserInstTable) :-
	UserInstTable0 = user_inst_table(InstDefns0, InstIds0),
	InstDefns0 = UserInstTable0 ^ uinst_table_defns,
	map__insert(InstDefns0, InstId, InstDefn, InstDefns),
	InstIds = [InstId | InstIds0],
	UserInstTable = user_inst_table(InstDefns, InstIds).

user_inst_table_optimize(UserInstTable0, UserInstTable) :-
	UserInstTable0 = user_inst_table(InstDefns0, InstIds0),
	map__optimize(InstDefns0, InstDefns),
	list__sort(InstIds0, InstIds),
	UserInstTable = user_inst_table(InstDefns, InstIds).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- interface.

	% The symbol table for modes.

:- type mode_id		==	pair(sym_name, arity).
				% name, arity

:- type mode_table.
:- type mode_defns	 ==	map(mode_id, hlds_mode_defn).

	% A hlds_mode_defn stores the information about a mode
	% definition such as
	%	:- mode out :: free -> ground.
	% or
	%	:- mode in(I) :: I -> I.
	% or
	%	:- mode in_list_skel :: in(list_skel).

:- type hlds_mode_defn --->
	hlds_mode_defn(
		mode_varset		:: inst_varset,
					% The names of the inst
					% parameters (if any).
		mode_params		:: list(inst_var),
					% The list of the inst
					% parameters (if any).
					% (e.g. [I] for the second
					% example above.)
		mody_body		:: hlds_mode_body,
					% The definition of this mode.
%		mode_condition		:: condition,
%					% Unused (reserved for
%					% holding a user-defined
%					% invariant).
		mode_context		:: prog_context,
					% The location of this mode
					% definition in the original
					% source code.
		mode_status		:: import_status
					% So intermod.m can tell
					% whether to output this mode.
	).

	% The only sort of mode definitions allowed are equivalence modes.

:- type hlds_mode_body
	--->	eqv_mode(mode).		% This mode is equivalent to some
					% other mode.

	% Given a mode table get the mode_id - hlds_mode_defn map.
:- pred mode_table_get_mode_defns(mode_table::in, mode_defns::out) is det.

	% Get the list of defined mode_ids from the mode_table.
:- pred mode_table_get_mode_ids(mode_table::in, list(mode_id)::out) is det.

	% Insert a mode_id and corresponding hlds_mode_defn into the
	% mode_table. Fail if the mode_id is already present in the table.
:- pred mode_table_insert(mode_id::in, hlds_mode_defn::in,
	mode_table::in, mode_table::out) is semidet.

:- pred mode_table_init(mode_table::out) is det.

	% Optimize the mode table for lookups.
:- pred mode_table_optimize(mode_table::in, mode_table::out) is det.


:- implementation.

:- type mode_table
	--->	mode_table(
			mode_table_defns	:: mode_defns,
			mode_table_ids		:: list(mode_id)
						% Cached for efficiency
		).

mode_table_get_mode_defns(ModeTable, ModeTable ^ mode_table_defns).
mode_table_get_mode_ids(ModeTable, ModeTable ^ mode_table_ids).

mode_table_insert(ModeId, ModeDefn, ModeTable0, ModeTable) :-
	ModeTable0 = mode_table(ModeDefns0, ModeIds0),
	map__insert(ModeDefns0, ModeId, ModeDefn, ModeDefns),
	ModeIds = [ModeId | ModeIds0],
	ModeTable = mode_table(ModeDefns, ModeIds).

mode_table_init(mode_table(ModeDefns, [])) :-
	map__init(ModeDefns).

mode_table_optimize(ModeTable0, ModeTable) :-
	ModeTable0 = mode_table(ModeDefns0, ModeIds0),
	map__optimize(ModeDefns0, ModeDefns), 	% NOP
		% Sort the list of mode_ids
		% for quick conversion to a set by module_qual
		% when qualifying the modes of lambda expressions.
	list__sort(ModeIds0, ModeIds),
	ModeTable = mode_table(ModeDefns, ModeIds).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- interface.

%
% Types and procedures for decomposing and analysing determinism.
% See also the `code_model' type in code_model.m.
% The `determinism' type itself is defined in prog_data.m.
%

:- type can_fail	--->	can_fail
			;	cannot_fail.

:- type soln_count
			--->	at_most_zero
			;	at_most_one
			;	at_most_many_cc
				% "_cc" means "committed-choice": there is
				% more than one logical solution, but
				% the pred or goal is being used in a context
				% where we are only looking for the first
				% solution.
			;	at_most_many.

:- pred determinism_components(determinism, can_fail, soln_count).
:- mode determinism_components(in, out, out) is det.
:- mode determinism_components(out, in, in) is det.

:- implementation.

determinism_components(det,         cannot_fail, at_most_one).
determinism_components(semidet,     can_fail,    at_most_one).
determinism_components(multidet,    cannot_fail, at_most_many).
determinism_components(nondet,      can_fail,    at_most_many).
determinism_components(cc_multidet, cannot_fail, at_most_many_cc).
determinism_components(cc_nondet,   can_fail,    at_most_many_cc).
determinism_components(erroneous,   cannot_fail, at_most_zero).
determinism_components(failure,     can_fail,    at_most_zero).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- interface.

:- type class_table == map(class_id, hlds_class_defn).

:- type class_id 	--->	class_id(sym_name, arity).

	% Information about a single `typeclass' declaration
:- type hlds_class_defn --->
	hlds_class_defn(
		class_status		:: import_status,
		class_supers		:: list(class_constraint),
					% SuperClasses
		class_vars		:: list(tvar),
					% ClassVars
		class_interface		:: class_interface,
					% The interface from the
					% original declaration,
					% used by intermod.m to
					% write out the interface
					% for a local typeclass to
					% the `.opt' file.
		class_hlds_interface	:: hlds_class_interface,
					% Methods
		class_tvarset		:: tvarset,
					% VarNames
		class_context		:: prog_context
					% Location of declaration
	).

:- type hlds_class_interface	==	list(hlds_class_proc).
:- type hlds_class_proc
	---> 	hlds_class_proc(
			pred_id,
			proc_id
		).

	% For each class, we keep track of a list of its instances, since there
	% can be more than one instance of each class.
:- type instance_table == map(class_id, list(hlds_instance_defn)).

	% Information about a single `instance' declaration
:- type hlds_instance_defn --->
	hlds_instance_defn(
		instance_module		:: module_name,
					% module of the instance decl
		instance_status		:: import_status,
					% import status of the instance
					% declaration
		instance_context	:: prog_context,
					% context of declaration
		instance_constraints	:: list(class_constraint),
					% Constraints
		instance_types		:: list(type),
					% ClassTypes
		instance_body		:: instance_body,
					% Methods
		instance_hlds_interface	:: maybe(hlds_class_interface),
					% After check_typeclass, we
					% will know the pred_ids and
					% proc_ids of all the methods
		instance_tvarset	:: tvarset,
					% VarNames
		instance_proofs		:: map(class_constraint,
						constraint_proof)
					% "Proofs" of how to build the
					% typeclass_infos for the
					% superclasses of this class,
					% for this instance
	).

	% `Proof' of why a constraint is redundant
:- type constraint_proof
			% Apply the instance decl with the given number.
			% Note that we don't store the actual
			% hlds_instance_defn for two reasons:
			% - That would require storing a renamed version of
			%   the constraint_proofs for *every* use of an
			%   instance declaration. This wouldn't even get GCed
			%   for a long time because it would be stored in
			%   the pred_info.
			% - The superclass proofs stored in the
			%   hlds_instance_defn would need to store all the
			%   constraint_proofs for all its ancestors. This
			%   would require the class relation to be
			%   topologically sorted before checking the
			%   instance declarations.
	--->	apply_instance(int)

			% The constraint is redundant because of the
			% following class's superclass declaration
	;	superclass(class_constraint).

%-----------------------------------------------------------------------------%

:- type subclass_details --->
	subclass_details(
		subclass_types		:: list(type),
					% arguments of the
					% superclass constraint
		subclass_id		:: class_id,
					% name of the subclass
		subclass_tvars		:: list(tvar),
					% variables of the subclass
		subclass_tvarset	:: tvarset
					% the names of these vars
	).

:- import_module multi_map.

	% I'm sure there's a very clever way of
	% doing this with graphs or relations...
:- type superclass_table == multi_map(class_id, subclass_details).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- interface.

	%
	% A table that records all the assertions in the system.
	% An assertion is a goal that will always evaluate to true,
	% subject to the constraints imposed by the quantifiers.
	%
	% ie :- promise all [A] some [B] (B > A)
	%
	% The above assertion states that for all possible values of A,
	% there will exist at least one value, B, such that B is greater
	% then A.
	%
:- type assert_id.
:- type assertion_table.

:- pred assertion_table_init(assertion_table::out) is det.

:- pred assertion_table_add_assertion(pred_id::in, assert_id::out,
	assertion_table::in, assertion_table::out) is det.

:- pred assertion_table_lookup(assertion_table::in, assert_id::in,
	pred_id::out) is det.

:- pred assertion_table_pred_ids(assertion_table::in,
	list(pred_id)::out) is det.

:- implementation.

:- import_module int.

:- type assert_id == int.
:- type assertion_table
	---> 	assertion_table(assert_id, map(assert_id, pred_id)).

assertion_table_init(assertion_table(0, AssertionMap)) :-
	map__init(AssertionMap).

assertion_table_add_assertion(Assertion, Id, AssertionTable0, AssertionTable) :-
	AssertionTable0 = assertion_table(Id, AssertionMap0),
	map__det_insert(AssertionMap0, Id, Assertion, AssertionMap),
	AssertionTable = assertion_table(Id + 1, AssertionMap).

assertion_table_lookup(AssertionTable, Id, Assertion) :-
	AssertionTable = assertion_table(_MaxId, AssertionMap),
	map__lookup(AssertionMap, Id, Assertion).

assertion_table_pred_ids(assertion_table(_, AssertionMap), PredIds) :-
	map__values(AssertionMap, PredIds).

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- interface.

	%
	% A table recording exclusivity declarations (i.e. promise_exclusive
	% and promise_exclusive_exhaustive).
	%
	% e.g. :- all [X]
	% 		promise_exclusive
	% 		some [Y] (
	% 			p(X, Y)
	% 		;
	% 			q(X)
	% 		).
	%
	% promises that only one of p(X, Y) and q(X) can succeed at a time,
	% although whichever one succeeds may have multiple solutions. See
	% notes/promise_ex.html for details of the declarations.
	%

	% an exclusive_id is the pred_id of an exclusivity declaration,
	% and is useful in distinguishing between the arguments of the
	% operations below on the exclusive_table
:- type exclusive_id	==	pred_id.
:- type exclusive_ids	==	list(pred_id).

:- type exclusive_table.

	% initialise the exclusive_table
:- pred exclusive_table_init(exclusive_table::out) is det.

	% search the exclusive table and return the list of exclusivity
	% declarations that use the predicate given by pred_id
:- pred exclusive_table_search(exclusive_table::in, pred_id::in,
	exclusive_ids::out) is semidet.

	% as for search, but aborts if no exclusivity declarations are
	% found
:- pred exclusive_table_lookup(exclusive_table::in, pred_id::in,
	exclusive_ids::out) is det.

	% optimises the exclusive_table
:- pred exclusive_table_optimize(exclusive_table::in, exclusive_table::out)
	is det.

	% add to the exclusive table that pred_id is used in the
	% exclusivity declaration exclusive_id
:- pred exclusive_table_add(pred_id::in, exclusive_id::in,
	exclusive_table::in, exclusive_table::out) is det.

%-----------------------------------------------------------------------------%

:- implementation.

:- import_module multi_map.

:- type exclusive_table		==	multi_map(pred_id, exclusive_id).

exclusive_table_init(ExclusiveTable) :-
	multi_map__init(ExclusiveTable).

exclusive_table_lookup(ExclusiveTable, PredId, ExclusiveIds) :-
	multi_map__lookup(ExclusiveTable, PredId, ExclusiveIds).

exclusive_table_search(ExclusiveTable, Id, ExclusiveIds) :-
	multi_map__search(ExclusiveTable, Id, ExclusiveIds).

exclusive_table_optimize(ExclusiveTable0, ExclusiveTable) :-
	multi_map__optimize(ExclusiveTable0, ExclusiveTable).

exclusive_table_add(ExclusiveId, PredId, ExclusiveTable0, ExclusiveTable) :-
	multi_map__set(ExclusiveTable0, PredId, ExclusiveId, ExclusiveTable).
