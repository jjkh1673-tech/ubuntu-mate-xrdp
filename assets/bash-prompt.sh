# Hermes desktop shell look (appended to ~/.bashrc; keeps everything Ubuntu already does).
PROMPT_DIRTRIM=3
if [ -n "${PS1:-}" ] && [ "$(id -u)" = "0" ]; then
  PS1='\[\e[1;31m\]╭ λ \u\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\]\n\[\e[1;31m\]╰ λ \$ \[\e[0m\]'
elif [ -n "${PS1:-}" ]; then
  PS1='\[\e[1;36m\]╭ λ \u\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\]\[\e[1;35m\]$(__hermes_git_branch)\n\[\e[1;36m\]╰ λ \$ \[\e[0m\]'
fi
__hermes_git_branch() {
  local b
  b=$(git symbolic-ref --short HEAD 2>/dev/null || true)
  [ -n "$b" ] && printf ' (%s)' "$b"
}
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
export GREP_COLOR='1;33'
