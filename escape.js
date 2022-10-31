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
	var quoted = false;
	var last = 0, len = str.length;
	return str.replace(/("|^)([^"]*)/g, function(match, quote, section) {
		last += match.length;
		if (quoted === false) {
			quoted = !quoted;
			return quote + cmdescape(section);
		} else if (last === len || /[!%]/.test(section)) {
			return '^' + quote + cmdescape(section);
		} else {
			quoted = !quoted;
			return match;
		}
	});
}

function escapeCmdDumb(str) {
	return str.replace(/[\t\r\n]+/g, " ").replace(/[()<>&|^!%"]/g, "^$&");
}

function escapeRedirect(str) {
	return '"' + str.replace(/%/g, "%%") + '"';
}

function escapeDelayed(str) {
	return str.replace(/!/g, "^!");
}
