#include <stdio.h>
#include <string.h>

int argvDumb(
	char *src,
	char *dst,
	int  n,
	char **endstr) /* optional out: pointer to the null-terminator of output */
{
	char *cap = dst + n - 1; /* for bounds check */
	char *anchor = src; /* first byte in src that hasn't been written to dst yet */
	int terminate = 0; /* flag: whether \0 has been encountered */
	int count;
	
	*dst++ = '\"';
	for (;;) {
		count = 0;
		while (*src == '\\') { count++; src++; }
		/* if this sequence of 0 or more backslashes is followed by a quote
		.. or a null, emit source characters followed by some amount of
		.. backslashes and break the loop if necessary */
		if (*src == '\"') {
			count++; /* extra backslash to escape this quote */
		} else if (*src == '\0') {
			terminate++; /* finish after this iteration */
		} else {
			src++;
			continue;
		}
		
		int toCopy = src - anchor;
		
		/* bounds check */
		if (dst + toCopy + count >= cap) return 1;
		
		memcpy(dst, anchor, toCopy);
		dst += toCopy;
		memset(dst, '\\', count);
		dst += count;
		anchor = src;
		
		src++; /* jump over whatever that if/else block found */
		if (terminate) break;
	}
	
	/* because of the -2 in cap's initial value, there will be room for these */
	*dst++ = '\"';
	*dst = '\0';
	if (endstr != NULL) *endstr = dst;
	return 0;
}

void main() {
	char src[] = "\"trailing and\\ in\"\"ternal\\\\\\\" quote\\\\\"";
	char dst[70];
	char example[] = "\"\\\"trailing and\\ in\\\"\\\"ternal\\\\\\\\\\\\\\\" quote\\\\\\\\\\\"\"";
	char *end;
	memset(dst, 'x', 70);
	dst[69] = '\0';
	int n1 = 51;
	if (argvDumb(src, dst, n1, &end)) {
		puts("not enough");
	}
	puts(src);
	puts(dst);
	puts(example);
	if (end == NULL || *end != '\0') puts("*end does not point to \\0");
}
