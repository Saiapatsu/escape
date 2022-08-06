/*
MIT License

Copyright (c) 2022 twiswist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Javascript ports of some of the functions in init.lua

// Fortify str against CommandLineToArgv or parse_cmdline.
// Only use this if the application splits its command line into argv using
// these functions. Notoriously, echo does not do that.
function escapeArgv(str) {
	return / \t\r\n/.test(str)
		? '"' + str.replace(/(\\*)"/g, '$1$1\\"').replace(/\\*$/, '$&$&"')
		: str.replace(/(\\*)"/g, '$1$1\\"');
}

function escapeArgvDumb(str) {
	return '"' + str.replace(/(\\*)"/g, '$1$1\\"').replace(/\\*$/, '$&$&"');
}

// Fortify string against cmd.exe.
// Only use this if the command line passes through the shell (cmd.exe, system(), popen() of any kind etc.)
// Does not do what escape.argv does.
function escapeCmd(str) {
	function cmdescape(str) {
		return str.replace(/[()<>&|^!%"]/g, "^$&");
	}
	str = str.replace(/[\t\r\n]+/g, " ");
	let quoted = false;
	let last = 0;
	return str.replace(/(\^*"|^)([^"]*)/g, (match, quote, unquote) => {
		last += match.length; // silly workaround for the lack of lua's () in regex
		if (quote.length & 1) {
			quoted = !quoted;
		}
		if (!quoted) {
			return quote + cmdescape(unquote);
		} else if (/[!%]/.test(unquote) || last == str.length) {
			quoted = !quoted;
			return "^" + quote + cmdescape(unquote);
		} else {
			return quote + unquote;
		}
	});
}

function escapeCmdDumb(str) {
	return str.replace(/[\t\r\n]+/g, " ").replace(/[()<>&|^!%"]/g, "^$&");
}

// Fortify str against Windows cmd followed by CommandLineToArgvW.
function unparse(str) {
	return escapeCmd(escapeArgv(str));
}
