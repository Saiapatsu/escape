#include <stdio.h>

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
	*out++ = '\"';
	for (;;) {
		count = 0;
		while (*in == '\\') { count++; in++; }
		if (*in == '\"') {
			count++;
		} else if (*in == '\0') {
			terminate = 1;
		} else {
			in++;
			continue;
		}
		while (start != in) *out++ = *start++;
		while (count) { *out++ = '\\'; count--; }
		in++;
		if (terminate) break;
	}
	*out++ = '\"';
	*out = '\0';
	
	return 0;
}

void main() {
	char inBuf[] = "\"trailing and\\ in\"\"ternal\\\\\\\" quote\\\\\"";
	char outBuf[100];
	char *in = inBuf;
	char *out = outBuf;
	argvDumb(in, out, 100, NULL, NULL);
	puts(inBuf);
	puts(outBuf);
	puts("\"\\\"trailing and\\ in\\\"\\\"ternal\\\\\\\\\\\\\\\" quote\\\\\\\\\\\"\"");
}
