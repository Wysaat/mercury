/*
** Copyright (C) 1998-2001, 2005 The University of Melbourne.
** This file may only be copied under the terms of the GNU Library General
** Public License - see the file COPYING.LIB in the Mercury distribution.
*/

/*
** This file contains the declarations of the types and functions that
** the internal and external debuggers can use to manipulate spy points.
**
** Main author: Zoltan Somogyi.
*/

#ifndef	MERCURY_TRACE_SPY_H
#define	MERCURY_TRACE_SPY_H

#include "mercury_stack_layout.h"	/* for MR_Proc_Layout etc */
#include "mercury_trace_base.h"		/* for MR_Trace_Port etc  */
#include "mercury_trace_browse.h"	/* for MR_Browse_Format */

typedef enum {
	MR_SPY_PRINT, MR_SPY_STOP
} MR_Spy_Action;

#define	MR_spy_action_string(a)		((a == MR_SPY_STOP) ? "stop" :      \
					(a == MR_SPY_PRINT) ? "print" :     \
					"unknown spy action")

typedef enum {
	MR_SPY_ALL,
	MR_SPY_INTERFACE,
	MR_SPY_ENTRY,
	MR_SPY_SPECIFIC,
	MR_SPY_LINENO
} MR_Spy_When;

typedef enum {
	MR_SPY_DONT_IGNORE,
	MR_SPY_IGNORE_INTERFACE,
	MR_SPY_IGNORE_ENTRY
} MR_Spy_Ignore_When;

extern	const char	*MR_spy_when_names[];

typedef	struct MR_Spy_Print_Struct	*MR_Spy_Print;
typedef	struct MR_Spy_Print_List_Struct	*MR_Spy_Print_List;

typedef enum {
	MR_SPY_PRINT_GOAL,
	MR_SPY_PRINT_ALL,
	MR_SPY_PRINT_ONE,
} MR_Spy_Print_What;

struct MR_Spy_Print_Struct {
	MR_Browse_Format	p_format;
	MR_Spy_Print_What	p_what;
	char			*p_name;	/* if MR_SPY_PRINT_ONE */
	MR_bool			p_warn;
};

struct MR_Spy_Print_List_Struct {
	MR_Spy_Print		pl_cur;
	MR_Spy_Print_List	pl_next;
};

typedef struct MR_Spy_Point_Struct MR_Spy_Point;

struct MR_Spy_Point_Struct {
	MR_bool			spy_exists;	/* MR_FALSE if deleted */
	MR_bool			spy_enabled;
	MR_Spy_When		spy_when;
	MR_Spy_Action		spy_action;
	MR_Spy_Ignore_When	spy_ignore_when;
	int			spy_ignore_count;
	MR_Spy_Print_List	spy_print_list;
	const MR_Proc_Layout	*spy_proc;      /* if not LINENO */
	const MR_Label_Layout	*spy_label;	/* if SPECIFIC */
	char			*spy_filename;  /* if LINENO */
	int			spy_linenumber; /* if LINENO */
	MR_Spy_Point		*spy_next;	/* if not LINENO */
};

/*
** The table of spy points, with counters saying which is the next free slot
** and how many slots are allocated.
*/

extern	MR_Spy_Point    **MR_spy_points;
extern	int		MR_spy_point_next;
extern	int		MR_spy_point_max;

extern	int		MR_most_recent_spy_point;

/*
** Check whether the event described by the given label layout and port
** matches any spy points. If yes, return MR_TRUE, set *action to say what
** action should be executed for the spy point, and set print_list to the
** variable print list of the first matching spy point.
*/

extern	MR_bool		MR_event_matches_spy_point(const MR_Label_Layout
				*layout, MR_Trace_Port port,
				MR_Spy_Action *action,
				MR_Spy_Print_List *print_list);

/*
** Add a new spy point on a procedure (as opposed to on a line number)
** to the table. If this cannot be done, return a negative number and set
** *problem to point to an error message.
*/

extern	int		MR_add_proc_spy_point(MR_Spy_When when,
				MR_Spy_Action action,
				MR_Spy_Ignore_When ignore_when,
				int ignore_count,
				const MR_Proc_Layout *entry,
				const MR_Label_Layout *label,
				MR_Spy_Print_List print_list,
				const char **problem);

/*
** Add a new spy point on a line number (as opposed to on a procedure)
** to the table. If this cannot be done, return a negative number and set
** *problem to point to an error message.
*/

extern	int		MR_add_line_spy_point(MR_Spy_Action action,
				MR_Spy_Ignore_When ignore_when,
				int ignore_count,
				const char *filename, int linenumber,
				MR_Spy_Print_List print_list,
				const char **problem);

/*
** Add the given set of things to be printed to the spy point's list,
** at either the start or the end of the existing list.
*/

extern	void 		MR_add_spy_point_print_list_start(int point_slot,
				MR_Spy_Print_List print_list);
extern	void 		MR_add_spy_point_print_list_end(int point_slot,
				MR_Spy_Print_List print_list);

/*
** Empty the set of things to be printed at the spy point.
*/

extern	void		MR_clear_spy_point_print_list(int point_slot);

/*
** Apply the given ignore specification to the given spy point.
** If the ignore specification is not appropriate for the spy point,
** return a non-NULL problem report.
*/

extern	const char 	*MR_ignore_spy_point(int point_slot,
				MR_Spy_Ignore_When ignore_when,
				int ignore_count);

/*
** Delete a spy point from the table.
*/

extern	void		MR_delete_spy_point(int point_table_slot);

/*
** Print the spy point with the given number in a nice format for humans to
** read to the given file.
*/

extern	void		MR_print_spy_point(FILE *fp, int i, MR_bool verbose);

/*
** Print the set of current spy points (including those that are currently
** disabled) to fp in a format that, when sourced by mdb, recreates those
** spy points. Any internal errors encountered while trying to do this
** should be reported to err_fp. Return MR_TRUE iff the debugger's data
** structures are inconsistent, and the spy points could not be saved.
*/

extern	MR_bool		MR_save_spy_points(FILE *fp, FILE *err_fp);

#endif	/* not MERCURY_TRACE_SPY_H */
