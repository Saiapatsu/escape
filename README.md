# escape

Routines for escaping command line arguments on Windows.

* `init.lua` is the primary file.
* `escape.js` contains spartan Javascript ports for each function in `init.lua`, except for `filename()`.

The functions attempt to minimize the amount of characters used to escape the string.  
The dumb variants of each function are less complicated and will not check the contents of the string, even if doing so escapes redundantly/overly cautiously.

For example, `cmd` will take it easy within quotes and `argv` will not quote the string if it contains no whitespace.  
Conversely, `argvDumb` will always surround the string in quotes and `cmdDumb` will attach a caret to every special character (as recommended in "*Everyone quotes command line arguments the wrong way*"), even though quotes suppress cmd.exe's behavior to some extent.

"cmd", "cmd.exe" and "shell" are used interchangeably in this code and documentation.

## Usage

### unparse
If your string is an argument to a program executed through the
shell, such as with `system`, `popen`, `ShellExecute` or similar
and the program splits its command line using `CommandLineToArgv`
or `parse_cmdline`, implicitly or explicitly, then use `unparse`.
This quotes the string and escapes quotes and shell characters.

Example of a script that uses `unparse`:
```lua
local unparse = require "escape".unparse
local script, inpath = unpack(args)
local magick = io.popen(table.concat({
	"magick",
	unparse(inpath),
	"-depth 8",
	"RGBA:-",
}, " "), "rb")
local str = magick:read("*a")
magick:close()
print(#str)
```

### argv
If your string is an argument to a program executed through
`CreateProcess` or similar that don't do shelly things and the
program splits its command line using `CommandLineToArgv` or
`parse_cmdline`, implicitly or explicitly, then use `argv`.
This escapes quotes, then surrounds the string in quotes.

### redirect
If your string is a shell redirection target, then use `redirect`.
This escapes shell characters and quotes the string.

Also prefer this undocumented cmd syntax which prevents a number
from being placed to the left of a `>`:
```
>"foo bar" echo 123456
```
This command will echo `123456` to the file `foo bar`, whereas:
```
echo 123456>"foo bar"
```
... attempts to redirect the 6th standard stream to a file.  
You only need to do this for programs that do not split arguments
or otherwise aren't sensitive to a space before the `<`, which is
another way to prevent this from happening.

### cmd
If your string is an argument to a program that does not split its arguments (uses `GetCommandLine` instead of `argv[]`) being executed through the shell, such as `set`, `echo` etc., then use `cmd`.
This only escapes shell characters.

### Nothing
If your string will pass through `CreateProcess` to a program that
doesn't split its arguments, then your string does not need to be
escaped.

## License

These functions and this README are distributed under the terms of the MIT License.

I feel that it's kind of strange to pull in an entire license with any of these one-liners, though. Well, what can you do.

The MIT License does not require you to provide public/user-facing
attribution.

## Credits

### 2021-09-15
*Everyone quotes command line arguments the wrong way*, from *Twisty Little Passages, All Alike*
https://docs.microsoft.com/en-us/archive/blogs/twistylittlepassagesallalike/everyone-quotes-command-line-arguments-the-wrong-way

These articles focus on the two functions that split a command line into argv.  
The website is down as of 2022-07-18, but the value in there was mostly in the illustrations.  
http://www.windowsinspired.com/understanding-the-command-line-string-and-arguments-received-by-a-windows-program/  
http://www.windowsinspired.com/how-a-windows-programs-splits-its-command-line-into-individual-arguments/

### 2022-08-07
https://ss64.com/nt/syntax-redirection.html
