#include <stdio.h>

int argvDumb(
	char *in,
	char *out,
	int  len,
	char **endstr, /* optional out: pointer to the null-terminator of output */
	int  *state) /* optional in/out: function state for continuing after running out of space in output buffer */
{
	char *start = in;
	*out++ = '\"';
	for (;;) {
		if (*in == '\\') {
			int count = 1;
			while (*++in == '\\') count++;
			if (*in == '\"') {
				/* escape slashes and quote */
				count++;
				while (start != in) *out++ = *start++;
				while (count--) *out++ = '\\';
			} else if (*in == '\0') {
				/* escape slashes */
				while (start != in) *out++ = *start++;
				while (count--) *out++ = '\\';
				break;
			}
			/* else backslashes were literal */
			
		} else if (*in == '\"') {
			/* stray quote */
			while (start != in) *out++ = *start++;
			*out++ = '\\';
			
		} else if (*in == '\0') {
			/* end of input string */
			while (start != in) *out++ = *start++;
			break;
		}
		in++;
	}
	*out++ = '\"';
	*out = '\0';
	
	return 0;
}

void main() {
	char inBuf[] = "trailing and\\ in\"ternal\\\\\\\" quote\\\\\"";
	char outBuf[100];
	char *in = inBuf;
	char *out = outBuf;
	argvDumb(in, out, 100, NULL, NULL);
	puts(inBuf);
	puts(outBuf);
	puts("\"trailing and\\ in\\\"ternal\\\\\\\\\\\\\\\" quote\\\\\\\\\\\"\"");
}
