" Vim global plugin for completion of classes, structs and unions in C/C++
" This plugin helps you complete things like:
" variableName.abc
" variableName->abc
" typeName::abc
" from the members of the struct/class/union that starts with abc.
" After you have picked the member is the preview window updated so
" it will show the member. If only one match was found is the code
" completed without asking.
"
" The plugin is depending on that exuberant ctags has generated some tags with
" the same options as in the following example:
" ctags --C++-types=+p --extra=q *.h *.cpp *.cc
" The script has a command called GenerateTags that executes the above ctags
" command.  
" 
" The normal commands for the preview window works so this fits pretty well
" into vim. 
" F4 is imaped to the actual code completion and F5 for just showing the class
" in the preview window.
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
" If you aborted the completion or got an error will the preview window be closed. 
" For some reason will the script not return to insert mode automatically after 
" completion if the list has been displayed.
" This plugin does not understand any C/C++ code so it will just use gd and try to
" get the class name. It works surprisingly well but can of course show a surprising
" result. :)
" It tries to handle templates but inheritance is an unknown concept.
" If the program hides the type with a typedef or definition is the script clueless.
" Even if the preview window displays the correct information can the completion be
" wrong since the script has to guess.
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
		silent! execute "ptag " .  s:clType 
		silent! wincmd P
		if &previewwindow
			normal! zt
			silent! wincmd p
		endif
	endif
endfunction
function! s:SelComp()
	if &previewwindow		
      		return
	endif
	call s:GetPieces()
	if (s:gotCType)
		call s:SelectAndPut("/".s:clType."::".s:uTyped)
	endif
endfunction
function! s:CompletePat()
    	if &previewwindow	
      		return
    	endif
	let s:uTyped=""
	call s:SelectAndPut("")
endfunction
function! s:SelectAndPut(selectString)
	silent!  execute "pclose"
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
" I guess it has to be a better way?
function! s:ExpandCMember()
	wincmd P
	let lineP = line(".")
	if (s:uTyped!="")
		call search(s:uTyped)
		normal! "cyw
		if (search("(")==lineP)
			call search(s:uTyped, "b")
			normal! w
			normal! b
			normal! "cyw
		elseif (search(";")==lineP)
				call search(s:uTyped, "b")
				normal! w
				normal! b
				normal! "cyw
		endif
		exe lineP.'normal! '."1".'|'
	elseif (search("(")==lineP)
		normal! "cyb
	else 
		exe lineP.'normal! '."1".'|'
		if (search(";")==lineP)
			normal! "cyb
			normal! b
			let c = getline(line("."))[col(".") - 1]
			let done=(c!="]")
			while (! done)
				call search("[","b")
				normal! "cyb
				let done=search("]","b")==lineP
			endwhile
		else "panic :)
			exe lineP.'normal! '."1".'|'
			normal! w
			normal! "cyb
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

	normal! w
	normal! b
	call s:GetUserTyped()
	if (s:gotUTyped>0)
		call s:GetClassSep()
		if (s:gotCSep)
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
	if ((c == "-") || (c == ".") || (c==":") || (c==">"))
		let s:uTyped=""
	else
		let s:uTyped = expand("<cword>")
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
" Searching for the nearest "class", "struct" or "union" is probably more accurate
function! s:GetClassType()
	let lineT=line(".")
	let colT=virtcol(".")
	normal! gd		
	if ((virtcol(".") == colT) && (line(".") == lineT))
		normal! gD
		if ((virtcol(".") == colT) && (line(".") == lineT))
			return
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
					let c = getline(line("."))[col(".") - 1]
					normal! b
					let c2 = getline(line("."))[col(".") - 1]
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
" shows how the tags should be generated
function! s:GenerateTags() 
	silent! call system("ctags --C++-types=+p --extra=q *.h *.cpp *.cc")
endfunction

