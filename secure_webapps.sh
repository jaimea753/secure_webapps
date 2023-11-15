#!/bin/sh

CONFIG_DIR=""$HOME"/.config/secure_webapps"
DATA_DIR=""$HOME"/.local/share/secure_webapps"
DMENU_APP=dmenu
SECURITY_OPTIONS="--apparmor" # --seccomp does not seem to work

APPS=""$CONFIG_DIR"/apps.json"

! [ -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"
! [ -d "$DATA_DIR" ] && mkdir -p "$DATA_DIR"
! [ -e "$APPS" ] && echo "[]" > "$APPS"

EXTENSIONS="https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm"

reset() {
    echo "Seguro que quieres restear todos los contenedores (type YES): "
    read OPT
    if [ "$OPT" = "YES" ]
    then
        rm -rf "$DATA_DIR"
        rm -rf "$CONFIG_DIR"
    fi
}

add() {
    while true
    do
        echo "Introduce the name of the new webapp: "
        read APP_NAME
        [ "$APP_NAME" != "" ] && break
    done
    while true
    do
        echo "Introduce its url: "
        read APP_URL
        [ "$APP_URL" != "" ] && break
    done

    NEW="$(jq ".[.| length] |= .+ {\"name\": \"$APP_NAME\", \"url\": \"$APP_URL\"}" "$APPS")"
    echo "$NEW" > "$APPS"
    rm -rf "$DATA_DIR"/"$APP_NAME"
    mkdir "$DATA_DIR"/"$APP_NAME"
    for x in $EXTENSIONS
    do
        firejail $SECURITY_OPTIONS --private="$DATA_DIR"/"$APP_NAME" chromium $x
    done
}

del() {
    APP_NAME="$(jq -r '.[].name' "$APPS" | $DMENU_APP)"
    [ "$APP_NAME" = "" ] && exit
    NEW=$(jq -r "[(.[] | select(.name!=\"$APP_NAME\"))]" "$APPS")
    echo "$NEW" > "$APPS"
    rm -rf "$DATA_DIR"/"$APP_NAME"
}

run() {
    SEL="$(jq -r '.[].name' "$APPS" | $DMENU_APP)"
    [ "$SEL" = "" ] && exit
    URL="$(jq -r ".[] | select(.name==\"$SEL\") | .url" "$APPS")"
    firejail $SECURITY_OPTIONS --private="$DATA_DIR"/"$SEL" chromium --app=$URL
}

if [ "$1" = "add" ]
then
    add
elif [ "$1" = "run" ]
then
    run
elif [ "$1" = "del" ]
then
    del
elif [ "$1" = "reset" ]
then
    reset
else
    echo "secure_webapps [add,run,del,reset]"
fi

