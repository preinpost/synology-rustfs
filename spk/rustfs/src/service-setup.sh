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

# Packages up to 1.0.4-1 wrote RUSTFS_VOLUMES=<path> into environment-variables.
# The data folder now always comes from SHARE_PATH (installer-variables), so
# disable such lines; otherwise a kept file would point to an old shared folder
# after "Uninstall only" + reinstall or a shared folder change on upgrade.
migrate_environment_variables ()
{
   for _file in "${ENV_VARIABLES}" "${ENV_VARIABLES}.new"; do
      [ -f "${_file}" ] && [ -w "${_file}" ] || continue
      if grep -q '^[[:space:]]*RUSTFS_VOLUMES[[:space:]]*=' "${_file}"; then
         echo "Disable RUSTFS_VOLUMES in ${_file} (data folder is the wizard shared folder: ${SHARE_PATH})"
         sed -i 's|^[[:space:]]*RUSTFS_VOLUMES[[:space:]]*=|# ignored since 1.0.4-2, data folder = wizard shared folder: &|' "${_file}"
      fi
   done
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

   migrate_environment_variables
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

# The service runs as the package user (sc-rustfs) on DSM 7, so plain
# test/touch checks the effective permissions of the service.
check_data_folder ()
{
   _dir="$1"
   _user="$(id -un 2>/dev/null)"
   _uid="$(id -u 2>/dev/null)"
   if [ -z "${_dir}" ]; then
      echo "ERROR: data folder is not set (SHARE_PATH missing in ${INST_VARIABLES})."
      echo "ERROR: run the upgrade wizard (install the same SPK again) and choose the data shared folder."
      return 1
   fi
   if [ ! -d "${_dir}" ]; then
      echo "ERROR: data folder ${_dir} does not exist."
      echo "ERROR: the shared folder may have been deleted, renamed or its volume is not mounted."
      echo "ERROR: restore the shared folder or run the upgrade wizard and choose another one."
      return 1
   fi
   _probe="${_dir}/.rustfs-write-test.$$"
   if [ -w "${_dir}" ] && [ -x "${_dir}" ] && (: > "${_probe}") 2>/dev/null; then
      rm -f "${_probe}"
      return 0
   fi
   echo "ERROR: data folder ${_dir} is not writable by the service user ${_user} (uid ${_uid})."
   echo "ERROR: current owner/permissions: $(ls -ld "${_dir}" 2>&1)"
   echo "ERROR: if the package was reinstalled, ${_user} may have a new UID and files still belong to the old one."
   echo "ERROR: fix: Control Panel > Shared Folder > (folder) > Edit > Permissions > System internal user ${_user}: Read/Write,"
   echo "ERROR: then Advanced permissions / 'Apply to this folder, sub-folders and files' (or: chown -R ${_user} ${_dir} as root)."
   return 1
}

service_prestart ()
{
   # SHARE_PATH is stored by the generic installer
   export_variables_from_file "${INST_VARIABLES}"
   _data_path="${SHARE_PATH}"

   # user configuration
   export_variables_from_file "${ENV_VARIABLES}"

   # the wizard shared folder is the only source of the data folder
   if [ -n "${RUSTFS_VOLUMES}" ] && [ "${RUSTFS_VOLUMES}" != "${_data_path}" ]; then
      echo "WARNING: RUSTFS_VOLUMES=${RUSTFS_VOLUMES} in ${ENV_VARIABLES} is ignored, using the wizard shared folder"
   fi
   export RUSTFS_VOLUMES="${_data_path}"
   check_data_folder "${RUSTFS_VOLUMES}" || exit 1

   export RUSTFS_ACCESS_KEY_FILE="${ACCESS_KEY_FILE}"
   export RUSTFS_SECRET_KEY_FILE="${SECRET_KEY_FILE}"
   # rustfs rejects inline keys together with key files
   unset RUSTFS_ACCESS_KEY RUSTFS_SECRET_KEY
   export HOME="${SYNOPKG_PKGVAR}"

   SERVICE_COMMAND="${SYNOPKG_PKGDEST}/bin/rustfs server"
}
