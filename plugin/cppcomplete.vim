" This plugin helps you complete things like:
" variableName.abc
" variableName->abc
" typeName::abc
" from the members of the struct/class/union that starts with abc.
"
" The default key mapping to complete the code are:
" Alt+l in insert mode will try to find the possible completions and display
" them in a popup menu.
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
" For use with a real external class library do you have to generate
" cppcomplete.tags so that it is a valid tags file. The script is also using the
" file for jumps. It will probably be a pretty big file but grep lookups are
" very fast so the performance should be OK. Worse is that the namespace will 
" be cluttered with a lot of identifiers. 
" Java users do not need the --C++-types flag.
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
" BuildBlockFromRegexp is a thin layer above grep. Use the tab key for tab. :)
" Some simple examples there > is the prompt:
" >class:l
" Gives a block with all members that has a scope of a class beginning with l
" >^a.*<Tab>s<Tab>
" all structures beginning with an a
" >^\(a\|b\|c)
" Everything that starts with a,b or c
" The full vim history mechanism can be used.
"
" The script has a number of variables that can be set from the menu in the 
" GUI version. They are at the top of the script file with descriptions if
" you want to change them more permanent. Windows users must change one and
" probably both of the first two configuration variables.
"
" For Java do you probably want to generate a cppcomplete.tags file from the
" sources of the Java SDK. The use is like with C/C++ but you will get a
" better result if you change some of the configuration variables.
" The default access is treated as if it was public.
 

" BUGS/Features
" This plugin does not really understand any C/C++ code so it will just use gd/gD
" combined with lookups in the tag file together with some simple rules trying to 
" get the class name. It is not a real parser.
" It works surprisingly well but can of course give a surprising result. :)
" The current scope is unknown.
" The script makes the assumption that the inherited stuff is given with real
" type names and not anything else like typedefs.
" Multidimensional arrays should not have a space between ][, eg.
" xyz[1][2].abc should be OK but not xyz[1] [2].abc
" Even if typedef search is enabled is it only one level deep so nested
" typedefs will fool cppcomplete.
" The script does not accept functions, eg. xyc()->abc will not be completed
" The vim documentation warns about the :popup command on Windows but it works
" perfectly here so I really do not know why.
" I got a command window popping up every time grep is called under Windows.
" (GTK) If the mouse leaves and then reenters the popup menu is the text cursor affected.
" (GTK) The popup is displayed at the mouse position and not the text cursor position.
" For internal use is register c used.
" Requires exuberant ctags and grep.
" The only tested platforms are GTK (linux) and Windows with DJGPP grep.
" + probably a lot of other issues
"
" Anyway, I have done some testing with MFC, DX9 framework (not COM), Java SDK, STL with
" good results.


" Here is the configuration variables.
"
" The following two options only applies to Windows.
" If you are using command.com as the shell is the command line length limited
" to 126 characters. This script needs more but grep from DJGPP supports
" longer lines by a response file method. If you are using another shell
" could perhaps other grep programs be used but you should confirm that
" :!grep works from vim. 
" I have only tested it with DJGPP grep under Windows.
let s:useDJGPP=0

" This is the only way to get a popup menu under Windows so it should always
" be set.
let s:useWinMenu=0

" The rest is platform independent.
" Search for typedefs?
let s:searchTDefs=1

" search for macros?
" this is not well supported
let s:searchMacros=0

" I have not tested to have anything else than 25 menu lines, not used under
" Windows.
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
let s:lastHit=0
let s:hitList=""
let s:regexBlock=""

" build the gui menu
if has("gui_running")
	set mousemodel=popup
	silent! aunmenu CppComplete
	amenu .100 &CppComplete.&Preview.Scan\ for\ new\ &items<Tab>:RefreshMenu   :RefreshMenu<CR>
	amenu .200 &CppComplete.&Preview.&Classes.*****\ \ \ Nothing\ yet\ \ \ *****   <NOP>
	amenu .300 &CppComplete.&Preview.&Structures.*****\ \ \ Nothing\ yet\ \ \ ******   <NOP>
	amenu .400 &CppComplete.&Preview.&Unions.*****\ \ \ Nothing\ yet\ \ \ *****   <NOP>
	amenu &CppComplete.&Use\ generated\ tag\ file\ in\ tags.&No<TAB>:ClearFromTags   :ClearFromTags<CR>
	amenu &CppComplete.&Use\ generated\ tag\ file\ in\ tags.&Yes<Tab>:InsertToTags   :InsertToTags<CR>
	amenu &CppComplete.&Toggle.&Typedefs<Tab>:ToggleTDefs   :ToggleTDefs<CR>
	amenu &CppComplete.&Toggle.&Macros<Tab>:ToggleMacros   :ToggleMacros<CR>
	amenu &CppComplete.&Toggle.&Access\ check<Tab>:ToggleAccess  :ToggleAccess<CR>
	amenu &CppComplete.&Toggle.&gd<Tab>:ToggleGD   :ToggleGD<CR>
	amenu &CppComplete.&Toggle.&Preview<Tab>:TogglePreview   :TogglePreview<CR>
	amenu &CppComplete.&Toggle.&Relaxed\ ancestor\ check<Tab>:ToggleRelaxed   :ToggleRelaxed<CR>
	amenu &CppComplete.&Toggle.Global\ &variables<Tab>:ToggleGlobalVars  :ToggleGlobalVars<CR>
	amenu &CppComplete.&Toggle.&Classes\ as\ class\ members<Tab>:ToggleClassMembers  :ToggleClassMembers<CR>
	amenu &CppComplete.&Toggle.Class\ &names\ tags<Tab>:ToggleClassTags  :ToggleClassTags<CR>
	amenu &CppComplete.&Toggle.Restrict\ p&ossible\ types<Tab>:ToggleRestricted  :ToggleRestricted<CR>
	amenu &CppComplete.&Toggle.&Fast\ grep<Tab>:ToggleFastGrep  :ToggleFastGrep<CR>
	amenu &CppComplete.&Toggle.&Show\ access<Tab>:ToggleShowAccess  :ToggleShowAccess<CR>
	amenu &CppComplete.&Toggle.&Inheritance\ for\ ::<Tab>:ToggleInheritance  :ToggleInheritance<CR>
	amenu &CppComplete.&GenerateTags.Re&build\ tags<Tab>:GenerateTags   :GenerateTags<CR>
	amenu &CppComplete.&GenerateTags.&Append\ to<Tab>:GenerateAndAppend   :GenerateAndAppend<CR>
	amenu &CppComplete.&GenerateTags.&Browse\ file\ to\ append<Tab>:BrowseNFiles   :BrowseNFiles<CR>
	amenu &CppComplete.S&et\ C/C++\ or\ Java<Tab>:SetLanguage   :SetLanguage<CR>
	amenu &CppComplete.Set\ max\ number\ of\ &hits\ displayed<Tab>:SetMaxHits   :SetMaxHits<CR>
	amenu &CppComplete.&Show\ current\ settings<Tab>ShowCurrentSettings   :ShowCurrentSettings<CR>
	amenu &CppComplete.-SEP1-   <NOP>
	amenu &CppComplete.&Build\ Menu\ From\ Block<Tab>:BuildMenuFromBlock   :BuildMenuFromBlock<CR>
	amenu &CppComplete.-SEP2-   <NOP>
	amenu &CppComplete.&RestorePopUp<Tab>:RestorePopup :RestorePopup<CR>
endif

function! s:PreCl()
	if &previewwindow		
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
	call confirm(cText,"&Ok",1,"Info")
endfunction
function! s:ToggleAccess()
	let s:accessCheck=!s:accessCheck
	if s:accessCheck
		let cText="Access check enabled"
	else
		let cText="Access check disabled"
	endif
	call confirm(cText, "&Ok",1,"Info")
endfunction
function! s:ToggleTDefs()
	let s:searchTDefs=!s:searchTDefs
	if (s:searchTDefs)
		let cText="Typedefs is now included in the search"
	else
		let cText="Further searches will not look for typedefs"
	endif
	call confirm(cText,"&Ok",1,"Info")
endfunction
function! s:ToggleMacros()
	let s:searchMacros=!s:searchMacros
	if (s:searchMacros)
		let cText="Macros is now included in the search"
	else
		let cText="Further searches will not look for macros"
	endif
	call confirm(cText,"&Ok",1,"Info")
endfunction
function! s:ToggleRelaxed()
	let s:relaxedParents=! s:relaxedParents
	if s:relaxedParents
		let cText="Ancestor check is now set to relaxed"
	else
		let cText="Strict ancestor check is now enabled"
	endif
	call confirm(cText, "&Ok",1,"Info")
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
	call confirm(cText, "&Ok",1, "Info")
endfunction
function! s:ToggleClassTags()
	let s:searchClassTags=! s:searchClassTags
	if s:searchClassTags
		let cText="Search for class names is enabled"
	else
		let cText="No search for class names"
	endif
	call confirm(cText, "&Ok",1, "Info")
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
	call confirm(cText, "&Ok",1, "Info")
endfunction
function! s:ToggleFastGrep()
	if (s:grepPrg=="grep")
		let s:grepPrg="grep --mmap"
		let cText="Fast GNU grep enabled"
	else
		let s:grepPrg="grep"
		let cText="Standard grep is now used"
	end
	call confirm(cText, "&Ok",1, "Info")
endfunction
function! s:ToggleInheritance()
	let s:colonNoInherit=! s:colonNoInherit
	if s:colonNoInherit
		let cText=":: will not show items from the ancestors"
	else
		let cText=":: will show the whole scope with items from the ancestors"
	endif
	call confirm(cText, "&Ok",1, "Info")
endfunction
function! s:ToggleShowAccess()
	let s:showAccess=! s:showAccess
	if s:showAccess
		let cText="Access information will be displayed if available on the popup menu"
	else
		let cText="No access information will be displayed"
	endif
	call confirm(cText, "&Ok",1, "Info")
endfunction
function! s:ToggleGlobalVars()
	let s:searchGlobalVars=! s:searchGlobalVars
	if s:searchGlobalVars
		let cText="Search for global variables is enabled"
	else
		let cText="No search for global variables"
	endif
	call confirm(cText, "&Ok",1, "Info")
endfunction
function! s:InsertToTags()
	if (match(&tags, "cppcomplete.tags,",0)>=0)
		call confirm("cppcomplete.tags is already in tags","&Ok",1,"Info")
	else
		let &tags="cppcomplete.tags," . &tags
	endif
endfunction
function! s:ClearFromTags()
	if (match(&tags,"cppcomplete.tags")<0)
		call confirm("tags did not include cppcomplete.tags","&Ok",1,"Info")
	else
		let &tags=substitute(&tags,"cppcomplete.tags.","","g")
	endif
endfunction

function! s:SetGrepArg(argtxt)
	silent! call delete("greparg.tmp")
	split
	silent! execute "silent! edit greparg.tmp"
	let @c=a:argtxt
	normal! "cp
	silent! w
	silent! bd
endfunction
function! s:RefreshMenu()	
	if ! s:CheckForTagFile()
		return
	endif
	let spaceAfter="[^!\t]\\+[\t]"
	let res=confirm("If you have a big cppcomplete.tags file may strange things happen", "&All\n&Just items in the current directory\n&Cancel",2,"Warning")
	if res==1
		let fileSelect=spaceAfter
	elseif res==3
		return
	else
		let fileSelect="[^\\/\t]\\+[\t]"
	endif
	silent! aunmenu CppComplete.Preview.Classes
	silent! aunmenu CppComplete.Preview.Structures
	silent! aunmenu CppComplete.Preview.Unions
	let cf=0
	let sf=0
	let uf=0
	if s:useDJGPP
		call s:SetGrepArg("'^" . spaceAfter . fileSelect . spaceAfter . "\\(c\\|s\\|u\\)' cppcomplete.tags")
		silent! let items=system(s:grepPrg . " @greparg.tmp")
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
			execute "amenu .200 &CppComplete.&Preview.&Classes." . cMore . @c . " :PreviewEntry " . @c ."<CR>" 
			let nclines=nclines+1
			if (! s:useWinMenu)
				if (nclines%s:maxNMenuLines)==0
					let cMore=cMore . "More."
				endif
			endif
		elseif (ms>=0) && (ms<nextM)
			let sf=1
			execute "amenu .300 &CppComplete.&Preview.&Structures." . sMore . @c . " :PreviewEntry " . @c ."<CR>"
			let nslines=nslines+1
			if (! s:useWinMenu)
				if (nslines%s:maxNMenuLines)==0
					let sMore=sMore . "More."
				endif
			endif

		else
			let uf=1
			execute "amenu .400 &CppComplete.&Preview.&Unions." . uMore . @c . " :PreviewEntry " . @c ."<CR>"
			let nulines=nulines+1
			if (! s:useWinMenu)
				if (nulines%s:maxNMenuLines)==0
					let uMore=uMore . "More."
				endif
			endif

		endif
	endwhile
	if cf==0
		amenu &CppComplete.&Preview.&Classes.*****\ \ \ no\ classes\ found\ \ \ ***** <NOP>
	endif
	if sf==0
		amenu &CppComplete.&Preview.&Structures.*****\ \ \ no\ structures\ found\ \ \ ***** <NOP>
	endif
	if uf==0
		amenu &CppComplete.&Preview.&Unions.*****\ \ \ no\ unions\ found\ \ \ ***** <NOP>
	endif
endfunction

function! s:BuildMenuFromBlock()
	if s:regexBlock==""
		call confirm("No block to build the menu from.\nYou must first create the block with the\n:BuildBlockFromRegexp command.","&Ok",1,"Error")
		return
	endif
	silent! aunmenu CppComplete.Preview.Regexp
	let spaceAfter="[^!\t]\\+[\t]"
	let nLines=0
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
		execute "amenu &CppComplete.&Preview.Regexp." . bMore . group . @c . " :JumpToLineInBlock " . nLines . "<CR>"
	endwhile
	if nLines==0
		call confirm("Could not build the menu", "&Ok",1,"Error")
	else
		call confirm("A menu with " . nLines . " items has been built.\nIt is placed under the Preview submenu", "&Ok", 1, "Info")
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
	let s:lastMatches=""
	if (s:matches=="")
		if has("gui_running")
			amenu PopUp.****\ \ no\ completions\ found\ \ *****   :let @c=''<CR>
		endif
		return
	endif
	let nextM=0
	let line=1
	let pMore=""

	while (s:tooBig>s:nHits) && (match(s:matches,"\t",nextM)>0)
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
			call confirm( qStr, "&Ok", 1,"Warning")
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
		normal! h
		normal! h
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
	let spaceAfter="[^!\t]\\+[\t]"
	let after3=spaceAfter . spaceAfter . spaceAfter
	if (s:listAge!=getftime("cppcomplete.tags"))
		if s:useDJGPP
			call s:SetGrepArg("'^" . after3 . ".*" ."inherits:.*' cppcomplete.tags")
			silent! let s:inheritsList="\n" . system(s:grepPrg . " @greparg.tmp")
		else
			let s:inheritsList="\n" . system(s:grepPrg . " '^" . after3 . ".*" ."inherits:.*' cppcomplete.tags")
		endif
		let s:listAge=getftime("cppcomplete.tags")
	endif
endfunction
function! s:BuildMenu()
	let s:nHits=0
	if ! s:CheckForTagFile()
		return
	endif
	let oldParents=s:relaxedParents
	call s:GetPieces()
	if (s:gotCType)
		let triesLeft=2
		let spaceAfter="[^!\t]\\+[\t]"
		let after3=spaceAfter . spaceAfter . spaceAfter

		while (triesLeft>0)
			let triesLeft=triesLeft-1
			call s:UpdateInheritList()
			let accSav=s:accessCheck
			if s:colonSep && s:colonNoInherit
				let s:classList=s:clType . "[\t]"
				let s:accessCheck=0
				let s:colonSep=0
			else
				call s:GetParents()
			endif
			if s:justInteresting
				let interesting="\\(c\\|m\\|p\\|s\\|u\\)[\t]"
			else
				let interesting=""
			endif
			let firstPart=s:uTyped . after3 . interesting . ".*\\(class:\\|struct:\\|union:\\)"
			if ! s:colonSep
				if s:accessCheck
					if s:currLanguage=="Java"
						let secondPart=".*access:\\(default\\|public\\)' cppcomplete.tags"
					else
						let secondPart=".*access:public' cppcomplete.tags"
					endif
				else
					let secondPart=".*' cppcomplete.tags"
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
			if s:colonSep
				if (s:useDJGPP)
					call s:SetGrepArg("'^\\(" . firstPart . s:classList . secondPart . firstPart . s:clType . "\\)' cppcomplete.tags")
					silent! let s:matches=system(s:grepPrg . " @greparg.tmp")
				else
					let s:matches=system(s:grepPrg . " '^\\(" . firstPart . s:classList . secondPart . firstPart . s:clType . "\\)' cppcomplete.tags")
				endif

			else
				if s:useDJGPP
					call s:SetGrepArg("'^" . firstPart . s:classList . secondPart)
					silent! let s:matches=system(s:grepPrg . " @greparg.tmp")
				else
					let s:matches=system(s:grepPrg . " '^" . firstPart . s:classList . secondPart)
				endif
			endif
			let s:accessCheck=accSav
			if (triesLeft>0) && (s:matches=="")
				if (! s:GetTagsDef())
					let triesLeft=0
					call s:BuildIt()
				endif
			else
				call s:BuildIt()
				let triesLeft=0
			endif
		endwhile
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
		call s:GetClassSep()
		if (s:gotCSep)
			let s:innerStruct=0
			if (s:colonSep)
				let s:clType=expand("<cword>")
				let s:gotCType=(s:clType!="")
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
	normal! w
	normal! b
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
	let hasTagJumped=s:JumpToDecl()
	if (hasTagJumped==-1)
		return
	endif
	call s:GetType()
	if hasTagJumped
		quit
"		pop
	endif
endfunction
" GetClassType moves back from the place there gd has jumped to and tries to
" determine the class type
function! s:JumpToDecl()
	let lineT=line(".")
	let colT=virtcol(".")
	let s:innerStruct=0
	if s:searchGlobalVars || s:searchClassMembers || s:searchClassTags
		call s:DoGlobalJump()
		if s:gotCType
			return -1
		endif
	endif
	if ((virtcol(".") == colT) && (line(".") == lineT))
		normal! b
		let c = getline(line("."))[col(".") - 1]
		if (c==".") || (c=="-") || (c==":")
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
				normal! mc
				let newLine=line(".")
				if (search("//","bW")==newLine)
					let lucky=0
				endif
				normal! 'c
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
			normal! [(
			normal! b
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
			normal! [{
			normal! b
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
						normal! mc
						let newLine=line(".")
						if (search("//","bW")==newLine)
							let c2="x"
						else
							let c2 = getline(line("."))[col(".") - 1]
						endif
						normal! 'c
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
	normal! mc
	normal! gd
	if s:IsInsane()
		normal! 'c
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
function! s:GetTypedef()
	let oldClType=s:clType
	let s:gotCType=0
	let lEnd=match(s:matches, "\n") 
	if lEnd<0
		let lEnd=strlen(s:matches)
	endif
	split
	call s:DoTagLikeJump(strpart(s:matches, 0, lEnd))
	call search(s:clType)
	call s:GetType()
	quit
	if (! s:gotCType)
		let s:gotCType=1
		let s:clType=oldClType
		return 0
	else
		return 1
	endif
endfunction
" a simple approach for macros
function! s:GetMacro()
	let lEnd=match(s:matches, "\n") 
	if lEnd<0
		let lEnd=strlen(s:matches)
	endif
	split
	call s:DoTagLikeJump(strpart(s:matches, 0, lEnd))
	execute "tag " s:clType
	normal! w
	normal! w
	normal! w
	let s:clType=expand("<cword>")
	if (s:clType=="class" || s:clType=="struct" || s:clType=="union")
		normal! w
		let s:clType=expand("<cword>")
	endif
	quit
	return 1
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
				let i=match(inhLine,",",i2)
				if (i==-1)
					let i=match(inhLine, "\t",i2)
					if (i==-1)
						let i=strlen(inhLine)
					endif
				endif
				let @c=strpart(inhLine,i2,i-i2)
				if  match(searched,":" . @c . ":")<0
					let searched=searched . ":" . @c . ":"
					let s:classList=s:classList . "\\|" . @c
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
			let s:classList="\\([^\\.]*\\.\\)\\(.*\\." . s:clType . rest . "\\)\\(\\.<anonymous>\\)*[\t]"
		else
			let s:classList="\\([^:]*::\\)*\\(.*::" . s:clType . rest . "\\)\\(::<anonymous>\\)*[\t]"
		endif
	elseif s:currLanguage=="Java"
		if s:relaxedParents
			let s:classList="\\([^\\.]*\\.\\)*\\(" . s:classList . "\\)\\(\\.<anonymous>\\)*[\t]"
		else
			let s:classList="\\(<anonymous>.\\)*\\(" . s:classList . "\\)\\(\\.<anonymous>\\)*[\t]"
		endif
	else
		if s:relaxedParents
			let s:classList="\\([^:]*::\\)*\\(" . s:classList . "\\)\\(::<anonymous>\\)*[\t]"
		else
			let s:classList="\\(<anonymous>::\\)*\\(" . s:classList . "\\)\\(::<anonymous>\\)*[\t]"
		endif
	endif
" Uncommenting the following line can be useful if you have hacked the script but breaks the popup in GTK.
"	 echo s:classList ."\n"
endfunction
function! s:JumpToLineInBlock(n)
	if s:regexBlock==""
		if has("gui_running") 
			call confirm("The current block is empty","&Ok",1,"Error")
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
		silent! aunmenu CppComplete.Preview.Regexp
	endif
	let s:nLinesInBlock=0
	let s:currInBlock=0
	if (a:regex=="")
		return
	endif
	if s:useDJGPP
		call s:SetGrepArg("'" . a:regex ."' cppcomplete.tags")
		let s:regexBlock=system(s:grepPrg . " @greparg.tmp |" . s:grepPrg . " '^[^!]'")
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
	execute "edit! " . jFile
	execute jEX
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
	let spaceAfter="[^!\t]\\+[\t]"
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
	if s:useDJGPP
		call s:SetGrepArg("'^" . searchFor . "[\t]" . spaceAfter . spaceAfter . tStr . "' cppcomplete.tags")
		silent! let foundIt=system(s:grepPrg . " @greparg.tmp")
	else
		let foundIt=system(s:grepPrg . " '^" . searchFor . "[\t]" . spaceAfter . spaceAfter . tStr . "' cppcomplete.tags")
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
" Check for a typedef/macro in cppcomplete.tags
function! s:GetTagsDef()
	let spaceAfter="[^!\t]\\+[\t]"
	if (s:searchTDefs)
		if s:useDJGPP
			call s:SetGrepArg("'^" . s:clType . "[\t]" . spaceAfter . spaceAfter . "t' cppcomplete.tags")
			silent! let s:matches=system(s:grepPrg . " @greparg.tmp")
		else
			let s:matches=system(s:grepPrg . " '^" . s:clType . "[\t]" . spaceAfter . spaceAfter . "t' cppcomplete.tags")
		endif
		if (s:matches!="")
			return s:GetTypedef()
		endif
	endif
	if (s:searchMacros)
		if s:useDJGPP
			call s:SetGrepArg("'^" . s:clType . "[\t]" . spaceAfter . spaceAfter . "t' cppcomplete.tags")
			silent! let s:matches=system(s:grepPrg . " @greparg.tmp")
		else
			let s:matches=system(greparg . " '^" . s:clType . "[\t]" . spaceAfter . spaceAfter . "d' cppcomplete.tags")
		endif
		if (s:matches!="")
			return s:GetMacro()
		endif
	endif
	return 0
endfunction
function! s:CheckForTagFile()
	if getftime("cppcomplete.tags")==-1
		call confirm("No cppcomplete.tags found","&Ok",1,"Error")
		return 0
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
		call confirm(setStr, "&Ok",1,"Info")
	endif
endfunction
function! s:BrowseNFiles()
	let browseFile=""
	let browseFile=browse(0, "File to include in cppcomplete.tags","./","")
	if (browseFile!="")
		if (s:currLanguage=="Java")
			call system("ctags -n -a -f cppcomplete.tags --fields=+ai " . browseFile)
		else
			call system("ctags -n -a -f cppcomplete.tags --fields=+ai --C++-types=+p " . browseFile)
		endif
	endif
endfunction
function! s:GenerateAndAppend()
	if (s:currLanguage=="Java")
		call system("ctags -n -a -f cppcomplete.tags --fields=+ai *")
	else
		call system("ctags -n -a -f cppcomplete.tags --fields=+ai --C++-types=+p *")
	endif
endfunction

" shows how the tags should be generated
function! s:GenerateTags()
	if has("gui_running")
		if getftime("cppcomplete.tags")!=-1
			let dial=confirm("You already have a cppcomplete.tags file, do you really want to destroy it?", "&Yes, I really want to replace it\n&No, I keep the old one",2,"Warning")
			if (dial!=1)
				return
			endif
		endif
	endif
	if (s:currLanguage=="Java")
		execute "!ctags -n -f cppcomplete.tags --fields=+ai *"
	else
		execute "!ctags -n -f cppcomplete.tags --fields=+ai --C++-types=+p *"
	endif
endfunction
