if (exists('b:did_ftplugin_boing'))
  finish
endif

let b:did_ftplugin_boing = 1

" politely at the autocmds, check if they've been made before too
" (CursorMoved is more important so is more likely to be there)
if !exists('#boind-gitrebase#CursorMoved')
    augroup boing-gitrebase
        autocmd!
        autocmd WinEnter,CursorMoved git-rebase-todo call boing#GitSHAPopup()
        autocmd InsertLeave git-rebase-todo let w:gitshapopupline = -1
    augroup END
endif

