# vim-boing

Overlay commit info during a `git rebase -i ...` in a popup window.

## Screenshot?

<img width="1436" alt="Screenshot 2022-01-29 at 00 18 07" src="https://user-images.githubusercontent.com/39111/151653632-d26928b3-c53a-49d6-84d2-e29dfae72c9f.png">

## Installation

However your vim plugin manager deals with GitHub:

```vimrc
   Plug 'barn/vim-boing'
```

And to enable it, a wee:

```vimrc
let g:boing#enabled = v:true
```

## FAQ

Q. Doesn't `<xyz>` do this?
A. Probably but I couldn't find out how to do this, so after messing around with fzf for a bit I found `popupwin` and made this.

Q. This code is terrible!
A. That's not a question, also I know.

## Configuration

`g:boing#browser` how to open links. `open` is the default.

`g:boing#opengithubkey` single key to press to open SHA in github. `<F9>` is the default.

`g:boing#togglekey` key combo to enable/disable previewing default: `<leader>gb`

Yeah, that would be a great feature. Agreed.
