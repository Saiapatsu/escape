/*
Javascript escape function tester
Execute escape.js in a browser's console, then paste tests.txt between the `` and run this script.
*/

((tests)=>{
const methods = [
	["unparse", unparse],
]
var count = 0, failures = 0;
tests.split("\n\n").map(x => x.split("\n")).forEach(lines => {
	const test = lines[0];
	count++;
	methods.forEach(([name, method], index) => {
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