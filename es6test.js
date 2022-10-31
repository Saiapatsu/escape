/*
Javascript escape function tester.
Requires an interactive environment with ES6, such as a browser console.
Execute escape.js, then replace all \ with \\ in tests.txt, then paste the contents of tests.txt between the `` and run this script.
*/

((tests)=>{
const methods = [
	["unparse", unparse],
	["unparseDumb", unparseDumb],
	["argv", escapeArgv],
	["argvDumb", escapeArgvDumb],
	["cmd", escapeCmd],
	["cmdDumb", escapeCmdDumb],
]
var count = 0, failures = 0;
tests.trim().split("\n\n").map(x => x.split("\n")).forEach(lines => {
	const test = lines[0];
	methods.forEach(([name, method], index) => {
		count++;
		const expected = lines[index + 1];
		const result = method(test);
		if (result !== expected) {
			console.log("Failed " + name);
			console.log("Test: " + test);
			console.log("Expected: " + expected);
			console.log("Result: " + result);
			console.log();
			failures++;
		}
	});
});
console.log(count + " tests, " + failures + " failed")
})(``);