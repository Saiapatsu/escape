#include <stdio.h>
#include <time.h>
#include <string.h>

/* todo: return amount of bytes written like strftime? */

int argvDumb(
	char *src,
	char *dst,
	int  n,
	char **endstr) /* optional out: pointer to the null-terminator of output */
{
	char *cap = dst + n - 1; /* for bounds check */
	char *anchor = src; /* first byte in src that hasn't been written to dst yet */
	int terminate = 0; /* flag: whether \0 has been encountered */
	
	*dst++ = '\"';
	for (;;) {
		int count = 0;
		int toCopy;
		
		while (*src != '\\' && *src != '\"' && *src != '\0') src++;
		while (*src == '\\') { count++; src++; }
		
		/* if this sequence of 0 or more backslashes is followed by a quote
		.. or a null, emit source characters followed by some amount of
		.. backslashes and break the loop if necessary */
		if (*src == '\"') {
			count++; /* insert extra backslash to escape this quote */
		} else if (*src == '\0') {
			terminate++; /* finish after this iteration */
		} else {
			/* at least one backslash not followed by any of the above */
			src++;
			continue;
		}
		
		toCopy = src - anchor;
		anchor = src;
		src++; /* jump over whatever that if/else block found */
		
		/* bounds check */
		if (dst + toCopy + count >= cap) return -1;
		
		memcpy(dst, anchor, toCopy);
		dst += toCopy;
		memset(dst, '\\', count);
		dst += count;
		
		if (terminate) break;
	}
	
	/* because of the -2 in cap's initial value, there will be room for these */
	*dst++ = '\"';
	*dst = '\0';
	if (endstr != NULL) *endstr = dst;
	return 0;
}

int cmdDumb(
	char *src,
	char *dst,
	int  n,
	char **endstr) /* optional out: pointer to the null-terminator of output */
{
	for (;*src;) {
		switch (*src) {
		case '\t':
		case '\r':
		case '\n':
			*dst++ = ' ';
			break;
		case '(':
		case ')':
		case '<':
		case '>':
		case '&':
		case '|':
		case '^':
		case '"':
		case '%':
		case '!':
			*dst++ = '^';
			/* fallthrough */
		default:
			*dst++ = *src;
		}
		src++;
	}
	*dst = '\0';
	if (endstr != NULL) *endstr = dst;
	return 0;
}

/* gcc escape.c -o cescape.exe -std=c99 -Wall -Wextra && cescape */
int main() {
	// char src[] = "\"trailing and\\ in\"\"ternal\\\\\\\" quote\\\\\"";
	char src[] = "trailing and\\ internal\\\\\\\" quote\\\\\"";
	char dst[70];
	// char example[] = "\"\\\"trailing and\\ in\\\"\\\"ternal\\\\\\\\\\\\\\\" quote\\\\\\\\\\\"\"";
	char example[] = "trailing and\\ internal\\\\\\^\" quote\\\\^\"";
	char *end;
	memset(dst, 'x', 70);
	dst[69] = '\0';
	int n1 = 51;
	
	int iterations = 1;
	clock_t start_time = clock();
	for (int i = 0; i < iterations; i++) {
		cmdDumb(src, dst, n1, &end);
	}
	double elapsed_time = (double)(clock() - start_time) / CLOCKS_PER_SEC;
	printf("Done %d iters in %f seconds\n", iterations, elapsed_time);
	
	puts(src);
	puts(dst);
	puts(example);
	if (end == NULL || *end != '\0') puts("*end does not point to \\0");
	return 0;
}
