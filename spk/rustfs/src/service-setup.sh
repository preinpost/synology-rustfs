# shellcheck shell=bash
# shellcheck disable=SC2034  # variables are consumed by the spksrc framework
# RustFS service setup (sourced by the spksrc generic installer and start-stop-status)

INST_ETC="/var/packages/${SYNOPKG_PKGNAME}/etc"
INST_VARIABLES="${INST_ETC}/installer-variables"
ENV_VARIABLES="${SYNOPKG_PKGVAR}/environment-variables"
ACCESS_KEY_FILE="${SYNOPKG_PKGVAR}/access_key"
SECRET_KEY_FILE="${SYNOPKG_PKGVAR}/secret_key"

SVC_BACKGROUND=y
SVC_WRITE_PID=y
SVC_CWD="${SYNOPKG_PKGVAR}"

# write a credential file readable by the service user only (no trailing newline,
# rustfs uses the file content verbatim)
write_secret_file ()
{
   _file="$1"
   _value="$2"
   (umask 077; printf '%s' "${_value}" > "${_file}")
   chmod 600 "${_file}"
}

service_postinst ()
{
   # credentials: always required on install, optional (keep existing) on upgrade
   if [ -n "${wizard_access_key}" ]; then
      write_secret_file "${ACCESS_KEY_FILE}" "${wizard_access_key}"
   fi
   if [ -n "${wizard_secret_key}" ]; then
      write_secret_file "${SECRET_KEY_FILE}" "${wizard_secret_key}"
   fi

   # set the data folder in the (new) configuration file
   for _file in "${ENV_VARIABLES}" "${ENV_VARIABLES}.new"; do
      if [ -w "${_file}" ] && [ -n "${SHARE_PATH}" ]; then
         sed -i "s|@SHARE_PATH@|${SHARE_PATH}|g" "${_file}"
      fi
   done
}

# read and export variables from a text file (KEY=VALUE)
# empty lines and lines starting with # are ignored, surrounding quotes are removed
export_variables_from_file ()
{
   [ -n "$1" ] && [ -r "$1" ] || return 0
   while IFS= read -r _line || [ -n "${_line}" ]; do
      case "${_line}" in
         ''|'#'*|[[:space:]]*'#'*) continue ;;
         *=*) ;;
         *) continue ;;
      esac
      _key="${_line%%=*}"
      _key="$(echo "${_key}" | tr -d '[:space:]')"
      _value="${_line#*=}"
      case "${_value}" in
         \"*\") _value="${_value#\"}"; _value="${_value%\"}" ;;
         \'*\') _value="${_value#\'}"; _value="${_value%\'}" ;;
      esac
      [ -n "${_key}" ] && export "${_key}=${_value}"
   done < "$1"
}

service_prestart ()
{
   # SHARE_PATH is stored by the generic installer
   export_variables_from_file "${INST_VARIABLES}"

   # user configuration
   export_variables_from_file "${ENV_VARIABLES}"

   if [ -z "${RUSTFS_VOLUMES}" ] || [ "${RUSTFS_VOLUMES}" = "@SHARE_PATH@" ]; then
      export RUSTFS_VOLUMES="${SHARE_PATH}"
   fi
   export RUSTFS_ACCESS_KEY_FILE="${ACCESS_KEY_FILE}"
   export RUSTFS_SECRET_KEY_FILE="${SECRET_KEY_FILE}"
   # rustfs rejects inline keys together with key files
   unset RUSTFS_ACCESS_KEY RUSTFS_SECRET_KEY
   export HOME="${SYNOPKG_PKGVAR}"

   SERVICE_COMMAND="${SYNOPKG_PKGDEST}/bin/rustfs server"
}
