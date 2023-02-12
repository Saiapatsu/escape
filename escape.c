#include <stdio.h>
#include <string.h>

int argvDumb(
	char *src,
	char *dst,
	int  n,
	char **endstr, /* optional out: pointer to the null-terminator of output */
	int  *state) /* optional in/out: state to resume from */
{
	char *cap = dst + n; /* first byte after end of dst, cannot write here */
	char *anchor = src; /* first byte in src that hasn't been written to dst yet */
	int terminate = 0; /* flag: whether \0 has been encountered */
	*dst++ = '\"';
	for (;;) {
		int count = 0;
		int toCopy;
		while (*src == '\\') { count++; src++; }
		/* if this sequence of 0 or more backslashes is followed by a quote
		.. or a null, emit source characters followed by some amount of
		.. backslashes and break the loop if necessary */
		if (*src == '\"') {
			count++; /* throw in an extra backslash to escape this quote */
		} else if (*src == '\0') {
			terminate++; /* finish after this iteration */
		} else {
			src++;
			continue;
		}
		toCopy = src - anchor;
		if (dst + toCopy >= cap) {
			return 1;
		}
		memcpy(dst, anchor, toCopy); dst += toCopy; anchor = src;
		if (dst + count >= cap) {
			return 1;
		}
		memset(dst, '\\', count); dst += count;
		src++;
		if (terminate) break;
	}
	if (cap - dst < 2) {
		return 1;
	}
	*dst++ = '\"';
	*dst = '\0';
	if (endstr != NULL) *endstr = dst;
	
	return 0;
}

void main() {
	char inBuf[] = "\"trailing and\\ in\"\"ternal\\\\\\\" quote\\\\\"";
	char outBuf[100];
	char *src = inBuf;
	char *dst = outBuf;
	char *end;
	int state;
	if (argvDumb(src, dst, 51, &end, &state)) {
		puts("not enough");
		return;
	}
	puts(inBuf);
	puts(outBuf);
	puts("\"\\\"trailing and\\ in\\\"\\\"ternal\\\\\\\\\\\\\\\" quote\\\\\\\\\\\"\"");
	if (end == NULL || *end != '\0') puts("*end does not point to \\0");
}
