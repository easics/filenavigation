if exists("loaded_alternateFile")
  finish
endif
let loaded_alternateFile = 1

func! AlternateFile(splitWindow, ...)
  let alternates = { 'vhd': [ ':@_ent.vhd', ':@_rtl.vhd', '@_str.vhd',
                   \          '@_ms.vhd', '@_beh.vhd', '@_systemc.vhd',
                   \          '@_ENT.vhd', '@_RTL.vhd', '@_STRUCT.vhd',
                   \          '@_tsmc040.vhd', '@_xilinx.vhd', '@.ari',
                   \          '@_series7.vhd', '@.e.vhdl', '@.a.vhdl',
                   \          '@_str.a.vhdl', '@_str.m.vhdl'],
                   \ 'ari' : [ '@_ent.vhd', '@_rtl.vhd', '@_str.vhd',
                   \           '@.v'],
                   \ 'vhdp':[ ':pck_@_body.vhd', ':pck_@.vhd',
                   \          'PCK_@_BODY.vhd', 'PCK_@.vhd' ],
                   \ 'c':   [ ':@.h', ':@.C', '@.c', '@.cpp', '@.cc', '@.hpp',
                   \          '@.virext', '@.tpp' ],
                   \ 'lex': [ ':@\.l', ':@\.y' ],
                   \ 'v':   [ ':@.ari', '@.v' ]}
  let currentFile = expand("%")
  let oldic = &ic
  set noic
  " find which group the current file is in
  for key in keys(alternates)
    let i=0
    let value = alternates[key]
    for pattern in value
      if pattern[0] == ':'
        let filepat=pattern[1:]
      else
        let filepat=pattern
      endif
      let filepat = substitute(filepat, "@", '\\(.*\\)', "")
      let matches = matchlist(currentFile, '^'.filepat.'$')
      if !empty(matches)
        let filebase=matches[1]
        " go through other endings
        let e = 1
        while e < len(value)
          let filepat2=value[(i+e) % len(value)]
          if filepat2[0] == ':'
            let filepat2 = filepat2[1:]
          endif
          let file = substitute(filepat2, "@", filebase, "")
          let buforfile = BufferOrFileExists(file)
          if buforfile != ""
            call FindOrCreateBuffer(buforfile, a:splitWindow)
            let &ic = oldic
            return
          endif
          let e = e + 1
        endwhile
      endif
      let i=i+1
    endfor
    " alternate file or buffer did not exist
    " check if we can create a new primary alternate
    let i=0
    for pattern in value
      if pattern[0] == ':'
        let filepat=pattern[1:]
      else
        continue
      endif
      let filepat = substitute(filepat, "@", '\\(.*\\)', "")
      let matches = matchlist(currentFile, '^'.filepat.'$')
      if !empty(matches)
        let filebase=matches[1]
        " go through other endings
        let e = 1
        while e < len(value)
          let filepat2=value[(i+e) % len(value)]
          if filepat2[0] != ":"
            let e = e + 1
            continue
          endif
          let filepat2 = filepat2[1:]
          let file = substitute(filepat2, "@", filebase, "")
          call FindOrCreateBuffer(file, a:splitWindow)
          let &ic = oldic
          return
        endwhile
      endif
      let i = i + 1
    endfor
  endfor
  let &ic = oldic
  " nothing found ??
  echo "AlternameFile: unknown file type `".currentFile."'"
endfunc
comm! -nargs=? A call AlternateFile(0, <f-args>)
comm! -nargs=? AS call AlternateFile(1, <f-args>)


" Function : BufferOrFileExists (PRIVATE)
" Purpose  : determines if a buffer or a readable file exists
" Args     : name (IN) - name of the buffer/file to check
" Returns  : TRUE if it exists, FALSE otherwise
function! BufferOrFileExists(name)
  let path = fnamemodify(a:name, ":h")
  let base = fnamemodify(a:name, ":t")
  if bufexists("^" . a:name . "$")
    return a:name
  elseif filereadable(a:name)
    return a:name
  elseif filereadable(path . "/../INTERFACE/" . base)
    return path . "/../INTERFACE/" . base
  elseif filereadable(path . "/../STRUCTURE/" . base)
    return path . "/../STRUCTURE/" . base
  elseif filereadable(path . "/../RTL/" . base)
    return path . "/../RTL/" . base
  else
    return ""
  endif
endfunction

" Function : FindOrCreateBuffer (PRIVATE)
" Purpose  : searches the buffer list (:ls) for the specified filename. If
"            found, checks the window list for the buffer. If the buffer is in
"            an already open window, it switches to the window. If the buffer
"            was not in a window, it switches to that buffer. If the buffer did
"            not exist, it creates it.
" Args     : filename (IN) -- the name of the file
"            doSplit (IN) -- indicates whether the window should be split
" Returns  : nothing
" Author   : Michael Sharpe <feline@irendi.com>
function! FindOrCreateBuffer(filename, doSplit)
  " Check to see if the buffer is already open before re-opening it.
  let bufName = bufname("^" . a:filename . "$")
  if (bufName == "")
     " Buffer did not exist....create it
     if (a:doSplit != 0)
        execute ":vsplit " . a:filename
     else
        execute ":e " . a:filename
     endif
  else
     " Buffer was already open......check to see if it is in a window
    if (a:doSplit != 0)
       execute ":vert sbuffer " . a:filename
    else
       execute ":buffer " . a:filename
    endif
  endif
endfunction
