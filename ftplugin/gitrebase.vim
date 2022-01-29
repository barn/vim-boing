if (exists('b:did_ftplugin_boing'))
  finish
endif

let b:did_ftplugin_boing = 1

" politely at the autocmds
" don't want to ! it, as someone else may have made one?
" if !exists('#gitrebase#CursorMoved')
    augroup boing-gitrebase
        autocmd!
        autocmd BufWinEnter,CursorMoved git-rebase-todo :call boing#GitSHAPopup()
        autocmd InsertLeave git-rebase-todo let w:gitshapopupline = -1
    augroup END
"endif

