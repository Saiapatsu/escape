#include <stdio.h>

void main() {
	char inBuf[] = "trailing and\\ internal\\\\\\\" quote\\\\\"";
	char outBuf[100];
	char *in = inBuf;
	char *out = outBuf;
	for (;;) {
		switch(*in) {
		case '\0':
			/* end of input string */
			*out = '\0';
			goto finish;
		case '\\':
			/* sequences of backslashes followed by quotes must all be escaped */
			in++;
			for (int count = 1; ; count++) {
				if (*in == '\\') {
					/* more backslashes, keep going */
					in++;
				} else if (*in == '\"') {
					/* quote after a sequence of backslashes, escape everything */
					while (count) {
						*out++ = '\\';
						*out++ = '\\';
						count--;
						// putchar('c');
					}
					*out++ = '\\';
					*out = '\"';
					break;
				} else {
					/* regular character, all of these backslashes were literal actually */
					while (count) {
						*out++ = '\\';
						count--;
					}
					*out = *in;
					break;
				}
				// putchar('b');
			}
			break;
		case '\"':
			/* quotes must be escaped */
			*out++ = '\\';
			/* gratuitous fallthrough */
		default:
			*out = *in;
			break;
		}
		in++;
		out++;
		// putchar('a');
	}
	finish:
	puts(inBuf);
	puts(outBuf);
}
