#!/usr/bin/env bash
# Libreria condivisa: risolve identità SSH+git per il repo corrente.
#
# Output (variabili esportate quando git_ctx_resolve ritorna 0):
#   HOST              hostname estratto dal remote URL
#   IDENT_FILE        path della private key da ssh -G (assoluto, ~ espanso)
#   IDENT_PUBKEY      path della pub key corrispondente ($IDENT_FILE.pub)
#   VAULT             nome del vault 1P (cartella di $IDENT_FILE), vuoto se default
#   VAULT_GITCONFIG   path a ~/.gitconfig.d/<vault>.gitconfig, vuoto se non esiste
#
# Convenzione: 46-ssh-identities.sh.tmpl deploya le chiavi in:
#   ~/.ssh/<vault>/<key>            (top-level vault)
#   ~/.ssh/<vault>/<sub-vault>/<key> (ricorsione _ssh.vaults)
# e scrive ~/.gitconfig.d/<vault>.gitconfig con email+name dell'Identity item.
# Quindi il vault = basename(dirname($IDENT_FILE)). La key personale default
# (~/.ssh/id_ed25519) ha dirname == ~/.ssh → trattata come "no vault override".
#
# Return codes:
#   0  risolto, variabili popolate
#   1  no remote / parse fallito / nessuna identityfile / file non esiste
#
# Failure mode: questa lib è chiamata da hook/wrapper "best-effort". Caller
# deve gestire return!=0 come fallback al comportamento default.

git_ctx_resolve() {
    HOST="" IDENT_FILE="" IDENT_PUBKEY="" VAULT="" VAULT_GITCONFIG=""

    local remote
    remote=$(git config --get remote.origin.url 2>/dev/null || true)
    [ -z "$remote" ] && return 1

    if [[ $remote =~ ^git@([^:]+): ]]; then
        HOST="${BASH_REMATCH[1]}"
    elif [[ $remote =~ ^ssh://(git@)?([^/:]+) ]]; then
        HOST="${BASH_REMATCH[2]}"
    else
        return 1  # http(s):// o altro → niente routing SSH
    fi

    # `ssh -G $host` stampa TUTTE le identityfile candidate (per host senza
    # stanza specifica, sono i 5 default: id_rsa, id_ecdsa, id_ecdsa_sk,
    # id_ed25519, id_ed25519_sk). Iteriamo nell'ordine SSH e prendiamo la
    # prima che ESISTE sul filesystem.
    local candidate
    while IFS= read -r candidate; do
        candidate="${candidate/#\~/$HOME}"
        if [ -f "$candidate" ]; then
            IDENT_FILE="$candidate"
            break
        fi
    done < <(ssh -G "$HOST" 2>/dev/null | awk '/^identityfile /{print $2}')

    [ -z "$IDENT_FILE" ] && return 1
    [ -f "${IDENT_FILE}.pub" ] && IDENT_PUBKEY="${IDENT_FILE}.pub"

    local vault_dir vault
    vault_dir=$(dirname "$IDENT_FILE")
    if [ "$vault_dir" = "$HOME/.ssh" ]; then
        # Chiave directly in ~/.ssh (es. id_ed25519 personale) → no vault override
        return 0
    fi
    vault=$(basename "$vault_dir")
    VAULT="$vault"

    local vgc="$HOME/.gitconfig.d/${vault}.gitconfig"
    [ -f "$vgc" ] && VAULT_GITCONFIG="$vgc"
    return 0
}
