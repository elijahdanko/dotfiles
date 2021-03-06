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

# Search for local git projects using fd(find) and fzf commands.

[ -x "$(command -v fd)" ] && cmd="fd" || cmd="fdfind"
[ -z "${FZF_PROJECTS_ROOT_DIR-}" ] && FZF_PROJECTS_ROOT_DIR="$HOME"
[ -z "${FZF_PROJECTS_FD_COMMAND-}" ] && FZF_PROJECTS_FD_COMMAND="$cmd --hidden --case-sensitive --absolute-path --exec echo '{//}' ';' '^\.git$' ${FZF_PROJECTS_ROOT_DIR}"
[ -z "${FZF_PROJECTS_COLORS-}" ] && FZF_PROJECTS_COLORS="0"
[ -z "${FZF_PROJECTS_MATCH_COLOR_FG-}" ] && FZF_PROJECTS_MATCH_COLOR_FG="34"
[ -z "${FZF_PROJECTS_PREVIEW_CONFIG-}" ] && FZF_PROJECTS_PREVIEW_CONFIG="nohidden|hidden,down"
[ -z "${FZF_PROJECTS_PREVIEW_THRESHOLD-}" ] && FZF_PROJECTS_PREVIEW_THRESHOLD="160"
[ -z "${FZF_PROJECTS_PROMPT-}" ] && FZF_PROJECTS_PROMPT='Projects> '

# Ensure precmds are run after cd.
function fzf_projects_redraw_prompt {
    local precmd
    for precmd in $precmd_functions; do
        $precmd
    done
    zle reset-prompt
}
zle -N fzf_projects_redraw_prompt

function _fzf_projects_color {
    [ "${FZF_PROJECTS_COLORS-}" -eq "0" ] && cat && return
    local esc="$(printf '\033')"
    sed "s/\(.*\)/${esc}[${FZF_PROJECTS_MATCH_COLOR_FG}m\1${esc}[0;0m/"
}

function _fzf_projects_preview_window {
    states=("${(s[|])FZF_PROJECTS_PREVIEW_CONFIG}")
    [ "${#states[@]}" -eq 1 ] && echo "${FZF_PROJECTS_PREVIEW_CONFIG}" && return
    [ "${#states[@]}" -gt 2 ] && echo "${FZF_PROJECTS_PREVIEW_CONFIG}" && return
    [ $(tput cols) -lt "${FZF_PROJECTS_PREVIEW_THRESHOLD}" ] && echo "${states[2]}" && return
    echo "${states[1]}"
}

function fzf-projects {
    local tmp_fd=$(mktemp --suffix .fzf-project)

    eval ${FZF_PROJECTS_FD_COMMAND} | _fzf_projects_color | fzf \
        --ansi \
        --prompt "${FZF_PROJECTS_PROMPT}" \
        --preview="tree -C -L 1 {}" \
        --preview-window=$(_fzf_projects_preview_window) \
        --bind "enter:execute(echo {} >> $tmp_fd)+abort"

    local mb_dir="$(cat $tmp_fd)"
    rm -rf "$tmp_fd"
    if [ -d "$mb_dir" ]; then
        if [ "$#" -gt 0 ]; then
            case $1 in
                '--print') printf "%s\n" "$mb_dir";;
            esac
        else
            cd "$mb_dir"
        fi
    fi

    zle && zle fzf_projects_redraw_prompt || true
}

zle -N fzf-projects

bindkey ${FZF_PROJECTS_TRIGGER_KEYMAP:-'^g'} fzf-projects
