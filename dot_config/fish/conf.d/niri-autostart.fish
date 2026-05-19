# Auto-start niri-session su tty1 (login shell, no Wayland già attivo).
# Sostituisce SDDM: il disco è cifrato LUKS, il prompt passphrase a boot fa
# da gate; Noctalia gestisce il lock screen quando serve.
#
# Guard __NIRI_AUTOSTART_DONE: lo script /usr/bin/niri-session si re-exec come
# login shell se non chiamato da systemd → ricarica fish conf.d → rilancerebbe
# `exec niri-session` ricorsivamente (loop infinito, black screen al login).
# La env var taglia il loop al secondo passaggio.

if status is-login
    and test "$XDG_VTNR" = "1"
    and not set -q WAYLAND_DISPLAY
    and not set -q DISPLAY
    and not set -q __NIRI_AUTOSTART_DONE
    set -gx __NIRI_AUTOSTART_DONE 1
    exec niri-session
end
