" Introduction: Call GenerateTags and press F8/F9 for completions, F5 shows
" the class in a preview window. Only tested in GTK but there does Alt+l pops up
" a menu with the possible completions. If you are running gvim will you also see a
" new menu in the menu bar. 
" 
" A try to write some documentation:
" Vim global plugin for completion of classes, structs and unions in C/C++
" This plugin helps you complete things like:
" variableName.abc
" variableName->abc
" typeName::abc
" from the members of the struct/class/union that starts with abc.
"
" The script has a number of variables that can be set from the menu in the 
" GUI version. I should probably write something about them but <insert some good excuse>
" so you will have to try them and see what happens. They are at the top of the script if
" you want to change them more permanent.
" 
" The popup menu with the last results can be reached by pressing
" Alt+j or the right mouse button, selecting any item will paste the text.
"
" The plugin is depending on that exuberant ctags has generated some tags with
" the same options as in the following example:
" ctags -n -f cppcomplete.tags --fields=+ai --C++-types=+p *
" The script has a command called GenerateTags that executes the above ctags
" command. The tag file cppcomplete.tags is 'local' to the script so you can
" use other tag files without affecting cppcomplete. I know that another script also has
" a function called GenerateTags so make sure that the correct one is called.
" 

" BUGS/Features
" This plugin does not understand any C/C++ code so it will just use gd/gD and try to
" get the class name. It works surprisingly well but can of course give a surprising
" result. :)
" If the mouse leaves and then reenters the popup menu is the text cursor affected.
" Does not work under Windows. (grep, limited command line length, popup menu)
" The popup is displayed at the mouse position and not the text cursor position.
" For internal use is register c used.
" Requires exuberant ctags and gnu grep.
" + probably a lot of other issues


" Here is the variables that can be changed
"
" Search for typedefs?
let s:searchTDefs=1

" search for macros?
" this is not well supported
let s:searchMacros=0

" I have not tested to have anything else than 25 menu lines
let s:maxNMenuLines=25

" ctags sometimes miss to set the access so the check is disabled by default
let s:accessCheck=0

" if you only use local variables is it recommended that you set onlyGD to 0
" but this does not work for global variables so the default is on
let s:onlyGD=1

" I like the preview window but the default is not to display 
let s:showPreview=0


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
	command! -nargs=1 PreviewEntry call s:PreviewEntry(<f-args>)
	command! -nargs=0 ToggleAccess call s:ToggleAccess()
	command! -nargs=0 ToggleGD call s:ToggleGD()
	command! -nargs=0 TogglePreview call s:TogglePreview()
endif
command! -nargs=0 InsPrevHit call s:InsPrevHit()
command! -nargs=0 InsNextHit call s:InsNextHit()

" Mappings
imap <F5> <ESC>:PreviewClass<CR>a
if has("gui_running")
	imap <A-l> <ESC>:BuildMenu<CR><RightMouse>a
	imap <A-j> <ESC><RightMouse>a
endif
" I wanted to have the following mappings but could only set it in GUI mode
"	imap <A-p> <ESC>:InsPrevHit<CR>a
"	imap <A-n> <ESC>:InsNextHit<CR>a
"
" so I picked two function keys instead
imap <F8> <ESC>:InsNextHit<CR>a
imap <F9> <ESC>:InsPrevHit<CR>a

" some variables for internal use
let s:listAge=0
let s:lastHit=0
let s:hitList=""

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
	amenu &CppComplete.Re&build\ tags<Tab>:GenerateTags   :GenerateTags<CR>
	amenu &CppComplete.&Append\ file\ to\ tags<Tab>:BrowseNFiles   :BrowseNFiles<CR>
	amenu &CppComplete.&RestorePopUp<Tab>:RestorePopup :RestorePopup<CR>
endif

function! s:PreCl()
	if &previewwindow		
      		return
    	endif
	if ! s:CheckForTagFile()
		return
	endif
	call s:GetPieces()
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

function! s:InsertToTags()
	if (match(&tags, "cppcomplete.tags,",0)>=0)
		call confirm("cppcomplete.tags is already in tags","&Ok",1,"Info")
	else
		let &tags="cppcomplete.tags, " . &tags
	endif
endfunction
function! s:ClearFromTags()
	if (match(&tags,"cppcomplete.tags")<0)
		call confirm("tags did not include cppcomplete.tags","&Ok",1,"Info")
	else
		let &tags=substitute(&tags,"cppcomplete.tags.","","g")
	endif
endfunction

function! s:RefreshMenu()	
	if ! s:CheckForTagFile()
		return
	endif
	silent! aunmenu CppComplete.Preview.Classes
	silent! aunmenu CppComplete.Preview.Structures
	silent! aunmenu CppComplete.Preview.Unions
	let cf=0
	let sf=0
	let uf=0
	let spaceAfter="[^![:space:]]\\+[[:space:]]"
	let items=system("grep '^" . spaceAfter . spaceAfter . spaceAfter . "\\(c\\|s\\|u\\)' cppcomplete.tags")
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
			if (nclines%s:maxNMenuLines)==0
				let cMore=cMore . "More."
			endif
		elseif (ms>=0) && (ms<nextM)
			let sf=1
			execute "amenu .300 &CppComplete.&Preview.&Structures." . sMore . @c . " :PreviewEntry " . @c ."<CR>"
			let nslines=nslines+1
			if (nslines%s:maxNMenuLines)==0
				let sMore=sMore . "More."
			endif
		
		else
			let uf=1
			execute "amenu .400 &CppComplete.&Preview.&Unions." . uMore . @c . " :PreviewEntry " . @c ."<CR>"
			let nulines=nulines+1
			if (nulines%s:maxNMenuLines)==0
				let uMore=uMore . "More."
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
	let s:hitList=""
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
	while (match(s:matches,"\t",nextM)>0)
		let @c=strpart(s:matches, nextM, match(s:matches,"\t",nextM)-nextM)
		if (match(s:hitList,substitute(@c,"\\~", ":","g") . "\n")<0)
			if has("gui_running")
				execute "silent amenu PopUp." . pMore . @c . "  :let @c=\"" . @c ."\"<Bar>DoMenu<CR>"
			endif
			let s:hitList=s:hitList . substitute(@c,"\\~", ":","g") . "\n"
			let s:nHits=s:nHits+1
			let line=line+1
			if (line%s:maxNMenuLines)==0
				let pMore=pMore . "More."
			endif
		endif
		let nextM=matchend(s:matches,"\n",nextM)
		if nextM<0
			let nextM=strlen(s:matches)
		endif
	endwhile
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
		call s:BuildMenu()
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
		call s:BuildMenu()
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
	
function! s:BuildMenu()
	let s:nHits=0
	if ! s:CheckForTagFile()
		return
	endif
	call s:GetPieces()
	if (s:gotCType)
		let triesLeft=2
		let spaceAfter="[^![:space:]]\\+[[:space:]]"
		let after3=spaceAfter . spaceAfter . spaceAfter

		while (triesLeft>0)
			let triesLeft=triesLeft-1
			if (s:listAge!=getftime("cppcomplete.tags"))
				let s:inheritsList=system("grep '^" . after3 . ".*" ."inherits:.*' cppcomplete.tags")
				let s:listAge=getftime("cppcomplete.tags")
			endif
			call s:GetParents()
			let firstPart=s:uTyped . after3 . ".*\\(class:\\|struct:\\|union:\\)"
			if ! s:colonSep
				if s:accessCheck
					let secondPart=".*access:public' cppcomplete.tags"
				else
					let secondPart=".*' cppcomplete.tags"
				endif
			elseif s:accessCheck
				let secondPart=".*access:\\(public\\|protected\\)\\|"
			else
				let secondPart=".*\\|"
			endif
			if s:colonSep
				let s:matches=system("grep '^\\(" . firstPart . s:classList . secondPart . firstPart . s:clType . "\\)' cppcomplete.tags")
			else
				let s:matches=system("grep '^" . firstPart . s:classList . secondPart)
			endif
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
				call s:GetClassType(0)
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
	else
		if (c==">")
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
						elseif (c="<")
							let nangle=nangle-1
						endif
					endwhile
					normal! b
				endif
			endif
		endif
	endif
endfunction
" GetClassType moves back from the place there gd has jumped to and tries to
" determine the class type
function! s:GetClassType(doTagJump)
	let lineT=line(".")
	let colT=virtcol(".")
	let s:innerStruct=0
	if (a:doTagJump)
		execute "tag " s:clType
		normal! $
		call search(s:clType, "bW")
	else
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
			if (line(".")!=lineT)
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
				return
			endif
		endif
		normal! w
		if (! s:onlyGD)
			normal! gd		
		endif
		if ((virtcol(".") == colT) && (line(".") == lineT))
			normal! gD
			if ((virtcol(".") == colT) && (line(".") == lineT))
				return
			endif
		endif
	endif
	while (line(".")>1)
		normal! b
		let c = getline(line("."))[col(".") - 1]

		if (c == ")")
			normal! [(
			normal! b
			continue
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
						if (c2==":")
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
" If a typedef was used
function! s:GetTypedef()
	let oldClType=s:clType
	let tagsSav=&tags
	let &tags="cppcomplete.tags" 
	call s:GetClassType(1)
	pop
	let &tags=tagsSav
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
	let tagsSav=&tags
	let &tags="cppcomplete.tags" 
	execute "tag " s:clType
	normal! w
	normal! w
	normal! w
	let s:clType=expand("<cword>")
	if (s:clType=="class" || s:clType=="struct" || s:clType=="union")
		normal! w
		let s:clType=expand("<cword>")
	endif
	pop
	let &tags=tagsSav
	return 1
endfunction
" Get the ancestors, I do not think that ctags always gives a complete list
function! s:GetParents()
	let s:classList=s:clType
	let clName=s:clType
	let unsearched=""
	let done=0
	if (s:innerStruct)
		let s:classList=".*::" . s:clType . "\\([^:]\\|::<anonymous>\\)"
		return
	endif
	while ! done
		let nextM=0
		while (match(s:inheritsList,"\\(\n\\|^\\)" . clName . "\t", nextM)>=0)
			let inhLine=strpart(s:inheritsList, nextM, match(s:inheritsList,"\n",nextM)-nextM)
			let i2=matchend(inhLine, "[^\t]*\t[^\t]*\t[^\t]*\t.*inherits:", 0)
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
				let s:classList=s:classList . "\\|" . @c
				if (strlen(unsearched)>0)
					let unsearched=unsearched . ":" . @c 
				else
					let unsearched=@c
				endif
				let c=strpart(inhLine, i,1)
				let i2=i+1
			endwhile
			let nextM=matchend(s:inheritsList,"\n",nextM)
			if nextM<0
				let nextM=strlen(s:inheritsList)
			endif
		endwhile
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
	let s:classList="\\(" . s:classList . "\\)\\([^:]\\|::<anonymous>\\)"
endfunction

" Check for a typedef/macro in cppcomplete.tags
function! s:GetTagsDef()
	let spaceAfter="[^![:space:]]\\+[[:space:]]"
	if (s:searchTDefs)
		let s:matches=system("grep '^" . s:clType . "[[:space:]]" . spaceAfter . spaceAfter . "t' cppcomplete.tags")
		if (s:matches!="")
			return s:GetTypedef()
		endif
	endif
	if (s:searchMacros)
		let s:matches=system("grep '^" . s:clType . "[[:space:]]" . spaceAfter . spaceAfter . "d' cppcomplete.tags")
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
function! s:BrowseNFiles()
	let browseFile=""
	let browseFile=browse(0, "File to include in cppcomplete.tags","./","")
	if (browseFile!="")
		call system("ctags -n -a -f cppcomplete.tags --fields=+ai --C++-types=+p " . browseFile)
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
	call system("ctags -n -f cppcomplete.tags --fields=+ai --C++-types=+p *")
endfunction
