set-option global ui_options  ncurses_assistant=none
set-option global tabstop     4
set-option global indentwidth 4
set-option global scrolloff   2,5

colorscheme gruvbox

# Use default terminal background
# set-face global Default default,default
# set-face global BufferPadding rgb:504945,default
# set-face global StatusLine default,default

add-highlighter global/ show-matching
add-highlighter global/ show-whitespaces

# hook global NormalKey '[ydc]' %{
#     nop %sh{
#         (printf '%s' "$kak_main_reg_dquote" | xclip -filter | xclip -selection clipboard) < /dev/null > /dev/null 2>&1 &
#     }
# }


map global user y '<a-|>xclip -i -selection clipboard<ret>'
map global user p '!xclip -o<ret>'

eval %sh{kak-lsp --kakoune -s $kak_session}
hook global WinSetOption filetype=(rust|python|go|javascript|typescript|c|cpp) %{
    lsp-enable-window
}

hook global ModuleLoaded x11 %{
    set-option global termcmd 'miniterm -e'
}

hook global WinCreate ^[^*]+$ %{
    add-highlighter window/ number-lines -hlcursor

    # Highlight for trailing whitespace
    add-highlighter window/ regex '\h+$' 0:Error
}

# tabs -> spaces
hook global BufCreate .* %{
    hook -group tabspaces buffer InsertChar \t %{ execute-keys -draft h@ }
    hook -group tabspaces buffer InsertDelete ' ' %{ try %{
        execute-keys -draft 'hGh<a-k>\A\h+\z<ret>gii<tab><esc><lt>h@'
    }}
}

# Don't expand tabs to spaces for Makefiles
hook global BufSetOption filetype=makefile %{
    remove-hooks buffer tabspaces
}

# Highlight word under the cursor
declare-option -hidden regex curword
set-face global CurWord default,rgb:4a4a4a

hook global NormalIdle .* %{
    evaluate-commands -draft %{ try %{
        execute-keys <space><a-i>w <a-k> '\A\w+\z' <ret>
        set-option buffer curword "%val{selection}"
    } catch %{
        set-option buffer curword ''
    }}
}
hook global InsertBegin .* %{
    set-option buffer curword ''
}
add-highlighter global/ dynregex '\b\Q%opt{curword}\E\b' 0:CurWord

# Git helper
hook global WinCreate    .* %{ git show-diff   }
hook global BufWritePost .* %{ git update-diff }
hook global BufReload    .* %{ git update-diff }

# Comment shortcuts
map global normal '#'     ": comment-line<ret>"  -docstring 'comment line'
map global normal '<a-#>' ": comment-block<ret>" -docstring 'comment block'

# X clipboard shortcuts
map global user p '<a-!>xsel --output --clipboard<ret>' -docstring "clip-paste after"
map global user P '!xsel --output --clipboard<ret>'     -docstring "clip-paste before"
map global user R '|xsel --output --clipboard<ret>'     -docstring "clip-replace"
map global user y '<a-|>xsel --input --clipboard<ret>'  -docstring "clip-yank"

# shell command
# declare-option str shell_termcmd
# define-command x11-shell -docstring 'Spawn a new terminal shell in the current directory' %{
#     nop %sh{
#         setsid ${kak_opt_shell_termcmd} "${PWD}"
#     }
# }
# alias global shell x11-shell

# miniterm
# set-option global shell_termcmd 'miniterm -d'

# Increment/decrement
define-command -hidden -params 2 inc %{
    evaluate-commands %sh{
        if [ "$1" = 0 ]
        then
            count=1
        else
            count="$1"
        fi
        printf '%s%s\n' 'exec h"_/\d<ret><a-i>na' "$2($count)<esc>|bc<ret>h"
    }
}
map global normal <c-a> ': inc %val{count} +<ret>'
map global normal <c-x> ': inc %val{count} -<ret>'


source "%val{config}/occivink/filetree.kak"

# load plugins
try %{
    source "%val{config}/plugins/plug.kak/rc/plug.kak"
    plug "andreyorst/plug.kak" noload
    plug "andreyorst/fzf.kak"
    plug "occivink/kakoune-sudo-write"
    plug "alexherbo2/explore.kak"
    plug "alexherbo2/connect.kak"

    plug "laelath/kakoune-show-matching-insert" config %{
        # Improved matching on insert
        add-highlighter global/ ranges show_matching_insert
    }

    plug "occivink/kakoune-vertical-selection" config %{
        # vertical-selection shortcuts
        map global user v     ': select-down<ret>'       -docstring "select 🡓"
        map global user <a-v> ': select-up<ret>'         -docstring "select 🡑"
        map global user V     ': select-vertically<ret>' -docstring "select 🡓🡑"
    }

    plug "occivink/kakoune-phantom-selection" config %{
        # phantom-selection shortcuts
        map global user f     ": phantom-sel-add-selection<ret>"                 -docstring 'Phantom selection add'
        map global user F     ": phantom-sel-select-all; phantom-sel-clear<ret>" -docstring 'Phantom selection restore'
        map global user <a-f> ": phantom-sel-iterate-next<ret>"                  -docstring 'Phantom selection next'
        map global user <a-F> ": phantom-sel-iterate-prev<ret>"                  -docstring 'Phantom selection previous'
    }

    plug "occivink/kakoune-gdb" config %{
        # GDB integration options
        set-option global gdb_breakpoint_active_symbol "x"
        set-option global gdb_breakpoint_inactive_symbol "o"
        set-option global gdb_location_symbol ">"
    }

    # plug "alexherbo2/auto-pairs.kak" config %{
    #     hook global WinCreate .* %{
    #         auto-pairs-enable
    #     }
    #     map global user s -docstring 'Surround' ':<space>auto-pairs-surround<ret>'
    #     map global user S -docstring 'Surround++' ':<space>auto-pairs-surround _ _ * *<ret>'
    # }

    # kak-lsp
    map global normal "'" ": enter-user-mode lsp<ret>" -docstring 'lsp user mode'
    evaluate-commands %sh{kak-lsp --kakoune -s $kak_session}

    hook global WinSetOption filetype=(python|go|c|cpp) %{
        lsp-enable-window
    }
}

# local rc files
evaluate-commands %sh{
    if [ -e '.kakrc.local' ]; then
        printf 'source .kakrc.local'
    fi
}

hook global InsertChar j %{ try %{
      exec -draft hH <a-k>jj<ret> d
        exec <esc>
}}



# eval %sh{kak=lsp --kakoune -s %kak_session}
# hook global WinSetOption filetype=(rust|python|go|javascript|typescript|c|cpp) %{
#         lsp-enable-window
# }

