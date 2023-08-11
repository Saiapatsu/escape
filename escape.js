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
	var qpos = str.indexOf('"');
	if (qpos == -1)
		return cmdescape(str);
	var quoted = true;
	var last = 0, len = str.length - qpos;
	return cmdescape(str.slice(0, qpos)) + str.slice(qpos).replace(/"([^"]*)/g, function(match, section) {
		last += match.length;
		if (quoted === false) {
			quoted = !quoted;
			return '"' + cmdescape(section);
		} else if (last === len || /[!%]/.test(section)) {
			return '^"' + cmdescape(section);
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

// escape HTML text and attributes
var escapesHtml = {
	'"': "&quot;",
	"'": "&apos;",
	"&": "&amp;",
	"<": "&lt;",
	">": "&gt;",
};
function escapeHtmlText(str) {
	return str.replace(/[&<>]/g, function(x) {return escapesHtml[x]});
}
function escapeHtmlAttr(str) {
	return str.replace(/['"&<>]/g, function(x) {return escapesHtml[x]});
}
// snippet 3B292732384D522A6262742D47617560
