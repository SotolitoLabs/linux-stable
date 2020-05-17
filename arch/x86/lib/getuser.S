/*
 * __get_user functions.
 *
 * (C) Copyright 1998 Linus Torvalds
 * (C) Copyright 2005 Andi Kleen
 * (C) Copyright 2008 Glauber Costa
 *
 * These functions have a non-standard call interface
 * to make them more efficient, especially as they
 * return an error value in addition to the "real"
 * return value.
 */

/*
 * __get_user_X
 *
 * Inputs:	%[r|e]ax contains the address.
 *
 * Outputs:	%[r|e]ax is error code (0 or -EFAULT)
 *		%[r|e]dx contains zero-extended value
 *		%ecx contains the high half for 32-bit __get_user_8
 *
 *
 * These functions should not modify any other registers,
 * as they get called from within inline assembly.
 */

#include <linux/linkage.h>
#include <asm/page_types.h>
#include <asm/errno.h>
#include <asm/asm-offsets.h>
#include <asm/thread_info.h>
#include <asm/asm.h>
#include <asm/smap.h>
#include <asm/export.h>
#include <asm/segment.h>
#include <asm/pgtable.h>
#include <asm/frame.h>
#include <asm/alternative-asm.h>

#define __copyuser_seg

	.text
ENTRY(__get_user_1)
	FRAME_BEGIN

	mov PER_CPU_VAR(current_task), %_ASM_DX
	cmp TASK_addr_limit(%_ASM_DX),%_ASM_AX
	jae bad_get_user

	ASM_USER_ACCESS_BEGIN
1:	__copyuser_seg movzbl (%_ASM_AX),%edx
	ASM_USER_ACCESS_END
	xor %eax,%eax
	FRAME_END
	pax_ret __get_user_1
ENDPROC(__get_user_1)
EXPORT_SYMBOL(__get_user_1)

ENTRY(__get_user_2)
	FRAME_BEGIN
	add $1,%_ASM_AX

	jc bad_get_user
	mov PER_CPU_VAR(current_task), %_ASM_DX
	cmp TASK_addr_limit(%_ASM_DX),%_ASM_AX
	jae bad_get_user

	ASM_USER_ACCESS_BEGIN
2:	__copyuser_seg movzwl -1(%_ASM_AX),%edx
	ASM_USER_ACCESS_END
	xor %eax,%eax
	FRAME_END
	pax_ret __get_user_2
ENDPROC(__get_user_2)
EXPORT_SYMBOL(__get_user_2)

ENTRY(__get_user_4)
	FRAME_BEGIN
	add $3,%_ASM_AX

	jc bad_get_user
	mov PER_CPU_VAR(current_task), %_ASM_DX
	cmp TASK_addr_limit(%_ASM_DX),%_ASM_AX
	jae bad_get_user

	ASM_USER_ACCESS_BEGIN
3:	__copyuser_seg movl -3(%_ASM_AX),%edx
	ASM_USER_ACCESS_END
	xor %eax,%eax
	FRAME_END
	pax_ret __get_user_4
ENDPROC(__get_user_4)
EXPORT_SYMBOL(__get_user_4)

ENTRY(__get_user_8)
	FRAME_BEGIN

#ifdef CONFIG_X86_64
	add $7,%_ASM_AX
	jc bad_get_user
	mov PER_CPU_VAR(current_task), %_ASM_DX
	cmp TASK_addr_limit(%_ASM_DX),%_ASM_AX
	jae bad_get_user

	ASM_USER_ACCESS_BEGIN
4:	movq -7(%_ASM_AX),%rdx
	ASM_USER_ACCESS_END
	xor %eax,%eax
	FRAME_END
	pax_ret __get_user_8
#else
	add $7,%_ASM_AX
	jc bad_get_user_8
	mov PER_CPU_VAR(current_task), %_ASM_DX
	cmp TASK_addr_limit(%_ASM_DX),%_ASM_AX
	jae bad_get_user_8
	ASM_USER_ACCESS_BEGIN
4:	__copyuser_seg movl -7(%_ASM_AX),%edx
5:	__copyuser_seg movl -3(%_ASM_AX),%ecx
	ASM_USER_ACCESS_END
	xor %eax,%eax
	FRAME_END
	pax_ret __get_user_8
#endif
ENDPROC(__get_user_8)
EXPORT_SYMBOL(__get_user_8)


bad_get_user_ex:
	ASM_USER_ACCESS_END
bad_get_user:
	xor %edx,%edx
	mov $(-EFAULT),%_ASM_AX
	FRAME_END
	pax_ret __get_user_bad
END(bad_get_user)

#ifdef CONFIG_X86_32
bad_get_user_ex_8:
	ASM_USER_ACCESS_END
bad_get_user_8:
	xor %edx,%edx
	xor %ecx,%ecx
	mov $(-EFAULT),%_ASM_AX
	FRAME_END
	pax_ret __get_user_bad
END(bad_get_user_8)
#endif

	_ASM_EXTABLE(1b,bad_get_user_ex)
	_ASM_EXTABLE(2b,bad_get_user_ex)
	_ASM_EXTABLE(3b,bad_get_user_ex)
#ifdef CONFIG_X86_64
	_ASM_EXTABLE(4b,bad_get_user_ex)
#else
	_ASM_EXTABLE(4b,bad_get_user_ex_8)
	_ASM_EXTABLE(5b,bad_get_user_ex_8)
#endif
