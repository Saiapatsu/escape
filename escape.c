#include <stdio.h>
#include <string.h>

int argvDumb(
	char *in,
	char *out,
	int  len,
	char **endstr, /* optional out: pointer to the null-terminator of output */
	int  *state) /* optional in/out: function state for continuing after running out of space in output buffer */
{
	char *start = in;
	int count;
	int terminate = 0;
	int toCopy;
	char *end = out + len; /* todo fix these names */
	*out++ = '\"';
	for (;;) {
		count = 0;
		while (*in == '\\') { count++; in++; }
		if (*in == '\"') {
			count++;
		} else if (*in == '\0') {
			terminate++;
		} else {
			in++;
			continue;
		}
		toCopy = in - start;
		if (out + toCopy >= end) {
			return 1;
		}
		memcpy(out, start, toCopy); out += toCopy; start = in;
		if (out + count >= end) {
			return 1;
		}
		memset(out, '\\', count); out += count;
		in++;
		if (terminate) break;
	}
	if (end - out < 2) {
		return 1;
	}
	*out++ = '\"';
	*out = '\0';
	if (endstr != NULL) *endstr = out;
	
	return 0;
}

void main() {
	char inBuf[] = "\"trailing and\\ in\"\"ternal\\\\\\\" quote\\\\\"";
	char outBuf[100];
	char *in = inBuf;
	char *out = outBuf;
	char *end;
	int state;
	// argvDumb(in, out, 100, &end, &state);
	if (argvDumb(in, out, 51, &end, &state)) {
		puts("not enough");
		return;
	}
	puts(inBuf);
	puts(outBuf);
	puts("\"\\\"trailing and\\ in\\\"\\\"ternal\\\\\\\\\\\\\\\" quote\\\\\\\\\\\"\"");
	if (end == NULL || *end != '\0') puts("*end does not point to \\0");
}
