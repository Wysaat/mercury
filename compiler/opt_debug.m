%-----------------------------------------------------------------------------%
% Copyright (C) 1994-2001 The University of Melbourne.
% This file may only be copied under the terms of the GNU General
% Public License - see the file COPYING in the Mercury distribution.
%-----------------------------------------------------------------------------%

% Debugging support for LLDS to LLDS peephole optimization.

% Main author: zs.

%-----------------------------------------------------------------------------%

:- module opt_debug.

:- interface.

:- import_module llds, vn_type, vn_table, livemap.
:- import_module code_model, rtti, layout, builtin_ops.
:- import_module atsort.

:- import_module io, bool, list, assoc_list, std_util.

:- pred opt_debug__msg(bool, int, string, io__state, io__state).
:- mode opt_debug__msg(in, in, in, di, uo) is det.

:- pred opt_debug__dump_instrs(bool, list(instruction), io__state, io__state).
:- mode opt_debug__dump_instrs(in, in, di, uo) is det.

:- pred opt_debug__dump_node_relmap(relmap(vn_node), string).
:- mode opt_debug__dump_node_relmap(in, out) is det.

:- pred opt_debug__dump_nodemap(assoc_list(vn_node, list(vn_node)), string).
:- mode opt_debug__dump_nodemap(in, out) is det.

:- pred opt_debug__dump_nodelist(list(vn_node), string).
:- mode opt_debug__dump_nodelist(in, out) is det.

:- pred opt_debug__dump_longnodelist(list(vn_node), string).
:- mode opt_debug__dump_longnodelist(in, out) is det.

:- pred opt_debug__dump_node(vn_node, string).
:- mode opt_debug__dump_node(in, out) is det.

:- pred opt_debug__dump_intlist(list(int), string).
:- mode opt_debug__dump_intlist(in, out) is det.

:- pred opt_debug__dump_livemap(livemap, string).
:- mode opt_debug__dump_livemap(in, out) is det.

:- pred opt_debug__dump_livemaplist(assoc_list(label, lvalset), string).
:- mode opt_debug__dump_livemaplist(in, out) is det.

:- pred opt_debug__dump_livevals(lvalset, string).
:- mode opt_debug__dump_livevals(in, out) is det.

:- pred opt_debug__dump_livelist(list(lval), string).
:- mode opt_debug__dump_livelist(in, out) is det.

:- pred opt_debug__dump_ctrlmap(ctrlmap, string).
:- mode opt_debug__dump_ctrlmap(in, out) is det.

:- pred opt_debug__dump_ctrl_list(assoc_list(int, vn_instr), string).
:- mode opt_debug__dump_ctrl_list(in, out) is det.

:- pred opt_debug__dump_vninstr(vn_instr, string).
:- mode opt_debug__dump_vninstr(in, out) is det.

:- pred opt_debug__dump_flushmap(flushmap, string).
:- mode opt_debug__dump_flushmap(in, out) is det.

:- pred opt_debug__dump_flush_list(assoc_list(int, flushmapentry), string).
:- mode opt_debug__dump_flush_list(in, out) is det.

:- pred opt_debug__dump_flush_entry(assoc_list(vnlval, int), string).
:- mode opt_debug__dump_flush_entry(in, out) is det.

:- pred opt_debug__dump_useful_vns(vn_tables, string).
:- mode opt_debug__dump_useful_vns(in, out) is det.

:- pred opt_debug__dump_useful_locs(vn_tables, string).
:- mode opt_debug__dump_useful_locs(in, out) is det.

:- pred opt_debug__dump_vn_locs(vn_tables, string).
:- mode opt_debug__dump_vn_locs(in, out) is det.

:- pred opt_debug__dump_tables(vn_tables, string).
:- mode opt_debug__dump_tables(in, out) is det.

:- pred opt_debug__dump_lval_to_vn(assoc_list(vnlval, vn), string).
:- mode opt_debug__dump_lval_to_vn(in, out) is det.

:- pred opt_debug__dump_rval_to_vn(assoc_list(vnrval, vn), string).
:- mode opt_debug__dump_rval_to_vn(in, out) is det.

:- pred opt_debug__dump_vn_to_rval(assoc_list(vn, vnrval), string).
:- mode opt_debug__dump_vn_to_rval(in, out) is det.

:- pred opt_debug__dump_vn_to_uses(assoc_list(vn, list(vn_src)), bool, string).
:- mode opt_debug__dump_vn_to_uses(in, in, out) is det.

:- pred opt_debug__dump_vn_to_locs(assoc_list(vn, list(vnlval)), string).
:- mode opt_debug__dump_vn_to_locs(in, out) is det.

:- pred opt_debug__dump_uses_list(list(vn_src), string).
:- mode opt_debug__dump_uses_list(in, out) is det.

:- pred opt_debug__dump_use(vn_src, string).
:- mode opt_debug__dump_use(in, out) is det.

:- pred opt_debug__dump_vn(vn, string).
:- mode opt_debug__dump_vn(in, out) is det.

:- pred opt_debug__dump_vnlvals(list(vnlval), string).
:- mode opt_debug__dump_vnlvals(in, out) is det.

:- pred opt_debug__dump_reg(reg_type, int, string).
:- mode opt_debug__dump_reg(in, in, out) is det.

:- pred opt_debug__dump_vnlval(vnlval, string).
:- mode opt_debug__dump_vnlval(in, out) is det.

:- pred opt_debug__dump_vnrval(vnrval, string).
:- mode opt_debug__dump_vnrval(in, out) is det.

:- pred opt_debug__dump_lval(lval, string).
:- mode opt_debug__dump_lval(in, out) is det.

:- pred opt_debug__dump_rval(rval, string).
:- mode opt_debug__dump_rval(in, out) is det.

:- pred opt_debug__dump_rvals(list(rval), string).
:- mode opt_debug__dump_rvals(in, out) is det.

:- pred opt_debug__dump_mem_ref(mem_ref, string).
:- mode opt_debug__dump_mem_ref(in, out) is det.

:- pred opt_debug__dump_const(rval_const, string).
:- mode opt_debug__dump_const(in, out) is det.

:- pred opt_debug__dump_data_addr(data_addr, string).
:- mode opt_debug__dump_data_addr(in, out) is det.

:- pred opt_debug__dump_data_name(data_name, string).
:- mode opt_debug__dump_data_name(in, out) is det.

:- pred opt_debug__dump_rtti_type_id(rtti_type_id, string).
:- mode opt_debug__dump_rtti_type_id(in, out) is det.

:- pred opt_debug__dump_rtti_name(rtti_name, string).
:- mode opt_debug__dump_rtti_name(in, out) is det.

:- pred opt_debug__dump_layout_name(layout_name, string).
:- mode opt_debug__dump_layout_name(in, out) is det.

:- pred opt_debug__dump_unop(unary_op, string).
:- mode opt_debug__dump_unop(in, out) is det.

:- pred opt_debug__dump_binop(binary_op, string).
:- mode opt_debug__dump_binop(in, out) is det.

:- pred opt_debug__dump_label(label, string).
:- mode opt_debug__dump_label(in, out) is det.

:- pred opt_debug__dump_labels(list(label), string).
:- mode opt_debug__dump_labels(in, out) is det.

:- pred opt_debug__dump_label_pairs(list(pair(label)), string).
:- mode opt_debug__dump_label_pairs(in, out) is det.

:- pred opt_debug__dump_proclabel(proc_label, string).
:- mode opt_debug__dump_proclabel(in, out) is det.

:- pred opt_debug__dump_maybe_rvals(list(maybe(rval)), int, string).
:- mode opt_debug__dump_maybe_rvals(in, in, out) is det.

:- pred opt_debug__dump_code_addr(code_addr, string).
:- mode opt_debug__dump_code_addr(in, out) is det.

:- pred opt_debug__dump_code_addrs(list(code_addr), string).
:- mode opt_debug__dump_code_addrs(in, out) is det.

:- pred opt_debug__dump_bool(bool, string).
:- mode opt_debug__dump_bool(in, out) is det.

:- pred opt_debug__dump_instr(instr, string).
:- mode opt_debug__dump_instr(in, out) is det.

:- pred opt_debug__dump_fullinstr(instruction, string).
:- mode opt_debug__dump_fullinstr(in, out) is det.

:- pred opt_debug__dump_fullinstrs(list(instruction), string).
:- mode opt_debug__dump_fullinstrs(in, out) is det.

:- pred opt_debug__dump_code_model(code_model, string).
:- mode opt_debug__dump_code_model(in, out) is det.

%-----------------------------------------------------------------------------%

:- implementation.

:- import_module prog_out.
:- import_module hlds_pred.
:- import_module llds_out, opt_util, vn_util.
:- import_module globals, options.

:- import_module int, set, map, string.

opt_debug__msg(OptDebug, LabelNo, Msg) -->
	(
		{ OptDebug = yes },
		io__write_string("\n"),
		io__write_string(Msg),
		( { LabelNo >= 0 } ->
			io__write_string(", next label no: "),
			io__write_int(LabelNo)
		;
			[]
		),
		io__write_string("\n")
	;
		{ OptDebug = no }
	).

opt_debug__dump_instrs(OptDebug, Instrs) -->
	(
		{ OptDebug = yes },
		globals__io_lookup_bool_option(auto_comments, PrintComments),
		opt_debug__dump_instrs_2(Instrs, PrintComments)
	;
		{ OptDebug = no }
	).

:- pred opt_debug__dump_instrs_2(list(instruction), bool, io__state, io__state).
:- mode opt_debug__dump_instrs_2(in, in, di, uo) is det.

opt_debug__dump_instrs_2([], _PrintComments) --> [].
opt_debug__dump_instrs_2([Uinstr - Comment | Instrs], PrintComments) -->
	output_instruction_and_comment(Uinstr, Comment, PrintComments),
	opt_debug__dump_instrs_2(Instrs, PrintComments).

opt_debug__dump_node_relmap(Relmap, Str) :-
	map__to_assoc_list(Relmap, Nodemap),
	opt_debug__dump_nodemap(Nodemap, Str).

opt_debug__dump_nodemap([], "").
opt_debug__dump_nodemap([Node - Nodelist | Nodemap], Str) :-
	opt_debug__dump_node(Node, N_str),
	opt_debug__dump_nodelist(Nodelist, Nl_str),
	opt_debug__dump_nodemap(Nodemap, S2_str),
	string__append_list([N_str, " -> ", Nl_str, "\n", S2_str], Str).

opt_debug__dump_nodelist([], "").
opt_debug__dump_nodelist([H | T], Str) :-
	opt_debug__dump_node(H, H_str),
	opt_debug__dump_nodelist(T, T_str),
	string__append_list([H_str, " ", T_str], Str).

opt_debug__dump_longnodelist([], "").
opt_debug__dump_longnodelist([H | T], Str) :-
	opt_debug__dump_node(H, H_str),
	opt_debug__dump_longnodelist(T, T_str),
	string__append_list([H_str, "\n", T_str], Str).

opt_debug__dump_node(node_shared(Vn), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list(["shared vn ", Vn_str], Str).
opt_debug__dump_node(node_lval(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, V_str),
	string__append_list(["vnlval ", V_str], Str).
opt_debug__dump_node(node_origlval(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, V_str),
	string__append_list(["orig vnlval ", V_str], Str).
opt_debug__dump_node(node_ctrl(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["ctrl ", N_str], Str).

opt_debug__dump_intlist([], "").
opt_debug__dump_intlist([H | T], Str) :-
	string__int_to_string(H, H_str),
	opt_debug__dump_intlist(T, T_str),
	string__append_list([" ", H_str, T_str], Str).

opt_debug__dump_livemap(Livemap, Str) :-
	map__to_assoc_list(Livemap, Livemaplist),
	opt_debug__dump_livemaplist(Livemaplist, Str).

opt_debug__dump_livemaplist([], "").
opt_debug__dump_livemaplist([Label - Lvalset | Livemaplist], Str) :-
	opt_debug__dump_label(Label, L_str),
	opt_debug__dump_livevals(Lvalset, S_str),
	opt_debug__dump_livemaplist(Livemaplist, Str2),
	string__append_list([L_str, " ->", S_str, "\n", Str2], Str).

opt_debug__dump_livevals(Lvalset, Str) :-
	set__to_sorted_list(Lvalset, Lvallist),
	opt_debug__dump_livelist(Lvallist, Str).

opt_debug__dump_livelist([], "").
opt_debug__dump_livelist([Lval | Lvallist], Str) :-
	opt_debug__dump_lval(Lval, L_str),
	opt_debug__dump_livelist(Lvallist, L2_str),
	string__append_list([" ", L_str, L2_str], Str).

opt_debug__dump_ctrlmap(Ctrlmap, Str) :-
	map__to_assoc_list(Ctrlmap, Ctrllist),
	opt_debug__dump_ctrl_list(Ctrllist, C_str),
	string__append("\nCtrl map\n", C_str, Str).

opt_debug__dump_ctrl_list([], "").
opt_debug__dump_ctrl_list([N - VnInstr | Ctrllist], Str) :-
	string__int_to_string(N, N_str),
	opt_debug__dump_vninstr(VnInstr, Vni_str),
	opt_debug__dump_ctrl_list(Ctrllist, Str2),
	string__append_list([N_str, " -> ", Vni_str, "\n", Str2], Str).

opt_debug__dump_vninstr(vn_livevals(_), Str) :-
	string__append_list(["livevals(...)"], Str).
opt_debug__dump_vninstr(vn_call(Proc, Ret, _, _, _, _), Str) :-
	opt_debug__dump_code_addr(Proc, P_str),
	opt_debug__dump_code_addr(Ret, R_str),
	string__append_list(["call(", P_str, ", ", R_str, ")"], Str).
opt_debug__dump_vninstr(vn_mkframe(_, _), "mkframe").
opt_debug__dump_vninstr(vn_label(Label), Str) :-
	opt_debug__dump_label(Label, L_str),
	string__append_list(["label(", L_str, ")"], Str).
opt_debug__dump_vninstr(vn_goto(CodeAddr), Str) :-
	opt_debug__dump_code_addr(CodeAddr, C_str),
	string__append_list(["goto(", C_str, ")"], Str).
opt_debug__dump_vninstr(vn_computed_goto(Vn, _), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list(["computed_goto(", Vn_str, ")"], Str).
opt_debug__dump_vninstr(vn_if_val(Vn, CodeAddr), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	opt_debug__dump_code_addr(CodeAddr, L_str),
	string__append_list(["if_val(", Vn_str, ", ", L_str, ")"], Str).
opt_debug__dump_vninstr(vn_mark_hp(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, V_str),
	string__append_list(["mark_hp(", V_str, ")"], Str).
opt_debug__dump_vninstr(vn_restore_hp(Vn), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list(["restore_hp(", Vn_str, ")"], Str).
opt_debug__dump_vninstr(vn_free_heap(Vn), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list(["free_heap(", Vn_str, ")"], Str).
opt_debug__dump_vninstr(vn_store_ticket(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, V_str),
	string__append_list(["store_ticket(", V_str, ")"], Str).
opt_debug__dump_vninstr(vn_reset_ticket(Vn, _Reason), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list(["reset_ticket(", Vn_str, ", _)"], Str).
opt_debug__dump_vninstr(vn_discard_ticket, "discard_ticket").
opt_debug__dump_vninstr(vn_prune_ticket, "prune_ticket").
opt_debug__dump_vninstr(vn_mark_ticket_stack(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, V_str),
	string__append_list(["mark_ticket_stack(", V_str, ")"], Str).
opt_debug__dump_vninstr(vn_prune_tickets_to(Vn), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list(["prune_tickets_to(", Vn_str, ", _)"], Str).
opt_debug__dump_vninstr(vn_incr_sp(N, _), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["incr_sp(", N_str, ")"], Str).
opt_debug__dump_vninstr(vn_decr_sp(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["decr_sp(", N_str, ")"], Str).

opt_debug__dump_flushmap(Flushmap, Str) :-
	map__to_assoc_list(Flushmap, Flushlist),
	opt_debug__dump_flush_list(Flushlist, F_str),
	string__append("\nFlush map\n", F_str, Str).

opt_debug__dump_flush_list([], "").
opt_debug__dump_flush_list([N - FlushEntry | FlushList], Str) :-
	string__int_to_string(N, N_str),
	map__to_assoc_list(FlushEntry, FlushEntryList),
	opt_debug__dump_flush_entry(FlushEntryList, Str1),
	opt_debug__dump_flush_list(FlushList, Str2),
	string__append_list([N_str, " -> ", Str1, "\n", Str2], Str).

opt_debug__dump_flush_entry([], "").
opt_debug__dump_flush_entry([Vnlval - Vn | FlushEntry], Str) :-
	opt_debug__dump_vnlval(Vnlval, L_str),
	opt_debug__dump_vn(Vn, Vn_str),
	opt_debug__dump_flush_entry(FlushEntry, F_str),
	string__append_list([" ", L_str, "/", Vn_str, F_str], Str).

opt_debug__dump_useful_vns(VnTables, Str) :-
	vn_table__get_vn_to_uses_table(VnTables, Vn_to_uses_table),
	map__to_assoc_list(Vn_to_uses_table, Vn_to_uses_list),
	opt_debug__dump_vn_to_uses(Vn_to_uses_list, no, Str).

opt_debug__dump_useful_locs(VnTables, Str) :-
	vn_table__get_loc_to_vn_table(VnTables, Loc_to_vn_table),
	map__to_assoc_list(Loc_to_vn_table, Loc_to_vn_list),
	opt_debug__dump_lval_to_vn(Loc_to_vn_list, Str).

opt_debug__dump_vn_locs(VnTables, Str) :-
	vn_table__get_vn_to_locs_table(VnTables, Vn_to_locs_table),
	map__to_assoc_list(Vn_to_locs_table, Vn_to_locs_list),
	opt_debug__dump_vn_to_locs(Vn_to_locs_list, Str).

opt_debug__dump_tables(VnTables, Str) :-
	vn_table__get_next_vn(VnTables, NextVn),
	vn_table__get_lval_to_vn_table(VnTables, Lval_to_vn_table),
	vn_table__get_rval_to_vn_table(VnTables, Rval_to_vn_table),
	vn_table__get_vn_to_rval_table(VnTables, Vn_to_rval_table),
	vn_table__get_vn_to_uses_table(VnTables, Vn_to_uses_table),
	vn_table__get_vn_to_locs_table(VnTables, Vn_to_locs_table),
	vn_table__get_loc_to_vn_table(VnTables, Loc_to_vn_table),
	string__int_to_string(NextVn, Next_vn_str),
	map__to_assoc_list(Lval_to_vn_table, Lval_to_vn_list),
	map__to_assoc_list(Rval_to_vn_table, Rval_to_vn_list),
	map__to_assoc_list(Vn_to_rval_table, Vn_to_rval_list),
	map__to_assoc_list(Vn_to_uses_table, Vn_to_uses_list),
	map__to_assoc_list(Vn_to_locs_table, Vn_to_locs_list),
	map__to_assoc_list(Loc_to_vn_table,  Loc_to_vn_list),
	opt_debug__dump_lval_to_vn(Lval_to_vn_list, Lval_to_vn_str),
	opt_debug__dump_rval_to_vn(Rval_to_vn_list, _Rval_to_vn_str),
	opt_debug__dump_vn_to_rval(Vn_to_rval_list, Vn_to_rval_str),
	opt_debug__dump_vn_to_uses(Vn_to_uses_list, yes, Vn_to_uses_str),
	opt_debug__dump_vn_to_locs(Vn_to_locs_list, Vn_to_locs_str),
	opt_debug__dump_lval_to_vn(Loc_to_vn_list,  Loc_to_vn_str),
	string__append_list([
		"\nNext vn\n",      Next_vn_str, "\n",
		% "\nRval to vn\n", Rval_to_vn_str,
		"\nVn to rval\n", Vn_to_rval_str,
		"\nVn to uses\n", Vn_to_uses_str,
		"\nLval to vn\n", Lval_to_vn_str,
		"\nVn to locs\n", Vn_to_locs_str,
		"\nLoc to vn\n",  Loc_to_vn_str
		], Str).

opt_debug__dump_lval_to_vn([], "").
opt_debug__dump_lval_to_vn([Vnlval - Vn | Lval_to_vn_list], Str) :-
	opt_debug__dump_lval_to_vn(Lval_to_vn_list, Tail_str),
	opt_debug__dump_vnlval(Vnlval, Vnlval_str),
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list([Vnlval_str, " -> ", Vn_str, "\n", Tail_str], Str).

opt_debug__dump_rval_to_vn([], "").
opt_debug__dump_rval_to_vn([Vnrval - Vn | Rval_to_vn_list], Str) :-
	opt_debug__dump_rval_to_vn(Rval_to_vn_list, Tail_str),
	opt_debug__dump_vnrval(Vnrval, Vnrval_str),
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list([Vnrval_str, " -> ", Vn_str, "\n", Tail_str], Str).

opt_debug__dump_vn_to_rval([], "").
opt_debug__dump_vn_to_rval([Vn - Vnrval | Vn_to_rval_list], Str) :-
	opt_debug__dump_vn_to_rval(Vn_to_rval_list, Tail_str),
	opt_debug__dump_vn(Vn, Vn_str),
	opt_debug__dump_vnrval(Vnrval, Vnrval_str),
	string__append_list([Vn_str, " -> ", Vnrval_str, "\n", Tail_str], Str).

opt_debug__dump_vn_to_uses([], _, "").
opt_debug__dump_vn_to_uses([Vn - Uses | Vn_to_uses_list], PrintUnused, Str) :-
	opt_debug__dump_vn_to_uses(Vn_to_uses_list, PrintUnused, Tail_str),
	( Uses = [], PrintUnused = no ->
		Str = Tail_str
	;
		opt_debug__dump_vn(Vn, Vn_str),
		opt_debug__dump_uses_list(Uses, Uses_str),
		string__append_list([Vn_str, " -> ", Uses_str, "\n", Tail_str],
			Str)
	).

opt_debug__dump_vn_to_locs([], "").
opt_debug__dump_vn_to_locs([Vn - Vn_locs | Vn_to_locs_list], Str) :-
	opt_debug__dump_vn_to_locs(Vn_to_locs_list, Tail_str),
	opt_debug__dump_vn(Vn, Vn_str),
	opt_debug__dump_vnlvals(Vn_locs, Vn_locs_str),
	string__append_list([Vn_str, " -> ", Vn_locs_str, "\n", Tail_str], Str).

opt_debug__dump_uses_list([], "").
opt_debug__dump_uses_list([Use | Uses], Str) :-
	opt_debug__dump_use(Use, Str1),
	opt_debug__dump_uses_list(Uses, Str2),
	string__append_list([Str1, ", ", Str2], Str).

opt_debug__dump_use(src_ctrl(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["src_ctrl(", N_str, ")"], Str).
opt_debug__dump_use(src_liveval(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, Vnlval_str),
	string__append_list(["src_liveval(", Vnlval_str, ")"], Str).
opt_debug__dump_use(src_access(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, Vnlval_str),
	string__append_list(["src_access(", Vnlval_str, ")"], Str).
opt_debug__dump_use(src_vn(Vn), Str) :-
	opt_debug__dump_vn(Vn, Vn_str),
	string__append_list(["src_vn(", Vn_str, ")"], Str).

opt_debug__dump_vn(Vn, Str) :-
	string__int_to_string(Vn, Str).

opt_debug__dump_vnlvals([], "").
opt_debug__dump_vnlvals([Lval | Lvals], Str) :-
	opt_debug__dump_vnlval(Lval, Lval_str),
	opt_debug__dump_vnlvals(Lvals, Tail_str),
	string__append_list([" ", Lval_str, Tail_str], Str).

opt_debug__dump_reg(r, N, Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["r(", N_str, ")"], Str).
opt_debug__dump_reg(f, N, Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["f(", N_str, ")"], Str).

opt_debug__dump_vnlval(vn_reg(Type, Num), Str) :-
	opt_debug__dump_reg(Type, Num, R_str),
	string__append_list(["vn_reg(", R_str, ")"], Str).
opt_debug__dump_vnlval(vn_temp(Type, Num), Str) :-
	opt_debug__dump_reg(Type, Num, R_str),
	string__append_list(["vn_temp(", R_str, ")"], Str).
opt_debug__dump_vnlval(vn_stackvar(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["vn_stackvar(", N_str, ")"], Str).
opt_debug__dump_vnlval(vn_framevar(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["vn_framevar(", N_str, ")"], Str).
opt_debug__dump_vnlval(vn_succip, Str) :-
	string__append_list(["vn_succip"], Str).
opt_debug__dump_vnlval(vn_maxfr, Str) :-
	string__append_list(["vn_maxfr"], Str).
opt_debug__dump_vnlval(vn_curfr, Str) :-
	string__append_list(["vn_curfr"], Str).
opt_debug__dump_vnlval(vn_prevfr(V), Str) :-
	string__int_to_string(V, V_str),
	string__append_list(["vn_prevfr(", V_str, ")"], Str).
opt_debug__dump_vnlval(vn_succfr(V), Str) :-
	string__int_to_string(V, V_str),
	string__append_list(["vn_succfr(", V_str, ")"], Str).
opt_debug__dump_vnlval(vn_redofr(V), Str) :-
	string__int_to_string(V, V_str),
	string__append_list(["vn_redofr(", V_str, ")"], Str).
opt_debug__dump_vnlval(vn_redoip(V), Str) :-
	string__int_to_string(V, V_str),
	string__append_list(["vn_redoip(", V_str, ")"], Str).
opt_debug__dump_vnlval(vn_succip(V), Str) :-
	string__int_to_string(V, V_str),
	string__append_list(["vn_succip(", V_str, ")"], Str).
opt_debug__dump_vnlval(vn_hp, Str) :-
	string__append_list(["vn_hp"], Str).
opt_debug__dump_vnlval(vn_sp, Str) :-
	string__append_list(["vn_sp"], Str).
opt_debug__dump_vnlval(vn_field(MT, N, F), Str) :-
	( MT = yes(T) ->
		string__int_to_string(T, T_str)
	;
		T_str = "no"
	),
	string__int_to_string(N, N_str),
	string__int_to_string(F, F_str),
	string__append_list(["vn_field(", T_str, ", ", N_str, ", ",
		F_str, ")"], Str).
opt_debug__dump_vnlval(vn_mem_ref(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["vn_mem_ref(", N_str, ")"], Str).

opt_debug__dump_vnrval(vn_origlval(Vnlval), Str) :-
	opt_debug__dump_vnlval(Vnlval, Lval_str),
	string__append_list(["vn_origlval(", Lval_str, ")"], Str).
opt_debug__dump_vnrval(vn_mkword(T, N), Str) :-
	string__int_to_string(T, T_str),
	string__int_to_string(N, N_str),
	string__append_list(["vn_mkword(", T_str, ", ", N_str, ")"], Str).
opt_debug__dump_vnrval(vn_const(C), Str) :-
	opt_debug__dump_const(C, C_str),
	string__append_list(["vn_const(", C_str, ")"], Str).
opt_debug__dump_vnrval(vn_create(T, MA, _TA, _U, L, _M), Str) :-
	string__int_to_string(T, T_str),
	opt_debug__dump_maybe_rvals(MA, 3, MA_str),
	string__int_to_string(L, L_str),
	string__append_list(["vn_create(", T_str, ", ", MA_str, ", ",
		L_str, ")"], Str).
opt_debug__dump_vnrval(vn_unop(O, N), Str) :-
	opt_debug__dump_unop(O, O_str),
	string__int_to_string(N, N_str),
	string__append_list(["vn_unop(", O_str, ", ", N_str, ")"], Str).
opt_debug__dump_vnrval(vn_binop(O, N1, N2), Str) :-
	opt_debug__dump_binop(O, O_str),
	string__int_to_string(N1, N1_str),
	string__int_to_string(N2, N2_str),
	string__append_list(["vn_binop(", O_str, ", ", N1_str, ", ",
		N2_str, ")"], Str).
opt_debug__dump_vnrval(vn_stackvar_addr(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["vn_stackvar_addr(", N_str, ")"], Str).
opt_debug__dump_vnrval(vn_framevar_addr(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["vn_framevar_addr(", N_str, ")"], Str).
opt_debug__dump_vnrval(vn_heap_addr(B, T, N), Str) :-
	string__int_to_string(B, B_str),
	string__int_to_string(T, T_str),
	string__int_to_string(N, N_str),
	string__append_list(["vn_heap_addr(", B_str, ", ", T_str, ", ",
		N_str, ")"], Str).

opt_debug__dump_lval(reg(Type, Num), Str) :-
	opt_debug__dump_reg(Type, Num, R_str),
	string__append_list(["reg(", R_str, ")"], Str).
opt_debug__dump_lval(stackvar(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["stackvar(", N_str, ")"], Str).
opt_debug__dump_lval(framevar(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["framevar(", N_str, ")"], Str).
opt_debug__dump_lval(succip, Str) :-
	string__append_list(["succip"], Str).
opt_debug__dump_lval(maxfr, Str) :-
	string__append_list(["maxfr"], Str).
opt_debug__dump_lval(curfr, Str) :-
	string__append_list(["curfr"], Str).
opt_debug__dump_lval(succfr(R), Str) :-
	opt_debug__dump_rval(R, R_str),
	string__append_list(["succfr(", R_str, ")"], Str).
opt_debug__dump_lval(prevfr(R), Str) :-
	opt_debug__dump_rval(R, R_str),
	string__append_list(["prevfr(", R_str, ")"], Str).
opt_debug__dump_lval(redofr(R), Str) :-
	opt_debug__dump_rval(R, R_str),
	string__append_list(["redofr(", R_str, ")"], Str).
opt_debug__dump_lval(redoip(R), Str) :-
	opt_debug__dump_rval(R, R_str),
	string__append_list(["redoip(", R_str, ")"], Str).
opt_debug__dump_lval(succip(R), Str) :-
	opt_debug__dump_rval(R, R_str),
	string__append_list(["succip(", R_str, ")"], Str).
opt_debug__dump_lval(hp, Str) :-
	string__append_list(["hp"], Str).
opt_debug__dump_lval(sp, Str) :-
	string__append_list(["sp"], Str).
opt_debug__dump_lval(field(MT, N, F), Str) :-
	( MT = yes(T) ->
		string__int_to_string(T, T_str)
	;
		T_str = "no"
	),
	opt_debug__dump_rval(N, N_str),
	opt_debug__dump_rval(F, F_str),
	string__append_list(["field(", T_str, ", ", N_str, ", ",
		F_str, ")"], Str).
opt_debug__dump_lval(lvar(_), Str) :-
	string__append_list(["lvar(_)"], Str).
opt_debug__dump_lval(temp(Type, Num), Str) :-
	opt_debug__dump_reg(Type, Num, R_str),
	string__append_list(["temp(", R_str, ")"], Str).
opt_debug__dump_lval(mem_ref(R), Str) :-
	opt_debug__dump_rval(R, R_str),
	string__append_list(["mem_ref(", R_str, ")"], Str).

opt_debug__dump_rval(lval(Lval), Str) :-
	opt_debug__dump_lval(Lval, Lval_str),
	string__append_list(["lval(", Lval_str, ")"], Str).
opt_debug__dump_rval(var(_), Str) :-
	string__append_list(["var(_)"], Str).
opt_debug__dump_rval(mkword(T, N), Str) :-
	string__int_to_string(T, T_str),
	opt_debug__dump_rval(N, N_str),
	string__append_list(["mkword(", T_str, ", ", N_str, ")"], Str).
opt_debug__dump_rval(const(C), Str) :-
	opt_debug__dump_const(C, C_str),
	string__append_list(["const(", C_str, ")"], Str).
opt_debug__dump_rval(create(T, MA, _, U, L, _, _), Str) :-
	string__int_to_string(T, T_str),
	opt_debug__dump_maybe_rvals(MA, 3, MA_str),
	(
		U = must_be_static,
		U_str = "static"
	;
		U = can_be_either,
		U_str = "either"
	;
		U = must_be_dynamic,
		U_str = "dynamic"
	),
	string__int_to_string(L, L_str),
	string__append_list(["create(", T_str, ", ", MA_str, ", ",
		U_str, ", ", L_str, ")"], Str).
opt_debug__dump_rval(unop(O, N), Str) :-
	opt_debug__dump_unop(O, O_str),
	opt_debug__dump_rval(N, N_str),
	string__append_list(["unop(", O_str, ", ", N_str, ")"], Str).
opt_debug__dump_rval(binop(O, N1, N2), Str) :-
	opt_debug__dump_binop(O, O_str),
	opt_debug__dump_rval(N1, N1_str),
	opt_debug__dump_rval(N2, N2_str),
	string__append_list(["binop(", O_str, ", ", N1_str, ", ",
		N2_str, ")"], Str).
opt_debug__dump_rval(mem_addr(M), Str) :-
	opt_debug__dump_mem_ref(M, M_str),
	string__append_list(["mem_addr(", M_str, ")"], Str).

opt_debug__dump_rvals([], "").
opt_debug__dump_rvals([Rval | Rvals], Str) :-
	opt_debug__dump_rval(Rval, R_str),
	opt_debug__dump_rvals(Rvals, S_str),
	string__append_list([R_str, ", ", S_str], Str).

opt_debug__dump_mem_ref(stackvar_ref(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["stackvar_ref(", N_str, ")"], Str).
opt_debug__dump_mem_ref(framevar_ref(N), Str) :-
	string__int_to_string(N, N_str),
	string__append_list(["framevar_ref(", N_str, ")"], Str).
opt_debug__dump_mem_ref(heap_ref(R, T, N), Str) :-
	opt_debug__dump_rval(R, R_str),
	string__int_to_string(T, T_str),
	string__int_to_string(N, N_str),
	string__append_list(["heap_ref(", R_str, ", ", T_str, ", ",
		N_str, ")"], Str).

opt_debug__dump_const(true, "true").
opt_debug__dump_const(false, "false").
opt_debug__dump_const(int_const(I), Str) :-
	string__int_to_string(I, Str).
opt_debug__dump_const(float_const(F), Str) :-
	string__float_to_string(F, Str).
opt_debug__dump_const(string_const(S), Str) :-
	string__append_list(["""", S, """"], Str).
opt_debug__dump_const(multi_string_const(L, _S), Str) :-
	string__int_to_string(L, L_str),
	string__append_list(["multi_string(", L_str, ")"], Str).
opt_debug__dump_const(code_addr_const(CodeAddr), Str) :-
	opt_debug__dump_code_addr(CodeAddr, C_str),
	string__append_list(["code_addr_const(", C_str, ")"], Str).
opt_debug__dump_const(data_addr_const(DataAddr), Str) :-
	opt_debug__dump_data_addr(DataAddr, DataAddr_str),
	string__append_list(
		["data_addr_const(", DataAddr_str, ")"], Str).
opt_debug__dump_const(label_entry(Label), Str) :-
	opt_debug__dump_label(Label, LabelStr),
	string__append_list(["label_entry(", LabelStr, ")"], Str).

opt_debug__dump_data_addr(data_addr(ModuleName, DataName), Str) :-
	prog_out__sym_name_to_string(ModuleName, ModuleName_str),
	opt_debug__dump_data_name(DataName, DataName_str),
	string__append_list(
		["data_addr(", ModuleName_str, ", ", DataName_str, ")"], Str).
opt_debug__dump_data_addr(rtti_addr(RttiTypeId, DataName), Str) :-
	opt_debug__dump_rtti_type_id(RttiTypeId, RttiTypeId_str),
	opt_debug__dump_rtti_name(DataName, DataName_str),
	string__append_list(
		["rtti_addr(", RttiTypeId_str, ", ", DataName_str, ")"], Str).
opt_debug__dump_data_addr(layout_addr(LayoutName), Str) :-
	opt_debug__dump_layout_name(LayoutName, LayoutName_str),
	string__append_list(["layout_addr(", LayoutName_str, ")"], Str).

opt_debug__dump_data_name(common(N), Str) :-
	string__int_to_string(N, N_str),
	string__append("common", N_str, Str).
opt_debug__dump_data_name(base_typeclass_info(ClassId, InstanceNum), Str) :-
	llds_out__make_base_typeclass_info_name(ClassId, InstanceNum, Str).
opt_debug__dump_data_name(tabling_pointer(ProcLabel), Str) :-
	opt_debug__dump_proclabel(ProcLabel, ProcLabelStr),
	string__append_list(["tabling_pointer(", ProcLabelStr, ")"], Str).

opt_debug__dump_rtti_type_id(rtti_type_id(ModuleName, TypeName, Arity), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleName_str),
	llds_out__name_mangle(TypeName, TypeName_str),
	string__int_to_string(Arity, Arity_str),
	string__append_list(["rtti_type_id(", ModuleName_str, ", ",
		TypeName_str, Arity_str, ")"], Str).

opt_debug__dump_rtti_name(exist_locns(Ordinal), Str) :-
	string__int_to_string(Ordinal, Ordinal_str),
	string__append("exist_locns_", Ordinal_str, Str).
opt_debug__dump_rtti_name(exist_info(Ordinal), Str) :-
	string__int_to_string(Ordinal, Ordinal_str),
	string__append("exist_info_", Ordinal_str, Str).
opt_debug__dump_rtti_name(field_names(Ordinal), Str) :-
	string__int_to_string(Ordinal, Ordinal_str),
	string__append("field_names_", Ordinal_str, Str).
opt_debug__dump_rtti_name(field_types(Ordinal), Str) :-
	string__int_to_string(Ordinal, Ordinal_str),
	string__append("field_types_", Ordinal_str, Str).
opt_debug__dump_rtti_name(enum_functor_desc(Ordinal), Str) :-
	string__int_to_string(Ordinal, Ordinal_str),
	string__append("enum_functor_desc_", Ordinal_str, Str).
opt_debug__dump_rtti_name(notag_functor_desc, Str) :-
	Str = "notag_functor_desc_".
opt_debug__dump_rtti_name(du_functor_desc(Ordinal), Str) :-
	string__int_to_string(Ordinal, Ordinal_str),
	string__append("du_functor_desc_", Ordinal_str, Str).
opt_debug__dump_rtti_name(enum_name_ordered_table, Str) :-
	Str = "enum_name_ordered_table".
opt_debug__dump_rtti_name(enum_value_ordered_table, Str) :-
	Str = "enum_value_ordered_table".
opt_debug__dump_rtti_name(du_name_ordered_table, Str) :-
	Str = "du_name_ordered_table".
opt_debug__dump_rtti_name(du_stag_ordered_table(Ptag), Str) :-
	string__int_to_string(Ptag, Ptag_str),
	string__append("du_stag_ordered_table_", Ptag_str, Str).
opt_debug__dump_rtti_name(du_ptag_ordered_table, Str) :-
	Str = "du_ptag_ordered_table".
opt_debug__dump_rtti_name(type_ctor_info, Str) :-
	Str = "type_ctor_info".
opt_debug__dump_rtti_name(base_typeclass_info(_ModuleName, ClassId,
		InstanceStr), Str) :-
	llds_out__make_base_typeclass_info_name(ClassId, InstanceStr, Str).
opt_debug__dump_rtti_name(pseudo_type_info(_Pseudo), Str) :-
	% XXX should give more info than this
	Str = "pseudo_type_info".
opt_debug__dump_rtti_name(type_hashcons_pointer, Str) :-
	Str = "type_hashcons_pointer".

opt_debug__dump_layout_name(label_layout(Label, LabelVars), Str) :-
	opt_debug__dump_label(Label, LabelStr),
	(
		LabelVars = label_has_var_info,
		LabelVarsStr = "label_has_var_info"
	;
		LabelVars = label_has_no_var_info,
		LabelVarsStr = "label_has_no_var_info"
	),
	string__append_list(["label_layout(", LabelStr, ", ",
		LabelVarsStr, ")"], Str).
opt_debug__dump_layout_name(proc_layout(ProcLabel, _), Str) :-
	opt_debug__dump_proclabel(ProcLabel, ProcLabelStr),
	string__append_list(["proc_layout(", ProcLabelStr, ")"], Str).
opt_debug__dump_layout_name(proc_layout_var_names(ProcLabel), Str) :-
	opt_debug__dump_proclabel(ProcLabel, ProcLabelStr),
	string__append_list(["proc_layout_var_names(", ProcLabelStr, ")"],
		Str).
opt_debug__dump_layout_name(closure_proc_id(ProcLabel, SeqNo, _), Str) :-
	opt_debug__dump_proclabel(ProcLabel, ProcLabelStr),
	string__int_to_string(SeqNo, SeqNoStr),
	string__append_list(["closure_proc_id(", ProcLabelStr, ", ",
		SeqNoStr, ")"], Str).
opt_debug__dump_layout_name(file_layout(ModuleName, FileNum), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleNameStr),
	string__int_to_string(FileNum, FileNumStr),
	string__append_list(["file_layout(", ModuleNameStr, ", ",
		FileNumStr, ")"], Str).
opt_debug__dump_layout_name(file_layout_line_number_vector(ModuleName,
		FileNum), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleNameStr),
	string__int_to_string(FileNum, FileNumStr),
	string__append_list(["file_layout_line_number_vector(", ModuleNameStr,
		", ", FileNumStr, ")"], Str).
opt_debug__dump_layout_name(file_layout_label_layout_vector(ModuleName,
		FileNum), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleNameStr),
	string__int_to_string(FileNum, FileNumStr),
	string__append_list(["file_layout_label_layout_vector(", ModuleNameStr,
		", ", FileNumStr, ")"], Str).
opt_debug__dump_layout_name(module_layout_string_table(ModuleName), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleNameStr),
	string__append_list(["module_layout_string_table(", ModuleNameStr,
		")"], Str).
opt_debug__dump_layout_name(module_layout_file_vector(ModuleName), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleNameStr),
	string__append_list(["module_layout_file_vector(", ModuleNameStr, ")"],
		Str).
opt_debug__dump_layout_name(module_layout_proc_vector(ModuleName), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleNameStr),
	string__append_list(["module_layout_proc_vector(", ModuleNameStr, ")"],
		Str).
opt_debug__dump_layout_name(module_layout(ModuleName), Str) :-
	llds_out__sym_name_mangle(ModuleName, ModuleNameStr),
	string__append_list(["module_layout(", ModuleNameStr, ")"], Str).

opt_debug__dump_unop(mktag, "mktag").
opt_debug__dump_unop(tag, "tag").
opt_debug__dump_unop(unmktag, "unmktag").
opt_debug__dump_unop(mkbody, "mkbody").
opt_debug__dump_unop(unmkbody, "unmkbody").
opt_debug__dump_unop(not, "not").
opt_debug__dump_unop(hash_string, "hash_string").
opt_debug__dump_unop(bitwise_complement, "bitwise_complement").

opt_debug__dump_binop(Op, String) :-
	llds_out__binary_op_to_string(Op, String).

opt_debug__dump_maybe_rvals([], _, "").
opt_debug__dump_maybe_rvals([MR | MRs], N, Str) :-
	( N > 0 ->
		( MR = yes(R) ->
			opt_debug__dump_rval(R, MR_str)
		;
			MR_str = "no"
		),
		N1 is N - 1,
		opt_debug__dump_maybe_rvals(MRs, N1, MRs_str),
		string__append_list([MR_str, ", ", MRs_str], Str)
	;
		Str = "truncated"
	).

opt_debug__dump_code_addr(label(Label), Str) :-
	opt_debug__dump_label(Label, Str).
opt_debug__dump_code_addr(imported(ProcLabel), Str) :-
	opt_debug__dump_proclabel(ProcLabel, Str).
opt_debug__dump_code_addr(succip, "succip").
opt_debug__dump_code_addr(do_succeed(Last), Str) :-
	(
		Last = no,
		Str = "do_succeed"
	;
		Last = yes,
		Str = "do_last_succeed"
	).
opt_debug__dump_code_addr(do_redo, "do_redo").
opt_debug__dump_code_addr(do_fail, "do_fail").
opt_debug__dump_code_addr(do_trace_redo_fail_shallow,
	"do_trace_redo_fail_shallow").
opt_debug__dump_code_addr(do_trace_redo_fail_deep, "do_trace_redo_fail_deep").
opt_debug__dump_code_addr(do_call_closure, "do_nondet_closure").
opt_debug__dump_code_addr(do_call_class_method, "do_nondet_class_method").
opt_debug__dump_code_addr(do_det_aditi_call, "do_det_aditi_call").
opt_debug__dump_code_addr(do_semidet_aditi_call, "do_semidet_aditi_call").
opt_debug__dump_code_addr(do_nondet_aditi_call, "do_nondet_aditi_call").
opt_debug__dump_code_addr(do_aditi_insert, "do_aditi_insert").
opt_debug__dump_code_addr(do_aditi_delete, "do_aditi_delete").
opt_debug__dump_code_addr(do_aditi_bulk_insert, "do_aditi_bulk_insert").
opt_debug__dump_code_addr(do_aditi_bulk_delete, "do_aditi_bulk_delete").
opt_debug__dump_code_addr(do_aditi_bulk_modify, "do_aditi_bulk_modify").
opt_debug__dump_code_addr(do_not_reached, "do_not_reached").

opt_debug__dump_code_addrs([], "").
opt_debug__dump_code_addrs([Addr | Addrs], Str) :-
	opt_debug__dump_code_addr(Addr, A_str),
	opt_debug__dump_code_addrs(Addrs, A2_str),
	string__append_list([" ", A_str, A2_str], Str).

opt_debug__dump_label(local(N, ProcLabel), Str) :-
	opt_debug__dump_proclabel(ProcLabel, P_str),
	string__int_to_string(N, N_str),
	string__append_list([P_str, "_", N_str], Str).
opt_debug__dump_label(c_local(ProcLabel), Str) :-
	opt_debug__dump_proclabel(ProcLabel, Str).
opt_debug__dump_label(local(ProcLabel), Str) :-
	opt_debug__dump_proclabel(ProcLabel, Str).
opt_debug__dump_label(exported(ProcLabel), Str) :-
	opt_debug__dump_proclabel(ProcLabel, Str).

opt_debug__dump_labels([], "").
opt_debug__dump_labels([Label | Labels], Str) :-
	opt_debug__dump_label(Label, L_str),
	opt_debug__dump_labels(Labels, L2_str),
	string__append_list([" ", L_str, L2_str], Str).

opt_debug__dump_label_pairs([], "").
opt_debug__dump_label_pairs([L1 - L2 | Labels], Str) :-
	opt_debug__dump_label(L1, L1_str),
	opt_debug__dump_label(L2, L2_str),
	opt_debug__dump_label_pairs(Labels, L_str),
	string__append_list([" ", L1_str, "-", L2_str, L_str], Str).

opt_debug__dump_proclabel(proc(Module, _PredOrFunc, PredModule,
		PredName, Arity, ProcId), Str) :-
	( Module = PredModule ->
		ExtraModule = ""
	;
		llds_out__sym_name_mangle(PredModule, PredModuleName),
		string__append(PredModuleName, "_", ExtraModule)
	),
	llds_out__sym_name_mangle(Module, ModuleName),
	string__int_to_string(Arity, A_str),
	proc_id_to_int(ProcId, Mode),
	string__int_to_string(Mode, M_str),
	string__append_list([ExtraModule, ModuleName, "_", PredName,
		"_", A_str, "_", M_str], Str).
opt_debug__dump_proclabel(special_proc(Module, Pred, TypeModule,
		Type, Arity, ProcId), Str) :-
	llds_out__sym_name_mangle(Module, ModuleName),
	llds_out__sym_name_mangle(TypeModule, TypeModuleName),
	llds_out__qualify_name(TypeModuleName, Type, TypeName),
	string__int_to_string(Arity, A_str),
	proc_id_to_int(ProcId, Mode),
	string__int_to_string(Mode, M_str),
	string__append_list([ModuleName, "_", Pred, "_",
		TypeName, "_", A_str, "_", M_str], Str).

opt_debug__dump_bool(yes, "yes").
opt_debug__dump_bool(no, "no").

opt_debug__dump_code_model(model_det, "model_det").
opt_debug__dump_code_model(model_semi, "model_semi").
opt_debug__dump_code_model(model_non, "model_non").

opt_debug__dump_instr(comment(Comment), Str) :-
	string__append_list(["comment(", Comment, ")"], Str).
opt_debug__dump_instr(livevals(Livevals), Str) :-
	opt_debug__dump_livevals(Livevals, L_str),
	string__append_list(["livevals(", L_str, ")"], Str).
opt_debug__dump_instr(block(RTemps, FTemps, _), Str) :-
	string__int_to_string(RTemps, R_str),
	string__int_to_string(FTemps, F_str),
	string__append_list(["block(", R_str, ", ", F_str, ", ...)"], Str).
opt_debug__dump_instr(assign(Lval, Rval), Str) :-
	opt_debug__dump_lval(Lval, L_str),
	opt_debug__dump_rval(Rval, R_str),
	string__append_list(["assign(", L_str, ", ", R_str, ")"], Str).
opt_debug__dump_instr(call(Proc, Ret, _, _, _, _), Str) :-
	opt_debug__dump_code_addr(Proc, P_str),
	opt_debug__dump_code_addr(Ret, R_str),
	string__append_list(["call(", P_str, ", ", R_str, ", ...)"], Str).
opt_debug__dump_instr(mkframe(FrameInfo, Redoip), Str) :-
	opt_debug__dump_code_addr(Redoip, R_str),
	(
		FrameInfo = ordinary_frame(Name, Size, MaybePragma),
		string__int_to_string(Size, S_str),
		( MaybePragma = yes(pragma_c_struct(StructName, Fields, _)) ->
			string__append_list(["yes(", StructName, ", ",
				Fields, ")"], P_str)
		;
			P_str = "no"
		),
		string__append_list(["mkframe(", Name, ", ", S_str, ", ",
			P_str, ", ", R_str, ")"], Str)
	;
		FrameInfo = temp_frame(Kind),
		(
			Kind = nondet_stack_proc,
			string__append_list(["mktempframe(", R_str, ")"], Str)
		;
			Kind = det_stack_proc,
			string__append_list(["mkdettempframe(", R_str, ")"],
				Str)
		)
	).
opt_debug__dump_instr(label(Label), Str) :-
	opt_debug__dump_label(Label, L_str),
	string__append_list(["label(", L_str, ")"], Str).
opt_debug__dump_instr(goto(CodeAddr), Str) :-
	opt_debug__dump_code_addr(CodeAddr, C_str),
	string__append_list(["goto(", C_str, ")"], Str).
opt_debug__dump_instr(computed_goto(Rval, Labels), Str) :-
	opt_debug__dump_rval(Rval, R_str),
	opt_debug__dump_labels(Labels, L_str),
	string__append_list(["computed_goto(", R_str, ", ", L_str, ")"], Str).
opt_debug__dump_instr(c_code(Code), Str) :-
	string__append_list(["c_code(", Code, ")"], Str).
opt_debug__dump_instr(if_val(Rval, CodeAddr), Str) :-
	opt_debug__dump_rval(Rval, R_str),
	opt_debug__dump_code_addr(CodeAddr, C_str),
	string__append_list(["if_val(", R_str, ", ", C_str, ")"], Str).
opt_debug__dump_instr(incr_hp(Lval, MaybeTag, Size, _), Str) :-
	opt_debug__dump_lval(Lval, L_str),
	(
		MaybeTag = no,
		T_str = "no"
	;
		MaybeTag = yes(Tag),
		string__int_to_string(Tag, T_str)
	),
	opt_debug__dump_rval(Size, S_str),
	string__append_list(["incr_hp(", L_str, ", ", T_str, ", ", S_str, ")"],
		Str).
opt_debug__dump_instr(mark_hp(Lval), Str) :-
	opt_debug__dump_lval(Lval, L_str),
	string__append_list(["mark_hp(", L_str, ")"], Str).
opt_debug__dump_instr(restore_hp(Rval), Str) :-
	opt_debug__dump_rval(Rval, R_str),
	string__append_list(["restore_hp(", R_str, ")"], Str).
opt_debug__dump_instr(free_heap(Rval), Str) :-
	opt_debug__dump_rval(Rval, R_str),
	string__append_list(["free_heap(", R_str, ")"], Str).
opt_debug__dump_instr(store_ticket(Lval), Str) :-
	opt_debug__dump_lval(Lval, L_str),
	string__append_list(["store_ticket(", L_str, ")"], Str).
opt_debug__dump_instr(reset_ticket(Rval, _Reason), Str) :-
	opt_debug__dump_rval(Rval, R_str),
	string__append_list(["reset_ticket(", R_str, ", _)"], Str).
opt_debug__dump_instr(discard_ticket, "discard_ticket").
opt_debug__dump_instr(prune_ticket, "prune_ticket").
opt_debug__dump_instr(mark_ticket_stack(Lval), Str) :-
	opt_debug__dump_lval(Lval, L_str),
	string__append_list(["mark_ticket_stack(", L_str, ")"], Str).
opt_debug__dump_instr(prune_tickets_to(Rval), Str) :-
	opt_debug__dump_rval(Rval, R_str),
	string__append_list(["prune_tickets_to(", R_str, ")"], Str).
opt_debug__dump_instr(incr_sp(Size, _), Str) :-
	string__int_to_string(Size, S_str),
	string__append_list(["incr_sp(", S_str, ")"], Str).
opt_debug__dump_instr(decr_sp(Size), Str) :-
	string__int_to_string(Size, S_str),
	string__append_list(["decr_sp(", S_str, ")"], Str).
opt_debug__dump_instr(init_sync_term(Lval, N), Str) :-
	opt_debug__dump_lval(Lval, L_str),
	string__int_to_string(N, N_str),
	string__append_list(["init_sync_term(", L_str, ", ", N_str, ")"], Str).
opt_debug__dump_instr(fork(Child, Parent, Lval), Str) :-
	opt_debug__dump_label(Child, ChildStr),
	opt_debug__dump_label(Parent, ParentStr),
	string__int_to_string(Lval, LvalStr),
	string__append_list(["fork(", ChildStr, ", ", ParentStr, ", ",
		LvalStr, ")"], Str).
opt_debug__dump_instr(join_and_terminate(Lval), Str) :-
	opt_debug__dump_lval(Lval, LvalStr),
	string__append_list(["join_and_terminate(", LvalStr, ")"], Str).
opt_debug__dump_instr(join_and_continue(Lval, Label), Str) :-
	opt_debug__dump_lval(Lval, LvalStr),
	opt_debug__dump_label(Label, LabelStr),
	string__append_list(["join(", LvalStr, ", ", LabelStr, ")"], Str).
% XXX  should probably give more info than this
opt_debug__dump_instr(pragma_c(_, Comps, _, _, _, _, _), Str) :-
	opt_debug__dump_components(Comps, C_str),
	string__append_list(["pragma_c(", C_str, ")"], Str).

:- pred opt_debug__dump_components(list(pragma_c_component), string).
:- mode opt_debug__dump_components(in, out) is det.

opt_debug__dump_components([], "").
opt_debug__dump_components([Comp | Comps], Str) :-
	opt_debug__dump_component(Comp, Str1),
	opt_debug__dump_components(Comps, Str2),
	string__append(Str1, Str2, Str).

:- pred opt_debug__dump_component(pragma_c_component, string).
:- mode opt_debug__dump_component(in, out) is det.

opt_debug__dump_component(pragma_c_inputs(_), "").
opt_debug__dump_component(pragma_c_outputs(_), "").
opt_debug__dump_component(pragma_c_user_code(_, Code), Code).
opt_debug__dump_component(pragma_c_raw_code(Code), Code).
opt_debug__dump_component(pragma_c_fail_to(Label), Code) :-
	opt_debug__dump_label(Label, LabelStr),
	string__append_list(["fail to ", LabelStr], Code).
opt_debug__dump_component(pragma_c_noop, "").

opt_debug__dump_fullinstr(Uinstr - Comment, Str) :-
	opt_debug__dump_instr(Uinstr, U_str),
	string__append_list([U_str, " - ", Comment, "\n"], Str).

opt_debug__dump_fullinstrs([], "").
opt_debug__dump_fullinstrs([Instr | Instrs], Str) :-
	opt_debug__dump_fullinstr(Instr, S1_str),
	opt_debug__dump_fullinstrs(Instrs, S2_str),
	string__append_list([S1_str, S2_str], Str).
