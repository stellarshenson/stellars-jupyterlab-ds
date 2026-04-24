# Bridge ~/.profile (POSIX sh) environment into fish via bass.
# Fish doesnt source .profile natively - this imports its exports,
# PATH changes, etc. without duplicating them in fish syntax.
if test -f ~/.profile
    if type -q bass
        bass source ~/.profile
    end
end
