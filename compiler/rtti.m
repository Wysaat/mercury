%-----------------------------------------------------------------------------%
% Copyright (C) 2000-2002 The University of Melbourne.
% This file may only be copied under the terms of the GNU General
% Public License - see the file COPYING in the Mercury distribution.
%-----------------------------------------------------------------------------%
%
% Definitions of data structures for representing run-time type information
% within the compiler. When output by rtti_out.m, values of most these types
% will correspond to the types defined in runtime/mercury_type_info.h;
% the documentation of those types can be found there.
% The code to generate the structures is in type_ctor_info.m.
% See also pseudo_type_info.m.
%
% This module is independent of whether we are compiling to LLDS or MLDS.
% It is used as an intermediate data structure that we generate from the
% HLDS, and which we can then convert to either LLDS or MLDS.
% The LLDS actually incorporates this data structure unchanged.
%
% Authors: zs, fjh.

%-----------------------------------------------------------------------------%

:- module rtti.

:- interface.

:- import_module prog_data.
:- import_module hlds_module, hlds_pred, hlds_data.
:- import_module pseudo_type_info, code_model.

:- import_module bool, list, std_util.

	% For a given du type and a primary tag value, this says where,
	% if anywhere, the secondary tag is.
:- type sectag_locn
	--->	sectag_none
	;	sectag_local
	;	sectag_remote.

	% For a given du family type, this says whether the user has defined
	% their own unification predicate.
:- type equality_axioms
	--->	standard
	;	user_defined.

	% For a notag or equiv type, this says whether the target type
	% contains variables or not.
:- type equiv_type_inst
	--->	equiv_type_is_ground
	;	equiv_type_is_not_ground.

	% The compiler is concerned with the type constructor representations
	% of only the types it generates RTTI information for; it need not and
	% does not know about the type_ctor_reps of types which have
	% hand-defined RTTI.
:- type type_ctor_rep
	--->	enum(equality_axioms)
	;	du(equality_axioms)
	;	reserved_addr(equality_axioms)
	;	notag(equality_axioms, equiv_type_inst)
	;	equiv(equiv_type_inst)
	;	unknown.

	% Different kinds of types have different type_layout information
	% generated for them, and some have no type_layout info at all.
	% This type represents values that will be put into the type_layout
	% field of a MR_TypeCtorInfo.
:- type type_ctor_layout_info
	--->	enum_layout(
			rtti_name
		)
	;	notag_layout(
			rtti_name
		)
	;	du_layout(
			rtti_name
		)
	;	reserved_addr_layout(
			rtti_name
		)
	;	equiv_layout(
			rtti_data	% a pseudo_type_info rtti_data
		)
	;	no_layout.

	% Different kinds of types have different type_functors information
	% generated for them, and some have no type_functors info at all.
	% This type represents values that will be put into the type_functors
	% field of a MR_TypeCtorInfo.
:- type type_ctor_functors_info
	--->	enum_functors(
			rtti_name
		)
	;	notag_functors(
			rtti_name
		)
	;	du_functors(
			rtti_name
		)
	;	no_functors.

	% This type corresponds to the C type MR_DuExistLocn.
:- type exist_typeinfo_locn
	--->	plain_typeinfo(
			int			% The typeinfo is stored
						% directly in the cell, at this
						% offset.
		)
	;	typeinfo_in_tci(
			int,			% The typeinfo is stored
						% indirectly in the typeclass
						% info stored at this offset
						% in the cell.
			int			% To find the typeinfo inside
						% the typeclass info structure,
						% give this integer to the
						% MR_typeclass_info_type_info
						% macro.
		).

	% This type corresponds to the MR_DuPtagTypeLayout C type.
:- type du_ptag_layout
	--->	du_ptag_layout(
			int,			% number of function symbols
						% sharing this primary tag
			sectag_locn,
			rtti_name		% a vector of size num_sharers;
						% element N points to the
						% functor descriptor for the
						% functor with secondary tag S;
						% if sectag_locn is none, S=0
		).

	% Values of this type uniquely identify a type in the program.
:- type rtti_type_ctor
	--->	rtti_type_ctor(
			module_name,		% module name
			string,			% type ctor's name
			arity			% type ctor's arity
		).

	% Global data generated by the compiler. Usually readonly,
	% with one exception: data containing code addresses must
	% be initialized at runtime in grades that don't support static
	% code initializers.
:- type rtti_data
	--->	exist_locns(
			rtti_type_ctor,		% identifies the type
			int,			% identifies functor in type

			% The remaining argument of this function symbol
			% corresponds to an array of MR_ExistTypeInfoLocns.

			list(exist_typeinfo_locn)
		)
	;	exist_info(
			rtti_type_ctor,		% identifies the type
			int,			% identifies functor in type

			% The remaining arguments of this function symbol
			% correspond to the MR_DuExistInfo C type.

			int,			% number of plain typeinfos
			int,			% number of typeinfos in tcis
			int,			% number of tcis
			rtti_name		% table of typeinfo locations
		)
	;	field_names(
			rtti_type_ctor,		% identifies the type
			int,			% identifies functor in type

			list(maybe(string))	% gives the field names
		)
	;	field_types(
			rtti_type_ctor,		% identifies the type
			int,			% identifies functor in type

			list(rtti_data)		% gives the field types
						% (as pseudo_type_info
						% rtti_data)
		)
	;	reserved_addrs(
			rtti_type_ctor,		% identifies the type

			% The remaining argument of this function symbol
			% corresponds to an array of const void *.

			list(reserved_address)	% gives the values of the
						% reserved addresses for that
						% type
		)
	;	reserved_addr_functors(
			rtti_type_ctor,		% identifies the type

			% The remaining argument of this function symbol
			% corresponds to an array of MR_ReservedAddrFunctorDesc

			list(rtti_name)		% gives the functor descriptors
						% for the reserved_addr
						% functors for that type
		)
	;	enum_functor_desc(
			rtti_type_ctor,		% identifies the type

			% The remaining arguments of this function symbol
			% correspond one-to-one to the fields of
			% MR_EnumFunctorDesc.

			string,			% functor name
			int			% ordinal number of functor
						% (also its value)
		)
	;	notag_functor_desc(
			rtti_type_ctor,		% identifies the type

			% The remaining arguments of this function symbol
			% correspond one-to-one to the fields of
			% the MR_NotagFunctorDesc C type.

			string,			% functor name
			rtti_data,		% pseudo typeinfo of argument
						% (as a pseudo_type_info
						% rtti_data)
			maybe(string)		% the argument's name, if any
		)
	;	du_functor_desc(
			rtti_type_ctor,		% identifies the type

			% The remaining arguments of this function symbol
			% correspond one-to-one to the fields of
			% the MR_DuFunctorDesc C type.

			string,			% functor name
			int,			% functor primary tag
			int,			% functor secondary tag
			sectag_locn,
			int,			% ordinal number of functor
						% in type definition
			arity,			% the functor's visible arity
			int,			% a bit vector of size at most
						% contains_var_bit_vector_size
						% which contains a 1 bit in the
						% position given by 1 << N if
						% the type of argument N
						% contains variables (assuming
						% that arguments are numbered
						% from zero)
			maybe(rtti_name),	% a vector of length arity
						% containing the pseudo
						% typeinfos of the arguments,
						% if any
						% (a field_types rtti_name)
			maybe(rtti_name),	% possibly a vector of length
						% arity containing the names
						% of the arguments, if any
						% (a field_names rtti_name)
			maybe(rtti_name)	% information about the
						% existentially quantified
						% type variables, if any
						% (an exist_info rtti_name)
		)
	;	reserved_addr_functor_desc(
			rtti_type_ctor,		% identifies the type

			% The remaining arguments of this function symbol
			% correspond one-to-one to the fields of
			% MR_ReservedAddrFunctorDesc.

			string,			% functor name
			int,			% ordinal number of functor
			reserved_address	% value
		)
	;	enum_name_ordered_table(
			rtti_type_ctor,		% identifies the type

			% The remaining argument of this function symbol
			% corresponds to the functors_enum alternative of
			% the MR_TypeFunctors C type.

			list(rtti_name)
		)	
	;	enum_value_ordered_table(
			rtti_type_ctor,		% identifies the type

			% The remaining argument of this function symbol
			% corresponds to the MR_EnumTypeLayout C type.

			list(rtti_name)
		)	
	;	reserved_addr_table(
			rtti_type_ctor,		% identifies the type

			% The remaining argument of this function symbol
			% corresponds to the functors_du alternative of
			% the MR_ReservedAddrTypeDesc C type.
			int,		% number of reserved numeric addresses
			int,		% number of reserved symbolic addresses
			rtti_name,	% the values of the reserved addresses
			rtti_name,	% the reserved_addr_functor_descs
					% for all the constants that are
					% represented as reserved addresses
			rtti_name	% the du_ptag_ordered_table for
					% the remaining functors
		)	
	;	du_name_ordered_table(
			rtti_type_ctor,		% identifies the type

			% The remaining argument of this function symbol
			% corresponds to the functors_du alternative of
			% the MR_TypeFunctors C type.

			list(rtti_name)
		)	
	;	du_stag_ordered_table(
			rtti_type_ctor,		% identifies the type
			int,			% primary tag value

			% The remaining argument of this function symbol
			% corresponds to the MR_sectag_alternatives field
			% of the MR_DuPtagTypeLayout C type.

			list(rtti_name)
		)	
	;	du_ptag_ordered_table(
			rtti_type_ctor,		% identifies the type

			% The remaining argument of this function symbol
			% corresponds to the elements of the MR_DuTypeLayout
			% C type.

			list(du_ptag_layout)
		)	
	;	type_ctor_info(
			% The arguments of this function symbol correspond
			% one-to-one to the fields of the MR_TypeCtorInfo
			% C type.

			rtti_type_ctor,		% identifies the type ctor
			maybe(rtti_proc_label),	% unify
			maybe(rtti_proc_label),	% compare
			type_ctor_rep,
			int,			% RTTI version number
			int,			% num of ptags used if ctor_rep
						% is DU or DUUSEREQ
			int,			% number of functors in type
			type_ctor_functors_info,% the functor layout
			type_ctor_layout_info	% the layout table
			% maybe(rtti_name),	% the type's hash cons table
			% maybe(rtti_proc_label)% prettyprinter
		)
	;	pseudo_type_info(pseudo_type_info)
	;	base_typeclass_info(
			module_name,	% module containing instance decl.
			class_id,	% specifies class name & class arity
			string,		% encodes the names and arities of the
					% types in the instance declaration

			base_typeclass_info
		)
	.

:- type rtti_name
	--->	exist_locns(int)		% functor ordinal
	;	exist_info(int)			% functor ordinal
	;	field_names(int)		% functor ordinal
	;	field_types(int)		% functor ordinal
	;	reserved_addrs
	;	reserved_addr_functors
	;	enum_functor_desc(int)		% functor ordinal
	;	notag_functor_desc
	;	du_functor_desc(int)		% functor ordinal
	;	reserved_addr_functor_desc(int)	% functor ordinal
	;	enum_name_ordered_table
	;	enum_value_ordered_table
	;	du_name_ordered_table
	;	du_stag_ordered_table(int)	% primary tag
	;	du_ptag_ordered_table
	;	reserved_addr_table
	;	type_ctor_info
	;	pseudo_type_info(pseudo_type_info)
	;	base_typeclass_info(
			module_name,	% module containing instance decl.
			class_id,	% specifies class name & class arity
			string		% encodes the names and arities of the
					% types in the instance declaration
		)
	;	type_hashcons_pointer.

	% A base_typeclass_info holds information about a typeclass instance.
	% See notes/type_class_transformation.html for details.
:- type base_typeclass_info --->
	base_typeclass_info(
			% num_extra = num_unconstrained + num_constraints,
			% where num_unconstrained is the number of
			% unconstrained type variables from the head
			% of the instance declaration.
		num_extra :: int,
			% num_constraints is the number of constraints
			% on the instance declaration
		num_constraints :: int,
			% num_superclasses is the number of constraints
			% on the typeclass declaration.
		num_superclasses :: int,
			% class_arity is the number of type variables
			% in the head of the class declaration
		class_arity :: int,
			% num_methods is the number of procedures
			% in the typeclass declaration
		num_methods :: int,
			% methods is a list of length num_methods
			% containing the addresses of the methods
			% for this instance declaration.
		methods :: list(rtti_proc_label)
	).

	% convert a rtti_data to an rtti_type_ctor and an rtti_name.
	% This calls error/1 if the argument is a type_var/1 rtti_data,
	% since there is no rtti_type_ctor to return in that case.
:- pred rtti_data_to_name(rtti_data::in, rtti_type_ctor::out, rtti_name::out)
	is det.

	% return yes iff the specified rtti_name is an array
:- func rtti_name_has_array_type(rtti_name) = bool.

	% return yes iff the specified rtti_name should be exported
	% for use by other modules.
:- func rtti_name_is_exported(rtti_name) = bool.

	% The rtti_proc_label type holds all the information about a procedure
	% that we need to compute the entry label for that procedure
	% in the target language (the llds__code_addr or mlds__code_addr).
:- type rtti_proc_label
	--->	rtti_proc_label(
			pred_or_func		::	pred_or_func,
			this_module		::	module_name,
			pred_module		::	module_name,
			pred_name		::	string,
			arity			::	arity,
			arg_types		::	list(type),
			pred_id			::	pred_id,
			proc_id			::	proc_id,
			proc_varset		::	prog_varset,
			proc_headvars		::	list(prog_var),
			proc_arg_modes		::	list(arg_mode),
			proc_interface_code_model ::	code_model,
			%
			% The following booleans hold values computed from the
			% pred_info, using procedures
			%	pred_info_is_imported/1,
			%	pred_info_is_pseudo_imported/1,
			%	procedure_is_exported/2, and
			%	pred_info_is_compiler_generated/1
			% respectively.
			% We store booleans here, rather than storing the
			% pred_info, to avoid retaining a reference to the
			% parts of the pred_info that we aren't interested in,
			% so that those parts can be garbage collected.
			% We use booleans rather than an import_status
			% so that we can continue to use the above-mentioned
			% abstract interfaces rather than hard-coding tests
			% on the import_status.
			%
			is_imported			::	bool,
			is_pseudo_imported		::	bool,
			is_exported			::	bool,
			is_special_pred_instance	::	bool
		).

	% Construct an rtti_proc_label for a given procedure.
:- func rtti__make_proc_label(module_info, pred_id, proc_id) = rtti_proc_label.

	% Construct an rtti_proc_label for a given procedure.
:- pred rtti__proc_label_pred_proc_id(rtti_proc_label::in,
	pred_id::out, proc_id::out) is det.

	% Return the C variable name of the RTTI data structure identified
	% by the input arguments.
	% XXX this should be in rtti_out.m
:- pred rtti__addr_to_string(rtti_type_ctor::in, rtti_name::in, string::out)
	is det.

	% Return the C representation of a secondary tag location.
	% XXX this should be in rtti_out.m
:- pred rtti__sectag_locn_to_string(sectag_locn::in, string::out) is det.

	% Return the C representation of a type_ctor_rep value.
	% XXX this should be in rtti_out.m
:- pred rtti__type_ctor_rep_to_string(type_ctor_rep::in, string::out) is det.

:- implementation.

:- import_module code_util.	% for code_util__compiler_generated
:- import_module llds_out.	% for name_mangle and sym_name_mangle
:- import_module hlds_data, type_util, mode_util.

:- import_module string, require.

rtti_data_to_name(exist_locns(RttiTypeCtor, Ordinal, _),
	RttiTypeCtor, exist_locns(Ordinal)).
rtti_data_to_name(exist_info(RttiTypeCtor, Ordinal, _, _, _, _),
	RttiTypeCtor, exist_info(Ordinal)).
rtti_data_to_name(field_names(RttiTypeCtor, Ordinal, _),
	RttiTypeCtor, field_names(Ordinal)).
rtti_data_to_name(field_types(RttiTypeCtor, Ordinal, _),
	RttiTypeCtor, field_types(Ordinal)).
rtti_data_to_name(reserved_addrs(RttiTypeCtor, _),
	RttiTypeCtor, reserved_addrs).
rtti_data_to_name(reserved_addr_functors(RttiTypeCtor, _),
	RttiTypeCtor, reserved_addr_functors).
rtti_data_to_name(enum_functor_desc(RttiTypeCtor, _, Ordinal),
	RttiTypeCtor, enum_functor_desc(Ordinal)).
rtti_data_to_name(notag_functor_desc(RttiTypeCtor, _, _, _),
	RttiTypeCtor, notag_functor_desc).
rtti_data_to_name(du_functor_desc(RttiTypeCtor, _,_,_,_, Ordinal, _,_,_,_,_),
	RttiTypeCtor, du_functor_desc(Ordinal)).
rtti_data_to_name(reserved_addr_functor_desc(RttiTypeCtor, _, Ordinal, _),
	RttiTypeCtor, reserved_addr_functor_desc(Ordinal)).
rtti_data_to_name(enum_name_ordered_table(RttiTypeCtor, _),
	RttiTypeCtor, enum_name_ordered_table).
rtti_data_to_name(enum_value_ordered_table(RttiTypeCtor, _),
	RttiTypeCtor, enum_value_ordered_table).
rtti_data_to_name(du_name_ordered_table(RttiTypeCtor, _),
	RttiTypeCtor, du_name_ordered_table).
rtti_data_to_name(du_stag_ordered_table(RttiTypeCtor, Ptag, _),
	RttiTypeCtor, du_stag_ordered_table(Ptag)).
rtti_data_to_name(du_ptag_ordered_table(RttiTypeCtor, _),
	RttiTypeCtor, du_ptag_ordered_table).
rtti_data_to_name(reserved_addr_table(RttiTypeCtor, _, _, _, _, _),
	RttiTypeCtor, reserved_addr_table).
rtti_data_to_name(type_ctor_info(RttiTypeCtor, _,_,_,_,_,_,_,_),
	RttiTypeCtor, type_ctor_info).
rtti_data_to_name(base_typeclass_info(_, _, _, _), _, _) :-
	% there's no rtti_type_ctor associated with a base_typeclass_info
	error("rtti_data_to_name: base_typeclass_info").
rtti_data_to_name(pseudo_type_info(PseudoTypeInfo), RttiTypeCtor,
		pseudo_type_info(PseudoTypeInfo)) :-
	RttiTypeCtor = pti_get_rtti_type_ctor(PseudoTypeInfo).

:- func pti_get_rtti_type_ctor(pseudo_type_info) = rtti_type_ctor.

pti_get_rtti_type_ctor(type_ctor_info(RttiTypeCtor)) = RttiTypeCtor.
pti_get_rtti_type_ctor(type_info(RttiTypeCtor, _)) = RttiTypeCtor.
pti_get_rtti_type_ctor(higher_order_type_info(RttiTypeCtor, _, _)) =
	RttiTypeCtor.
pti_get_rtti_type_ctor(type_var(_)) = _ :-
	% there's no rtti_type_ctor associated with a type_var
	error("rtti_data_to_name: type_var").

rtti_name_has_array_type(exist_locns(_))		= yes.
rtti_name_has_array_type(exist_info(_))			= no.
rtti_name_has_array_type(field_names(_))		= yes.
rtti_name_has_array_type(field_types(_))		= yes.
rtti_name_has_array_type(reserved_addrs)		= yes.
rtti_name_has_array_type(reserved_addr_functors)	= yes.
rtti_name_has_array_type(enum_functor_desc(_))		= no.
rtti_name_has_array_type(notag_functor_desc)		= no.
rtti_name_has_array_type(du_functor_desc(_))		= no.
rtti_name_has_array_type(reserved_addr_functor_desc(_))	= no.
rtti_name_has_array_type(enum_name_ordered_table)	= yes.
rtti_name_has_array_type(enum_value_ordered_table)	= yes.
rtti_name_has_array_type(du_name_ordered_table)		= yes.
rtti_name_has_array_type(du_stag_ordered_table(_))	= yes.
rtti_name_has_array_type(du_ptag_ordered_table)		= yes.
rtti_name_has_array_type(reserved_addr_table)		= no.
rtti_name_has_array_type(type_ctor_info)		= no.
rtti_name_has_array_type(pseudo_type_info(_))		= no.
rtti_name_has_array_type(base_typeclass_info(_, _, _))	= yes.
rtti_name_has_array_type(type_hashcons_pointer)		= no.

rtti_name_is_exported(exist_locns(_))		= no.
rtti_name_is_exported(exist_info(_))            = no.
rtti_name_is_exported(field_names(_))           = no.
rtti_name_is_exported(field_types(_))           = no.
rtti_name_is_exported(reserved_addrs)           = no.
rtti_name_is_exported(reserved_addr_functors)   = no.
rtti_name_is_exported(enum_functor_desc(_))     = no.
rtti_name_is_exported(notag_functor_desc)       = no.
rtti_name_is_exported(du_functor_desc(_))       = no.
rtti_name_is_exported(reserved_addr_functor_desc(_)) = no.
rtti_name_is_exported(enum_name_ordered_table)  = no.
rtti_name_is_exported(enum_value_ordered_table) = no.
rtti_name_is_exported(du_name_ordered_table)    = no.
rtti_name_is_exported(du_stag_ordered_table(_)) = no.
rtti_name_is_exported(du_ptag_ordered_table)    = no.
rtti_name_is_exported(reserved_addr_table)      = no.
rtti_name_is_exported(type_ctor_info)           = yes.
rtti_name_is_exported(pseudo_type_info(Pseudo)) =
	pseudo_type_info_is_exported(Pseudo).
rtti_name_is_exported(base_typeclass_info(_, _, _)) = yes.
rtti_name_is_exported(type_hashcons_pointer)    = no.

:- func pseudo_type_info_is_exported(pseudo_type_info) = bool.
pseudo_type_info_is_exported(type_var(_))			= no.
pseudo_type_info_is_exported(type_ctor_info(_))			= yes.
pseudo_type_info_is_exported(type_info(_, _))			= no.
pseudo_type_info_is_exported(higher_order_type_info(_, _, _))	= no.

rtti__make_proc_label(ModuleInfo, PredId, ProcId) = ProcLabel :-
	module_info_name(ModuleInfo, ThisModule),
	module_info_pred_proc_info(ModuleInfo, PredId, ProcId,
		PredInfo, ProcInfo),
	pred_info_get_is_pred_or_func(PredInfo, PredOrFunc),
	pred_info_module(PredInfo, PredModule),
	pred_info_name(PredInfo, PredName),
	pred_info_arity(PredInfo, Arity),
	pred_info_arg_types(PredInfo, ArgTypes),
	proc_info_varset(ProcInfo, ProcVarSet),
	proc_info_headvars(ProcInfo, ProcHeadVars),
	proc_info_argmodes(ProcInfo, ProcModes),
	proc_info_interface_code_model(ProcInfo, ProcCodeModel),
	modes_to_arg_modes(ModuleInfo, ProcModes, ArgTypes, ProcArgModes),
	IsImported = (pred_info_is_imported(PredInfo) -> yes ; no),
	IsPseudoImp = (pred_info_is_pseudo_imported(PredInfo) -> yes ; no),
	IsExported = (procedure_is_exported(PredInfo, ProcId) -> yes ; no),
	IsSpecialPredInstance =
		(code_util__compiler_generated(PredInfo) -> yes ; no),
	ProcLabel = rtti_proc_label(PredOrFunc, ThisModule, PredModule,
		PredName, Arity, ArgTypes, PredId, ProcId,
		ProcVarSet, ProcHeadVars, ProcArgModes, ProcCodeModel,
		IsImported, IsPseudoImp, IsExported, IsSpecialPredInstance).

rtti__proc_label_pred_proc_id(ProcLabel, PredId, ProcId) :-
	ProcLabel = rtti_proc_label(_, _, _, _, _, _, PredId, ProcId,
		_, _, _, _, _, _, _, _).

rtti__addr_to_string(RttiTypeCtor, RttiName, Str) :-
	rtti__mangle_rtti_type_ctor(RttiTypeCtor, ModuleName, TypeName, A_str),
	(
		RttiName = exist_locns(Ordinal),
		string__int_to_string(Ordinal, O_str),
		string__append_list([ModuleName, "__exist_locns_",
			TypeName, "_", A_str, "_", O_str], Str)
	;
		RttiName = exist_info(Ordinal),
		string__int_to_string(Ordinal, O_str),
		string__append_list([ModuleName, "__exist_info_",
			TypeName, "_", A_str, "_", O_str], Str)
	;
		RttiName = field_names(Ordinal),
		string__int_to_string(Ordinal, O_str),
		string__append_list([ModuleName, "__field_names_",
			TypeName, "_", A_str, "_", O_str], Str)
	;
		RttiName = field_types(Ordinal),
		string__int_to_string(Ordinal, O_str),
		string__append_list([ModuleName, "__field_types_",
			TypeName, "_", A_str, "_", O_str], Str)
	;
		RttiName = reserved_addrs,
		string__append_list([ModuleName, "__reserved_addrs_",
			TypeName, "_", A_str], Str)
	;
		RttiName = reserved_addr_functors,
		string__append_list([ModuleName, "__reserved_addr_functors_",
			TypeName, "_", A_str], Str)
	;
		RttiName = enum_functor_desc(Ordinal),
		string__int_to_string(Ordinal, O_str),
		string__append_list([ModuleName, "__enum_functor_desc_",
			TypeName, "_", A_str, "_", O_str], Str)
	;
		RttiName = notag_functor_desc,
		string__append_list([ModuleName, "__notag_functor_desc_",
			TypeName, "_", A_str], Str)
	;
		RttiName = du_functor_desc(Ordinal),
		string__int_to_string(Ordinal, O_str),
		string__append_list([ModuleName, "__du_functor_desc_",
			TypeName, "_", A_str, "_", O_str], Str)
	;
		RttiName = reserved_addr_functor_desc(Ordinal),
		string__int_to_string(Ordinal, O_str),
		string__append_list([ModuleName, "__reserved_addr_functor_desc_",
			TypeName, "_", A_str, "_", O_str], Str)
	;
		RttiName = enum_name_ordered_table,
		string__append_list([ModuleName, "__enum_name_ordered_",
			TypeName, "_", A_str], Str)
	;
		RttiName = enum_value_ordered_table,
		string__append_list([ModuleName, "__enum_value_ordered_",
			TypeName, "_", A_str], Str)
	;
		RttiName = du_name_ordered_table,
		string__append_list([ModuleName, "__du_name_ordered_",
			TypeName, "_", A_str], Str)
	;
		RttiName = du_stag_ordered_table(Ptag),
		string__int_to_string(Ptag, P_str),
		string__append_list([ModuleName, "__du_stag_ordered_",
			TypeName, "_", A_str, "_", P_str], Str)
	;
		RttiName = du_ptag_ordered_table,
		string__append_list([ModuleName, "__du_ptag_ordered_",
			TypeName, "_", A_str], Str)
	;
		RttiName = reserved_addr_table,
		string__append_list([ModuleName, "__reserved_addr_table_",
			TypeName, "_", A_str], Str)
	;
		RttiName = type_ctor_info,
		string__append_list([ModuleName, "__type_ctor_info_",
			TypeName, "_", A_str], Str)
	;
		RttiName = pseudo_type_info(PseudoTypeInfo),
		rtti__pseudo_type_info_to_string(PseudoTypeInfo, Str)
	;
		RttiName = base_typeclass_info(_ModuleName, ClassId,
			InstanceStr),
		ClassId = class_id(ClassSym, ClassArity),
		llds_out__sym_name_mangle(ClassSym, MangledClassString),
		string__int_to_string(ClassArity, ArityString),
		llds_out__name_mangle(InstanceStr, MangledTypeNames),
		string__append_list(["base_typeclass_info_",
			MangledClassString, "__arity", ArityString, "__",
			MangledTypeNames], Str)
	;
		RttiName = type_hashcons_pointer,
		string__append_list([ModuleName, "__hashcons_ptr_",
			TypeName, "_", A_str], Str)
	).

:- pred rtti__mangle_rtti_type_ctor(rtti_type_ctor::in,
	string::out, string::out, string::out) is det.

rtti__mangle_rtti_type_ctor(RttiTypeCtor, ModuleName, TypeName, A_str) :-
	RttiTypeCtor = rtti_type_ctor(ModuleName0, TypeName0, TypeArity),
	llds_out__sym_name_mangle(ModuleName0, ModuleName),
	llds_out__name_mangle(TypeName0, TypeName),
	string__int_to_string(TypeArity, A_str).

:- pred rtti__pseudo_type_info_to_string(pseudo_type_info::in, string::out)
	is det.

rtti__pseudo_type_info_to_string(PseudoTypeInfo, Str) :-
	(
		PseudoTypeInfo = type_var(VarNum),
		string__int_to_string(VarNum, Str)
	;
		PseudoTypeInfo = type_ctor_info(RttiTypeCtor),
		rtti__addr_to_string(RttiTypeCtor, type_ctor_info, Str)
	;
		PseudoTypeInfo = type_info(RttiTypeCtor, ArgTypes),
		rtti__mangle_rtti_type_ctor(RttiTypeCtor,
			ModuleName, TypeName, A_str),
		ATs_str = pseudo_type_list_to_string(ArgTypes),
		string__append_list([ModuleName, "__type_info_",
			TypeName, "_", A_str, ATs_str], Str)
	;
		PseudoTypeInfo = higher_order_type_info(RttiTypeCtor,
			RealArity, ArgTypes),
		rtti__mangle_rtti_type_ctor(RttiTypeCtor,
			ModuleName, TypeName, _A_str),
		ATs_str = pseudo_type_list_to_string(ArgTypes),
		string__int_to_string(RealArity, RA_str),
		string__append_list([ModuleName, "__ho_type_info_",
			TypeName, "_", RA_str, ATs_str], Str)
	).

:- func pseudo_type_list_to_string(list(pseudo_type_info)) = string.
pseudo_type_list_to_string(PseudoTypeList) =
	string__append_list(list__map(pseudo_type_to_string, PseudoTypeList)).

:- func pseudo_type_to_string(pseudo_type_info) = string.
pseudo_type_to_string(type_var(Int)) =
	string__append("__var_", string__int_to_string(Int)).
pseudo_type_to_string(type_ctor_info(TypeCtor)) =
	string__append("__type0_", rtti__type_ctor_to_string(TypeCtor)).
pseudo_type_to_string(type_info(TypeCtor, ArgTypes)) =
	string__append_list([
		"__type_", rtti__type_ctor_to_string(TypeCtor),
		pseudo_type_list_to_string(ArgTypes)
	]).
pseudo_type_to_string(higher_order_type_info(TypeCtor, Arity, ArgTypes)) =
	string__append_list([
		"__ho_type_", rtti__type_ctor_to_string(TypeCtor),
		"_", string__int_to_string(Arity),
		pseudo_type_list_to_string(ArgTypes)
	]).

:- func rtti__type_ctor_to_string(rtti_type_ctor) = string.
rtti__type_ctor_to_string(RttiTypeCtor) = String :-
	rtti__mangle_rtti_type_ctor(RttiTypeCtor, ModuleName, TypeName, A_Str),
	String0 = string__append_list([ModuleName, "__", TypeName, "_", A_Str]),
	% To ensure that the mapping is one-to-one, and to make demangling
	% easier, we insert the length of the string at the start of the string.
	string__length(String0, Length),
	String = string__format("%d_%s", [i(Length), s(String0)]).

rtti__sectag_locn_to_string(sectag_none,   "MR_SECTAG_NONE").
rtti__sectag_locn_to_string(sectag_local,  "MR_SECTAG_LOCAL").
rtti__sectag_locn_to_string(sectag_remote, "MR_SECTAG_REMOTE").

rtti__type_ctor_rep_to_string(du(standard),
	"MR_TYPECTOR_REP_DU").
rtti__type_ctor_rep_to_string(du(user_defined),
	"MR_TYPECTOR_REP_DU_USEREQ").
rtti__type_ctor_rep_to_string(reserved_addr(standard),
	"MR_TYPECTOR_REP_RESERVED_ADDR").
rtti__type_ctor_rep_to_string(reserved_addr(user_defined),
	"MR_TYPECTOR_REP_RESERVED_ADDR_USEREQ").
rtti__type_ctor_rep_to_string(enum(standard),
	"MR_TYPECTOR_REP_ENUM").
rtti__type_ctor_rep_to_string(enum(user_defined),
	"MR_TYPECTOR_REP_ENUM_USEREQ").
rtti__type_ctor_rep_to_string(notag(standard, equiv_type_is_not_ground),
	"MR_TYPECTOR_REP_NOTAG").
rtti__type_ctor_rep_to_string(notag(user_defined, equiv_type_is_not_ground),
	"MR_TYPECTOR_REP_NOTAG_USEREQ").
rtti__type_ctor_rep_to_string(notag(standard, equiv_type_is_ground),
	"MR_TYPECTOR_REP_NOTAG_GROUND").
rtti__type_ctor_rep_to_string(notag(user_defined, equiv_type_is_ground),
	"MR_TYPECTOR_REP_NOTAG_GROUND_USEREQ").
rtti__type_ctor_rep_to_string(equiv(equiv_type_is_not_ground),
	"MR_TYPECTOR_REP_EQUIV").
rtti__type_ctor_rep_to_string(equiv(equiv_type_is_ground),
	"MR_TYPECTOR_REP_EQUIV_GROUND").
rtti__type_ctor_rep_to_string(unknown,
	"MR_TYPECTOR_REP_UNKNOWN").

