#!/bin/sh

CONFIG_DIR="$HOME/.config/secure_webapps"
DATA_DIR="$HOME/.local/share/secure_webapps"
DMENU_APP="dmenu -i"
SECURITY_OPTIONS="--apparmor" # --seccomp does not seem to work

APPS="$CONFIG_DIR/apps.json"

! [ -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"
! [ -d "$DATA_DIR" ] && mkdir -p "$DATA_DIR"
! [ -e "$APPS" ] && printf "[]" > "$APPS"


# Deletes all app containers
reset() {
    printf "This will reset all containers (type YES): "
    read -r OPT
    if [ "$OPT" = "YES" ]
    then
        rm -rf "$DATA_DIR"
        rm -rf "$CONFIG_DIR"
    fi
}

# Add a new container
add() {
    while true
    do
        printf "Introduce the name of the new webapp: "
        read -r APP_NAME
        [ "$APP_NAME" != "" ] && break
    done
    while true
    do
        printf "Introduce its url: "
        read -r APP_URL
        [ "$APP_URL" != "" ] && break
    done
    while true
    do
        printf "Select a mode: \n1) Normal browser\n2) Webapp (uses chromium webapp mode)\nEnter [1,2]: "
        read -r MODE 
        ( [ "$MODE" = 1 ] || [ "$MODE" = 2 ] ) && break
    done

    if [ "$MODE" = 1 ]
    then
        NEW="$(jq ".[.| length] |= .+ {\"name\": \"$APP_NAME\", \"url\": \"$APP_URL\", \"mode\": \"browser\"}" "$APPS")"
    else
        NEW="$(jq ".[.| length] |= .+ {\"name\": \"$APP_NAME\", \"url\": \"$APP_URL\", \"mode\": \"app\"}" "$APPS")"
    fi
    echo "$NEW" > "$APPS"
    rm -rf "$DATA_DIR"/"$APP_NAME"
    mkdir "$DATA_DIR"/"$APP_NAME"
    # Default extensions, modify as necessary
    set "https://chromewebstore.google.com/detail/decentraleyes/ldpochfccmkkmhdbclfhpagapcfdljkj" \
        "https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm"
    for x in $@
    do
        firejail $SECURITY_OPTIONS --private="$DATA_DIR"/"$APP_NAME" chromium "$x" &
    done
}

# Deletes a container
del() {
    APP_NAME="$(jq -r '.[].name' "$APPS" | $DMENU_APP)"
    [ "$APP_NAME" = "" ] && exit
    NEW=$(jq -r "[(.[] | select(.name!=\"$APP_NAME\"))]" "$APPS")
    echo "$NEW" > "$APPS"
    rm -rf "$DATA_DIR"/"$APP_NAME"
}

# Run the container
run() {
    SEL="$(jq -r '.[].name' "$APPS" | $DMENU_APP)"
    [ "$SEL" = "" ] && exit
    URL="$(jq -r ".[] | select(.name==\"$SEL\") | .url" "$APPS")"
    MODE="$(jq -r ".[] | select(.name==\"$SEL\") | .mode" "$APPS")"
    ( [ "$MODE" = "app" ] || [ "$MODE" = "null" ] ) && firejail $SECURITY_OPTIONS --private="$DATA_DIR"/"$SEL" chromium --app="$URL"
    [ "$MODE" = "browser" ] && firejail $SECURITY_OPTIONS --private="$DATA_DIR"/"$SEL" chromium "$URL"
}

# Modify container settings after creation
config() {
    SEL="$(jq -r '.[].name' "$APPS" | $DMENU_APP)"
    [ "$SEL" = "" ] && exit
    firejail $SECURITY_OPTIONS --private="$DATA_DIR"/"$SEL" chromium
}

if [ "$1" = "add" ]
then
    add
elif [ "$1" = "run" ]
then
    run
elif [ "$1" = "config" ]
then
    config
elif [ "$1" = "del" ]
then
    del
elif [ "$1" = "reset" ]
then
    reset
else
    printf "secure_webapps [add,run,config,del,reset]\n"
fi

