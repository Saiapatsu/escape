#include <stdio.h>

void main() {
	char inBuf[] = "trailing and\\ in\"ternal\\\\\\\" quote\\\\\"";
	char outBuf[100];
	char *in = inBuf;
	char *out = outBuf;
	for (;;) {
		if (*in == '\\') {
			in++;
			for (int count = 1; ; count++) {
				if (*in == '\\') {
					/* more backslashes */
					in++;
				} else if (*in == '\"') {
					/* sequence of backslashes followed by quote, escape everything */
					while (count) {
						*out++ = '\\';
						*out++ = '\\';
						count--;
					}
					*out++ = '\\';
					break;
				} else {
					/* sequence of backslashes not followed by quote, the backslashes were literal */
					while (count) {
						*out++ = '\\';
						count--;
					}
					break;
				}
			}
			
		} else if (*in == '\"') {
			/* stray quote */
			*out++ = '\\';
			
		} else if (*in == '\0') {
			/* end of input string */
			*out = '\0';
			break;
		}
		/* else do nothing noteworthy other than the following */
		*out = *in;
		in++;
		out++;
	}
	
	puts(inBuf);
	puts(outBuf);
}
