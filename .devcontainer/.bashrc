__bash_prompt() {
    local gitbranch='`\
        export BRANCH="$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)"; \
        if [ "${BRANCH:-}" != "" ]; then \
            echo -n " \[\033[1;33m\](${BRANCH})\[\033[0m\]"; \
        fi`'
    local green='\[\033[0;32m\]'
    local blue='\[\033[0;34m\]'
    local reset='\[\033[0m\]'
    PS1="${green}\u${reset} ${blue}\w${reset}${gitbranch} \$ "
    unset -f __bash_prompt
}
__bash_prompt
