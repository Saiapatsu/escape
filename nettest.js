/*
JScript .NET is used to test the JavaScript implementation
because it is unfathomably silly and goofy and does not require a browser!
Node or standalone V8 (is that a thing?) is far better, but I already have jsc.
Compile with jsc:
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\jsc.exe nettest.js
Pipe tests.txt to this script:
nettest.exe < tests.txt
*/

import System; // Console
import System.IO; // File

// eval will return the completion value of the last statement.
// This was done because recompiling the script every time escape.js is
// changed feels dumb when there's eval. Eval fits well in this ditzy script.
// In addition, I couldn't figure out (nor could bother to research)
// how to ensure that the stuff in escape.js ends up in the global scope.
// Maybe escape.js is running after test.js? It isn't.
// Nor did I want to pollute escape.js with JScript stuff.
const methods = eval(File.ReadAllText("escape.js")
	+ ';['
		+ '["unparse", unparse]'
	+ '];'
);

var count = 0;
var failures = 0;

while (1) {
	const test = Console.ReadLine();
	if (!test) break;
	// ECMAScript 3 does not have Array.forEach
	for (var i = 0; i < methods.length; i++) {
		count++;
		const pair = methods[i], name = pair[0], method = pair[1];
		const expected = Console.ReadLine();
		const result = method(test);
		if (result !== expected) {
			Console.WriteLine("Failed " + name);
			Console.WriteLine("Test: " + test);
			Console.WriteLine("Expected: " + expected);
			Console.WriteLine("Result: " + result);
			Console.WriteLine();
			failures++;
		}
	}
	// skip cruft
	while (Console.ReadLine());
}

Console.WriteLine(count + " tests, " + failures + " failed");
