set encoding=utf-8
scriptencoding utf-8

if exists('g:loaded_boing') || v:version < 800 || &compatible || !has('popupwin')
  finish
endif
let g:loaded_boing = 1


" Use this so we don't call the func on every CursorMoved, just up and
" down or all around
let w:gitshapopupline = -1

" for "centring" the title
let s:title_spc = '              '
let s:sha = ''

" Do it manually
" nmap <silent><Leader>g :call  GitSHAPopup()<CR>

function! boing#GitSHAPopup()

    " Fast fail for lines that aren't likely to contain SHAs
    let l:line = getline('.')
    if l:line[0] ==# '#' || l:line[0] !~? '[a-z]' || line('.') == w:gitshapopupline
        return
    endif

    " Try and get the second element of the line
    let l:sline = split(l:line, ' ')
    let s:sha = get(l:sline, 1, 'NONE')

    " see if that second element is a sha?
    if s:sha =~# '\v^[a-fA-F0-9]+$'

        " set this early for autocmd CursorMoved thing
        let w:gitshapopupline = line('.')

        " git command we run, split in to a list
        let l:cmd = 'git show --pretty=medium ' . s:sha
        let l:text = split(system(l:cmd), '\n')

        " Fun working out how wide the popup should be
        let l:ww = &columns
        let l:width = &columns / 2

        let l:title = 'Doing a rebase'
        if exists('*airline#extensions#branch#head')
            let l:title = 'Rebase on ' . airline#extensions#branch#head()
        endif

        :call setbufvar(
        \        winbufnr(
        \           popup_create(l:text,
        \           { 'padding': [1,1,1,1],
        \             'line': 2,
        \             'col': l:width,
        \             'minheight': &lines - 1,
        \             'minwidth': &columns - l:width,
        \             'fixed': v:true,
        \             'scrollbar': v:true,
        \             'moved': [line('.'),0,l:ww],
        \             'title': s:title_spc . "\<Esc>[33m" . l:title . s:title_spc,
        \             'filter': funcref('boing#CloseThatPopup'),
        \             'wrap': v:false }
        \       )
        \   )
        \ , '&filetype', 'git') " set the filetype in the popup to git, so syntax hi
    endif
endfunction

" Processes keys and closes popup accordingly
" :help popup-filter
" The filter can return TRUE to indicate the key has been handled and is to be
" discarded, or FALSE to let Vim handle the key as usual in the current state.
function! boing#CloseThatPopup(winid, key)
  let l:close_keys = ['x', 'q', "\<Esc>", "\<Ctrl>c"]
  if index(l:close_keys, a:key) >= 0
    call popup_close(a:winid)
    let w:gitshapopupline = -1
    return v:true
  elseif a:key ==# 'G'
      " XXX need to steal variables here? sha repo origin
      call system('git branch -r --contains SHA && open https://github.com' )
  " borrowed from https://github.com/prabirshrestha/vim-lsp/issues/975#issuecomment-751658462
  elseif a:key ==# "\<c-j>" || a:key ==# "\<pagedown>"
      call win_execute(a:winid, "normal! 5\<c-e>")
      return v:true
  elseif a:key ==# "\<c-k>" || a:key ==# "\<pageup>"
      call win_execute(a:winid, "normal! 5\<c-y>")
      return v:true
  elseif a:key ==# "\<c-g>"
      call win_execute(a:winid, 'normal! G')
  elseif a:key ==# "\<c-t>"
      call win_execute(a:winid, 'normal! gg')
  endif
  return v:false
endfunction

"" the random string  I found that kicked this whole thing off.
" nmap <silent><Leader>g :call setbufvar(winbufnr(popup_atcursor(split(system("git log -n 1 -L " . line(".") . ",+1:" . expand("%:p")), "\n"), { "padding": [1,1,1,1], "pos": "botleft", "wrap": 0 })), "&filetype", "git")<CR>
