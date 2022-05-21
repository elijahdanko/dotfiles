# Copyright (c) 2022 Elijah Danko

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Search for local git projects using fdfind and fzf commands.

[ -z "${FZM_FD_COMMAND-}" ] && FZM_FD_COMMAND="fdfind --hidden --case-sensitive --absolute-path --exec echo '{//}' ';' '^\.git$'"
[ -z "${FZM_FZF_COMMAND-}" ] && FZM_FZF_COMMAND="fzf"
[ -z "${FZM_ROOT_DIR-}" ] && FZM_ROOT_DIR="$HOME"

# Ensure precmds are run after cd.
function fzm_redraw_prompt {
    local precmd
    for precmd in $precmd_functions; do
        $precmd
    done
    zle reset-prompt
}
zle -N fzm_redraw_prompt

function fzm {
    local line=$(cd "${FZM_ROOT_DIR}"; eval ${FZM_FD_COMMAND} | eval ${FZM_FZF_COMMAND})
    if [[ -z "$line" ]]; then
        zle && zle fzm_redraw_prompt
        return 1
    fi

    if [ "$#" -gt 0 ]; then
        case $1 in
            '--print') printf "%s\n" "$line";;
        esac
    else
        cd "$line"
    fi
    zle && zle fzm_redraw_prompt || true
}

zle -N fzm

bindkey ${FZM_TRIGGER_KEYMAP:-'^g'} fzm