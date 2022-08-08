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

/*
Javascript ports of some of the functions in init.lua.
Please read init.lua for info and documentation.

Not copying over the comments is irresponsible, but these are just
ports and not having to fix up the comments in every single port
when I feel like slightly adjusting them is not my cup of tea.
*/

function unparse(str) {
	return escapeCmd(escapeArgv(str));
}

function unparseDumb(str) {
	return '^"' + str.replace(/(\\*)"/g, '$1$1\\"').replace(/\\*$/, '$&$&"')
		.replace(/[\t\r\n]+/g, " ").replace(/[()<>&|^"%!]/g, "^$&");
}

function escapeArgv(str) {
	return /[ \t\r\n]/.test(str)
		? '"' + str.replace(/(\\*)"/g, '$1$1\\"').replace(/\\*$/, '$&$&"')
		: str.replace(/(\\*)"/g, '$1$1\\"');
}

function escapeArgvDumb(str) {
	return '"' + str.replace(/(\\*)"/g, '$1$1\\"').replace(/\\*$/, '$&$&"');
}

function escapeCmd(str) {
	function cmdescape(str) {
		return str.replace(/[()<>&|^"%!]/g, "^$&");
	}
	str = str.replace(/[\t\r\n]+/g, " ");
	let quoted = false;
	let last = 0, len = str.length;
	return str.replace(/("|^)([^"]*)/g, (match, quote, section) => {
		last += match.length;
		if (quoted === false) {
			quoted = !quoted;
			return '"' + cmdescape(section);
		} else if (last === len || /[!%]/.test(section)) {
			return '^"' + quote + cmdescape(section);
		} else {
			quoted = !quoted;
			return match;
		}
	});
}

function escapeCmdDumb(str) {
	return str.replace(/[\t\r\n]+/g, " ").replace(/[()<>&|^!%"]/g, "^$&");
}
