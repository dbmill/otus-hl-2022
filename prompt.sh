if [ $EUID -eq 0 ] ; then
#  PS1='\[\e[1;35m\]\t \[\e[1;31m\]\h\[\e[m\]:\[\e[36m\]\w\[\e[1;33m\]\$\[\e[m\] '
  PS1='\e[1;35m\D{%d.%m.%Y} \t \e[1;31m\h\e[m:\e[36m\w\n\[\e[1;33m\]\$\[\e[m\] '
else
#  PS1='\[\e[1;35m\]\t \[\e[0;32m\]\u\[\e[33m\]@\[\e[32m\]\h\[\e[m\]:\[\e[36m\]\w\[\e[1;33m\]\$\[\e[m\] '
  PS1='\e[1;35m\D{%d.%m.%Y} \t \e[0;32m\u\e[33m@\e[32m\h\e[m:\e[36m\w\n\[\e[1;33m\]\$\[\e[m\] '
fi
export PS1
