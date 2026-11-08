#!/bin/bash
# Upgrade wizard: the data folder is preset with the current share,
# credentials may be left empty to keep the existing ones.

INST_ETC="/var/packages/${SYNOPKG_PKGNAME}/etc"
INST_VARIABLES="${INST_ETC}/installer-variables"
SHARE_NAME=""

# Reload variables stored by the installer (we cannot source the file)
if [ -r "${INST_VARIABLES}" ]; then
   while IFS= read -r _line; do
      _key="${_line%%=*}"
      _value="${_line#*=}"
      case "${_key}" in
         SHARE_NAME) SHARE_NAME="${_value}" ;;
         SHARE_PATH) [ -z "${SHARE_NAME}" ] && SHARE_NAME="$(basename "${_value}")" ;;
      esac
   done < "${INST_VARIABLES}"
fi
[ -z "${SHARE_NAME}" ] && SHARE_NAME="rustfs"

cat <<EOW > "${SYNOPKG_TEMP_LOGFILE}"
[
   {
      "step_title": "RustFS configuration",
      "items": [
         {
            "type": "textfield",
            "desc": "Data shared folder. Keep the current value to continue using your existing data. If you change it, also update RUSTFS_VOLUMES in /var/packages/rustfs/var/environment-variables.",
            "subitems": [
               {
                  "key": "wizard_data_directory",
                  "desc": "Data shared folder",
                  "defaultValue": "${SHARE_NAME}",
                  "validator": {
                     "allowBlank": false,
                     "regex": {
                        "expr": "/^[^<>: */?\\"]*\$/",
                        "errorText": "Share name must be a folder name only. Path separators, spaces and other special chars are not allowed."
                     }
                  }
               }
            ]
         },
         {
            "desc": "Leave the credential fields empty to keep the current access key and secret key."
         },
         {
            "type": "textfield",
            "subitems": [
               {
                  "key": "wizard_access_key",
                  "desc": "New access key (optional)",
                  "defaultValue": "",
                  "validator": {
                     "allowBlank": true,
                     "regex": {
                        "expr": "/^([^=,\\\\s]{3,128})?\$/",
                        "errorText": "3-128 characters, '=', ',' and whitespace are not allowed."
                     }
                  }
               }
            ]
         },
         {
            "type": "password",
            "subitems": [
               {
                  "key": "wizard_secret_key",
                  "desc": "New secret key (optional)",
                  "defaultValue": "",
                  "validator": {
                     "allowBlank": true,
                     "regex": {
                        "expr": "/^([^=,\\\\s]{8,})?\$/",
                        "errorText": "At least 8 characters, '=', ',' and whitespace are not allowed."
                     }
                  }
               }
            ]
         }
      ]
   }
]
EOW
exit 0
