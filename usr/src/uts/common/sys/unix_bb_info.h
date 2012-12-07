/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */
/*
 *	Copyright (c) 1993-2001 by Sun Microsystems, Inc.
 *	All rights reserved.
 */

#ifndef _SYS_UNIX_BB_INFO_H
#define	_SYS_UNIX_BB_INFO_H

#pragma ident	"%Z%%M%	%I%	%E% SMI"

#ifdef	__cplusplus
extern "C" {
#endif

/*
 *  data structures for kernel basic block coverage via kcov
 */

#define	NMI_LEVEL	15

/*
 *	struct bb_info is built in to the compiler
 *	Don't change this structure except to reflect
 *	changes to the code generated by the compiler
 */
struct bb_info {
	ulong_t			bb_initflag;
	char			*bb_filename;
	uint64_t		*bb_counters;
	ulong_t			bb_ncounters;
	struct bb_info		*bb_next;
};

#ifdef	__cplusplus
}
#endif

#endif	/* _SYS_UNIX_BB_INFO_H */
