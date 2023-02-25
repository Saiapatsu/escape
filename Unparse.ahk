#Requires AutoHotkey v2

global Unparse := UnparseDumb
global EscapeArgv := EscapeArgvDumb
global EscapeCmd := EscapeCmdDumb

UnparseDumb(str)
{
	return '^"' RegExReplace(RegExReplace(RegExReplace(RegExReplace(str
		, '(\\*)"', '$1$1\"')
		, '\\*$', '$0$0"')
		, '[`t`r`n]+', " ")
		, '[()<>&|^"%!]', "^$0")
}

EscapeArgvDumb(str)
{
	return '^"' RegExReplace(RegExReplace(str
		, '(\\*)"', '$1$1\"')
		, '\\*$', '$0$0"')
}

EscapeCmdDumb(str)
{
	return RegExReplace(RegExReplace(str
		, '[`t`r`n]+', " ")
		, '[()<>&|^"%!]', "^$0")
}

EscapeFilename(str)
{
	str := StrReplace(str, "_", "__")
	str := StrReplace(str, "<", "_{")
	str := StrReplace(str, ">", "_}")
	str := StrReplace(str, ":", "_.")
	str := StrReplace(str, '"', "_'")
	str := StrReplace(str, "/", "_[")
	str := StrReplace(str, "\", "_]")
	str := StrReplace(str, "|", "_I")
	str := StrReplace(str, "?", "_!")
	return StrReplace(str, "*", "_#")
} ; from screenshot.ahk
