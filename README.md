# escape

Routines for escaping command line arguments on Windows.

**At the moment, cmd() (and thus, unparse()) is broken in JavaScript, prefer cmdDumb**

* `init.lua` is the primary file.
* `escape.js` contains spartan Javascript ports for each function in `init.lua`, except for `filename()`.

The functions attempt to minimize the amount of characters used to escape the string.  
The dumb variants of each function are less complicated and will not check the contents of the string, even if doing so escapes redundantly/overly cautiously.

For example, `cmd` will take it easy within quotes and `argv` will not quote the string if it contains no whitespace.  
Conversely, `argvDumb` will always surround the string in quotes and `cmdDumb` will attach a caret to every special character (as recommended in "*Everyone quotes command line arguments the wrong way*"), even though quotes suppress the shell's behavior to some extent.

## Usage

### unparse
If your string is an argument to a program executed through the
shell, such as with `system`, `popen`, `ShellExecute` or similar
and the program splits its command line using `CommandLineToArgv`
or `parse_cmdline`, implicitly or explicitly, then use `unparse`.  
This argv-escapes and then shell-escapes the string, read how that happens below.

### argv
If your string is an argument to a program executed through
`CreateProcess` or similar that don't do shelly things and the
program splits its command line using `CommandLineToArgv` or
`parse_cmdline`, implicitly or explicitly, then use `argv`.  
This escapes quotes, then surrounds the string in quotes.

### redirect
If your string is a shell redirection target filename, then use `redirect`.  
This escapes shell characters and spaces.

`redirect` trusts that your string is already a valid NTFS file path.
It does not sanitize filenames, you are responsible for doing that.

### cmd
If your string is an argument to a program that does not split its arguments (uses `GetCommandLine` instead of `argv[]`) being executed through the shell, such as `set`, `echo` etc., then use `cmd`.  
This only escapes shell characters.

`cmd` also turns tabs, carriage returns and line feeds into spaces in an attempt to make the string safe to paste into a command prompt.  
That's not a good idea, but they get lost in transit in other ways most of the time, anyway.

### Nothing
If your string will pass through `CreateProcess` to a program that
doesn't split its arguments, then your string does not need to be
escaped.

### Delayed expansion
If delayed expansion is enabled in the shell for whatever reason, then use `delayed` on strings immediately before shell-escaping.  
This will shell-escape exclamation points. The caret and exclamation point get shell-escaped a second time.

Escaping delayed 

### Pipes

Pipes spawn extra shells which parse the two halves of the command line at least one more time.
(todo: elaborate)

## Warning about redirection

A numeral before a `>` or `>>` specifies which IO stream the shell will redirect. A numeral may be unintentionally placed before a `>`:
```
echo 123456>numbers
```
This command will execute `echo 12345` and pipe the 6th io stream to `numbers`.

There are three ways to mitigate this:
* put a space before `>`;
```
echo 123456 >numbers
```
* escape the numeral with a caret;
```
echo 12345^6>numbers
```
* move the redirection to the left of the command.
```
>numbers echo 123456
```

The first option adds a trailing space to the command line, which `argv`-using/command line-splitting programs safely ignore. `echo`, `set` etc. are sensitive to this space, however.

`escape` has no function for the second option.

The third option is undocumented and bizarre syntax, but works for any command.

## Other

The separation between `cmd` and `argv` seems to be a uniquely Windows thing and these methods aren't really applicable to Linux.  
On Windows, the shell is responsible for splitting commands on `&`, `>` etc. and passing entire command line strings, which then split it on space characters independently, but can choose to just use `GetCommandLine` and use it as-is or split it in another way (a horrible idea).  
On the other hand, it is not possible to get the un-split command line in Linux and "gluing it back together" loses some information about spaces.  
You can't know what the shell saw neither in Linux nor in Windows.

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
