set encoding=utf-8
scriptencoding utf-8

if exists('g:loaded_boing') || v:version < 800 || &compatible || !has('popupwin')
  finish
endif
let g:loaded_boing = 1

" This should come from some config thing.
let g:boing#enabled = v:true
let s:github_open_key = get(g:, 'boing#opengithubkey', "\<F9>")

" Use this so we don't call the func on every CursorMoved, just up and
" down or all around
let w:gitshapopupline = -1
let w:boingbufferid = ''

" for "centring" the title
let s:title_spc = '              '
let s:sha = ''

nmap <silent><Leader>g :call boing#Toggle()<CR>

function! boing#Toggle()
    " let g:boing#enabled = ( g:boing#enabled == v:false )
    if g:boing#enabled == v:false
        let g:boing#enabled = v:true
        call boing#GitSHAPopup()
    else
        let g:boing#enabled = v:false
        call boing#GuessClose()
    endif
endfunction

function! boing#GuessClose()
    if !empty(w:boingbufferid) && !empty(popup_getoptions(w:boingbufferid))
        call popup_close(w:boingbufferid)
    endif
endfunction

function! boing#GitSHAPopup()

    " Fast fail for lines that aren't likely to contain SHAs
    let l:line = getline('.')
    if l:line[0] ==# '#' || l:line[0] !~? '[a-z]' || line('.') == w:gitshapopupline || g:boing#enabled == v:false
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

        let w:boingbufferid = popup_create(l:text,
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
        \           )

        call setbufvar(winbufnr(w:boingbufferid), '&filetype', 'git')
        " set the filetype in the popup to git, so syntax hi
    endif
endfunction

" Processes keys and closes popup accordingly
" :help popup-filter
" The filter can return TRUE to indicate the key has been handled and is to be
" discarded, or FALSE to let Vim handle the key as usual in the current state.
function! boing#CloseThatPopup(winid, key)
  " let l:close_keys = ['x', 'q', "\<Esc>", "\<Ctrl>c"]

  " close popup, if indeed these aren't already the defaults
  let l:close_keys = ['x', "\<Ctrl>c"]
  if index(l:close_keys, a:key) >= 0
    call popup_close(a:winid)
    let w:gitshapopupline = -1
    return v:true

  " Open commit in github if it exists, and youre on a mac, and a lot of
  " planets are very carefully aligned.
  elseif a:key ==# s:github_open_key
      " XXX need to steal variables here? sha repo origin
      let l:isitpushed = 'git branch -r --contains ' . s:sha
      if !empty(system(l:isitpushed))
          " Well this all seems terrible dot gif
          " please move this to a function
          let l:remote = system('git remote get-url --push origin')
          let l:url = substitute(l:remote, '\n\+$', '', '')
          let l:url = substitute(l:url, '\v.*\bgithub\.com[/:]', 'https;//github.com/', '')
          let l:url = substitute(l:url, '\v\.git$', '', '')

          let l:bumpercommand = 'open ' . l:url . '/commit/' . s:sha  . ' >/dev/null 2>&1'
          echo l:bumpercommand
          call system(l:bumpercommand)
          call popup_close(a:winid)
      else
          echo s:sha . ' not pushed to remote.'
      endif
      return v:true

  " scroll around popup
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
