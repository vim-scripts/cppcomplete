" This plugin helps you complete things like:
" variableName.abc
" variableName->abc
" typeName::abc
" from the members of the struct/class/union that starts with abc.
" Also completion of the other names in the browser file is supported.
"
" The default key mapping to complete the code are:
" Alt+l in insert mode will try to find the possible completions and display
" them in a popup menu. Also normal completions to the names in
" cppcomplete.tags.
" Alt+j in insert mode will show the popup menu with the last results.
" Selecting one of the  items will paste the text.
" F8/F9 will work in a similar way as Ctrl+N, Ctrl+P in unextended vim.
" F5 will lookup the class and display it in a preview window
" 
" The plugin is depending on that exuberant ctags has generated some tags with
" the same options as in the following example:
" ctags -n -f cppcomplete.tags --fields=+ai --C++-types=+p *
" The script has a command called GenerateTags that executes the above ctags
" command. The tag file cppcomplete.tags is local to the script so you can
" use other tag files without affecting cppcomplete. 
" Java users do not need the --C++-types flag.
"
" For C/C++ can the script generate the cppcomplete.tags from the included
" files for you. This is based on vims checkpath function. The path must be
" set correct, see the vim documentation.
"
" This script do not requires grep anymore but it is supported. If the first
" completion takes a very long time may grep speed things up. The recommended setup
" is a combination of grep and vims search function. For Windows does the DJGPP
" port of grep works. You only need grep.exe from the grep'version'b.zip file.
" A good place for grep.exe could be the compilers bin directory.
" The zip file is in the v2gnu directory, it can be downloaded from here:
" http://www.delorie.com/djgpp/getting.html
"
" It is possible to define a set of lines from cppcomplete.tags with regular
" expressions. I call the set for a block. The functions for this:
" BuildBlockFromRegexp the command to build the block, see below.
" NextInBlock jump to the line described in the block, can be called by Shift+F8 
" PrevInBlock same as the above but in the other direction, use Shift+F9
" EchoBlock shows the block itself
" BuildMenuFromBlock builds a menu in GUI mode from the block
" The jumps are done with an internal function so the tag stack will not be
" affected.
"
" Some simple examples there > is the prompt:
" >class:l
" Gives a block with all members that has a scope of a class beginning with l
" >^a.*\ts\t
" all structures beginning with an a
" >^\(a\|b\|c)
" Everything that starts with a,b or c
" The full vim history mechanism can be used.
"
" The script has a number of variables that can be set from the menu in the 
" GUI version. They are at the top of the script file with descriptions if
" you want to change them more permanent.
"
" For Java do you probably want to generate a cppcomplete.tags file from the
" sources of the Java SDK. The use is like with C/C++ but you will get a
" better result if you change some of the configuration variables.
" The default access is treated as if it was public. It is strongly
" recommended that have s:neverUseGrep set to 0 and a working grep program
" otherwise will the first completion take a very long time.
"
" If you are new to vim and have not heard about ctags, regexp, grep are they
" all described in the online documentation. Just type :help followed by the word you
" want more information about. They are excellent tools that can be used for
" many things.
 

" BUGS/Features
" This plugin does not really understand any C/C++ code so it will just use gd/gD
" combined with lookups in the tag file together with some simple rules trying to 
" get the class name. It is not a real parser.
" It works surprisingly well but can of course give a surprising result. :)
" The current scope is unknown.
" Multidimensional arrays should not have a space between ][, eg.
" xyz[1][2].abc should be OK but not xyz[1] [2].abc
" The script does not accept functions, eg. xyc()->abc will not be completed
" The first time a completion is done is the script setting up some internal
" variables. This can be very slow if have s:neverUseGrep set to true.
" (GTK) If the mouse leaves and then reenters the popup menu is the text cursor affected.
" (GTK) The popup is displayed at the mouse position and not the text cursor position.
" For internal use is register c used.
" Requires exuberant ctags.
" The only tested platforms are GTK (linux) and Windows.
" + probably a lot of other issues
"
" Anyway, I have done some testing with MFC, DX9 framework (not COM), Java SDK, STL with
" good results.


" Here is the configuration variables.
"
" The following two options only applies to Windows.
" This is the only tested grep program under windows and the only one that
" works with command.com. If grep is used depends on s:useBuffer and
" s:neverUseGrep.
let s:useDJGPP=has("win32") || has("win16") || has("dos16") || has("dos32")

" This is the only way to get a popup menu under Windows so it should always
" be set if you are running under Windows.
let s:useWinMenu=has("gui_running") && has("gui_win32")
	
" The rest is platform independent.
" Use an internal buffer instead of grep?
" This should be the fastest option but in some cases is it much faster to use
" grep. See s:neverUseGrep below.
let s:useBuffer=1

" Using an internal buffer probably makes the searches faster but building a
" variable line by line is very expensive in a vim script. The reason is that
" you do not have real variables like in C/C++ but more like names for values. 
" If you have a big cppcomplete.tags with many inherits will it be much faster
" to use grep in some cases
let s:neverUseGrep=has("win32") || has("win16") || has("dos16") || has("dos32")


" Search for typedefs?
let s:searchTDefs=1

" search for macros?
" this is not well supported
let s:searchMacros=0

" How many lines can the menu have?
" Not used under Windows.
let s:maxNMenuLines=35

" Search cppcomplete.tags for class members?
" It is _really_ recommended that this is on or the script will not know of
" classes that is members in other classes.  
let s:searchClassMembers=1

" This is similar to the above but check if xxx in xxx.abc is a class type.
" In Java is this useful but for C/C++ is xxx almost always a variable name.
let s:searchClassTags=0

" Search cppcomplete.tags for global variables?
" If they are declared in the current file should gD find them but I turned
" it on anyway. This means that global variables is found before local with
" the same name and that is of course wrong.
let s:searchGlobalVars=1

" ctags sometimes miss to set the access so the check is disabled by default.
" If you are using Java should I turn on this check because ctags does not
" miss the access for Java in the same way as for C++.
let s:accessCheck=0

" New in the 5.0 version is a little sanity for gd so it is used first by 
" default. See the vim documentation about how gd limits the search scope.
let s:onlyGD=0

" I like the preview window but the default is not to display it. 
let s:showPreview=0

" The default language is C/C++, the other option is Java.
let s:currLanguage="C/C++"

" The max size of the popup menu. Perhaps is 50 more than that is useful.
" If you set this to some big value may it take a long time before the
" script has finished.
let s:tooBig=50

" The max number of items that the popup menu will be built from.
" This is to prevent very long lists being built internally since this could
" be very slow. The best value depends on how many identical identifiers it is
" in cppcomplete.tags.
" If you are running gvim will you get a warning if the limit is reached.
let s:maxGrepHits=2*s:tooBig

" Setting this option on means that the ancestor can be anything.
" This is a good idea since the script does not know the current scope and
" ctags also treats namespaces as class scopes.
let s:relaxedParents=1

" How the grep program is invoked. The GNU grep has an --mmap option
" for faster memory mapping. This can be set from the menu.
let s:grepPrg="grep"

" Should the access information be displayed on the popup?
let s:showAccess=0

" Should :: show the whole scope with items from the ancestors?
" This does not seems to be the case in MSVC and that is probably a sensible
" way to handle it concerning the main use in class implementation. 
" The default is anyway the more correct show everything alternative.
let s:colonNoInherit=0

" Should the completions be limited to class, member, prototype, struct and
" union type?
" It is probably a bad idea to have this as an option because turning it on
" will make the script miss all members in C/C++ with an implementation 
" in the class  interface because they do not have a prototype.
let s:justInteresting=0

" Extra help.
let s:nannyMode=has("gui_running")

" Complete all identifiers from cppcomplete.tags?
" Pretty much the same is already in vim but I prefer the popup instead of
" single stepping with Ctrl-N or Ctrl-P.
let s:completeOrdinary=1

" Max recursive depth search for typedefs. This is mostly to prevent the
" script to enter an endless loop for some special cases.
let s:maxDepth=3

" Mappings
" Take them as suggestions only.
imap <F5> <ESC>:PreviewClass<CR>a
if has("gui_running")
	if (s:useWinMenu)
		imap <A-j> <ESC>:popup PopUp<CR>a
		imap <A-l> <ESC>:BuildMenu<CR>a
	else
		imap <A-l> <ESC>:BuildMenu<CR><RightMouse>a
		imap <A-j> <ESC><RightMouse>a
	endif
endif
imap <F8> <ESC>:InsNextHit<CR>a
imap <F9> <ESC>:InsPrevHit<CR>a
map <S-F9> <ESC>:PrevInBlock<CR>
map <S-F8> <ESC>:NextInBlock<CR>


" From this line should you be more careful if you change anything.
" 
" Commands 

command! -nargs=0 AppendFromCheckpath call s:AppendFromCheckpath()
command! -nargs=0 GenerateFromCheckpath call s:GenerateFromCheckpath()
command! -nargs=0 GenerateTags call s:GenerateTags()
command! -nargs=0 PreviewClass call s:PreCl()
if has("gui_running")
	command! -nargs=0 BuildMenu call s:BuildMenu()
	command! -nargs=0 DoMenu call s:DoMenu()
	command! -nargs=0 RestorePopup call s:SetStandardPopup()
	command! -nargs=0 RefreshMenu call s:RefreshMenu()
	command! -nargs=0 ClearFromTags call s:ClearFromTags()
	command! -nargs=0 InsertToTags call s:InsertToTags()
	command! -nargs=0 ToggleTDefs call s:ToggleTDefs()
	command! -nargs=0 ToggleMacros call s:ToggleMacros()
	command! -nargs=0 BrowseNFiles call s:BrowseNFiles()
	command! -nargs=0 GenerateAndAppend call s:GenerateAndAppend()
	command! -nargs=1 PreviewEntry call s:PreviewEntry(<f-args>)
	command! -nargs=0 ToggleAccess call s:ToggleAccess()
	command! -nargs=0 ToggleGD call s:ToggleGD()
	command! -nargs=0 TogglePreview call s:TogglePreview()
	command! -nargs=0 SetLanguage call s:SetLanguage()
	command! -nargs=0 ToggleRelaxed call s:ToggleRelaxed()
	command! -nargs=0 ToggleGlobalVars call s:ToggleGlobalVars()
	command! -nargs=0 ToggleClassMembers call s:ToggleClassMembers()
	command! -nargs=0 ToggleClassTags call s:ToggleClassTags()
	command! -nargs=0 ToggleRestricted call s:ToggleRestricted()
	command! -nargs=0 ToggleFastGrep call s:ToggleFastGrep()
	command! -nargs=0 ToggleShowAccess call s:ToggleShowAccess()
	command! -nargs=0 ToggleInheritance call s:ToggleInheritance()
	command! -nargs=0 ToggleNanny call s:ToggleNanny()
	command! -nargs=0 ShowCurrentSettings call s:ShowCurrentSettings()
	command! -nargs=0 SetMaxHits call s:SetMaxHits()
	command! -nargs=0 BuildMenuFromBlock call s:BuildMenuFromBlock()
endif
command! -nargs=0 InsPrevHit call s:InsPrevHit()
command! -nargs=0 InsNextHit call s:InsNextHit()

command! -nargs=0 BuildBlockFromRegexp call s:BuildBlockFromRegexp()
command! -nargs=0 NextInBlock call s:NextInBlock()
command! -nargs=0 PrevInBlock call s:PrevInBlock()
command! -nargs=0 EchoBlock call s:EchoBlock()
command! -nargs=1 JumpToLineInBlock call s:JumpToLineInBlock(<f-args>)


" some variables for internal use
let s:listAge=0
let s:bufAge=0
let s:lastHit=0
let s:hitList=""
let s:regexBlock=""
let s:nannyAsked="\n"

if has("win32") || has("win16") || has("dos16") || has("dos32")
	let s:ctagsTemp=tempname()
	let s:grepTemp=tempname()
endif

" build the gui menu
if has("gui_running")
	set mousemodel=popup
	silent! aunmenu &cppcomplete
	silent! tunmenu &cppcomplete
	amenu .100 &cppcomplete.&Preview.Scan\ for\ new\ &items<Tab>:RefreshMenu   :RefreshMenu<CR>
	tmenu .100 &cppcomplete.&Preview.Scan\ for\ new\ &items Scan cppcomplete.tags for classes, structures and unions
	amenu .200 &cppcomplete.&Preview.&Classes.*****\ \ \ Nothing\ yet\ \ \ *****   <NOP>
	amenu .300 &cppcomplete.&Preview.&Structures.*****\ \ \ Nothing\ yet\ \ \ ******   <NOP>
	amenu .400 &cppcomplete.&Preview.&Unions.*****\ \ \ Nothing\ yet\ \ \ *****   <NOP>
	amenu &cppcomplete.&Use\ generated\ tag\ file\ in\ tags.&No<TAB>:ClearFromTags   :ClearFromTags<CR>
	tmenu &cppcomplete.&Use\ generated\ tag\ file\ in\ tags.&No Do not use cppcomplete.tags as an ordinary tag file
	amenu &cppcomplete.&Use\ generated\ tag\ file\ in\ tags.&Yes<Tab>:InsertToTags   :InsertToTags<CR>
	tmenu &cppcomplete.&Use\ generated\ tag\ file\ in\ tags.&Yes Use cppcomplete.tags as an ordinary tag file
	amenu &cppcomplete.&Toggle.&Typedefs<Tab>:ToggleTDefs   :ToggleTDefs<CR>
	tmenu &cppcomplete.&Toggle.&Typedefs Toggle search for typedefs
	amenu &cppcomplete.&Toggle.&Macros<Tab>:ToggleMacros   :ToggleMacros<CR>
	tmenu &cppcomplete.&Toggle.&Macros Toggle search for macros
	amenu &cppcomplete.&Toggle.&Access\ check<Tab>:ToggleAccess  :ToggleAccess<CR>
	tmenu &cppcomplete.&Toggle.&Access\ check Should only  items with the proper access status be displayed?
	amenu &cppcomplete.&Toggle.&gd<Tab>:ToggleGD   :ToggleGD<CR>
	tmenu &cppcomplete.&Toggle.&gd Try gd before gD?
	amenu &cppcomplete.&Toggle.&Preview<Tab>:TogglePreview   :TogglePreview<CR>
	tmenu &cppcomplete.&Toggle.&Preview Open a preview window after completion?
	amenu &cppcomplete.&Toggle.&Relaxed\ ancestor\ check<Tab>:ToggleRelaxed   :ToggleRelaxed<CR>
	tmenu &cppcomplete.&Toggle.&Relaxed\ ancestor\ check Allow inner classes that may be wrong but hard to check?
	amenu &cppcomplete.&Toggle.Global\ &variables<Tab>:ToggleGlobalVars  :ToggleGlobalVars<CR>
	tmenu &cppcomplete.&Toggle.Global\ &variables Search cppcomplete.tags for global variables?
	amenu &cppcomplete.&Toggle.&Classes\ as\ class\ members<Tab>:ToggleClassMembers  :ToggleClassMembers<CR>
	tmenu &cppcomplete.&Toggle.&Classes\ as\ class\ members Complete classes that is members of other classes?
	amenu &cppcomplete.&Toggle.Class\ &names\ tags<Tab>:ToggleClassTags  :ToggleClassTags<CR>
	tmenu &cppcomplete.&Toggle.Class\ &names\ tags Search for classes that defined in other classes scop?
	amenu &cppcomplete.&Toggle.Restrict\ p&ossible\ types<Tab>:ToggleRestricted  :ToggleRestricted<CR>
	tmenu &cppcomplete.&Toggle.Restrict\ p&ossible\ types Allow only completions of certain types?
	amenu &cppcomplete.&Toggle.&Fast\ grep<Tab>:ToggleFastGrep  :ToggleFastGrep<CR>
	tmenu &cppcomplete.&Toggle.&Fast\ grep --mmap option for GNU grep
	amenu &cppcomplete.&Toggle.&Show\ access<Tab>:ToggleShowAccess  :ToggleShowAccess<CR>
	tmenu &cppcomplete.&Toggle.&Show\ access Should the popup menu also display access information?
	amenu &cppcomplete.&Toggle.&Inheritance\ for\ ::<Tab>:ToggleInheritance  :ToggleInheritance<CR>
	tmenu &cppcomplete.&Toggle.&Inheritance\ for\ :: Should :: also show inherited items?
	amenu &cppcomplete.&Toggle.&Nanny\ mode<Tab>:ToggleNanny  :ToggleNanny<CR>
	tmenu &cppcomplete.&Toggle.&Nanny\ mode Try to give some extra help.
	amenu &cppcomplete.&GenerateTags.Re&build\ from\ current\ directory<Tab>:GenerateTags   :GenerateTags<CR>
	tmenu &cppcomplete.&GenerateTags.Re&build\ from\ current\ directory Generate a new cppcomplete.tags file from the files in the current dorectory
	amenu &cppcomplete.&GenerateTags.&Append\ from\ current\ directory<Tab>:GenerateAndAppend   :GenerateAndAppend<CR>
	tmenu &cppcomplete.&GenerateTags.&Append\ from\ current\ directory Append instead of creating a totally new one.
	amenu &cppcomplete.&GenerateTags.&Browse\ file\ to\ append<Tab>:BrowseNFiles   :BrowseNFiles<CR>
	tmenu &cppcomplete.&GenerateTags.&Browse\ file\ to\ append Append a file using the file browser.
	amenu &cppcomplete.&GenerateTags.A&uto\ Generate\ a\ new\ one<Tab>:GenerateFromCheckpath   :GenerateFromCheckpath<CR>
	tmenu &cppcomplete.&GenerateTags.A&uto\ Generate\ a\ new\ one Auto generate a new cppcomplete.tags file for C/C++.
	amenu &cppcomplete.&GenerateTags.Aut&o\ Generate\ and\ append<Tab>:AppendFromCheckpath   :AppendFromCheckpath<CR>
	tmenu &cppcomplete.&GenerateTags.Aut&o\ Generate\ and\ append Auto generate and append.
	amenu &cppcomplete.S&et\ C/C++\ or\ Java<Tab>:SetLanguage   :SetLanguage<CR>
	tmenu &cppcomplete.S&et\ C/C++\ or\ Java Set the current language used.
	amenu &cppcomplete.Set\ max\ number\ of\ &hits\ displayed<Tab>:SetMaxHits   :SetMaxHits<CR>
	tmenu &cppcomplete.Set\ max\ number\ of\ &hits\ displayed How many items should the popup menu have?
	amenu &cppcomplete.&Show\ current\ settings<Tab>ShowCurrentSettings   :ShowCurrentSettings<CR>
	tmenu &cppcomplete.&Show\ current\ settings List the current settings.
	amenu &cppcomplete.-SEP1-   <NOP>
	amenu &cppcomplete.&Build\ Menu\ From\ Block<Tab>:BuildMenuFromBlock   :BuildMenuFromBlock<CR>
	tmenu &cppcomplete.&Build\ Menu\ From\ Block Build a menu from the items in the current bllock.
	amenu &cppcomplete.-SEP2-   <NOP>
	amenu &cppcomplete.&RestorePopUp<Tab>:RestorePopup :RestorePopup<CR>
	tmenu &cppcomplete.&RestorePopUp Restores the popup menu.
endif

function! s:PreCl()
	if &previewwindow		
		if has("gui_running")
			call confirm("You are not supposed to do this then you\nalready are in the Preview window.","&OK",1,"Error")
		endif
      		return
    	endif
	if ! s:CheckForTagFile()
		return
	endif
	let oldParents=s:relaxedParents
	call s:GetPieces()
	let s:relaxedParents=oldParents
	if (s:gotCType)
		call s:PreviewEntry(s:clType)
	endif
endfunction
function! s:PreviewEntry(entry)
	if &previewwindow		
		if has("gui_running")
			call confirm("You are not supposed to do this then you\nalready are in the Preview window.","&OK",1,"Error")
		endif
      		return
    	endif
	if ! s:CheckForTagFile()
		return
	endif
	if (a:entry!="")
		let tagsSav=&tags
		let &tags="cppcomplete.tags" 
		execute "ptag " . a:entry
		silent! wincmd P
		if &previewwindow
			normal! zt
			silent! wincmd p
		endif
		let &tags=tagsSav
	endif
endfunction
function! s:TogglePreview()
	let s:showPreview=!s:showPreview
endfunction
function! s:ToggleGD()
	let s:onlyGD=!s:onlyGD
	if s:onlyGD
		let cText="Cppcomplete will only use gD"
	else
		let cText="Cppcomplete will first try gd before gD"
	endif
	call confirm(cText,"&OK",1,"Info")
endfunction
function! s:ToggleAccess()
	let s:accessCheck=!s:accessCheck
	if s:accessCheck
		let cText="Access check enabled"
	else
		let cText="Access check disabled"
	endif
	call confirm(cText, "&OK",1,"Info")
endfunction
function! s:ToggleTDefs()
	let s:searchTDefs=!s:searchTDefs
	if (s:searchTDefs)
		let cText="Typedefs is now included in the search"
	else
		let cText="Further searches will not look for typedefs"
	endif
	call confirm(cText,"&OK",1,"Info")
endfunction
function! s:ToggleMacros()
	let s:searchMacros=!s:searchMacros
	if (s:searchMacros)
		let cText="Macros is now included in the search"
	else
		let cText="Further searches will not look for macros"
	endif
	call confirm(cText,"&OK",1,"Info")
endfunction
function! s:ToggleRelaxed()
	let s:relaxedParents=! s:relaxedParents
	if s:relaxedParents
		let cText="Ancestor check is now set to relaxed"
	else
		let cText="Strict ancestor check is now enabled"
	endif
	call confirm(cText, "&OK",1,"Info")
endfunction
function! s:ToggleClassMembers()
	let s:searchClassMembers=! s:searchClassMembers
	if s:searchClassMembers
		let cText="Search for classes as class members is enabled"
	elseif confirm("This is not recommended if your classes\contains other classes as members","Do it anyway\nCancel",2,"Warning")==1
		let cText="No search for classes as class members"
	else
		let s:searchClassMembers=1
		return
	endif
	call confirm(cText, "&OK",1, "Info")
endfunction
function! s:ToggleClassTags()
	let s:searchClassTags=! s:searchClassTags
	if s:searchClassTags
		let cText="Search for class names is enabled"
	else
		let cText="No search for class names"
	endif
	call confirm(cText, "&OK",1, "Info")
endfunction
function! s:ToggleRestricted()
	if (s:currLanguage!="Java") && (! s:justInteresting)
		if confirm("This is not recommended for C++ if your classes has functions with\njust implementation and no prototype.","Do it anyway\nCancel",2)!=1
			return
		endif
	endif
	let s:justInteresting=! s:justInteresting
	if s:justInteresting
		let cText="Possible completions is restricted to class, member, prototype, struct or union type"
	else
		let cText="Completions not restricted by type"
	endif
	call confirm(cText, "&OK",1, "Info")
endfunction
function! s:ToggleFastGrep()
	if (s:grepPrg=="grep")
		let s:grepPrg="grep --mmap"
		let cText="Fast GNU grep enabled"
	else
		let s:grepPrg="grep"
		let cText="Standard grep is now used"
	end
	call confirm(cText, "&OK",1, "Info")
endfunction
function! s:ToggleInheritance()
	let s:colonNoInherit=! s:colonNoInherit
	if s:colonNoInherit
		let cText=":: will not show items from the ancestors"
	else
		let cText=":: will show the whole scope with items from the ancestors"
	endif
	call confirm(cText, "&OK",1, "Info")
endfunction
function! s:ToggleNanny()
	let s:nannyMode=! s:nannyMode
	if s:nannyMode
		let cText="Nanny mode enabled"
	else
		let cText="Nanny mode disabled"
	endif
	call confirm(cText,"&OK",1,"Info")
endfunction
function! s:ToggleShowAccess()
	let s:showAccess=! s:showAccess
	if s:showAccess
		let cText="Access information will be displayed if available on the popup menu"
	else
		let cText="No access information will be displayed"
	endif
	call confirm(cText, "&OK",1, "Info")
endfunction
function! s:ToggleGlobalVars()
	let s:searchGlobalVars=! s:searchGlobalVars
	if s:searchGlobalVars
		let cText="Search for global variables is enabled"
	else
		let cText="No search for global variables"
	endif
	call confirm(cText, "&OK",1, "Info")
endfunction
function! s:InsertToTags()
	if (match(&tags, "cppcomplete.tags,",0)>=0)
		call confirm("cppcomplete.tags is already in tags","&OK",1,"Info")
	else
		let &tags="cppcomplete.tags," . &tags
	endif
endfunction
function! s:ClearFromTags()
	if (match(&tags,"cppcomplete.tags")<0)
		call confirm("tags did not include cppcomplete.tags","&OK",1,"Info")
	else
		let &tags=substitute(&tags,"cppcomplete.tags.","","g")
	endif
endfunction

function! s:SetGrepArg(argtxt)
	silent! call delete(s:grepTemp)
	split
	silent! execute "silent! edit " s:grepTemp
	let @c=a:argtxt
	normal! "cp
	silent! w
	silent! bd
endfunction
function! s:RefreshMenu()	
	if ! s:CheckForTagFile()
		return
	endif
	let spaceAfter="[^!\t]\\+\t"
	let res=confirm("If you have a big cppcomplete.tags file may strange things happen", "&All\n&Just items in the current directory\n&Cancel",2,"Warning")
	if res==1
		let fileSelect=spaceAfter
	elseif res==3
		return
	else
		let fileSelect="[^\\/\t]\\+\t"
	endif
	silent! aunmenu cppcomplete.Preview.Classes
	silent! aunmenu cppcomplete.Preview.Structures
	silent! aunmenu cppcomplete.Preview.Unions
	let cf=0
	let sf=0
	let uf=0
	if s:useBuffer && s:neverUseGrep
		split
		let items=""
		call s:CheckHiddenLoaded()
		let x=line(".")
		execute ":call search('^" . spaceAfter . fileSelect . spaceAfter . "\\(c\\|s\\|u\\)','W')"
		while line(".")!=x
			let x=line(".")
			normal! "cyy$
			let items=items . @c
			execute ":call search('^" . spaceAfter . fileSelect . spaceAfter . "\\(c\\|s\\|u\\)','W')"
		endwhile
		quit
	elseif s:useDJGPP
		call s:SetGrepArg("'^" . spaceAfter . fileSelect . spaceAfter . "\\(c\\|s\\|u\\)' cppcomplete.tags")
		silent! let items=system(s:grepPrg . " @" . s:grepTemp)
	else
		let items=system(s:grepPrg . " '^" . spaceAfter . fileSelect . spaceAfter . "\\(c\\|s\\|u\\)' cppcomplete.tags")
	endif
	let nextM=0
	let nclines=0
	let nslines=0
	let nulines=0
	let cMore=""
	let sMore=""
	let uMore=""
	
	while match(items,"\t",nextM)>0
		let oldM=nextM
		let @c=strpart(items,nextM,match(items,"\t",nextM)-nextM)
		let nextM=matchend(items,"\n",nextM)
		if nextM<0
			let nextM=strlen(items)
		endif
		let mc=match(items,"^[^\t]*\t[^\t]*\t[^\t]*\tc",oldM)
		let ms=match(items,"^[^\t]*\t[^\t]*\t[^\t]*\ts.*",oldM)
		if (mc>=0) && (mc<nextM)
			let cf=1
			execute "amenu .200 &cppcomplete.&Preview.&Classes." . cMore . @c . " :PreviewEntry " . @c ."<CR>" 
			let nclines=nclines+1
			if (! s:useWinMenu)
				if (nclines%s:maxNMenuLines)==0
					let cMore=cMore . "More."
				endif
			endif
		elseif (ms>=0) && (ms<nextM)
			let sf=1
			execute "amenu .300 &cppcomplete.&Preview.&Structures." . sMore . @c . " :PreviewEntry " . @c ."<CR>"
			let nslines=nslines+1
			if (! s:useWinMenu)
				if (nslines%s:maxNMenuLines)==0
					let sMore=sMore . "More."
				endif
			endif

		else
			let uf=1
			execute "amenu .400 &cppcomplete.&Preview.&Unions." . uMore . @c . " :PreviewEntry " . @c ."<CR>"
			let nulines=nulines+1
			if (! s:useWinMenu)
				if (nulines%s:maxNMenuLines)==0
					let uMore=uMore . "More."
				endif
			endif

		endif
	endwhile
	if cf==0
		amenu &cppcomplete.&Preview.&Classes.*****\ \ \ no\ classes\ found\ \ \ ***** <NOP>
	endif
	if sf==0
		amenu &cppcomplete.&Preview.&Structures.*****\ \ \ no\ structures\ found\ \ \ ***** <NOP>
	endif
	if uf==0
		amenu &cppcomplete.&Preview.&Unions.*****\ \ \ no\ unions\ found\ \ \ ***** <NOP>
	endif
endfunction

function! s:BuildMenuFromBlock()
	let hittedList="\n"
	if s:regexBlock==""
		call confirm("No block to build the menu from.\nYou must first create the block with the\n:BuildBlockFromRegexp command.","&OK",1,"Error")
		return
	endif
	silent! aunmenu cppcomplete.Preview.Regexp
	let spaceAfter="[^!\t]\\+\t"
	let nLines=0
	let skippedLines=0
	let nextM=0
	let grouped=confirm("Which type of menu","&Grouped by visibility\n&Not grouped",1,"Question")
	if grouped!=1
		if grouped!=2
			return
		else
			let grouped=0
		endif
	endif
	let bMore=""
	let uMore=""
	let uLines=0
	while match(s:regexBlock, "\t", nextM)>0
		let oldM=nextM
		let nLines=nLines+1
		let @c=strpart(s:regexBlock, nextM, match(s:regexBlock,"\t",nextM)-nextM)
		let nextM=matchend(s:regexBlock,"\n",nextM)
		if nextM<0
			let nextM=strlen(s:regexBlock)
		endif
		if grouped
			let gStart=matchend(s:regexBlock,"^[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t\\(class\\|struct\\|union\\):",oldM)

			if gStart<0
				let uLines=uLines+1
				if !s:useWinMenu
					if (uLines % s:maxNMenuLines)==0
						let uMore=uMore . "More."
					endif
				endif
				let group="uncategorized." . uMore 
			else
				let gEnd=match(s:regexBlock,"\t",gStart)
				let group=strpart(s:regexBlock, gStart, gEnd-gStart) . "."
			endif
		else
			let group=""
			if !s:useWinMenu
				if (nLines % s:maxNMenuLines)==0
					let bMore=bMore . "More."
				endif
			endif
		endif
		if match(hittedList, "\n" . group . @c . "\n")<0
			let hittedList=hittedList . group . @c . "\n"
			execute "amenu &cppcomplete.&Preview.Regexp." . bMore . group . @c . " :JumpToLineInBlock " . nLines . "<CR>"
		else
			let skippedLines=skippedLines+1
		endif
	endwhile
	if nLines==0
		call confirm("Could not build the menu", "&OK",1,"Error")
	elseif skippedLines==0
		call confirm("A menu with " . nLines . " items has been built.\nIt is placed under the Preview submenu", "&OK", 1, "Info")
	else
		call confirm("From the original " . nLines . " items was " . skippedLines . "\n skipped because of name clashes.\nThe resulting menu can be reached from the Preview submenu.", "&OK", 1, "Info")
	endif
endfunction

function! s:SetStandardPopup()
	aunmenu PopUp
	" The popup menu
	an 1.10 PopUp.&Undo			u
	an 1.15 PopUp.-SEP1-			<Nop>
	vnoremenu 1.20 PopUp.Cu&t		"+x
	vnoremenu 1.30 PopUp.&Copy		"+y
	cnoremenu 1.30 PopUp.&Copy		<C-Y>
	nnoremenu 1.40 PopUp.&Paste		"+gP
	cnoremenu 1.40 PopUp.&Paste		<C-R>+
	if has("virtualedit")
		vnoremenu <script> 1.40 PopUp.&Paste	"-c<Esc><SID>Paste
		inoremenu <script> 1.40 PopUp.&Paste	<Esc><SID>Pastegi
	else
		vnoremenu <script> 1.40 PopUp.&Paste	"-c<Esc>gix<Esc><SID>Paste"_x
		inoremenu <script> 1.40 PopUp.&Paste	x<Esc><SID>Paste"_s
	endif
	vnoremenu 1.50 PopUp.&Delete		x
	an 1.55 PopUp.-SEP2-			<Nop>
	vnoremenu 1.60 PopUp.Select\ Blockwise	<C-V>
	an 1.70 PopUp.Select\ &Word		vaw
	an 1.80 PopUp.Select\ &Line		V
	an 1.90 PopUp.Select\ &Block		<C-V>
	an 1.100 PopUp.Select\ &All		ggVG
endfunction
function! s:BuildIt()
	let s:nHits=0
	let s:hitList="\n"
	if has("gui_running")
		aunmenu PopUp
	endif
	if (s:matches=="")
		if has("gui_running")
			amenu PopUp.****\ \ no\ completions\ found\ \ *****   :let @c=''<CR>
		endif
		return
	endif
	let nextM=0
	let line=1
	let pMore=""
	let totHits=0

	while (s:tooBig>s:nHits) && (match(s:matches,"\t",nextM)>0)
		let totHits=totHits+1
		let @c=strpart(s:matches, nextM, match(s:matches,"\t",nextM)-nextM)
		if (strpart(@c,0,9)!="operator ") && (match(s:hitList,"\n" . substitute(@c,"\\~", ":","g") . "\n")<0)
			let sAcc=matchend(s:matches,"access:",nextM)
			let accEnd=match(s:matches,"\n",nextM) 
			if (accEnd<0)
				let accEnd=strlen(s:matches)
			endif
			if (sAcc>0) && (sAcc<accEnd) && s:showAccess
				let accStr="<Tab>" . strpart(s:matches, sAcc, accEnd-sAcc) 
			else
				let accStr=""
			endif
			if has("gui_running")
				execute "silent amenu PopUp." . pMore . @c . accStr . "  :let @c=\"" . @c ."\"<Bar>DoMenu<CR>"
			endif
			let s:hitList=s:hitList . substitute(@c,"\\~", ":","g") . "\n"
			let s:nHits=s:nHits+1
			let line=line+1
			if (! s:useWinMenu)
				if (line % s:maxNMenuLines)==0
					let pMore=pMore  . "More."
				endif
			endif
		endif
		let nextM=matchend(s:matches,"\n",nextM)
		if nextM<0
			let nextM=strlen(s:matches)
		endif
	endwhile
	let s:hitList=strpart(s:hitList,1)
	if (s:nHits>=s:tooBig)
		let s:nHits=s:nHits+1
		let s:hitList=s:hitList . "xxxxxxMAX_NR_OF_HITSxxxxxx\n"
		if has("gui_running") 
			let qStr="Max number of hits reached"
			if !s:useWinMenu
				execute "amenu PopUp." . pMore . "xxxxxxMAX_NR_OF_HITSxxxxxx <NOP>"
			else
				amenu PopUp.****\ \ Max\ number\ of\ hits\ reched\ **** <NOP>
			endif
			call confirm( qStr, "&OK", 1,"Warning")
		endif
	elseif totHits>=s:maxGrepHits
		if has("gui_running")
			call confirm("The number of items the popup was built from\nis equal to s:maxGrepHits.\nMore completions may exists.","&OK",1,"Warning")
		endif
	endif
	if s:nHits==0 && has("gui_running")
		amenu PopUp.*****\ \ Strange\ output\ from\ grep\ \ *****  :let @c=""<CR>
	endif
endfunction
function! s:xAndBack()
	let colP = col(".")
	normal! x
	if (col(".")==colP)
		normal! h
	endif
endfunction
function! s:RemoveTyped()
	if (s:uTyped=="\\~")
		call s:xAndBack()
	elseif (s:uTyped!="")
		if (strlen(s:uTyped)>1)
			if (strlen(s:uTyped)==3) && (match(s:uTyped,"\\~")>=0)
				call s:xAndBack()
			else
				normal! db
			endif
		endif
			call s:xAndBack()
	endif
	let c = getline(line("."))[col(".") - 1]
	if (c=="~")
		call s:xAndBack()
	endif
endfunction
function! s:DoMenu()
	if @c==""
		return
	endif
	let colP = col(".")
	normal! l
	if colP!=col(".")
		normal! hh
		let strangeFix=1
	else
		let strangeFix=0
	endif
	call s:RemoveTyped()
	normal! "cp
	if (strangeFix)
		normal! l
	endif
	if (s:showPreview)
		call s:PreviewEntry(@c)
	endif
	let s:uTyped=""
endfunction
function! s:InsNextHit()
	if (s:IsHitted())
		call s:DelHit()
		let s:lastHit=s:lastHit+1
		if (s:lastHit>s:nHits)
			let s:lastHit=1
		endif
		call s:InsHit()
	else
		let s:lastHit=1
		let winMenuSav=s:useWinMenu
		let s:useWinMenu=0
		call s:BuildMenu()
		let s:useWinMenu=winMenuSav
		if (s:nHits>0)
			call s:RemoveTyped()
			call s:InsHit()
		else
			let s:lastHit=0
		endif
	endif
endfunction
function! s:InsPrevHit()
	if (s:IsHitted())
		call s:DelHit()
		let s:lastHit=s:lastHit-1
		if (s:lastHit<1)
			let s:lastHit=s:nHits
		endif
		call s:InsHit()
	else
		let winMenuSav=s:useWinMenu
		let s:useWinMenu=0
		call s:BuildMenu()
		let s:useWinMenu=winMenuSav
		let s:lastHit=s:nHits
		if (s:nHits>0)
			call s:RemoveTyped()
			call s:InsHit()
		endif
	endif
endfunction

function! s:IsHitted()	
	if (s:lastHit>0) && expand("<cword>")==substitute(s:CurrentHit(),":","","g")
		return expand("<cword>")!=""
	endif
	return 0
endfunction
function! s:CurrentHit()
	let prevM=0
	let nextM=matchend(s:hitList,"\n")
	let toGo=s:lastHit
	while (toGo>1) && match(s:hitList, "\n", nextM)
		let prevM=nextM
		let nextM=matchend(s:hitList,"\n",nextM)
		if (nextM<0)
			let nextM=strlen(s:hitList)
		endif
		let toGo=toGo-1
	endwhile
	if (toGo==1)
		return strpart(s:hitList, prevM, nextM-prevM-1)
	endif
	return ""
endfunction
function! s:DelHit()
	let prevTyped=s:uTyped
	let s:uTyped=substitute(s:CurrentHit(),":","\\~","g")
	call s:RemoveTyped()
	let s:uTyped=prevTyped
endfunction
function! s:InsHit()
	let @c=substitute(s:CurrentHit(),":","\\~","g")
	normal! "cp
	if (s:showPreview)
		call s:PreviewEntry(@c)
	endif
endfunction
	
function! s:UpdateInheritList()
	let spaceAfter="[^!\t]\\+\t"
	let after3=spaceAfter . spaceAfter . spaceAfter
	if (s:listAge!=getftime("cppcomplete.tags"))
		if s:useBuffer && s:neverUseGrep
			split
			let s:inheritsList="\n"
			call s:CheckHiddenLoaded()
			let x=line(".")
			execute ":call search('^" . after3 . ".*inherits:','W')"
			while line(".")!=x
				let x=line(".")
				normal! "cyy$
				let s:inheritsList=s:inheritsList . @c
				execute ":call search('^" . after3 . ".*inherits:','W')"
			endwhile
			quit
		elseif s:useDJGPP
			call s:SetGrepArg("'^" . after3 . ".*" ."inherits:.*' cppcomplete.tags")
			silent! let s:inheritsList="\n" . system(s:grepPrg . " @" . s:grepTemp)
		else
			let s:inheritsList="\n" . system(s:grepPrg . " '^" . after3 . ".*" ."inherits:.*' cppcomplete.tags")
		endif
		let s:listAge=getftime("cppcomplete.tags")
	endif
endfunction
function! s:SetMatchesFromBuffer(grepArg)
	let hits=0
	split
	let s:matches=""
	call s:CheckHiddenLoaded()
	let x=line(".")
	execute ":call search(" . a:grepArg .",'W')"
	while (line(".")!=x) && (hits<s:maxGrepHits)
		let hits=hits+1
		let x=line(".")
		normal! "cyy$
		let s:matches=s:matches . @c
	execute ":call search(" . a:grepArg .",'W')"
	endwhile
	quit
endfunction

function! s:BuildFromOrdinary()
	let maxGrep=" --max-count=" . s:maxGrepHits
	if s:useBuffer
		call s:SetMatchesFromBuffer("'^" . s:uTyped. "'")
	elseif s:useDJGPP
		call s:SetGrepArg("'^" . s:uTyped . "'")
		let s:matches=system(s:grepPrg . " @" . s:grepTemp . " cppcomplete.tags")
	else
		let s:matches=system(s:grepPrg . maxGrep . " '^" . s:uTyped . "' cppcomplete.tags")
	endif
endfunction

function! s:BuildMenu()
	if &previewwindow		
		if has("gui_running")
			call confirm("Dont do this is the Preview window","&OK",1,"Error")
		endif
      		return
    	endif
	let s:nHits=0
	if ! s:CheckForTagFile()
		return
	endif
	let oldParents=s:relaxedParents
	call s:GetPieces()
	if (s:gotCType)
		let spaceAfter="[^! \t]\\+\t"
		let someSpaceAfter="[^\t]\\+\t"
		let after3=spaceAfter . someSpaceAfter . someSpaceAfter

		call s:UpdateInheritList()
		let accSav=s:accessCheck
		if s:colonSep && s:colonNoInherit
			let s:classList=s:clType . "\t"
			let s:accessCheck=0
			let s:colonSep=0
		else
			call s:GetParents()
		endif
		if s:justInteresting
			let interesting="\\(c\\|m\\|p\\|s\\|u\\)\t"
		else
			let interesting=""
		endif
		let firstPart=s:uTyped . after3 . interesting . ".*\\(class:\\|struct:\\|union:\\)"
		if ! s:colonSep
			if s:accessCheck
				if s:currLanguage=="Java"
					let secondPart=".*access:\\(default\\|public\\)"
				else
					let secondPart=".*access:public"
				endif
			else
				let secondPart=""
			endif
		elseif s:accessCheck
			if s:currLanguage=="Java"
				let secondPart=".*access:\\(public\\|default\\|protected\\)\\|"
			else
				let secondPart=".*access:\\(public\\|protected\\)\\|"
			endif
		else
			let secondPart=".*\\|"
		endif
		let maxGrep=" --max-count=" . s:maxGrepHits . " "
		if s:colonSep
			if s:useBuffer
				call s:SetMatchesFromBuffer("'^\\(" . firstPart . s:classList . secondPart . firstPart . s:clType . "\t\\)'")
			elseif (s:useDJGPP)
				call s:SetGrepArg("'^\\(" . firstPart . s:classList . secondPart . firstPart . s:clType . "\t\\)' cppcomplete.tags")
				silent! let s:matches=system(s:grepPrg . " @" . s:grepTemp)
			else
				let s:matches=system(s:grepPrg . maxGrep . " '^\\(" . firstPart . s:classList . secondPart . firstPart . s:clType . "\t\\)' cppcomplete.tags")
			endif

		else
			if s:useBuffer
				call s:SetMatchesFromBuffer("'^" . firstPart . s:classList . secondPart . "'")
			elseif s:useDJGPP
				call s:SetGrepArg("'^" . firstPart . s:classList . secondPart . "'")
				silent! let s:matches=system(s:grepPrg . " @" . s:grepTemp . " cppcomplete.tags")
			else
				let s:matches=system(s:grepPrg . maxGrep . " '^" . firstPart . s:classList . secondPart . "' cppcomplete.tags")
			endif
		endif
		let s:accessCheck=accSav
		call s:BuildIt()
	elseif s:completeOrdinary && (s:uTyped!="") && (! s:gotCSep)
		call s:BuildFromOrdinary()
		call s:BuildIt()
	else
		let s:matches=""
		call s:BuildIt()
	endif
	let s:relaxedParents=oldParents
	if s:useWinMenu
		execute "popup PopUp"
	endif
endfunction
" Get the input and try to determine the class type
function! s:GetPieces()
	let lineP = line(".")
	let colP = virtcol(".")

	let s:gotUTyped=0
	let s:gotCSep=0
	let s:gotCType=0
	let s:colonSep=0
	let s:uTyped=""
	let s:clType=""

	call s:GetUserTyped()
	if (s:gotUTyped>0)
		if line(".")!=lineP
			let lineP2 = line(".")
			let colP2 = virtcol(".")
			call search("//","bW")
			if (virtcol(".")!=colP2) && (lineP2==line("."))
				exe lineP.'normal! '.colP.'|'
				return
			else
				exe lineP2.'normal! '.colP2.'|'
			endif
		endif
		call s:GetClassSep()
		if (s:gotCSep)
			let s:innerStruct=0
			let s:currDepth=0
			let s:isStruct=0
			if (s:colonSep)
				let s:clType=expand("<cword>")
				let s:gotCType=(s:clType!="")
				call s:CheckClassType()
			else
				call s:GetClassType()
			endif
		endif
	endif
	exe lineP.'normal! '.colP.'|'
endfunction
" The stuff that was typed after  ::, -> or . 
function! s:GetUserTyped()
	let c = getline(line("."))[col(".") - 1]
	normal! wb
	if (c!="~") 
		let c = getline(line("."))[col(".") - 1]
		if (c=="]") 
			normal! e
			let c = getline(line("."))[col(".") - 1]
			normal! b
		endif
	else
		let s:uTyped="\\~"
		let s:gotUTyped=1
		return
	endif
	if ((c == "-") || (c == ".") || (c==":") || (c==">"))
		let s:uTyped=""
	else
		let s:uTyped = expand("<cword>")
		if (strlen(s:uTyped)>0)
			normal! h
			let c = getline(line("."))[col(".") - 1]
			normal! l
		endif
		if (c=="~")
			let s:uTyped="\\~" . s:uTyped
		endif
		normal! b
	endif
	let s:gotUTyped=1
endfunction
" the code is using w and b movements and that makes the code harder
" a better method is probably using single char moves
function! s:GetClassSep()
	let c = getline(line("."))[col(".") - 1]
	if ((c == "-")  || (c == "."))
		if c=="-"
			normal! l
			let c = getline(line("."))[col(".") - 1]
			if c!=">"
				return 0
			endif
			normal! h
		endif
		normal! b
		let s:gotCSep=1
	elseif (c==":")
		let s:gotCSep=1
		let s:colonSep=1

		normal! b
		let c = getline(line("."))[col(".") - 1]
		if (c==">")
			let nangle=1
			while ((nangle>0) && line(".")>1))
				normal! b
				let c = getline(line("."))[col(".") - 1]
				if (c==">")
					let nangle=nangle+1
				elseif (c="<")
					let nangle=nangle-1
				endif
			endwhile
			normal! b
		endif
	elseif (c==">")
		normal! l
		let c = getline(line("."))[col(".") - 1]
		if (c==":")
			let s:gotCSep=1
			let s:colonSep=1

			normal! b
			let c = getline(line("."))[col(".") - 1]
			if (c==">")
				let nangle=1
				while (nangle>0) && (line(".")>1)
					normal! b
					let c = getline(line("."))[col(".") - 1]
					if (c==">")
						let nangle=nangle+1
					elseif (c=="<")
						let nangle=nangle-1
					endif
				endwhile
				normal! b
			endif
		endif
	elseif (c=="]")
		normal! e
		let done=0
		while ! done
			let c = getline(line("."))[col(".") - 1]
			if (c==".") || (c==">")
				let s:gotCSep=1
				let done=1
			elseif (c==":")
				let s:colonSep=1
				let s:gotCSep=1
				let done=1
			elseif (c=="~")
				normal! h
			else
				let done=1
			endif
		endwhile
		normal! b
		if s:gotCSep
			let c = getline(line("."))[col(".") - 1]
			while (c!="[") && (line(".")>1)
				normal! b
				let c = getline(line("."))[col(".") - 1]
			endwhile
			if ! (line(".")>1)
				let s:gotCSep=0
			else 
				normal! b
			endif
		endif
	endif
endfunction

function! s:GetClassType()
	let lineT=line(".")
	let colT=virtcol(".")
	let hasTagJumped=s:JumpToDecl(1)
	if (hasTagJumped==-1)
		return
	endif

	call s:GetType()
	if hasTagJumped
		quit
"		pop
	endif
	if s:gotCType 
		call s:CheckClassType()
		if (s:gotCType)
			return
		endif
		if (hasTagJumped)
			exe lineT.'normal! '.colT.'|'
			if s:JumpToDecl(0)==-1
				return
			endif
			call s:GetType()
			if s:gotCType
				call s:CheckClassType()
			endif
		endif
	endif
endfunction
function! s:CheckClassType()
	let spaceAfter="[^!\t]\\+\t"
	let goodTypes="s\\|u\\|c\\|"
	if s:searchTDefs
		let goodTypes=goodTypes . "\\|t"
	endif
	if s:searchMacros
		let goodTypes=goodTypes . "\\|d"
	endif
	let goodTypes="\\(" . goodTypes . "\\)"
	if s:useBuffer
		split
		call s:CheckHiddenLoaded()
		let foundIt=""
		let x=line(".")
		execute ":call search(" . "'^" . s:clType . "\t" . spaceAfter . spaceAfter . goodTypes . "','W')"
		while line(".")!=x
			let x=line(".")
			normal! "cyy$
			let foundIt=foundIt . @c
			execute ":call search(" . "'^" . s:clType . "\t" . spaceAfter . spaceAfter . goodTypes . "','W')"
		endwhile
		quit
	elseif s:useDJGPP
		call s:SetGrepArg("'^" . s:clType . "\t" . spaceAfter . spaceAfter . goodTypes . "' cppcomplete.tags")
		silent! let foundIt=system(s:grepPrg . " @" . s:grepTemp)
	else
		let foundIt=system(s:grepPrg . " '^" . s:clType . "\t" . spaceAfter . spaceAfter . goodTypes . "' cppcomplete.tags")
	endif
	if foundIt==""
		let s:gotCType=0
	elseif match(foundIt, "\t\\(s\\|u\\|c\\)[\t\n]")<0
		let s:gotCType=0
		if match(foundIt, "\tt[\t\n]")>0
			if s:searchTDefs
				call s:GetTypedef(foundIt)
			endif
		else
			if s:searchMacros
				call s:GetMacro(foundIt)
			endif
		endif
	elseif match(foundIt, "\ts[\t\n]")>=0
		let s:isStruct=1
	endif
endfunction
function! s:IsTypedefStruct(wordCheck)
	let isStructSave=s:isStruct
	let s:isStruct=0
	let clTypeSave=s:clType
	let s:clType=a:wordCheck
	let s:currDepth=0
	call s:CheckClassType()
	if s:gotCType && (s:clType!=a:wordCheck)
		call s:CheckClassType()
	endif
	let res=s:isStruct && s:gotCType
	let s:isStruct=isStructSave
	let s:typeDefStruct=s:clType
	let s:clType=clTypeSave
	return res 
endfunction
		
function! s:JumpToDecl(jumpAllowed)
	let lineT=line(".")
	let colT=virtcol(".")
	let s:innerStruct=0
	if a:jumpAllowed && (s:searchGlobalVars || s:searchClassMembers || s:searchClassTags)
		call s:DoGlobalJump()
		if s:gotCType
			return -1
		endif
	endif
	if ((virtcol(".") == colT) && (line(".") == lineT))
		normal! b
		let c = getline(line("."))[col(".") - 1]
		if a:jumpAllowed && ((c==".") || (c=="-") || (c==":"))
			let lucky=1
			if (c=="-")
				normal! l
				let c = getline(line("."))[col(".") - 1]
				if (c!=">")
					let lucky=0
				endif
				normal! h
			endif
			if lucky && (line(".")!=lineT)
				let lineT2=line(".")
				let colT2=virtcol(".")
				let newLine=line(".")
				if (search("//","bW")==newLine)
					let lucky=0
				endif
				exe lineT2.'normal! '.colT2.'|'
			endif
			normal! w
			if lucky
				let s:innerStruct=1
				let s:gotCType=1
				let s:clType = expand("<cword>")
				return -1
			endif
		endif
		exe lineT.'normal! '.colT.'|'
		if (! s:onlyGD)
			call s:TryLocalJump()	
		endif
		if ((virtcol(".") == colT) && (line(".") == lineT))
			normal! gD
			if ((virtcol(".") == colT) && (line(".") == lineT))
				return -1
			endif
		endif
	else
		return 1
	endif
	return 0
endfunction
function! s:GetType()
	while (line(".")>1)
		normal! b
		let c = getline(line("."))[col(".") - 1]

		if (c == ")")
			normal! [(b
			continue
		elseif (c=="]")
			while (c!="[") && (line(".")>1)
				normal! b
				let c = getline(line("."))[col(".") - 1]
			endwhile
			if ! (line(".")>1)
				return
			else
				continue
			endif
		elseif (c==";") || (c=="{")
			return
		endif
		if (c == ",")
			normal! b
		elseif (c=="}")
			normal! [{b
			let s:gotCType=1
			let s:clType = expand("<cword>")
			return
		else
			let s:clType = expand("<cword>")
			if ((c!="*") && (c!="&") && (s:clType!="const") && (s:clType!="static"))
				normal! w
				let c = getline(line("."))[col(".") - 1]
				normal! b
				if (c!=",")
					let prevLine=line(".")
					let c = getline(line("."))[col(".") - 1]
					normal! b
					if (line(".")!=prevLine)
						let lineT2=line(".")
						let colT2=virtcol(".")
						let newLine=line(".")
						if (search("//","bW")==newLine)
							let c2="x"
						else
							let c2 = getline(line("."))[col(".") - 1]
						endif
						exe lineT2.'normal! '.colT2.'|'
					else
						let c2 = getline(line("."))[col(".") - 1]
					endif
					let nangle=0
					if (c==">")
						if (c2==">")
							let nangle=2
						else
							let nangle=1
						endif
					elseif (c2==">")
						let nangle=1
					else
						if (c2==":") || (c2==".") || (c2=="-")
							let s:relaxedParents=1
						elseif (c2=="<")
							continue
						endif
						let s:gotCType=1
						return
					endif
					while((nangle>0) && (line(".")>1))
						normal! b
						let c = getline(line("."))[col(".") - 1]
						if (c==">")
							let nangle=nangle+1
						elseif (c=="<")
							let nangle=nangle-1
						endif
					endwhile
				endif
			elseif (c=="*")
				normal! l
				let c = getline(line("."))[col(".") - 1]
				normal! h
				if (c=="/")
					normal! [/
				endif
			endif
		endif
	endwhile
endfunction
function! s:TryLocalJump()
	let lineT2=line(".")
	let colT2=virtcol(".")
	normal! gd
	if s:IsInsane()
		exe lineT2.'normal! '.colT2.'|'
	endif
endfunction
function! s:IsInsane()
	let insaneLine=line(".")
	let insaneCol=virtcol(".")
	normal! [{
	if ((virtcol(".") == insaneCol) && (line(".") == insaneLine))
		return 0
	endif
	exe insaneLine.'normal! '.insaneCol.'|'
	normal! [(
	if ! ((virtcol(".") == insaneCol) && (line(".") == insaneLine))
		exe insaneLine.'normal! '.insaneCol.'|'
		return 1
	endif
	if (search("=","bW"))!=0
		if line(".")==insaneLine
			exe insaneLine.'normal! '.insaneCol.'|'
			return 1
		endif
		exe insaneLine.'normal! '.insaneCol.'|'
	endif
	normal! w
	let c = getline(line("."))[col(".") - 1]
	exe insaneLine.'normal! '.insaneCol.'|'
	return (c==".") || (c==":") || (c=="-")
endfunction	
	
function! s:JumpToInterestingLine(lines, i)
	let lEnd=match(a:lines, "\n", a:i)
	if lEnd<0
		let lEnd=strlen(a:lines)
	endif
	let lStart=0
	while (lEnd>match(a:lines, "\n", lStart))
		let lStart=matchend(a:lines, "\n", lStart)
		if lStart<0
			call s:DoTagLikeJump(strpart(a:lines,0,lEnd))
			return
		endif
	endwhile
	call s:DoTagLikeJump(strpart(a:lines,lStart,lEnd))
endfunction
	
" If a typedef was used
function! s:GetTypedef(foundIt)
	let s:gotCType=0
	let s:currDepth=s:currDepth+1
	if s:currDepth>=s:maxDepth
		return
	endif
	split
	call s:DoTagLikeJump(a:foundIt)
	call search(s:clType)
	let lineT=line(".")
	let colT=virtcol(".")
	call s:GetClassType()
	if ! s:gotCType
		exe lineT.'normal! '.colT.'|'
		call s:GetType()
	endif
	quit
endfunction
" a simple approach for macros
function! s:GetMacro(foundIt)
	split
	call s:DoTagLikeJump(a:foundIt)
	normal! www
	let s:clType=expand("<cword>")
	if (s:clType=="class" || s:clType=="struct" || s:clType=="union")
		normal! w
		let s:clType=expand("<cword>")
	endif
	let s:gotCType=1
	quit
endfunction
" Get the ancestors, I do not think that ctags always gives a complete list
function! s:GetParents()
	let s:classList=s:clType
	let clName=s:clType
	let unsearched=""
	let searched=""
	let done=0

	while ! done
		let nextM=match(s:inheritsList,"\n". clName . "\t")
		if (nextM>=0)
			let nextM=nextM+1
			let inhLine=strpart(s:inheritsList, nextM, match(s:inheritsList,"\n",nextM)-nextM)
			let i2=matchend(inhLine, "inherits:")
			let c=","
			while c==","
				let i=match(inhLine,"[,\t\n]",i2)
				if (i==-1)
"					let i=match(inhLine, "[\t\n]",i2)
"					if (i==-1)
						let i=strlen(inhLine)
"					endif
				endif
				let @c=strpart(inhLine,i2,i-i2)
				if  match(searched,":" . @c . ":")<0
					let searched=searched . ":" . @c . ":"
					if s:isStruct
						if s:IsTypedefStruct(@c)
							let @c=s:typeDefStruct
							let searched=searched . ":" . s:typeDefStruct . ":"
						else
							let @c=strpart(inhLine,i2,i-i2)
						endif
						let s:classList=s:classList . "\\|" . @c
					else
						let s:classList=s:classList . "\\|" . @c
					endif
					if (strlen(unsearched)>0)
						let unsearched=unsearched . ":" . @c 
					else
						let unsearched=@c
					endif
				endif
				let c=strpart(inhLine, i,1)
				let i2=i+1
			endwhile
		endif
		if (strlen(unsearched)<=0)
			let done=1
		elseif (match(unsearched,":")>0)
			let clName=strpart(unsearched, 0, match(unsearched,":"))
			let unsearched=strpart(unsearched, matchend(unsearched,":"))
		else
			let clName=unsearched
			let unsearched=""
		endif
	endwhile
	if (s:innerStruct) 
		if s:classList!=s:clType
			let rest="\\|" . strpart(s:classList, matchend(s:classList,"|"))
		else
			let rest=""
		endif
		if s:currLanguage=="Java"
			let s:classList="\\([^\\.]*\\.\\)\\(.*\\." . s:clType . rest . "\\)\\(\\.<anonymous>\\)*\t"
		else
			let s:classList="\\([^:]*::\\)*\\(.*::" . s:clType . rest . "\\)\\(::<anonymous>\\)*\t"
		endif
	elseif s:currLanguage=="Java"
		if s:relaxedParents
			let s:classList="\\([^\\.]*\\.\\)*\\(" . s:classList . "\\)\\(\\.<anonymous>\\)*\t"
		else
			let s:classList="\\(<anonymous>.\\)*\\(" . s:classList . "\\)\\(\\.<anonymous>\\)*\t"
		endif
	else
		if s:relaxedParents
			let s:classList="\\([^:]*::\\)*\\(" . s:classList . "\\)\\(::<anonymous>\\)*\t"
		else
			let s:classList="\\(<anonymous>::\\)*\\(" . s:classList . "\\)\\(::<anonymous>\\)*\t"
		endif
	endif
" Uncommenting the following line can be useful if you have hacked the script but breaks the popup in GTK.
"	 echo s:classList ."\n"
endfunction
function! s:JumpToLineInBlock(n)
	if s:regexBlock==""
		if has("gui_running") 
			call confirm("The current block is empty","&OK",1,"Error")
		endif
		return
	endif
	let currLine=0
	let currPos=0
	let prevPos=0
	if (a:n>s:nLinesInBlock) || (a:n<1)
		return
	endif
	while a:n>currLine
		let prevPos=currPos
		let currPos=match(s:regexBlock, "\n", currPos+1)
		if currPos<0
			let currLine=a:n
			let currPos=strlen(s:regexBlock)
		else
			let currLine=currLine+1
		endif
	endwhile
	let s:currInBlock=a:n
	call s:DoTagLikeJump(strpart(s:regexBlock, prevPos, currPos-prevPos))
	normal! zt
endfunction
	
function! s:PrevInBlock()
	let s:currInBlock=s:currInBlock-1
	if s:currInBlock<=0
		let s:currInBlock=s:nLinesInBlock
	endif
	call s:JumpToLineInBlock(s:currInBlock) 
endfunction
function! s:NextInBlock()
	let s:currInBlock=s:currInBlock+1
	if s:currInBlock>s:nLinesInBlock
		let s:currInBlock=1
	endif
	call s:JumpToLineInBlock(s:currInBlock) 
endfunction
function! s:BuildBlock(regex)
	let s:regexBlock=""
	if has("gui_running") 
		silent! aunmenu cppcomplete.Preview.Regexp
	endif
	let s:nLinesInBlock=0
	let s:currInBlock=0
	if (a:regex=="")
		return
	endif
	if s:useBuffer
		split
		let s:regexBlock=""
		call s:CheckHiddenLoaded()
		let x=line(".")
		execute ":call search('" . a:regex . "','W')"
		while line(".")!=x
			let x=line(".")
			normal! "cyy$
			if strpart(@c,1,1)!="!" || 1
				let s:regexBlock=s:regexBlock . @c
			endif
			execute ":call search('" . a:regex . "','W')"
		endwhile
		quit
	elseif s:useDJGPP
		call s:SetGrepArg("'" . a:regex ."' cppcomplete.tags")
		let s:regexBlock=system(s:grepPrg . " @" . s:grepTemp . " | " . s:grepPrg . " '^[^!]'")
	else
		let s:regexBlock=system(s:grepPrg . " '" . a:regex ."' cppcomplete.tags | " . s:grepPrg ." '^[^!]'")
	endif
	if s:regexBlock==""
		echo "could not build the block"
	else
		let currPos=0
		while currPos>=0
			let s:nLinesInBlock=s:nLinesInBlock+1
			let currPos=matchend(s:regexBlock,"\n",currPos)
		endwhile
		let s:nLinesInBlock=s:nLinesInBlock-1
		echo "a block with " . s:nLinesInBlock . " lines was built"
	endif
endfunction
function! s:BuildBlockFromRegexp()
	highlight BlockLiteral cterm=bold ctermbg=NONE gui=bold guibg=NONE
	highlight BlockItalic cterm=italic ctermbg=NONE gui=italic guibg=NONE
	echo "Build from regular expression\n"
	echo "The format of cppcomplete.tags\n"
	echon "tag_name<TAB>file_name<TAB>ex_cmd;<TAB>" 
	echohl BlockItalic
	echon "kind"
	echohl None
	echon"<TAB>"
	echohl BlockItalic
	echon "visibility"
	echohl None
	echon "<TAB>"
	echohl BlockItalic
	echon "file"
	echohl None
	echon "<TAB>"
	echohl BlockItalic
	echon "access"
	echohl None
	echon "<TAB>"
	echohl BlockItalic
	echon "inherits\nkind "
	echohl None
	echohl BlockGroup
	echon "c d e f g m n p s t u v"
	echohl None
	echon "\tfor Java is it "
	echohl BlockGroup
	echon "c f i m p"
	echohl None
	echohl BlockItalic
	echon "\nvisibility "
	echohl BlockGroup
	echon "class: struct: union: "
	echohl BlockItalic
	echon "\nfile "
	echohl BlockGroup
	echon "file:"
	echohl BlockItalic
	echon "\naccess "
	echohl BlockGroup
	echon "access:"
	echohl None
	echon " followed by "
	echohl BlockGroup
	echon "public protected private friend default\n"
	echohl BlockItalic
	echon "inherits"
	echohl BlockGroup
	echon " inherits:"
	echohl None

	let regex=input("\n>")
	if regex!=""
		call s:BuildBlock(regex)
	endif
endfunction
function! s:EchoBlock()
	echo s:regexBlock
endfunction
function! s:DoTagLikeJump(tagLine)
	let fStart=matchend(a:tagLine, "\t")
	let fEnd=match(a:tagLine, "\t", fStart)
	let jFile=strpart(a:tagLine, fStart, fEnd-fStart)
	let exStart=fEnd+1
	let exEnd=match(a:tagLine, "\t", exStart)
	let jEX=strpart(a:tagLine, exStart, exEnd-exStart)
	execut "edit! " . jFile
	execute jEX
endfunction
function! s:CheckHiddenLoaded()
	if !bufexists(getcwd() . "/cppcomplete.tags") || (getftime(getcwd() . "/cppcomplete.tags")!=s:bufAge)
		execute "edit! " . getcwd() . "/cppcomplete.tags"
		let &buflisted=0
		let s:bufAge=getftime(getcwd() . "/cppcomplete.tags")
	endif
	execute "buffer " . getcwd() . "/cppcomplete.tags"
	normal! gg^
endfunction

function! s:SimpleScopeGuess()
	normal! [[
	if search("::","Wb")<0
		return 0
	endif
	normal! b
	return 1
endfunction
function! s:DoGlobalJump()
	let spaceAfter="[^!\t]\\+\t"
	let tStr=""
	if s:searchClassMembers && s:searchGlobalVars
		let tStr="m\\|v"
	elseif s:searchClassMembers 
		let tStr="m"
	elseif s:searchGlobalVars
		let tStr="v"
	endif
	if s:searchClassTags
		if s:searchClassMembers || s:searchGlobalVars
			let tStr="s\\|u\\|c\\|" . tStr
		else
			let tStr="s\\|u\\|c"
		endif
	endif
	let tStr="\\(" . tStr . "\\)"
	let searchFor=expand("<cword>")
	if s:useBuffer
		split
		let foundIt=""
		call s:CheckHiddenLoaded()
		let x=line(".")
		execute ":call search(" . "'^" . searchFor . "\t" . spaceAfter . spaceAfter . tStr . "','W')"
		while line(".")!=x
			let x=line(".")
			normal! "cyy$
			let foundIt=foundIt . @c
			execute ":call search(" . "'^" . searchFor . "\t" . spaceAfter . spaceAfter . tStr . "','W')"
		endwhile
		quit
	elseif s:useDJGPP
		call s:SetGrepArg("'^" . searchFor . "\t" . spaceAfter . spaceAfter . tStr . "' cppcomplete.tags")
		silent! let foundIt=system(s:grepPrg . " @" . s:grepTemp)
	else
		let foundIt=system(s:grepPrg . " '^" . searchFor . "\t" . spaceAfter . spaceAfter . tStr . "' cppcomplete.tags")
	endif
	if foundIt!=""
		if match(foundIt, "\t\\(u\\|s\\|c\\)\t")<0 
			if s:SimpleScopeGuess()
				split
				let scop=expand("<cword>")
				call s:JumpToInterestingLine(foundIt, match(foundIt,scop))
			else
				split
				let tagSav=&tags
				let &tags="cppcomplete.tags"
				execute "tag " . searchFor
				let &tags=tagSav
			endif
			call search(searchFor)
		else
			let s:clType=searchFor
			let s:gotCType=1
		endif
	endif
endfunction
function! s:CheckForTagFile()
	if s:nannyMode && s:HasNotAsked()
		return s:NannyCheck()
	elseif getftime("cppcomplete.tags")==-1
		if s:nannyMode 
			return s:NannyCheck()
		endif
		if has("gui_running")
			call confirm("No cppcomplete.tags found","&OK",1,"Error")
		endif
		return 0
	endif
	return 1
endfunction
function! s:HasNotAsked()
	let cFile=substitute(expand("%"),"\\",":","g")
	if match(s:nannyAsked, "\n" . cFile . "\n")>=0
		return 0
	endif
	let s:nannyAsked=s:nannyAsked . cFile . "\n"
	return 1
endfunction
function! s:CheckFiletype()
	let fType=expand("%:e")
	if fType=="c" || fType=="C" || fType=="cpp" || fType=="h" || fType=="cxx" || fType=="hxx"
		if s:currLanguage=="Java"
			if confirm("The name of the current file indicates\na C/C++ file but the current language is set to Java.\nDo you want to change it to C/C++?","&Yes\n&No",1,"Warning")==1
				let s:currLanguage="C/C++"
			endif
		endif
	elseif fType=="java" && (s:currLanguage!="Java")
		if confirm("The name of the current file indicates\na Java file but the current language is C/C++.\nDo you want to change it to Java?","&Yes\n&No",1,"Warning")==1
			let s:currLanguage="Java"
		endif
	endif
endfunction
function! s:NannyCheck()
	if getftime("cppcomplete.tags")==-1
		if s:currLanguage=="Java"
			let ans=confirm("No cppcomplete.tahs file found","&Generate from the files in the current directory\n&Cancel",1,"Question")
			if ans==1
				return s:GenerateTags()
			else
				return 0
			endif
		endif
		let ans=confirm("No cppcomplete.tags file found.","&Auto generate from included files\n&Generate from the files in the current directory\n&Cancel",1,"Question")
		if ans==1
			return s:GenerateFromCheckpath()
		elseif ans==2
			return s:GenerateTags()
		else
			return 0
		endif
			
	elseif s:currLanguage=="Java"
		let ans=confirm("A cppcomplete.tags file already exists.","&Use it\n&Generate new\nC&omplete it\n&Cancel",1,"Question")
		if ans==2
			call s:GenerateTags()
		elseif ans==3
			call s:GenerateAndAppend()
		elseif ans==4
			return 0
		endif
	else
		let ans=confirm("A cppcomplete.tags file already exists.","&Use it\nAu&to complete it\n&Auto generate new\n&Generate new\nC&omplete it\n&Cancel",1,"Question")
		if ans==2
			call s:AppendFromCheckpath()
		elseif ans==3
			call s:GenerateFromCheckpath()
		elseif ans==4
			call s:GenerateTags()
		elseif ans==5
			call s:GenerateAndAppend()
		elseif ans==6
			return 0
		endif
	endif
	return 1
endfunction
		
function! s:SetMaxHits()
	let res=inputdialog("Current value for max hits is " . s:tooBig . "\nEnter the new value")
	if res!=""
		let s:tooBig=res
	endif
endfunction
function! s:SetLanguage()
	let res=confirm("Set the current language to use", "&C/C++\nJava",s:currLanguage=="Java" ? 2 : 1,"Question")
	if res==2
		let s:currLanguage="Java"
		let s:searchTDefs=0
		let s:searchMacros=0
		let s:searchClassTags=1
	elseif res==1
		let s:currLanguage="C/C++"
		let s:searchTDefs=1
		let s:justInteresting=0
	endif
endfunction
function! s:ShowCurrentSettings()
	if has("gui_running")
		let setStr="Current language is " . (s:currLanguage=="Java" ? "Java" : "C/C++")
		let setStr=setStr . "\nAccess check is " . (s:accessCheck==0 ? "disabled" : "enabled")
		let setStr=setStr . "\nSearch for typedefs is " . (s:searchTDefs==0 ? "disabled" : "enabled")
		let setStr=setStr . "\nSearch for macros is " . (s:searchMacros==0 ? "disabled" : "enabled")
		if (s:onlyGD!=0)
			let setStr=setStr . "\nThe script is only using gD"
		else
			let setStr=setStr . "\nThe script is first trying gd before gD"
		endif
		let setStr=setStr . "\nPreview mode is " . (s:showPreview==0 ? "off" : "on")
		let setStr=setStr . "\nAncestor check is " . (s:relaxedParents!=0 ? "relaxed" : "strict")
		let setStr=setStr . "\nSearch for global variables is " . (s:searchGlobalVars==0 ? "disabled" : "enabled")
		let setStr=setStr . "\nSearch for class members is " . (s:searchClassMembers==0 ? "disabled" : "enabled")
		let setStr=setStr . "\nSearch for class names is " . (s:searchClassTags==0 ? "disabled" : "enabled")
		let setStr=setStr . "\nRestricted completions by type is " . (s:justInteresting==0 ? "disabled" : "enabled")
		let setStr=setStr . "\nCurrent value for max hits is " . s:tooBig
		let setStr=setStr . "\nSearches is being done with " . (s:grepPrg=="grep" ? "standard grep" : "fast grep")
		let setStr=setStr . "\nThe scope resolution operator :: will " . (s:colonNoInherit ? "not " : "") . "show everything in the scope"
		let setStr=setStr . "\nNanny mode is " . (s:nannyMode ? "enabled" : "disabled")
		call confirm(setStr, "&OK",1,"Info")
	endif
endfunction
function! s:GetIncludeFiles()
	if has("gui_running") 
		call s:CheckFiletype() 
	endif
	if s:currLanguage=="Java"
		if has("gui_running")
			call confirm("This commando is not supported for Java","&OK",1,"Error")
		endif
		return 0
	endif
	silent redir @c
	silent! checkpath!
	redir END
	if match(@c,"No included files")>=0
		return 0
	endif
	if has("win32") || has("win16") || has("dos16") || has("dos32")
		let sep="\n"
	else
		let sep=" "
	endif
	let s:includedFiles=expand("%") . sep
	let nextM=matchend(@c, "Included files [^\n]*\n")
	let totalIncFiles=0
	let missedIncFiles=0
	echon "\r                                             "
	echon "\rsearching for included files..."
	redraw
	while (nextM<strlen(@c))
		let totalIncFiles=totalIncFiles+1
		let prevM=nextM
		let nextM=match(@c, "\n",prevM+1)
		if (nextM<0)
			let nextM=strlen(@c)
		endif
		let thisLine=strpart(@c, prevM, nextM-prevM)
		if match(thisLine, "NOT FOUND")>0
			let missedIncFiles=missedIncFiles+1
			continue
		elseif match(thisLine, "(Already listed)")>0
			continue
		elseif (match(thisLine, " -->")>0)
			continue
		else
			let firstC=matchend(thisLine,"[\"<]")
			let lastC=match(thisLine, "[\">]", firstC)
			let fName=substitute(strpart(thisLine, firstC, lastC-firstC),"\n","","g")
			if (fName=="")
				continue
			endif
			let s:includedFiles=s:includedFiles . globpath(&path,fName) . sep

		endif
	endwhile
	if missedIncFiles>0
		let str1="Of " . totalIncFiles . " files was " . missedIncFiles . " not found."
		if 2*missedIncFiles>totalIncFiles && has ("gui_running")
			let pStr="\nYour path is set to " . &path . "\nIs this really correct?"
			if confirm(str1 . pStr, "&Generate it\n&Cancel",2,"Error")!=1
				return 0
			endif
		elseif has("gui_running")
			if confirm(str1 . "\nThe :checkpath command lists the missing files", "&OK\n&Cancel",1,"Warning")==2
			return 0
			endif
		endif
	else	
		echon "\r                                                           "
		echon "\rcould findd all files... generating cppcomplete.tags"
	endif
	return 1
endfunction
function! s:UpdatehiddenBuffer()
	if s:useBuffer
		split
		call s:CheckHiddenLoaded()
		quit
	endif
endfunction
function! s:AnotherLongCommandLinePatchForWindows()
	silent! call delete(s:ctagsTemp)
	split
	silent! execute "silent! edit " s:ctagsTemp
	let @c=s:includedFiles
	normal! "cp
	silent! w
	silent! bd
endfunction
function! s:GenerateFromCheckpath()
	if has("gui_running")
		if getftime("cppcomplete.tags")!=-1
			let dial=confirm("You already have a cppcomplete.tags file, do you really want to destroy it?", "&Yes, I really want to replace it\n&No, I keep the old one",2,"Warning")
			if (dial!=1)
				return 0
			endif
		endif
	endif
	if (! s:GetIncludeFiles())
		return 0
	endif
	if has("win32") || has("win16") || has("dos16") || has("dos32")
		call s:AnotherLongCommandLinePatchForWindows()
		call system("ctags -n --language-force=C++ -f cppcomplete.tags --fields=+ai --C++-types=+p -L " . s:ctagsTemp)
	else
		call system("ctags -n --language-force=C++ -f cppcomplete.tags --fields=+ai --C++-types=+p " . s:includedFiles)
	endif
	call s:UpdatehiddenBuffer()
	return 1
endfunction
function! s:AppendFromCheckpath()
	if (! s:GetIncludeFiles())
		return 0
	endif
	if has("win32") || has("win16") || has("dos16") || has("dos32")
		call s:AnotherLongCommandLinePatchForWindows()
		call system("ctags -n --language-force=C++ -a -f cppcomplete.tags --fields=+ai --C++-types=+p " . s:ctagsTemp)
	else
		call system("ctags -n --language-force=C++ -a -f cppcomplete.tags --fields=+ai --C++-types=+p " . s:includedFiles)
	endif
	call s:UpdatehiddenBuffer()
	return 1
endfunction

function! s:BrowseNFiles()
	if has("gui_running") 
		call s:CheckFiletype() 
	endif
	let browseFile=""
	let browseFile=browse(0, "File to include in cppcomplete.tags","./","")
	if (browseFile!="")
		if (s:currLanguage=="Java")
			call system("ctags -n -a -f cppcomplete.tags --fields=+ai " . browseFile)
		else
			call system("ctags -n -a -f cppcomplete.tags --fields=+ai --C++-types=+p " . browseFile)
		endif
		call s:UpdatehiddenBuffer()
	endif
endfunction
function! s:GenerateAndAppend()
	if has("gui_running") 
		call s:CheckFiletype() 
	endif
	if (s:currLanguage=="Java")
		call system("ctags -n -a -f cppcomplete.tags --fields=+ai *")
	else
		call system("ctags -n -a -f cppcomplete.tags --fields=+ai --C++-types=+p *")
	endif
	call s:UpdatehiddenBuffer()
	return 1
endfunction

" shows how the tags should be generated
function! s:GenerateTags()
	if has("gui_running") 
		call s:CheckFiletype() 
	endif
	if has("gui_running")
		if getftime("cppcomplete.tags")!=-1
			let dial=confirm("You already have a cppcomplete.tags file, do you really want to destroy it?", "&Yes, I really want to replace it\n&No, I keep the old one",2,"Warning")
			if (dial!=1)
				return 0
			endif
		endif
	endif
	if (s:currLanguage=="Java")
		execute "!ctags -n -f cppcomplete.tags --fields=+ai *"
	else
		execute "!ctags -n -f cppcomplete.tags --fields=+ai --C++-types=+p *"
	endif
	call s:UpdatehiddenBuffer()
	return 1
endfunction
