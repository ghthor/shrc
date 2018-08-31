# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bash_profile if it exists
    if [ -f "$HOME/.bash_profile" ]; then
        . "$HOME/.bash_profile"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [[ -d "$HOME/bin"  && ":$PATH:" != *":$HOME/bin:"* ]] ; then
    PATH=$HOME/bin:$PATH
fi
