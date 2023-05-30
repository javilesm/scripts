#!/bin/bash
# edit_nsswitch.sh
# shell script that adds the "ldap" entry to the "/etc/nsswitch.conf" file to enable LDAP for UNIX client authentication
# Variables
NSSWITCH_CONF_FILE="/etc/nsswitch.conf"

# This function creates a backup of the original /etc/nsswitch.conf file by copying it to /etc/nsswitch.conf.bak
function backup_nsswitch_conf() {
    if [ -f "$NSSWITCH_CONF_FILE" ]; then
        sudo cp "$NSSWITCH_CONF_FILE" "$NSSWITCH_CONF_FILE.bak"
        echo "Backup created: $NSSWITCH_CONF_FILE.bak"
    else
        echo "Error: $NSSWITCH_CONF_FILE does not exist."
        exit 1
    fi
}
function change_ownership_to_user() {
    sudo chown $USER:$USER "$NSSWITCH_CONF_FILE"
}
# This function adds the "ldap" entry to the /etc/nsswitch.conf file using the sed command.
function add_ldap_entry() {
    #passwd
    if grep -q "#passwd" "$NSSWITCH_CONF_FILE"; then
        sudo sed -i "s|^#passwd:.*|passwd:              ldap|" "$NSSWITCH_CONF_FILE" || { echo "ERROR: Hubo un problema al configurar el archivo '$NSSWITCH_CONF_FILE': #passwd"; exit 1; }
    elif grep -q "passwd" "$NSSWITCH_CONF_FILE"; then
        sudo sed -i "s|^passwd:.*|passwd:               ldap|" "$NSSWITCH_CONF_FILE" || { echo "ERROR: Hubo un problema al configurar el archivo '$NSSWITCH_CONF_FILE': passwd"; exit 1; }
    else
        echo "passwd:               ldap" >> "$NSSWITCH_CONF_FILE"
    fi
    #group
    if grep -q "#group" "$NSSWITCH_CONF_FILE"; then
        sudo sed -i "s|^#group:.*|group:                ldap|" "$NSSWITCH_CONF_FILE" || { echo "ERROR: Hubo un problema al configurar el archivo '$NSSWITCH_CONF_FILE': #group"; exit 1; }
    elif grep -q "group" "$NSSWITCH_CONF_FILE"; then
        sudo sed -i "s|^group:.*|group:                 ldap|" "$NSSWITCH_CONF_FILE" || { echo "ERROR: Hubo un problema al configurar el archivo '$NSSWITCH_CONF_FILE': group"; exit 1; }
    else
        echo "group:                ldap" >> "$NSSWITCH_CONF_FILE"
    fi
    #shadow
    if grep -q "#shadow" "$NSSWITCH_CONF_FILE"; then
        sudo sed -i "s|^#shadow:.*|shadow:              ldap|" "$NSSWITCH_CONF_FILE" || { echo "ERROR: Hubo un problema al configurar el archivo '$NSSWITCH_CONF_FILE': #shadow"; exit 1; }
    elif grep -q "shadow" "$NSSWITCH_CONF_FILE"; then
        sudo sed -i "s|^shadow:.*|shadow:               ldap|" "$NSSWITCH_CONF_FILE" || { echo "ERROR: Hubo un problema al configurar el archivo '$NSSWITCH_CONF_FILE': shadow"; exit 1; }
    else
        echo "shadow:               ldap" >> "$NSSWITCH_CONF_FILE"
    fi
    echo "LDAP entry added to file '$NSSWITCH_CONF_FILE'"
}
# This function restarts the necessary services (nscd and nslcd) to apply the changes.
function restart_services() {
    if service nscd status >/dev/null 2>&1; then
        sudo service nscd restart
    else
        echo "Error: nscd service is not installed or running."
        exit 1
    fi

    if service nslcd status >/dev/null 2>&1; then
        sudo service nslcd restart
    else
        echo "Error: nslcd service is not installed or running."
        exit 1
    fi

    echo "Services restarted successfully"
}

function edit_nsswitch() {
    change_ownership_to_user
    backup_nsswitch_conf
    add_ldap_entry
    restart_services
}
edit_nsswitch
