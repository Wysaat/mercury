%---------------------------------------------------------------------------%
% Copyright (C) 1994-1999 The University of Melbourne.
% This file may only be copied under the terms of the GNU General
% Public License - see the file COPYING in the Mercury distribution.
%---------------------------------------------------------------------------%
%
% This module handles code generation for "simple" unifications,
% i.e. those unifications which are simple enough for us to generate
% inline code.
%
% For "complicated" unifications, we generate a call to an out-of-line
% unification predicate (the call is handled in call_gen.m) - and then
% eventually generate the out-of-line code (unify_proc.m).
%
%---------------------------------------------------------------------------%

:- module unify_gen.

:- interface.

:- import_module hlds_goal, hlds_data, llds, code_info.
:- import_module prog_data.

:- type test_sense
	--->	branch_on_success
	;	branch_on_failure.

:- pred unify_gen__generate_unification(code_model, unification, code_tree,
	code_info, code_info).
:- mode unify_gen__generate_unification(in, in, out, in, out) is det.

:- pred unify_gen__generate_tag_test(prog_var, cons_id, test_sense, label,
	code_tree, code_info, code_info).
:- mode unify_gen__generate_tag_test(in, in, in, out, out, in, out) is det.

%---------------------------------------------------------------------------%

:- implementation.

:- import_module builtin_ops.
:- import_module hlds_module, hlds_pred, prog_data, prog_out, code_util.
:- import_module mode_util, type_util, code_aux, hlds_out, tree, arg_info.
:- import_module globals, options, continuation_info, stack_layout.

:- import_module term, bool, string, int, list, map, require, std_util.

:- type uni_val		--->	ref(prog_var)
			;	lval(lval).

%---------------------------------------------------------------------------%

unify_gen__generate_unification(CodeModel, Uni, Code) -->
	{ CodeModel = model_non ->
		error("nondet unification in unify_gen__generate_unification")
	;
		true
	},
	(
		{ Uni = assign(Left, Right) },
		unify_gen__generate_assignment(Left, Right, Code)
	;
		{ Uni = construct(Var, ConsId, Args, Modes, _, _, AditiInfo) },
		unify_gen__generate_construction(Var, ConsId,
			Args, Modes, AditiInfo, Code)
	;
		{ Uni = deconstruct(Var, ConsId, Args, Modes, _Det) },
		( { CodeModel = model_det } ->
			unify_gen__generate_det_deconstruction(Var, ConsId,
				Args, Modes, Code)
		;
			unify_gen__generate_semi_deconstruction(Var, ConsId,
				Args, Modes, Code)
		)
	;
		{ Uni = simple_test(Var1, Var2) },
		( { CodeModel = model_det } ->
			{ error("det simple_test during code generation") }
		;
			unify_gen__generate_test(Var1, Var2, Code)
		)
	;
			% These should have been transformed into calls
			% to unification procedures by polymorphism.m.
		{ Uni = complicated_unify(_UniMode, _CanFail, _TypeInfoVars) },
		{ error("complicated unify during code generation") }
	).

%---------------------------------------------------------------------------%

	% assignment unifications are generated by simply caching the
	% bound variable as the expression that generates the free
	% variable. No immediate code is generated.

:- pred unify_gen__generate_assignment(prog_var, prog_var, code_tree,
	code_info, code_info).
:- mode unify_gen__generate_assignment(in, in, out, in, out) is det.

unify_gen__generate_assignment(VarA, VarB, empty) -->
	(
		code_info__variable_is_forward_live(VarA)
	->
		code_info__cache_expression(VarA, var(VarB))
	;
		% For free-free unifications, the mode analysis reports
		% them as assignment to the dead variable.  For such
		% unifications we of course don't generate any code
		{ true }
	).

%---------------------------------------------------------------------------%

	% A [simple] test unification is generated by flushing both
	% variables from the cache, and producing code that branches
	% to the fall-through point if the two values are not the same.
	% Simple tests are in-in unifications on enumerations, integers,
	% strings and floats.

:- pred unify_gen__generate_test(prog_var, prog_var, code_tree,
		code_info, code_info).
:- mode unify_gen__generate_test(in, in, out, in, out) is det.

unify_gen__generate_test(VarA, VarB, Code) -->
	code_info__produce_variable(VarA, Code0, ValA),
	code_info__produce_variable(VarB, Code1, ValB),
	{ CodeA = tree(Code0, Code1) },
	code_info__variable_type(VarA, Type),
	{ Type = term__functor(term__atom("string"), [], _) ->
		Op = str_eq
	; Type = term__functor(term__atom("float"), [], _) ->
		Op = float_eq
	;
		Op = eq
	},
	code_info__fail_if_rval_is_false(binop(Op, ValA, ValB), FailCode),
	{ Code = tree(CodeA, FailCode) }.

%---------------------------------------------------------------------------%

unify_gen__generate_tag_test(Var, ConsId, Sense, ElseLab, Code) -->
	code_info__produce_variable(Var, VarCode, Rval),
	(
		{ ConsId = cons(_, Arity) },
		{ Arity > 0 }
	->
		code_info__variable_type(Var, Type),
		code_info__lookup_type_defn(Type, TypeDefn),
		{ hlds_data__get_type_defn_body(TypeDefn, TypeBody) },
		{
			TypeBody = du_type(_, ConsTable, _, _)
		->
			map__to_assoc_list(ConsTable, ConsList),
			(
				ConsList = [ConsId - _, OtherConsId - _],
				OtherConsId = cons(_, 0)
			->
				Reverse = yes(OtherConsId)
			;
				ConsList = [OtherConsId - _, ConsId - _],
				OtherConsId = cons(_, 0)
			->
				Reverse = yes(OtherConsId)
			;
				Reverse = no
			)
		;
			Reverse = no
		}
	;
		{ Reverse = no }
	),
	code_info__variable_to_string(Var, VarName),
	{ hlds_out__cons_id_to_string(ConsId, ConsIdName) },
	(
		{ Reverse = no },
		{ string__append_list(["checking that ", VarName,
			" has functor ", ConsIdName], Comment) },
		{ CommentCode = node([comment(Comment) - ""]) },
		code_info__cons_id_to_tag(Var, ConsId, Tag),
		{ unify_gen__generate_tag_rval_2(Tag, Rval, TestRval) }
	;
		{ Reverse = yes(TestConsId) },
		{ string__append_list(["checking that ", VarName,
			" has functor ", ConsIdName, " (inverted test)"],
			Comment) },
		{ CommentCode = node([comment(Comment) - ""]) },
		code_info__cons_id_to_tag(Var, TestConsId, Tag),
		{ unify_gen__generate_tag_rval_2(Tag, Rval, NegTestRval) },
		{ code_util__neg_rval(NegTestRval, TestRval) }
	),
	code_info__get_next_label(ElseLab),
	(
		{ Sense = branch_on_success },
		{ TheRval = TestRval }
	;
		{ Sense = branch_on_failure },
		{ code_util__neg_rval(TestRval, TheRval) }
	),
	{ TestCode = node([
		if_val(TheRval, label(ElseLab)) - "tag test"
	]) },
	{ Code = tree(VarCode, tree(CommentCode, TestCode)) }.

%---------------------------------------------------------------------------%

:- pred unify_gen__generate_tag_rval(prog_var, cons_id, rval, code_tree,
	code_info, code_info).
:- mode unify_gen__generate_tag_rval(in, in, out, out, in, out) is det.

unify_gen__generate_tag_rval(Var, ConsId, TestRval, Code) -->
        code_info__produce_variable(Var, Code, Rval),
	code_info__cons_id_to_tag(Var, ConsId, Tag),
	{ unify_gen__generate_tag_rval_2(Tag, Rval, TestRval) }.

:- pred unify_gen__generate_tag_rval_2(cons_tag, rval, rval).
:- mode unify_gen__generate_tag_rval_2(in, in, out) is det.

unify_gen__generate_tag_rval_2(string_constant(String), Rval, TestRval) :-
	TestRval = binop(str_eq, Rval, const(string_const(String))).
unify_gen__generate_tag_rval_2(float_constant(Float), Rval, TestRval) :-
	TestRval = binop(float_eq, Rval, const(float_const(Float))).
unify_gen__generate_tag_rval_2(int_constant(Int), Rval, TestRval) :-
	TestRval = binop(eq, Rval, const(int_const(Int))).
unify_gen__generate_tag_rval_2(pred_closure_tag(_, _, _), _Rval, _TestRval) :-
	% This should never happen, since the error will be detected
	% during mode checking.
	error("Attempted higher-order unification").
unify_gen__generate_tag_rval_2(code_addr_constant(_, _), _Rval, _TestRval) :-
	% This should never happen
	error("Attempted code_addr unification").
unify_gen__generate_tag_rval_2(type_ctor_info_constant(_, _, _), _, _) :-
	% This should never happen
	error("Attempted type_ctor_info unification").
unify_gen__generate_tag_rval_2(base_typeclass_info_constant(_, _, _), _, _) :-
	% This should never happen
	error("Attempted base_typeclass_info unification").
unify_gen__generate_tag_rval_2(tabling_pointer_constant(_, _), _, _) :-
	% This should never happen
	error("Attempted tabling_pointer unification").
unify_gen__generate_tag_rval_2(no_tag, _Rval, TestRval) :-
	TestRval = const(true).
unify_gen__generate_tag_rval_2(unshared_tag(UnsharedTag), Rval, TestRval) :-
	TestRval = binop(eq,	unop(tag, Rval),
				unop(mktag, const(int_const(UnsharedTag)))).
unify_gen__generate_tag_rval_2(shared_remote_tag(Bits, Num), Rval, TestRval) :-
	TestRval = binop(and,
			binop(eq,	unop(tag, Rval),
					unop(mktag, const(int_const(Bits)))), 
			binop(eq,	lval(field(yes(Bits), Rval,
						const(int_const(0)))),
					const(int_const(Num)))).
unify_gen__generate_tag_rval_2(shared_local_tag(Bits, Num), Rval,
		TestRval) :-
	TestRval = binop(eq,	Rval,
			mkword(Bits, unop(mkbody, const(int_const(Num))))).

%---------------------------------------------------------------------------%

	% A construction unification consists of a heap-increment to
	% create a term, and a series of [optional] assignments to
	% instantiate the arguments of that term.

:- pred unify_gen__generate_construction(prog_var, cons_id,
		list(prog_var), list(uni_mode), maybe(rl_exprn_id),
		code_tree, code_info, code_info).
:- mode unify_gen__generate_construction(in, in, in, in,
		in, out, in, out) is det.

unify_gen__generate_construction(Var, Cons, Args, Modes, AditiInfo, Code) -->
	code_info__cons_id_to_tag(Var, Cons, Tag),
	unify_gen__generate_construction_2(Tag, Var, Args,
		Modes, AditiInfo, Code).

:- pred unify_gen__generate_construction_2(cons_tag, prog_var, 
		list(prog_var), list(uni_mode), maybe(rl_exprn_id),
		code_tree, code_info, code_info).
:- mode unify_gen__generate_construction_2(in, in, in, in, in, out,
					in, out) is det.

unify_gen__generate_construction_2(string_constant(String),
		Var, _Args, _Modes, _, Code) -->
	{ Code = empty },
	code_info__cache_expression(Var, const(string_const(String))).
unify_gen__generate_construction_2(int_constant(Int),
		Var, _Args, _Modes, _, Code) -->
	{ Code = empty },
	code_info__cache_expression(Var, const(int_const(Int))).
unify_gen__generate_construction_2(float_constant(Float),
		Var, _Args, _Modes, _, Code) -->
	{ Code = empty },
	code_info__cache_expression(Var, const(float_const(Float))).
unify_gen__generate_construction_2(no_tag, Var, Args, Modes, _, Code) -->
	( { Args = [Arg], Modes = [Mode] } ->
		code_info__variable_type(Arg, Type),
		unify_gen__generate_sub_unify(ref(Var), ref(Arg),
			Mode, Type, Code)
	;
		{ error(
		"unify_gen__generate_construction_2: no_tag: arity != 1") }
	).
unify_gen__generate_construction_2(unshared_tag(UnsharedTag),
		Var, Args, Modes, _, Code) -->
	code_info__get_module_info(ModuleInfo),
	code_info__get_next_cell_number(CellNo),
	unify_gen__var_types(Args, ArgTypes),
	{ unify_gen__generate_cons_args(Args, ArgTypes, Modes, ModuleInfo,
		RVals) },
	{ Code = empty },
	code_info__variable_type(Var, VarType),
	{ unify_gen__var_type_msg(VarType, VarTypeMsg) },
	% XXX Later we will need to worry about
	% whether the cell must be unique or not.
	{ Expr = create(UnsharedTag, RVals, uniform(no), can_be_either,
		CellNo, VarTypeMsg) },
	code_info__cache_expression(Var, Expr).
unify_gen__generate_construction_2(shared_remote_tag(Bits0, Num0),
		Var, Args, Modes, _, Code) -->
	code_info__get_module_info(ModuleInfo),
	code_info__get_next_cell_number(CellNo),
	unify_gen__var_types(Args, ArgTypes),
	{ unify_gen__generate_cons_args(Args, ArgTypes, Modes, ModuleInfo,
		RVals0) },
		% the first field holds the secondary tag
	{ RVals = [yes(const(int_const(Num0))) | RVals0] },
	{ Code = empty },
	code_info__variable_type(Var, VarType),
	{ unify_gen__var_type_msg(VarType, VarTypeMsg) },
	% XXX Later we will need to worry about
	% whether the cell must be unique or not.
	{ Expr = create(Bits0, RVals, uniform(no), can_be_either,
		CellNo, VarTypeMsg) },
	code_info__cache_expression(Var, Expr).
unify_gen__generate_construction_2(shared_local_tag(Bits1, Num1),
		Var, _Args, _Modes, _, Code) -->
	{ Code = empty },
	code_info__cache_expression(Var,
		mkword(Bits1, unop(mkbody, const(int_const(Num1))))).
unify_gen__generate_construction_2(type_ctor_info_constant(ModuleName,
		TypeName, TypeArity), Var, Args, _Modes, _, Code) -->
	( { Args = [] } ->
		[]
	;
		{ error("unify_gen: type-info constant has args") }
	),
	{ Code = empty },
	code_info__cache_expression(Var, const(data_addr_const(data_addr(
		ModuleName, type_ctor(info, TypeName, TypeArity))))).
unify_gen__generate_construction_2(base_typeclass_info_constant(ModuleName,
		ClassId, Instance), Var, Args, _Modes, _, Code) -->
	( { Args = [] } ->
		[]
	;
		{ error("unify_gen: typeclass-info constant has args") }
	),
	{ Code = empty },
	code_info__cache_expression(Var, const(data_addr_const(data_addr(
		ModuleName, base_typeclass_info(ClassId, Instance))))).
unify_gen__generate_construction_2(tabling_pointer_constant(PredId, ProcId),
		Var, Args, _Modes, _, Code) -->
	( { Args = [] } ->
		[]
	;
		{ error("unify_gen: tabling pointer constant has args") }
	),
	{ Code = empty },
	code_info__get_module_info(ModuleInfo),
	{ code_util__make_proc_label(ModuleInfo, PredId, ProcId, ProcLabel) },
	{ module_info_name(ModuleInfo, ModuleName) },
	{ DataAddr = data_addr(ModuleName, tabling_pointer(ProcLabel)) },
	code_info__cache_expression(Var, const(data_addr_const(DataAddr))).
unify_gen__generate_construction_2(code_addr_constant(PredId, ProcId),
		Var, Args, _Modes, _, Code) -->
	( { Args = [] } ->
		[]
	;
		{ error("unify_gen: address constant has args") }
	),
	{ Code = empty },
	code_info__get_module_info(ModuleInfo),
	code_info__make_entry_label(ModuleInfo, PredId, ProcId, no, CodeAddr),
	code_info__cache_expression(Var, const(code_addr_const(CodeAddr))).
unify_gen__generate_construction_2(
		pred_closure_tag(PredId, ProcId, EvalMethod),
		Var, Args, _Modes, _AditiInfo, Code) -->
	% This code constructs or extends a closure.
	% The structure of closures is defined in runtime/mercury_ho_call.h.

	code_info__get_module_info(ModuleInfo),
	{ module_info_preds(ModuleInfo, Preds) },
	{ map__lookup(Preds, PredId, PredInfo) },
	{ pred_info_procedures(PredInfo, Procs) },
	{ map__lookup(Procs, ProcId, ProcInfo) },
%
% We handle currying of a higher-order pred variable as a special case.
% We recognize
%
%	P = l(P0, X, Y, Z)
%
%  where
%
%	l(P0, A, B, C, ...) :- P0(A, B, C, ...).  % higher-order call
%
% as a special case, and generate special code to construct the
% new closure P from the old closure P0 by appending the args X, Y, Z.
% The advantage of this optimization is that when P is called, we
% will only need to do one indirect call rather than two.
% Its disadvantage is that the cost of creating the closure P is greater.
% Whether this is a net win depend on the number of times P is called.
%
% The pattern that this optimization looks for happens rarely at the moment.
% The reason is that although we allow the creation of closures with a simple
% syntax (e.g. P0 = append4([1])), we don't allow their extension with a
% similarly simple syntax (e.g. P = call(P0, [2])). In fact, typecheck.m
% contains code to detect such constructs, because it does not have code
% to typecheck them (you get a message about call/2 should be used as a goal,
% not an expression).
%
	{ proc_info_goal(ProcInfo, ProcInfoGoal) },
	{ proc_info_interface_code_model(ProcInfo, CodeModel) },
	{ proc_info_headvars(ProcInfo, ProcHeadVars) },
	(
		{ EvalMethod = normal },
		{ Args = [CallPred | CallArgs] },
		{ ProcHeadVars = [ProcPred | ProcArgs] },
		{ ProcInfoGoal = generic_call(higher_order(ProcPred, _, _),
			ProcArgs, _, CallDeterminism) - _GoalInfo },
		{ determinism_to_code_model(CallDeterminism, CallCodeModel) },
			% Check that the code models are compatible.
			% Note that det is not compatible with semidet,
			% and semidet is not compatible with nondet,
			% since the arguments go in different registers.
			% But det is compatible with nondet.
		{ CodeModel = CallCodeModel
		; CodeModel = model_non, CallCodeModel = model_det
		}
	->
	    ( { CallArgs = [] } ->
		% if there are no new arguments, we can just use the old
		% closure
		code_info__produce_variable(CallPred, Code, Value)
	    ;
		code_info__get_next_label(LoopStart),
		code_info__get_next_label(LoopTest),
		code_info__acquire_reg(r, LoopCounter),
		code_info__acquire_reg(r, NumOldArgs),
		code_info__acquire_reg(r, NewClosure),
		{ Zero = const(int_const(0)) },
		{ One = const(int_const(1)) },
		{ Two = const(int_const(2)) },
		{ Three = const(int_const(3)) },
		{ list__length(CallArgs, NumNewArgs) },
		{ NumNewArgs_Rval = const(int_const(NumNewArgs)) },
		{ NumNewArgsPlusThree is NumNewArgs + 3 },
		{ NumNewArgsPlusThree_Rval =
			const(int_const(NumNewArgsPlusThree)) },
		code_info__produce_variable(CallPred, Code1, OldClosure),
		{ Code2 = node([
			comment("build new closure from old closure") - "",
			assign(NumOldArgs,
				lval(field(yes(0), OldClosure, Two)))
				- "get number of arguments",
			incr_hp(NewClosure, no,
				binop(+, lval(NumOldArgs),
				NumNewArgsPlusThree_Rval), "closure")
				- "allocate new closure",
			assign(field(yes(0), lval(NewClosure), Zero),
				lval(field(yes(0), OldClosure, Zero)))
				- "set closure layout structure",
			assign(field(yes(0), lval(NewClosure), One),
				lval(field(yes(0), OldClosure, One)))
				- "set closure code pointer",
			assign(field(yes(0), lval(NewClosure), Two),
				binop(+, lval(NumOldArgs), NumNewArgs_Rval))
				- "set new number of arguments",
			assign(NumOldArgs, binop(+, lval(NumOldArgs), Three))
				- "set up loop limit",
			assign(LoopCounter, Three)
				- "initialize loop counter",
			% It is possible for the number of hidden arguments
			% to be zero, in which case the body of this loop
			% should not be executed at all. This is why we
			% jump to the loop condition test.
			goto(label(LoopTest))
				- "enter the copy loop at the conceptual top",
			label(LoopStart) - "start of loop",
			assign(field(yes(0), lval(NewClosure),
					lval(LoopCounter)),
				lval(field(yes(0), OldClosure,
					lval(LoopCounter))))
				- "copy old hidden argument",
			assign(LoopCounter,
				binop(+, lval(LoopCounter), One))
				- "increment loop counter",
			label(LoopTest)
				- "do we have more old arguments to copy?",
			if_val(binop(<, lval(LoopCounter), lval(NumOldArgs)),
				label(LoopStart))
				- "repeat the loop?"
		]) },
		unify_gen__generate_extra_closure_args(CallArgs,
			LoopCounter, NewClosure, Code3),
		code_info__release_reg(LoopCounter),
		code_info__release_reg(NumOldArgs),
		code_info__release_reg(NewClosure),
		{ Code = tree(Code1, tree(Code2, Code3)) },
		{ Value = lval(NewClosure) }
	    )
	;
		{ Code = empty },
		code_info__make_entry_label(ModuleInfo, PredId, ProcId, no,
			CodeAddr),
		{ code_util__extract_proc_label_from_code_addr(CodeAddr,
			ProcLabel) },
		(
			{ EvalMethod = normal }
		;
			{ EvalMethod = (aditi_bottom_up) },
			% XXX The closure_layout code needs to be changed
			% to handle these.
			{ error(
			"Sorry, not implemented: `aditi_bottom_up' closures") }
		;
			{ EvalMethod = (aditi_top_down) },
			% XXX The closure_layout code needs to be changed
			% to handle these.
			{ error(
			"Sorry, not implemented: `aditi_top_down' closures") }
		),
		{ module_info_globals(ModuleInfo, Globals) },
		{ globals__lookup_bool_option(Globals, typeinfo_liveness,
			TypeInfoLiveness) },
		{
			TypeInfoLiveness = yes,
			continuation_info__generate_closure_layout(
				ModuleInfo, PredId, ProcId, ClosureInfo),
			MaybeClosureInfo = yes(ClosureInfo)
		;
			TypeInfoLiveness = no,
			% In the absence of typeinfo liveness, procedures
			% are not guaranteed to have typeinfos for all the
			% type variables in their signatures. Such a missing
			% typeinfo would cause a compile-time abort in
			% continuation_info__generate_closure_layout,
			% and even if that predicate was modified,
			% we still couldn't generate a usable layout
			% structure.
			MaybeClosureInfo = no
		},
		code_info__get_cell_count(CNum0),
		{ stack_layout__construct_closure_layout(ProcLabel,
			MaybeClosureInfo, ClosureLayoutMaybeRvals,
			ClosureLayoutArgTypes, CNum0, CNum) },
		code_info__set_cell_count(CNum),
		code_info__get_next_cell_number(ClosureLayoutCellNo),
		{ ClosureLayout = create(0, ClosureLayoutMaybeRvals,
			ClosureLayoutArgTypes, must_be_static,
			ClosureLayoutCellNo, "closure_layout") },
		{ list__length(Args, NumArgs) },
		{ proc_info_arg_info(ProcInfo, ArgInfo) },
		{ unify_gen__generate_pred_args(Args, ArgInfo, PredArgs) },
		{ Vector = [
			yes(ClosureLayout),
			yes(const(code_addr_const(CodeAddr))),
			yes(const(int_const(NumArgs)))
			| PredArgs
		] },
		code_info__get_next_cell_number(ClosureCellNo),
		{ Value = create(0, Vector, uniform(no), can_be_either,
			ClosureCellNo, "closure") }
	),
	code_info__cache_expression(Var, Value).

:- pred unify_gen__generate_extra_closure_args(list(prog_var), lval, lval,
		code_tree, code_info, code_info).
:- mode unify_gen__generate_extra_closure_args(in, in, in, out, in, out) is det.

unify_gen__generate_extra_closure_args([], _, _, empty) --> [].
unify_gen__generate_extra_closure_args([Var | Vars], LoopCounter,
				NewClosure, Code) -->
	code_info__produce_variable(Var, Code0, Value),
	{ One = const(int_const(1)) },
	{ Code1 = node([
		assign(field(yes(0), lval(NewClosure), lval(LoopCounter)),
			Value)
			- "set new argument field",
		assign(LoopCounter,
			binop(+, lval(LoopCounter), One))
			- "increment argument counter"
	]) },
	{ Code = tree(tree(Code0, Code1), Code2) },
	unify_gen__generate_extra_closure_args(Vars, LoopCounter,
		NewClosure, Code2).

:- pred unify_gen__generate_pred_args(list(prog_var), list(arg_info),
	list(maybe(rval))).
:- mode unify_gen__generate_pred_args(in, in, out) is det.

unify_gen__generate_pred_args([], _, []).
unify_gen__generate_pred_args([_|_], [], _) :-
	error("unify_gen__generate_pred_args: insufficient args").
unify_gen__generate_pred_args([Var | Vars], [ArgInfo | ArgInfos],
		[Rval | Rvals]) :-
	ArgInfo = arg_info(_, ArgMode),
	( ArgMode = top_in ->
		Rval = yes(var(Var))
	;
		Rval = no
	),
	unify_gen__generate_pred_args(Vars, ArgInfos, Rvals).

:- pred unify_gen__generate_cons_args(list(prog_var), list(type),
		list(uni_mode), module_info, list(maybe(rval))).
:- mode unify_gen__generate_cons_args(in, in, in, in, out) is det.

unify_gen__generate_cons_args(Vars, Types, Modes, ModuleInfo, Args) :-
	( unify_gen__generate_cons_args_2(Vars, Types, Modes, ModuleInfo,
			Args0) ->
		Args = Args0
	;
		error("unify_gen__generate_cons_args: length mismatch")
	).

	% Create a list of maybe(rval) for the arguments
	% for a construction unification.  For each argument which
	% is input to the construction unification, we produce `yes(var(Var))',
	% but if the argument is free, we just produce `no', meaning don't
	% generate an assignment to that field.

:- pred unify_gen__generate_cons_args_2(list(prog_var), list(type),
		list(uni_mode), module_info, list(maybe(rval))).
:- mode unify_gen__generate_cons_args_2(in, in, in, in, out) is semidet.

unify_gen__generate_cons_args_2([], [], [], _, []).
unify_gen__generate_cons_args_2([Var|Vars], [Type|Types], [UniMode|UniModes],
			ModuleInfo, [Arg|RVals]) :-
	UniMode = ((_LI - RI) -> (_LF - RF)),
	( mode_to_arg_mode(ModuleInfo, (RI -> RF), Type, top_in) ->
		Arg = yes(var(Var))
	;
		Arg = no
	),
	unify_gen__generate_cons_args_2(Vars, Types, UniModes, ModuleInfo,
		RVals).

%---------------------------------------------------------------------------%

:- pred unify_gen__var_types(list(prog_var), list(type), code_info, code_info).
:- mode unify_gen__var_types(in, out, in, out) is det.

unify_gen__var_types(Vars, Types) -->
	code_info__get_proc_info(ProcInfo),
	{ proc_info_vartypes(ProcInfo, VarTypes) },
	{ map__apply_to_list(Vars, VarTypes, Types) }.

%---------------------------------------------------------------------------%

:- pred unify_gen__make_fields_and_argvars(list(prog_var), rval, int, int,
		list(uni_val), list(uni_val)).
:- mode unify_gen__make_fields_and_argvars(in, in, in, in, out, out) is det.

	% Construct a pair of lists that associates the fields of
	% a term with variables.

unify_gen__make_fields_and_argvars([], _, _, _, [], []).
unify_gen__make_fields_and_argvars([Var | Vars], Rval, Field0, TagNum,
		[F | Fs], [A | As]) :-
	F = lval(field(yes(TagNum), Rval, const(int_const(Field0)))),
	A = ref(Var),
	Field1 is Field0 + 1,
	unify_gen__make_fields_and_argvars(Vars, Rval, Field1, TagNum, Fs, As).

%---------------------------------------------------------------------------%

	% Generate a deterministic deconstruction. In a deterministic
	% deconstruction, we know the value of the tag, so we don't
	% need to generate a test.

	% Deconstructions are generated semi-eagerly. Any test sub-
	% unifications are generated eagerly (they _must_ be), but
	% assignment unifications are cached.

:- pred unify_gen__generate_det_deconstruction(prog_var, cons_id,
		list(prog_var), list(uni_mode), code_tree,
		code_info, code_info).
:- mode unify_gen__generate_det_deconstruction(in, in, in, in, out,
	in, out) is det.

unify_gen__generate_det_deconstruction(Var, Cons, Args, Modes, Code) -->
	code_info__cons_id_to_tag(Var, Cons, Tag),
	% For constants, if the deconstruction is det, then we already know
	% the value of the constant, so Code = empty.
	(
		{ Tag = string_constant(_String) },
		{ Code = empty }
	;
		{ Tag = int_constant(_Int) },
		{ Code = empty }
	;
		{ Tag = float_constant(_Float) },
		{ Code = empty }
	;
		{ Tag = pred_closure_tag(_, _, _) },
		{ Code = empty }
	;
		{ Tag = code_addr_constant(_, _) },
		{ Code = empty }
	;
		{ Tag = type_ctor_info_constant(_, _, _) },
		{ Code = empty }
	;
		{ Tag = base_typeclass_info_constant(_, _, _) },
		{ Code = empty }
	;
		{ Tag = tabling_pointer_constant(_, _) },
		{ Code = empty }
	;
		{ Tag = no_tag },
		( { Args = [Arg], Modes = [Mode] } ->
			code_info__variable_type(Arg, Type),
			unify_gen__generate_sub_unify(ref(Var), ref(Arg),
				Mode, Type, Code)
		;
			{ error("unify_gen__generate_det_deconstruction: no_tag: arity != 1") }
		)
	;
		{ Tag = unshared_tag(UnsharedTag) },
		{ Rval = var(Var) },
		{ unify_gen__make_fields_and_argvars(Args, Rval, 0,
			UnsharedTag, Fields, ArgVars) },
		unify_gen__var_types(Args, ArgTypes),
		unify_gen__generate_unify_args(Fields, ArgVars,
			Modes, ArgTypes, Code)
	;
		{ Tag = shared_remote_tag(Bits0, _Num0) },
		{ Rval = var(Var) },
		{ unify_gen__make_fields_and_argvars(Args, Rval, 1,
			Bits0, Fields, ArgVars) },
		unify_gen__var_types(Args, ArgTypes),
		unify_gen__generate_unify_args(Fields, ArgVars,
			Modes, ArgTypes, Code)
	;
		{ Tag = shared_local_tag(_Bits1, _Num1) },
		{ Code = empty } % if this is det, then nothing happens
	).

%---------------------------------------------------------------------------%

	% Generate a semideterministic deconstruction.
	% A semideterministic deconstruction unification is tag-test
	% followed by a deterministic deconstruction.

:- pred unify_gen__generate_semi_deconstruction(prog_var, cons_id,
		list(prog_var), list(uni_mode), code_tree,
		code_info, code_info).
:- mode unify_gen__generate_semi_deconstruction(in, in, in, in, out, in, out)
	is det.

unify_gen__generate_semi_deconstruction(Var, Tag, Args, Modes, Code) -->
	unify_gen__generate_tag_test(Var, Tag, branch_on_success,
		SuccLab, TagTestCode),
	code_info__remember_position(AfterUnify),
	code_info__generate_failure(FailCode),
	code_info__reset_to_position(AfterUnify),
	unify_gen__generate_det_deconstruction(Var, Tag, Args, Modes,
		DeconsCode),
	{ SuccessLabelCode = node([
		label(SuccLab) - ""
	]) },
	{ Code =
		tree(TagTestCode,
		tree(FailCode,
		tree(SuccessLabelCode,
		     DeconsCode)))
	}.

%---------------------------------------------------------------------------%

	% Generate code to perform a list of deterministic subunifications
	% for the arguments of a construction.

:- pred unify_gen__generate_unify_args(list(uni_val), list(uni_val),
			list(uni_mode), list(type), code_tree,
			code_info, code_info).
:- mode unify_gen__generate_unify_args(in, in, in, in, out, in, out) is det.

unify_gen__generate_unify_args(Ls, Rs, Ms, Ts, Code) -->
	( unify_gen__generate_unify_args_2(Ls, Rs, Ms, Ts, Code0) ->
		{ Code = Code0 }
	;
		{ error("unify_gen__generate_unify_args: length mismatch") }
	).

:- pred unify_gen__generate_unify_args_2(list(uni_val), list(uni_val),
			list(uni_mode), list(type), code_tree,
			code_info, code_info).
:- mode unify_gen__generate_unify_args_2(in, in, in, in, out, in, out)
	is semidet.

unify_gen__generate_unify_args_2([], [], [], [], empty) --> [].
unify_gen__generate_unify_args_2([L|Ls], [R|Rs], [M|Ms], [T|Ts], Code) -->
	unify_gen__generate_sub_unify(L, R, M, T, CodeA),
	unify_gen__generate_unify_args_2(Ls, Rs, Ms, Ts, CodeB),
	{ Code = tree(CodeA, CodeB) }.

%---------------------------------------------------------------------------%

	% Generate a subunification between two [field|variable].

:- pred unify_gen__generate_sub_unify(uni_val, uni_val, uni_mode, type,
					code_tree, code_info, code_info).
:- mode unify_gen__generate_sub_unify(in, in, in, in, out, in, out) is det.

unify_gen__generate_sub_unify(L, R, Mode, Type, Code) -->
	{ Mode = ((LI - RI) -> (LF - RF)) },
	code_info__get_module_info(ModuleInfo),
	{ mode_to_arg_mode(ModuleInfo, (LI -> LF), Type, LeftMode) },
	{ mode_to_arg_mode(ModuleInfo, (RI -> RF), Type, RightMode) },
	(
			% Input - input == test unification
		{ LeftMode = top_in },
		{ RightMode = top_in }
	->
		% This shouldn't happen, since mode analysis should
		% avoid creating any tests in the arguments
		% of a construction or deconstruction unification.
		{ error("test in arg of [de]construction") }
	;
			% Input - Output== assignment ->
		{ LeftMode = top_in },
		{ RightMode = top_out }
	->
		unify_gen__generate_sub_assign(R, L, Code)
	;
			% Input - Output== assignment <-
		{ LeftMode = top_out },
		{ RightMode = top_in }
	->
		unify_gen__generate_sub_assign(L, R, Code)
	;
		{ LeftMode = top_unused },
		{ RightMode = top_unused }
	->
		{ Code = empty } % free-free - ignore
			% XXX I think this will have to change
			% if we start to support aliasing
	;
		{ error("unify_gen__generate_sub_unify: some strange unify") }
	).

%---------------------------------------------------------------------------%

:- pred unify_gen__generate_sub_assign(uni_val, uni_val, code_tree,
							code_info, code_info).
:- mode unify_gen__generate_sub_assign(in, in, out, in, out) is det.

	% Assignment between two lvalues - cannot cache [yet]
	% so generate immediate code
	% If the destination of the assignment contains any vars,
	% we need to materialize those before we can do the assignment.
unify_gen__generate_sub_assign(lval(Lval0), lval(Rval), Code) -->
	code_info__materialize_vars_in_rval(lval(Lval0), NewLval,
		MaterializeCode),
	(
		{ NewLval = lval(Lval) }
	->
		{ Code = tree(MaterializeCode, node([
			assign(Lval, lval(Rval)) - "Copy field"
		])) }
	;
		{ error("unify_gen__generate_sub_assign: lval vanished with lval") }
	).
	% assignment from a variable to an lvalue - cannot cache
	% so generate immediately
unify_gen__generate_sub_assign(lval(Lval0), ref(Var), Code) -->
	code_info__produce_variable(Var, SourceCode, Source),
	code_info__materialize_vars_in_rval(lval(Lval0), NewLval,
		MaterializeCode),
	(
		{ NewLval = lval(Lval) }
	->
		{ Code = tree(
			tree(SourceCode, MaterializeCode),
			node([
				assign(Lval, Source) - "Copy value"
			])
		) }
	;
		{ error("unify_gen__generate_sub_assign: lval vanished with ref") }
	).
	% assignment to a variable, so cache it.
unify_gen__generate_sub_assign(ref(Var), lval(Rval), empty) -->
	(
		code_info__variable_is_forward_live(Var)
	->
		code_info__cache_expression(Var, lval(Rval))
	;
		{ true }
	).
	% assignment to a variable, so cache it.
unify_gen__generate_sub_assign(ref(Lvar), ref(Rvar), empty) -->
	(
		code_info__variable_is_forward_live(Lvar)
	->
		code_info__cache_expression(Lvar, var(Rvar))
	;
		{ true }
	).

%---------------------------------------------------------------------------%

:- pred unify_gen__var_type_msg(type, string).
:- mode unify_gen__var_type_msg(in, out) is det.

unify_gen__var_type_msg(Type, Msg) :-
	( type_to_type_id(Type, TypeId, _) ->
		TypeId = TypeSym - TypeArity,
		prog_out__sym_name_to_string(TypeSym, TypeSymStr),
		string__int_to_string(TypeArity, TypeArityStr),
		string__append_list([TypeSymStr, "/", TypeArityStr], Msg)
	;
		error("type is still a type variable in var_type_msg")
	).

%---------------------------------------------------------------------------%
%---------------------------------------------------------------------------%
