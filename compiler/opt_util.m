%-----------------------------------------------------------------------------%

% Utilities for LLDS to LLDS peephole optimization.

% Main author: zs.

%-----------------------------------------------------------------------------%

:- module opt_util.

:- interface.
:- import_module llds, value_number, list, int, std_util.

:- type instmap == map(label, instruction).
:- type tailmap == map(label, list(instruction)).
:- type succmap == map(label, bool).

:- pred opt_util__gather_comments(list(instruction),
	list(instruction), list(instruction)).
:- mode opt_util__gather_comments(in, out, out) is det.

:- pred opt_util__gather_comments_livevals(list(instruction),
	list(instruction), list(instruction)).
:- mode opt_util__gather_comments_livevals(in, out, out) is det.

:- pred opt_util__skip_comments(list(instruction), list(instruction)).
:- mode opt_util__skip_comments(in, out) is det.

:- pred opt_util__skip_comments_livevals(list(instruction), list(instruction)).
:- mode opt_util__skip_comments_livevals(in, out) is det.

:- pred opt_util__skip_comments_labels(list(instruction), list(instruction)).
:- mode opt_util__skip_comments_labels(in, out) is det.

:- pred opt_util__skip_comments_livevals_labels(list(instruction), list(instruction)).
:- mode opt_util__skip_comments_livevals_labels(in, out) is det.

	% Find the next modframe if it is guaranteed to be reached from here

:- pred opt_util__next_modframe(list(instruction), list(instruction),
	code_addr, list(instruction), list(instruction)).
:- mode opt_util__next_modframe(in, in, out, out, out) is semidet.

	% Skip to the next label, returning the code before the label,
	% and the label together with the code after the label.

:- pred opt_util__skip_to_next_label(list(instruction),
	list(instruction), list(instruction)).
:- mode opt_util__skip_to_next_label(in, out, out) is det.

	% Check whether the named label follows without any intervening code.
	% If yes, return the instructions after the label.

:- pred opt_util__is_this_label_next(label, list(instruction),
	list(instruction)).
:- mode opt_util__is_this_label_next(in, in, out) is semidet.

 	% Is a proceed instruction (i.e. a goto(succip) instruction)
 	% next in the instruction list, possibly preceded by a restoration
 	% of succip and a det stack frame removal? If yes, return the
 	% instructions up to the proceed.

:- pred opt_util__is_proceed_next(list(instruction), list(instruction)).
:- mode opt_util__is_proceed_next(in, out) is semidet.

 	% Is a proceed instruction (i.e. a goto(succip) instruction)
 	% next in the instruction list, possibly preceded by an assignment
	% to r1, a restoration of succip and a det stack frame removal?
	% If yes, return the instructions up to the proceed.

:- pred opt_util__is_sdproceed_next(list(instruction), list(instruction)).
:- mode opt_util__is_sdproceed_next(in, out) is semidet.

	% Same as the previous predicate, but also return whether it is
	% a success or a fail.

:- pred opt_util__is_sdproceed_next_sf(list(instruction), list(instruction),
	bool).
:- mode opt_util__is_sdproceed_next_sf(in, out, out) is semidet.

 	% Is a succeed instruction (i.e. a goto(do_succeed) instruction)
 	% next in the instruction list? If yes, return the instructions
	% up to the succed.

:- pred opt_util__is_succeed_next(list(instruction), list(instruction)).
:- mode opt_util__is_succeed_next(in, out) is semidet.

 	% Is the following code a test of r1, followed in both continuations
	% by a semidet proceed with the same value of r1?

:- pred opt_util__is_forkproceed_next(list(instruction), map(label, bool),
	list(instruction)).
:- mode opt_util__is_forkproceed_next(in, in, out) is semidet.

	% If the following code a setup of a det stack frame? If yes, return
	% the size of the frame and the remaining instructions.

:- pred opt_util__detstack_setup(list(instruction), int, list(instruction)).
:- mode opt_util__detstack_setup(in, out, out) is semidet.

	% If the following code a teardown of a det stack frame, including
	% possibly a semidet assignment to r1 and a proceed or tailcall?
	% Return the teardown instructions, the non-stack instructions
	% (possible assignment to r1 and the branch away), and the instructions
	% remaining after that.

:- pred opt_util__detstack_teardown(list(instruction), int,
	list(instruction), list(instruction), list(instruction)).
:- mode opt_util__detstack_teardown(in, in, out, out, out) is semidet.

	% Remove the assignment to r1 from the list returned by
	% opt_util__is_sdproceed_next.

:- pred opt_util__filter_out_r1(list(instruction), list(instruction)).
:- mode opt_util__filter_out_r1(in, out) is det.

	% Remove the livevals instruction from the list returned by
	% opt_util__is_proceed_next.

:- pred opt_util__filter_out_livevals(list(instruction), list(instruction)).
:- mode opt_util__filter_out_livevals(in, out) is det.

	% Get just the livevals instructions from a list of instructions.

:- pred opt_util__filter_in_livevals(list(instruction), list(instruction)).
:- mode opt_util__filter_in_livevals(in, out) is det.

	% See if an instruction sequence contains incr_sp, and if yes,
	% what is the increment.

% :- pred opt_util__has_incr_sp(list(instruction), int).
% :- mode opt_util__has_incr_sp(in, out) is semidet.

	% See if an instruction sequence contains decr_sp, and if yes,
	% what is the decrement.

% :- pred opt_util__has_decr_sp(list(instruction), int).
% :- mode opt_util__has_decr_sp(in, out) is semidet.

	% Check whether an instruction can possibly branch away.

:- pred opt_util__can_instr_branch_away(instr, bool).
:- mode opt_util__can_instr_branch_away(in, out) is det.

	% Check whether an instruction can possibly fall through
	% to the next instruction without using its label.

:- pred opt_util__can_instr_fall_through(instr, bool).
:- mode opt_util__can_instr_fall_through(in, out) is det.

	% Find out what vn, if any, is needed to access a vn_lval.

:- pred opt_util__vnlval_access_vn(vn_lval, maybe(vn)).
:- mode opt_util__vnlval_access_vn(in, out) is det.

	% Check whether a code_addr, when the target of a goto, represents
	% either a call or a proceed/succeed; if so, it is the end of an
	% extended basic block and needs a livevals in front of it.

:- pred opt_util__livevals_addr(code_addr, bool).
:- mode opt_util__livevals_addr(in, out) is det.

	% Determine all the labels and code addresses which are referenced
	% by an instruction.

:- pred opt_util__instr_labels(instr, list(label), list(code_addr)).
:- mode opt_util__instr_labels(in, out, out) is det.

	% See whether an instruction list contains the body of a chain
	% predicate, i.e. a predicate that sets up a stack frame containing
	% only succip, possibly does some argument shuffling, destroys the
	% stack frame and then does a tailcall.

:- pred opt_util__chain_pred(list(instruction),
	list(instruction), list(instruction), list(instruction)).
:- mode opt_util__chain_pred(in, out, out, out) is semidet.

	% See whether an instruction list contains the first base case
	% of a det or semidet predicate, a base case that does not need
	% any stack space. If yes, return the instruction sequences
	% setting up sp, saving succip, testing the base case (jump away),
	% the base case code itself, the stack frame teardown code,
	% and the code following the base case's proceed.

:- pred opt_util__first_base_case(list(instruction),
	list(instruction), list(instruction), list(instruction),
	list(instruction), list(instruction), list(instruction)).
:- mode opt_util__first_base_case(in, out, out, out, out, out, out) is semidet.

	% Find a label number that does not occur in the instruction list,
	% starting the search at a given number.

:- pred opt_util__new_label_no(list(instruction), int, int).
:- mode opt_util__new_label_no(in, in, out) is det.

	% Find the maximum temp variable number used.

:- pred opt_util__count_temps_instr_list(list(instruction), int, int).
:- mode opt_util__count_temps_instr_list(in, in, out) is det.

	% See whether an lval references any stackvars.

:- pred opt_util__lval_refers_stackvars(lval, bool).
:- mode opt_util__lval_refers_stackvars(in, out) is det.

	% See whether an rval references any stackvars.

:- pred opt_util__rval_refers_stackvars(rval, bool).
:- mode opt_util__rval_refers_stackvars(in, out) is det.

%-----------------------------------------------------------------------------%

:- implementation.
:- import_module map, require.

opt_util__gather_comments(Instrs0, Comments, Instrs) :-
	(
		Instrs0 = [Instr0 | Instrs1],
		Instr0 = comment(_) - _
	->
		opt_util__gather_comments(Instrs1, Comments0, Instrs),
		Comments = [Instr0 | Comments0]
	;
		Instrs = Instrs0,
		Comments = []
	).

opt_util__gather_comments_livevals(Instrs0, Comments, Instrs) :-
	(
		Instrs0 = [Instr0 | Instrs1],
		( Instr0 = comment(_) - _ ; Instr0 = livevals(_, _) - _ )
	->
		opt_util__gather_comments_livevals(Instrs1, Comments0, Instrs),
		Comments = [Instr0 | Comments0]
	;
		Instrs = Instrs0,
		Comments = []
	).

	% Given a list of instructions, skip past any comment instructions
	% at the start and return the remaining instructions.
	% We do this because comment instructions get in the way of
	% peephole optimization.

opt_util__skip_comments(Instrs0, Instrs) :-
	( Instrs0 = [comment(_) - _ | Instrs1] ->
		opt_util__skip_comments(Instrs1, Instrs)
	;
		Instrs = Instrs0
	).

opt_util__skip_comments_livevals(Instrs0, Instrs) :-
	( Instrs0 = [comment(_) - _ | Instrs1] ->
		opt_util__skip_comments(Instrs1, Instrs)
	; Instrs0 = [livevals(_, _) - _ | Instrs1] ->
		opt_util__skip_comments_livevals(Instrs1, Instrs)
	;
		Instrs = Instrs0
	).

opt_util__skip_comments_labels(Instrs0, Instrs) :-
	( Instrs0 = [comment(_) - _ | Instrs1] ->
		opt_util__skip_comments_labels(Instrs1, Instrs)
	; Instrs0 = [label(_) - _ | Instrs1] ->
		opt_util__skip_comments_labels(Instrs1, Instrs)
	;
		Instrs = Instrs0
	).

opt_util__skip_comments_livevals_labels(Instrs0, Instrs) :-
	( Instrs0 = [comment(_) - _ | Instrs1] ->
		opt_util__skip_comments_livevals_labels(Instrs1, Instrs)
	; Instrs0 = [livevals(_, _) - _ | Instrs1] ->
		opt_util__skip_comments_livevals_labels(Instrs1, Instrs)
	; Instrs0 = [label(_) - _ | Instrs1] ->
		opt_util__skip_comments_livevals_labels(Instrs1, Instrs)
	;
		Instrs = Instrs0
	).

opt_util__next_modframe([Instr | Instrs], RevSkip, Redoip, Skip, Rest) :-
	Instr = Uinstr - _Comment,
	( Uinstr = modframe(Redoip0) ->
		Redoip = Redoip0,
		list__reverse(RevSkip, Skip),
		Rest = Instrs
	; Uinstr = mkframe(_, _, _) ->
		fail
	;
		opt_util__can_instr_branch_away(Uinstr, Canbranchaway),
		( Canbranchaway = no ->
			opt_util__next_modframe(Instrs, [Instr | RevSkip],
				Redoip, Skip, Rest)
		;
			fail
		)
	).

opt_util__skip_to_next_label([], [], []).
opt_util__skip_to_next_label([Instr0 | Instrs0], Before, Remain) :-
	( Instr0 = label(_) - _ ->
		Before = [],
		Remain = [Instr0 | Instrs0]
	;
		opt_util__skip_to_next_label(Instrs0, Before1, Remain),
		Before = [Instr0 | Before1]
	).

opt_util__is_this_label_next(Label, [Instr | Moreinstr], Remainder) :-
	Instr = Uinstr - _Comment,
	% write('looking for label '),
	% write(Label),
	% write(' in instr '),
	% write(Uinstr),
	% nl,
	( Uinstr = comment(_) ->
		opt_util__is_this_label_next(Label, Moreinstr, Remainder)
	; Uinstr = livevals(_, _) ->
		% this is questionable
		opt_util__is_this_label_next(Label, Moreinstr, Remainder)
	; Uinstr = label(NextLabel) ->
		( Label = NextLabel ->
			Remainder = Moreinstr
		;
			opt_util__is_this_label_next(Label, Moreinstr,
				Remainder)
		)
	;
		fail
	).

opt_util__is_proceed_next(Instrs0, Instrs_between) :-
	opt_util__skip_comments_labels(Instrs0, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	( Instr1 = assign(succip, lval(stackvar(_))) - _ ->
		Instr1use = Instr1,
		opt_util__skip_comments_labels(Instrs2, Instrs3)
	;
		Instr1use = comment("no succip restoration") - "",
		Instrs3 = Instrs1
	),
	Instrs3 = [Instr3 | Instrs4],
	( Instr3 = decr_sp(_) - _ ->
		Instr3use = Instr3,
		opt_util__skip_comments_labels(Instrs4, Instrs5)
	;
		Instr3use = comment("no sp restoration") - "",
		Instrs5 = Instrs3
	),
	Instrs5 = [Instr5 | Instrs6],
	( Instr5 = livevals(_, _) - _ ->
		Instr5use = Instr5,
		opt_util__skip_comments_labels(Instrs6, Instrs7)
	;
		Instr5use = comment("no livevals") - "",
		Instrs7 = Instrs5
	),
	Instrs7 = [Instr7 | _],
	Instr7 = goto(succip) - _,
	Instrs_between = [Instr1use, Instr3use, Instr5use].

opt_util__is_sdproceed_next(Instrs0, Instrs_between) :-
	opt_util__is_sdproceed_next_sf(Instrs0, Instrs_between, _).

opt_util__is_sdproceed_next_sf(Instrs0, Instrs_between, Success) :-
	opt_util__skip_comments_labels(Instrs0, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	( Instr1 = assign(succip, lval(stackvar(_))) - _ ->
		Instr1use = Instr1,
		opt_util__skip_comments_labels(Instrs2, Instrs3)
	;
		Instr1use = comment("no succip restoration") - "",
		Instrs3 = Instrs1
	),
	Instrs3 = [Instr3 | Instrs4],
	( Instr3 = decr_sp(_) - _ ->
		Instr3use = Instr3,
		opt_util__skip_comments_labels(Instrs4, Instrs5)
	;
		Instr3use = comment("no sp restoration") - "",
		Instrs5 = Instrs3
	),
	Instrs5 = [Instr5 | Instrs6],
	Instr5 = assign(reg(r(1)), const(R1val)) - _,
	(
		R1val = true,
		Success = yes
	;
		R1val = false,
		Success = no
	),
	opt_util__skip_comments_labels(Instrs6, Instrs7),
	Instrs7 = [Instr7 | Instrs8],
	( Instr7 = livevals(_, _) - _ ->
		Instr7use = Instr7,
		opt_util__skip_comments_labels(Instrs8, Instrs9)
	;
		Instr7use = comment("no livevals") - "",
		Instrs9 = Instrs7
	),
	Instrs9 = [Instr9 | _],
	Instr9 = goto(succip) - _,
	Instrs_between = [Instr1use, Instr3use, Instr5, Instr7use].

opt_util__is_succeed_next(Instrs0, Instrs_between) :-
	opt_util__skip_comments_labels(Instrs0, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	( Instr1 = livevals(_, _) - _ ->
		Instr1use = Instr1,
		opt_util__skip_comments_labels(Instrs2, Instrs3)
	;
		Instr1use = comment("no livevals") - "",
		Instrs3 = Instrs1
	),
	Instrs3 = [Instr3 | _],
	Instr3 = goto(do_succeed) - _,
	Instrs_between = [Instr1use].

	% When we return Between, we are implicitly assuming that
	% the other continuation' instruction sequence is the same
	% expect for the value assigned to r1. If this isn't true,
	% then we are up shit creek anyway.

opt_util__is_forkproceed_next(Instrs0, Succmap, Between) :-
	opt_util__skip_comments_labels(Instrs0, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	( Instr1 = if_val(lval(reg(r(1))), label(BranchLabel)) - _ ->
		map__search(Succmap, BranchLabel, BranchSuccess),
		BranchSuccess = yes,
		opt_util__is_sdproceed_next_sf(Instrs2, Between, FallSuccess),
		FallSuccess = no
	; Instr1 = if_val(unop(not, lval(reg(r(1)))), label(BranchLabel)) - _ ->
		map__search(Succmap, BranchLabel, BranchSuccess),
		BranchSuccess = no,
		opt_util__is_sdproceed_next_sf(Instrs2, Between, FallSuccess),
		FallSuccess = yes
	;
		fail
	).

opt_util__detstack_setup(Instrs0, FrameSize, Instrs) :-
	opt_util__skip_comments_livevals(Instrs0, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	Instr1 = incr_sp(FrameSize) - _,
	opt_util__skip_comments_livevals(Instrs2, Instrs3),
	Instrs3 = [Instr3 | Instrs4],
	Instr3 = assign(stackvar(FrameSize), lval(succip)) - _,
	opt_util__skip_comments_livevals(Instrs4, Instrs).

opt_util__detstack_teardown(Instrs0, FrameSize, Teardown, Tail, Remain) :-
	opt_util__gather_comments_livevals(Instrs0, Comments1, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	Instr1 = assign(succip, lval(stackvar(FrameSize))) - _,
	opt_util__gather_comments_livevals(Instrs2, Comments2, Instrs3),
	Instrs3 = [Instr3 | Instrs4],
	Instr3 = decr_sp(FrameSize) - _,
	opt_util__gather_comments_livevals(Instrs4, Comments3, Instrs5),
	Instrs5 = [Instr5 | Instrs6],
	( Instr5 = assign(reg(r(1)), const(_)) - _ ->
		SemiDet = [Instr5],
		opt_util__gather_comments_livevals(Instrs6, Comments4, Instrs7)
	;
		SemiDet = [],
		Comments4 = [],
		Instrs7 = Instrs5
	),
	Instrs7 = [Instr7 | Remain],
	Instr7 = goto(_) - _,
	list__condense([Comments1, [Instr1], Comments2, [Instr3]], Teardown),
	list__condense([Comments3, SemiDet, Comments4, [Instr7]], Tail).

opt_util__chain_pred(Instrs0, Shuffle, Livevals, Tailcall) :-
	opt_util__skip_comments_livevals(Instrs0, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	Instr1 = incr_sp(Framesize) - _,
	Framesize = 1,

	opt_util__skip_comments_livevals(Instrs2, Instrs3),
	Instrs3 = [Instr3 | Instrs4],
	Instr3 = assign(stackvar(Framesize), lval(succip)) - _,

	opt_util__no_stack_straight_line(Instrs4, Shuffle, Instrs5),
	Instrs5 = [Instr5 | Instrs6],
	Instr5 = assign(succip, lval(stackvar(Framesize))) - _,

	opt_util__gather_comments_livevals(Instrs6, _Comments2, Instrs7),
	Instrs7 = [Instr7 | Instrs8],
	Instr7 = decr_sp(Framesize) - _,

	opt_util__gather_comments_livevals(Instrs8, Livevals, Instrs9),
	Instrs9 = [Instr9 | Instrs10],
	Instr9 = goto(_Label) - _,

	opt_util__gather_comments(Instrs10, _Comments3, Instrs11),
	Instrs11 = [],

	Tailcall = [Instr9].

opt_util__first_base_case(Instrs0, SetupSp, SetupSuccip,
		Test, After, Teardown, Follow) :-
	opt_util__gather_comments_livevals(Instrs0, Comments0, Instrs1),
	Instrs1 = [Instr1 | Instrs2],
	Instr1 = incr_sp(Framesize) - _,

	opt_util__gather_comments_livevals(Instrs2, Comments1, Instrs3),
	Instrs3 = [Instr3 | Instrs4],
	Instr3 = assign(stackvar(Framesize), lval(succip)) - _,

	opt_util__gather_comments_livevals(Instrs4, Comments2, Instrs5),
	Instrs5 = [Instr5 | Instrs6],
	Instr5 = if_val(_, label(_)) - _,

	opt_util__no_stack_straight_line(Instrs6, After0, Instrs7),
	Instrs7 = [Instr7 | Instrs8],
	Instr7 = assign(succip, lval(stackvar(Framesize))) - _,

	opt_util__gather_comments_livevals(Instrs8, Comments3, Instrs9),
	Instrs9 = [Instr9 | Instrs10],
	Instr9 = decr_sp(Framesize) - _,

	opt_util__gather_comments_livevals(Instrs10, Comments4, Instrs11),
	Instrs11 = [Instr11 | Instrs12],
	( Instr11 = assign(reg(r(1)), const(_)) - _ ->
		Instr11use = Instr11,
		opt_util__gather_comments_livevals(Instrs12, Comments5, Instrs13)
	;
		Instr11use = comment("no semidet assign to r1") - "",
		Comments5 = [],
		Instrs13 = Instrs11
	),

	Instrs13 = [Instr13 | Instrs14],
	Instr13 = goto(succip) - _,

	list__condense([Comments0, [Instr1], Comments1], SetupSp),
	list__condense([[Instr3], Comments2], SetupSuccip),
	Test = [Instr5],
	list__condense([After0, Comments3, [Instr11use],
		Comments4, Comments5], After),
	Teardown = [Instr7, Instr9],
	Follow = Instrs14.

:- pred opt_util__no_stack_straight_line(list(instruction),
	list(instruction), list(instruction)).
:- mode opt_util__no_stack_straight_line(in, out, out) is det.

opt_util__no_stack_straight_line(Instrs0, Shuffle, Instrs) :-
	opt_util__no_stack_straight_line_2(Instrs0, [], RevShuffle, Instrs),
	list__reverse(RevShuffle, Shuffle).

:- pred opt_util__no_stack_straight_line_2(list(instruction),
	list(instruction), list(instruction), list(instruction)).
:- mode opt_util__no_stack_straight_line_2(in, in, out, out) is det.

opt_util__no_stack_straight_line_2([], After, After, []).
opt_util__no_stack_straight_line_2([Instr0 | Instrs0], After0, After, Instrs) :-
	Instr0 = Uinstr - _,
	(
		(
			Uinstr = comment(_)
		;
			Uinstr = livevals(_, _)
		;
			Uinstr = assign(Lval, Rval),
			opt_util__lval_refers_stackvars(Lval, LvalRefer),
			opt_util__rval_refers_stackvars(Rval, RvalRefer),
			LvalRefer = no,
			RvalRefer = no
		)
	->
		After1 = [Instr0 | After0],
		opt_util__no_stack_straight_line_2(Instrs0, After1, After, Instrs)
	;
		After = After0,
		Instrs = [Instr0 | Instrs0]
	).

opt_util__lval_refers_stackvars(reg(_), no).
opt_util__lval_refers_stackvars(stackvar(_), yes).
opt_util__lval_refers_stackvars(framevar(_), _) :-
	error("found framevar in lval_refers_stackvars").
opt_util__lval_refers_stackvars(succip, no).
opt_util__lval_refers_stackvars(maxfr, no).
opt_util__lval_refers_stackvars(curredoip, no).
opt_util__lval_refers_stackvars(hp, no).
opt_util__lval_refers_stackvars(sp, no).
opt_util__lval_refers_stackvars(field(_, Baselval, _), Refers) :-
	opt_util__lval_refers_stackvars(Baselval, Refers).
opt_util__lval_refers_stackvars(lvar(_), _) :-
	error("found lvar in lval_refers_stackvars").
opt_util__lval_refers_stackvars(temp(_), no).

opt_util__rval_refers_stackvars(lval(Lval), Refers) :-
	opt_util__lval_refers_stackvars(Lval, Refers).
opt_util__rval_refers_stackvars(var(_), _) :-
	error("found var in rval_refers_stackvars").
opt_util__rval_refers_stackvars(create(_, Rvals, _), Refers) :-
	opt_util__rvals_refer_stackvars(Rvals, Refers).
opt_util__rval_refers_stackvars(mkword(_, Baserval), Refers) :-
	opt_util__rval_refers_stackvars(Baserval, Refers).
opt_util__rval_refers_stackvars(const(_), no).
opt_util__rval_refers_stackvars(field(_, Baserval, _), Refers) :-
	opt_util__rval_refers_stackvars(Baserval, Refers).
opt_util__rval_refers_stackvars(unop(_, Baserval), Refers) :-
	opt_util__rval_refers_stackvars(Baserval, Refers).
opt_util__rval_refers_stackvars(binop(_, Baserval1, Baserval2), Refers) :-
	opt_util__rval_refers_stackvars(Baserval1, Refers1),
	opt_util__rval_refers_stackvars(Baserval2, Refers2),
	( ( Refers1 = yes ; Refers2 = yes ) ->
		Refers = yes
	;
		Refers = no
	).

:- pred opt_util__rvals_refer_stackvars(list(maybe(rval)), bool).
:- mode opt_util__rvals_refer_stackvars(in, out) is det.

opt_util__rvals_refer_stackvars([], no).
opt_util__rvals_refer_stackvars([MaybeRval | Tail], Refers) :-
	(
		(
			MaybeRval = no
		;
			MaybeRval = yes(Rval),
			opt_util__rval_refers_stackvars(Rval, Refers1),
			Refers1 = no
		)
	->
		opt_util__rvals_refer_stackvars(Tail, Refers)
	;
		Refers = yes
	).

opt_util__filter_out_r1([], []).
opt_util__filter_out_r1([Instr0 | Instrs0], Instrs) :-
	opt_util__filter_out_r1(Instrs0, Instrs1),
	( Instr0 = assign(reg(r(1)), const(_)) - _ ->
		Instrs = Instrs1
	;
		Instrs = [Instr0 | Instrs1]
	).

opt_util__filter_out_livevals([], []).
opt_util__filter_out_livevals([Instr0 | Instrs0], Instrs) :-
	opt_util__filter_out_livevals(Instrs0, Instrs1),
	( Instr0 = livevals(_, _) - _Comment ->
		Instrs = Instrs1
	;
		Instrs = [Instr0 | Instrs1]
	).

opt_util__filter_in_livevals([], []).
opt_util__filter_in_livevals([Instr0 | Instrs0], Instrs) :-
	opt_util__filter_in_livevals(Instrs0, Instrs1),
	( Instr0 = livevals(_, _) - _Comment ->
		Instrs = [Instr0 | Instrs1]
	;
		Instrs = Instrs1
	).

% opt_util__has_incr_sp([Instr0 | Instrs0], Inc) :-
% 	( Instr0 = incr_sp(N) - _Comment ->
% 		Inc = N
% 	;
% 		opt_util__has_incr_sp(Instrs0, Inc)
% 	).

% opt_util__has_decr_sp([Instr0 | Instrs0], Dec) :-
% 	( Instr0 = decr_sp(N) - _Comment ->
% 		Dec = N
% 	;
% 		opt_util__has_decr_sp(Instrs0, Dec)
% 	).

opt_util__new_label_no([], N, N).
opt_util__new_label_no([Instr0 | Instrs0], N0, N) :-
	( Instr0 = label(local(_, K)) - _Comment ->
		( K < N0 ->
			N1 = N0
		;
			N1 is K + 1
		)
	;
		N1 = N0
	),
	opt_util__new_label_no(Instrs0, N1, N).

opt_util__can_instr_branch_away(comment(_), no).
opt_util__can_instr_branch_away(livevals(_, _), no).
opt_util__can_instr_branch_away(block(_, _), yes).
opt_util__can_instr_branch_away(assign(_, _), no).
opt_util__can_instr_branch_away(call(_, _), yes).
opt_util__can_instr_branch_away(mkframe(_, _, _), no).
opt_util__can_instr_branch_away(modframe(_), no).
opt_util__can_instr_branch_away(label(_), no).
opt_util__can_instr_branch_away(goto(_), yes).
opt_util__can_instr_branch_away(computed_goto(_, _), yes).
opt_util__can_instr_branch_away(c_code(_), no).
opt_util__can_instr_branch_away(if_val(_, _), yes).
opt_util__can_instr_branch_away(incr_sp(_), no).
opt_util__can_instr_branch_away(decr_sp(_), no).
opt_util__can_instr_branch_away(incr_hp(_), no).

opt_util__can_instr_fall_through(comment(_), yes).
opt_util__can_instr_fall_through(livevals(_, _), yes).
opt_util__can_instr_fall_through(block(_, _), yes).
opt_util__can_instr_fall_through(assign(_, _), yes).
opt_util__can_instr_fall_through(call(_, _), no).
opt_util__can_instr_fall_through(mkframe(_, _, _), yes).
opt_util__can_instr_fall_through(modframe(_), yes).
opt_util__can_instr_fall_through(label(_), yes).
opt_util__can_instr_fall_through(goto(_), no).
opt_util__can_instr_fall_through(computed_goto(_, _), no).
opt_util__can_instr_fall_through(c_code(_), yes).
opt_util__can_instr_fall_through(if_val(_, _), yes).
opt_util__can_instr_fall_through(incr_sp(_), yes).
opt_util__can_instr_fall_through(decr_sp(_), yes).
opt_util__can_instr_fall_through(incr_hp(_), yes).

opt_util__instr_labels(comment(_), [], []).
opt_util__instr_labels(livevals(_, _), [], []).
opt_util__instr_labels(block(_, _), [], []).
opt_util__instr_labels(assign(_,_), [], []).
opt_util__instr_labels(call(Target, Ret), [], [Target, Ret]).
opt_util__instr_labels(mkframe(_, _, Addr), [], [Addr]).
opt_util__instr_labels(modframe(Addr), [], [Addr]).
opt_util__instr_labels(label(_), [], []).
opt_util__instr_labels(goto(Addr), [], [Addr]).
opt_util__instr_labels(computed_goto(_, Labels), Labels, []).
opt_util__instr_labels(if_val(_, Addr), [], [Addr]).
opt_util__instr_labels(c_code(_), [], []).
opt_util__instr_labels(incr_hp(_), [], []).
opt_util__instr_labels(incr_sp(_), [], []).
opt_util__instr_labels(decr_sp(_), [], []).

opt_util__vnlval_access_vn(vn_reg(_), no).
opt_util__vnlval_access_vn(vn_stackvar(_), no).
opt_util__vnlval_access_vn(vn_framevar(_), no).
opt_util__vnlval_access_vn(vn_succip, no).
opt_util__vnlval_access_vn(vn_maxfr, no).
opt_util__vnlval_access_vn(vn_curredoip, no).
opt_util__vnlval_access_vn(vn_hp, no).
opt_util__vnlval_access_vn(vn_sp, no).
opt_util__vnlval_access_vn(vn_field(_, Vn, _), yes(Vn)).
opt_util__vnlval_access_vn(vn_temp(_), no).

opt_util__livevals_addr(label(Label), Result) :-
	( Label = local(_,_) ->
		Result = no
	;	
		Result = yes
	).
opt_util__livevals_addr(imported(_), yes).
opt_util__livevals_addr(succip, yes).
opt_util__livevals_addr(do_succeed, yes).
opt_util__livevals_addr(do_redo, no).
opt_util__livevals_addr(do_fail, no).

opt_util__count_temps_instr_list([], N, N).
opt_util__count_temps_instr_list([Uinstr - _Comment | Instrs], N0, N) :-
	opt_util__count_temps_instr(Uinstr, N0, N1),
	opt_util__count_temps_instr_list(Instrs, N1, N).

:- pred opt_util__count_temps_instr(instr, int, int).
:- mode opt_util__count_temps_instr(in, in, out) is det.

opt_util__count_temps_instr(comment(_), N, N).
opt_util__count_temps_instr(livevals(_, _), N, N).
opt_util__count_temps_instr(block(_, _), N, N).
opt_util__count_temps_instr(assign(Lval, Rval), N0, N) :-
	opt_util__count_temps_lval(Lval, N0, N1),
	opt_util__count_temps_rval(Rval, N1, N).
opt_util__count_temps_instr(call(_, _), N, N).
opt_util__count_temps_instr(mkframe(_, _, _), N, N).
opt_util__count_temps_instr(modframe(_), N, N).
opt_util__count_temps_instr(label(_), N, N).
opt_util__count_temps_instr(goto(_), N, N).
opt_util__count_temps_instr(computed_goto(Rval, _), N0, N) :-
	opt_util__count_temps_rval(Rval, N0, N).
opt_util__count_temps_instr(if_val(Rval, _), N0, N) :-
	opt_util__count_temps_rval(Rval, N0, N).
opt_util__count_temps_instr(c_code(_), N, N).
opt_util__count_temps_instr(incr_hp(_), N, N).
opt_util__count_temps_instr(incr_sp(_), N, N).
opt_util__count_temps_instr(decr_sp(_), N, N).

:- pred opt_util__count_temps_lval(lval, int, int).
:- mode opt_util__count_temps_lval(in, in, out) is det.

opt_util__count_temps_lval(Lval, N0, N) :-
	( Lval = temp(T) ->
		int__max(N0, T, N)
	; Lval = field(_, Sub_lval, _) ->
		opt_util__count_temps_lval(Sub_lval, N0, N)
	;
		N = N0
	).

:- pred opt_util__count_temps_rval(rval, int, int).
:- mode opt_util__count_temps_rval(in, in, out) is det.

% XXX assume that we don't generate code
% that uses a temp var without defining it.
opt_util__count_temps_rval(_, N, N).

:- end_module opt_util.

%-----------------------------------------------------------------------------%
