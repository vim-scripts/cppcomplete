" Short Introduction: Call GenerateTags and press F4 for completion, F5 shows
" the class and shift+F4 for the same search.
" 
" A try to write some documentation:
" Vim global plugin for completion of classes, structs and unions in C/C++
" This plugin helps you complete things like:
" variableName.abc
" variableName->abc
" typeName::abc
" from the members of the struct/class/union that starts with abc.
" After you have picked the member is the preview window updated so
" it will show the member. If only one match was found is the code
" completed without asking. New in this version is that the access rules
" applies like this: 
" -> and . should only expand to public members
"  :: expands to private members for this class and protected for the ancestor
"  besides the public members
"
" The plugin is depending on that exuberant ctags has generated some tags with
" the same options as in the following example:
" ctags -f  cppcomplete.tags --extra=q --fields=aiK --C++-types=+p *
" The script has a command called GenerateTags that executes the above ctags
" command. The tag file cppcomplete.tags is 'local' to the script so you can
" use other tag files without affecting cppcomplete. If the search fails for
" cppcomplete.tags is the standard tag files used but without bothering
" about inheritance.
" 
" Vim stores the last argument used to display a tag in the 
" preview window. This script binds shift+F4 to a command that will 
" reuse the last argument in a code completion. Despite that the vim 
" documentation says is not the tag stack affected so you will
" only have one pattern.
" Pressing F4 has the side effect that the pattern is set to
" typeName::whatever_you_typed. This can be convenient, if you for
" example has typed typeName::<F4> do you get the member list
" again with <S-F4>
" The pattern can be set manually with :ptag /regex there regex 
" is a regular expression. Remember that if only one match is 
" found will it be inserted without prompting.
"
" BUGS/Features
" The more sophisticated search with inheritance is very slow. It should work
" OK for a small project but is useless for any real class library. 
" The script is using the standard tag functions from vim and this can lead to
" undesired results. 
" If you aborted the completion or got an error will the preview window be closed. 
" For some reason will the script not return to insert mode automatically after 
" completion if the list has been displayed.
" This plugin does not understand any C/C++ code so it will just use gd and try to
" get the class name. It works surprisingly well but can of course show a surprising
" result. :)
" Even if the preview window displays the correct information can the completion be
" wrong since the script is guessing.
" Does not (and should not) work if you are in a preview window
" For internal use is register c used.

" Commands 
command! -nargs=0 GenerateTags call s:GenerateTags()
command! -nargs=0 PreviewClass call s:PreCl()
command! -nargs=0 SelectCompletion call s:SelComp()
command! -nargs=0 CompletePattern call s:CompletePat()

" Mappings
imap <F4> <ESC>:SelectCompletion<CR>a
imap <S-F4> <ESC>:CompletePattern<CR>a
imap <F5> <ESC>:PreviewClass<CR>a

" The main functions
function! s:PreCl()
	if &previewwindow		
      		return
    	endif
	call s:GetPieces()
	if (s:gotCType)
		let tagsSav=&tags
		let &tags="./cppcomplete.tags" 
		" "." &tags
		silent! execute "ptag " .  s:clType 
		silent! wincmd P
		if &previewwindow
			normal! zt
			silent! wincmd p
		endif
		let &tags=tagsSav
	endif
endfunction
function! s:SelComp()
	if &previewwindow		
      		return
	endif
	silent! pclose
	silent! wincmd P
	if &previewwindow
		wincmd p
		return
	endif
	call s:GetPieces()
	if (s:gotCType)
		let tagsSav=&tags
		let &tags="./cppcomplete.tags"
		silent! execute "ped " . "cppcomplete.tags"
		let triesLeft=2
		while (triesLeft>0)
			let triesLeft=triesLeft-1
			call s:GetParents()
			call s:BuildMatchList()
			if (s:matchList=="")
				if (triesLeft>0 && s:GetTagsDef())
					if (s:isTypedef)
						if (! s:GetTypedef())
							let triesLeft=0
						endif
					elseif (! s:GetMacro())
						let triesLeft=0
					endif
				elseif (triesLeft>0)
					let triesLeft=0
				endif
				if (triesLeft==0)
					let &tags=tagsSav
					call s:SelectAndPut("/^".s:clType."::".s:uTyped)
				endif
			else
				let triesLeft=0
				call s:SelectAndPut(" /" . s:matchList)
				let &tags=tagsSav
			endif
		endwhile
	endif
endfunction
function! s:CompletePat()
    	if &previewwindow	
      		return
    	endif
	let s:uTyped=""
	let tagsSav=&tags
	let &tags="./cppcomplete.tags" . &tags
	call s:SelectAndPut("")
	let &tags=tagsSav
endfunction
function! s:SelectAndPut(selectString)
	silent!  pclose
	execute "ptjump" a:selectString 
	silent! wincmd P
	if &previewwindow
		normal! zt
		silent! wincmd p
	else
		return
	endif
	call s:ExpandCMember()
	if (s:uTyped!="")
		if (strlen(s:uTyped)>1)
			normal! db
		endif
		normal! x
	endif
	normal! "cp
endfunction

" ExpandCMember tries to guess the tag that the user selected
" It should be possible to use the match list but this is not implemented
function! s:ExpandCMember()
	wincmd P
	let lineP = line(".")
	if (s:uTyped!="")
		call search(s:uTyped)
		normal! "cyw
		if (search("(","W")==lineP)
			normal! v
			call search(s:uTyped, "b")
			normal! "cy
		else
			exe lineP.'normal! '."1".'|'
			let res=search("=","W")==lineP
			exe lineP.'normal! '."1".'|'
			if (res || search(";","W")==lineP)
				call search(s:uTyped, "b")
				normal! w
				normal! b
				normal! "cyw
			endif
		endif
		exe lineP.'normal! '."1".'|'
	elseif (search("(")==lineP)
		normal! v
		normal! b
		normal! h
		let c = getline(line("."))[col(".") - 1]
		if (c!="~")
			normal! l
		endif
		normal! "cy
	else 
		exe lineP.'normal! '."1".'|'
		if (search("=","W")==lineP)
			normal! "cyb
		else
			exe lineP.'normal! '."1".'|'
			if (search(";")==lineP)
				normal! b
				normal! "cyw
				let c = getline(line("."))[col(".") - 1]
				let done=(c!="]")
				while (! done)
					call search("[","bW")
					normal! "cyb
					let done=search("]","bW")!=lineP
				endwhile
			else "panic :)
				exe lineP.'normal! '."1".'|'
				normal! g_
			normal! b
			normal! "cyw
		endif
	endif
	endif	
	exe lineP.'normal! '."1".'|'
	" normal! zt
	wincmd p
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
" GetClassType moves back from the place there gd has jumped to
function! s:GetClassType(doTagJump)
	let lineT=line(".")
	let colT=virtcol(".")
	if (a:doTagJump)
		execute "tag " s:clType
		normal! $
		call search(s:clType, "bW")
	else
		normal! gd		
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
	call s:GetClassType(1)
	pop
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
	return 1
endfunction
" Get the ancestors, I do not think that ctags always gives a complete list
function! s:GetParents()
	silent! wincmd P
	let s:classPattern=s:clType
	let clName=s:clType
	let unsearched=""
	while &previewwindow
		normal! gg
		while (search("^" . clName . "::", "W")>0)
			normal! $
			let lineP=line(".")
			if (search("inherits","b")==lineP)
				normal! w
				let c=","
				while (c==",")
					normal! w
					normal! "cyw
					if (match(s:classPattern, "\\(:\\|^\\)" . @c . "\\(:\\|$\\)") <0)
						if (strlen(s:classPattern)>0)
							let s:classPattern  =s:classPattern . ":" . @c 
						else
							let s:classPattern=@c
						endif
						if (strlen(unsearched)>0)
							let unsearched=unsearched . ":" . @c 
						else
							let unsearched=@c
						endif
						normal! w
						let c = getline(line("."))[col(".") - 1]
					endif
				endwhile
				normal! G
			else
				exe lineP.'normal! '."1".'|'
			endif
		endwhile
		if (strlen(unsearched)<=0)
			wincmd p
		elseif (match(unsearched,":")>0)
			let clName=strpart(unsearched, 0, match(unsearched,":"))
			let unsearched=strpart(unsearched, matchend(unsearched,":"))
		else
			let clName=unsearched
			let unsearched=""
		endif
	endwhile
endfunction
" Build the regex expression 
function! s:BuildMatchList()
	silent! wincmd P
	while &previewwindow
		let firstHit=1
		let allAcc=s:colonSep
		let s:matchList=""
		while (strlen(s:classPattern)>0)
			normal! gg
			if (match(s:classPattern,":")>0)
				let currentClass=strpart(s:classPattern, 0, match(s:classPattern,":"))
				let s:classPattern=strpart(s:classPattern, matchend(s:classPattern,":"))
			else
				let currentClass=s:classPattern
				let s:classPattern=""
			endif
			while (search("^" . currentClass . "::" . "\\(<anonymous>::\\)*" . s:uTyped,"W")>0)
				call search("\t")
				normal! "cy^
				let candidate=substitute(@c,"\\~","\134\134~","g") ."$"
				if (match(candidate,"::", strlen(currentClass)+1)>0)
					if (match(candidate,"<anonymous>",strlen(currentClass)+1)<0)
						continue
					endif
				endif
				let lineP=line(".")
				let insertIt=0
				normal! $
				if (search("access","bW")==lineP)
					normal! w
					normal! w
					normal! "cyw
					if (@c=="public" || (@c=="protected" && s:colonSep) || allAcc)
						let insertIt=1
					 endif
				else
					let insertIt=1
					exe lineP.'normal! '."2".'|'
				endif
				if (firstHit && insertIt)
					let s:matchList=candidate
					let firstHit=0
				elseif insertIt
					let s:matchList=s:matchList . "\134\134|^" . candidate
				endif
			endwhile
			let allAcc=0
		endwhile
		wincmd p
	endwhile
endfunction
" Check for a typedef/macro in cppcomplete.tags
function! s:GetTagsDef()
	silent! wincmd P
	while &previewwindow
		normal! gg
		while (search("^" . s:clType . "\t", "W")>0)
			normal! $
			let lineP=line(".")
			if (search("typedef","Wb")==lineP)
				let s:isTypedef=1
				if (search("\t")!=lineP)
					wincmd p
					return 1
				endif
			endif
			exe lineP.'normal! '."1".'|'
			normal! $
			if (search("macro", "Wb")==lineP)
				let s:isTypedef=0
				if (search("\t")!=lineP)
					wincmd p
					return 1
				endif
			endif
			exe lineP.'normal! '."1".'|'
		endwhile
		wincmd p
	endwhile
	return 0
endfunction
	
" shows how the tags should be generated
function! s:GenerateTags() 
	silent! call system("ctags -f  cppcomplete.tags --extra=q --fields=aiK --C++-types=+p *")
endfunction

