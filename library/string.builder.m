%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sw=4 et
%-----------------------------------------------------------------------------%
% Copyright (C) 2006-2007 The University of Melbourne.
% This file may only be copied under the terms of the GNU Library General
% Public License - see the file COPYING.LIB in the Mercury distribution.
%-----------------------------------------------------------------------------%
%
% File: string.builder.m.
% Main author: maclarty.
% 
% This module implements a string builder stream.  It can be used to
% build up a string using string or character writers.
%
% To build up a string using this module, you first construct an initial
% string builder state by calling the init function.  You can then use
% any instances of stream.writer that write strings or characters to update the
% string builder state, using string.builder.handle as the stream argument.
% Once you've finished writing to the string builder you can get the final
% string by calling string.builder.to_string/1.
%
% For example:
%
%     State0 = string.builder.init,
%     stream.string_writer.put_int(string.builder.handle, 5, State0, State),
%     Str = string.builder.to_string(State),  % Str = "5".
%
%-----------------------------------------------------------------------------%

:- module string.builder.
:- interface.

:- import_module char.
:- import_module stream.

%-----------------------------------------------------------------------------%

:- type handle
    --->    handle.

:- type state.

:- func init = (string.builder.state::uo) is det.

:- instance stream.stream(string.builder.handle, string.builder.state).

:- instance stream.output(string.builder.handle, string.builder.state).

:- instance stream.writer(string.builder.handle, string, string.builder.state).
:- instance stream.writer(string.builder.handle, char, string.builder.state).

:- func to_string(string.builder.state::di) = (string::uo) is det.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- import_module list.

:- type state
    --->    state(list(string)).

init = state([]).

:- instance stream.stream(string.builder.handle, string.builder.state)
        where [
    name(_, "<<string builder stream>>", !State)
].

:- instance stream.output(string.builder.handle, string.builder.state)
        where [
    flush(_, !State)
].

:- instance stream.writer(string.builder.handle, string, string.builder.state)
        where [
    ( put(_, String, !State) :-
        !.State = state(StringList0),
        copy(String, UniqueString),
        StringList = [UniqueString | StringList0],
        !:State = state(StringList)
    )
].

:- instance stream.writer(string.builder.handle, char, string.builder.state)
        where [
    ( put(_, Char, !State) :-
        !.State = state(StringList0),
        StringList = [string.from_char(Char) | StringList0],
        !:State = state(StringList)
    )
].

to_string(State) = String :-
    State = state(StringList),
    String = string.append_list(list.reverse(StringList)).

%-----------------------------------------------------------------------------%
:- end_module string.builder.
%-----------------------------------------------------------------------------%
