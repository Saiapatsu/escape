#include <stdio.h>

int argvDumb(
	char *in,
	char *out,
	int  len,
	char **endstr, /* optional out: pointer to the null-terminator of output */
	int  *state) /* optional in/out: function state for continuing after running out of space in output buffer */
{
	*out++ = '\"';
	for (;;) {
		if (*in == '\\') {
			/* count and pass backslashes */
			*out++ = '\\';
			int count = 1;
			while (*++in == '\\') {
				*out++ = '\\';
				count++;
			}
			if (*in == '\"') {
				/* escape quote and all slashes */
				count++;
				while (count--) *out++ = '\\';
			} else if (*in == '\0') {
				/* same, as the output string will be capped with a quote anyway */
				count++;
				while (count--) *out++ = '\\';
				break;
			}
			/* else backslashes were not followed by anything special and were copied as-is */
			
		} else if (*in == '\"') {
			/* stray quote */
			*out++ = '\\';
			
		} else if (*in == '\0') {
			/* end of input string */
			break;
		}
		
		*out = *in;
		in++;
		out++;
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
