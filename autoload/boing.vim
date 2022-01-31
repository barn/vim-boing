" boing.vim - Popup window for commits when interactive rebasing
" Author:       Bea Hughes <ohgoodmorespamviagithub@mumble.org.uk>
" Version:      0.0.1
"
set encoding=utf-8
scriptencoding utf-8

if exists('g:loaded_boing') || v:version < 800 || &compatible || !has('popupwin')
  finish
endif
let g:loaded_boing = 1

" This should come from some config thing.
let g:boing#enabled = get(g:, 'boing#enabled', v:false)
let s:github_open_key = get(g:, 'boing#opengithubkey', "\<F9>")
let s:togglekey = get(g:, 'boing#togglekey', '<Leader>gb')
let s:popup_persist = get(g:, 'boing#popuppersist', v:true)
let s:cachegit = get(g:, 'boing#cache', v:true)

" Use this so we don't call the func on every CursorMoved, just up and
" down or all around
let w:gitshapopupline = 0
let w:boingbufferid = ''

let s:sha = ''

" By making the cache buffer scoped it should get emptied when one exists
" the buffer to finish the commit. This utter may not work for people who
" rebase in vim. I think an autocmd on bufsave or similar may work.
let b:boingcache = {}

" Yeah, this could be a thing people might went to define themselves one
" day. Put in the things we know ahead of time in one place.
" the "arbritary" numbers are based on my statusline/airline, so really
" should be adjusted for that.
let s:popup_defaults = {
    \             'padding': [1,1,1,1],
    \             'line': 2,
    \             'minheight': &lines - 4,
    \             'maxheight': &lines - 4,
    \             'fixed': v:true,
    \             'scrollbar': v:true,
    \             'moved': [0, 0, 0],
    \             'wrap': v:false }

" this should be scoped I think, and isn't?
execute 'nmap <silent>' . s:togglekey . ' :call boing#Toggle()<CR>'

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
    else
        " debugin' only
        for l:buf in popup_list()
            let l:pos = popup_getpos(l:buf)
            if exists(l:pos['line'])
                echo ['line']
            endif
        endfor
    endif
endfunction

function! boing#GitSHAPopup()

    " Fast fail for lines that aren't likely to contain SHAs
    let l:line = getline('.')

    if l:line[0] ==# '#' || l:line[0] !~? '[a-z]' || line('.') == w:gitshapopupline || g:boing#enabled == v:false
        "more debug " echom 'line ' . l:line . 'cur line ' . line('.') . ' saved line ' . w:gitshapopupline
        if s:popup_persist == v:true
            call boing#GuessClose()
        endif
        return
    endif

    " Try and get the second element of the line
    let l:sline = split(l:line, ' ')
    let s:sha = get(l:sline, 1, 'NONE')

    " see if that second element is a sha?
    if s:sha =~# '\v^[a-fA-F0-9]+$'

        " set this early for autocmd CursorMoved thing
        let w:gitshapopupline = line('.')
        let l:width = get(g:, 'boing#width', &columns/2)

        if s:cachegit && has_key(b:boingcache,s:sha) && !empty(b:boingcache[s:sha])
            let l:text = b:boingcache[s:sha]
        else
            " git command we run, split in to a list
            let l:cmd = 'git show --pretty=medium ' . s:sha
            let l:text = split(system(l:cmd), '\n')
            if s:cachegit
                let b:boingcache[s:sha] = l:text
            endif
        endif

        let l:title = 'Doing a rebase'
        if exists('*airline#extensions#branch#head')
            let l:title = "\<Esc>[33m" . 'Rebase on ' . airline#extensions#branch#head()
        endif
        let l:title = boing#CentreText(l:title, &columns - (&columns/2))

        " ahem debug
        " echo 'list is ' . join(popup_list(), ', ')

        call boing#DoPopup(l:title, l:text, l:width)
        " " do we have an existing window? great, lets use that, otherwise
        " " make a new one
        " if !empty(w:boingbufferid) && index(popup_list(), w:boingbufferid) >= 0
        "     " is calling these bad? should we check they work and if not
        "     " do the regular thing?
        "     " maybe make checks that it's not hidden and has the right
        "     " params??
        "     call popup_setoptions(w:boingbufferid, 
        "                 \             { 'title': l:title })
        "     call popup_settext(w:boingbufferid, l:text)
        "     " buffer id shouldn't change so we won't need to set it.
        " else
        "     " merge the default options here, to make this hopefully
        "     " clearly, and one day configurable
        "     let w:boingbufferid = popup_create(l:text, extend(s:popup_defaults,
        "     \           { 
        "     \             'col': l:width,
        "     \             'minwidth': &columns - l:width,
        "     \             'title': l:title,
        "     \             'filter': funcref('boing#CloseThatPopup'),
        "     \           })
        "     \    )
        " endif
        " call setbufvar(winbufnr(w:boingbufferid), '&filetype', 'git')
        " set the filetype in the popup to git, so syntax hi
    endif

endfunction

" I wanted to make width optional but.
" vimlparser doesn't like this line,
" https://github.com/vim-jp/vim-vimlparser/issues/154
function! boing#DoPopup(title, body, width)

    " do we have an existing window? great, lets use that, otherwise
    " make a new one
    if !empty(w:boingbufferid) && index(popup_list(), w:boingbufferid) >= 0
        " is calling these bad? should we check they work and if not
        " do the regular thing?
        " maybe make checks that it's not hidden and has the right
        " params??
        call popup_setoptions(w:boingbufferid, 
                    \             { 'title': a:title })
        call popup_settext(w:boingbufferid, a:body)
        " buffer id shouldn't change so we won't need to set it.
    else
        " merge the default options here, to make this hopefully
        " clearly, and one day configurable
        let w:boingbufferid = popup_create(a:body, extend(s:popup_defaults,
        \           { 
        \             'col': a:width,
        \             'minwidth': a:width,
        \             'title': a:title,
        \             'filter': funcref('boing#CloseThatPopup'),
        \           })
        \    )
    endif
    call setbufvar(winbufnr(w:boingbufferid), '&filetype', 'git')
    " set the filetype in the popup to git, so syntax hi

endfunction

" Given a width, say of a term/pane, and a string, centre it with spaces
" like a computer professional.
function! boing#CentreText(text, size)
    let l:spaces = repeat(' ', (a:size - len(strtrans(a:text)))/ 2)
    return l:spaces . a:text . l:spaces
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
      " we can just call it, as it might work, it might not. Not vital.
      call boing#OpenGithubSha(a:winid)
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
  " return v:false
endfunction

function! boing#OpenGithubSha(winid)
    let l:isitpushed = 'git branch -r --contains ' . s:sha
    if !empty(system(l:isitpushed))
        " Well this all seems terrible dot gif
        let l:remote = system('git remote get-url --push origin')
        if match(l:remote, '\cgithub.com') >= 0
            " chomp()
            let l:url = substitute(l:remote, '\n\+$', '', '')
            " make it a https not git/ssh link
            let l:url = substitute(l:url, '\v.*\bgithub\.com[/:]', 'https;//github.com/', '')
            " remove .git if its there at the end
            let l:url = substitute(l:url, '\v\.git$', '', '')

            let l:browser = get(g:, 'boing#browser', 'open')
            let l:bumpercommand = l:browser . ' ' . l:url . '/commit/' . s:sha  . ' >/dev/null 2>&1'

            call system(l:bumpercommand)
            call popup_close(a:winid)
        else
            echo 'sorry we only support jithub.'
        endif
    else
        echo s:sha . ' is not pushed to remote.'
    endif
endfunction


"" the random string  I found that kicked this whole thing off.
" nmap <silent><Leader>g :call setbufvar(winbufnr(popup_atcursor(split(system("git log -n 1 -L " . line(".") . ",+1:" . expand("%:p")), "\n"), { "padding": [1,1,1,1], "pos": "botleft", "wrap": 0 })), "&filetype", "git")<CR>
