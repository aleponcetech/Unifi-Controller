#!/bin/bash

# UniFi Network Application Easy Update Script.
# Social: https://linkme.bio/aleponce
# Colabore: https://app.picpay.com/user/seuti

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
#GRAY='\033[0;37m'
#WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
#BOLD='\e[1m'

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header() {
  clear
  clear
  echo -e "${GREEN}#########################################################################${RESET}\\n"
}

header_red() {
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}\\n"
}

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i\\n"
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su\\n\\n"
  exit 1
fi

if ! grep -iq "udm" /usr/lib/version &> /dev/null; then
  if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8"; then
    header
    echo -e "${WHITE_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
    echo -e "${WHITE_R}#${RESET} Information: This is done to prevent issues in the script.."
    export LC_ALL=C &> /dev/null
    set_lc_all=true
    sleep 3
  fi
fi

abort() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL; fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!\\n"
  echo -e "${WHITE_R}#${RESET} Creating support file..."
  mkdir -p "/tmp/EUS/support" &> /dev/null
  if dpkg -l lsb-release 2> /dev/null | grep -iq "^ii\\|^hi"; then lsb_release -a &> "/tmp/EUS/support/lsb-release"; fi
  df -h &> "/tmp/EUS/support/df"
  free -hm &> "/tmp/EUS/support/memory"
  uname -a &> "/tmp/EUS/support/uname"
  dpkg -l | grep "mongo\\|oracle\\|openjdk\\|unifi" &> "/tmp/EUS/support/unifi-packages"
  dpkg -l &> "/tmp/EUS/support/dpkg-list"
  dpkg --print-architecture &> "/tmp/EUS/support/architecture"
  # shellcheck disable=SC2129
  sed -n '3p' "${script_location}" &>> "/tmp/EUS/support/script"
  grep "# Version" "${script_location}" | head -n1 &>> "/tmp/EUS/support/script"
  if dpkg -l tar 2> /dev/null | grep -iq "^ii\\|^hi"; then
    tar -cvf /tmp/eus_support.tar.gz "/tmp/EUS" "${eus_dir}" &> /dev/null && support_file="/tmp/eus_support.tar.gz"
  elif dpkg -l zip 2> /dev/null | grep -iq "^ii\\|^hi"; then
    zip -r /tmp/eus_support.zip "/tmp/EUS/*" "${eus_dir}/*" &> /dev/null && support_file="/tmp/eus_support.zip"
  fi
  if [[ -n "${support_file}" ]]; then echo -e "${WHITE_R}#${RESET} Support file has been created here: ${support_file} \\n"; fi
  exit 1
}

eus_directories() {
  if ! rm -rf /tmp/EUS &> /dev/null; then header_red; echo -e "${RED}#${RESET} Failed to remove \"/tmp/EUS\"..."; abort; fi
  if ! mkdir -p /tmp/EUS/requirement; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/sites; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/accounts; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/application; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/apt; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/dpkg; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/firmware; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/repository; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/downloads; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/keys; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/upgrade; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  if ! mkdir -p /tmp/EUS/mongodb; then header_red; echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi
  grep -riIl "unifi-[0-9].[0-9]" /etc/apt/sources.list* &> /tmp/EUS/repository/unifi-repo-file
  if uname -a | tr '[:upper:]' '[:lower:]' | grep -iq "cloudkey\\|uck\\|ubnt-mtk"; then
    eus_dir='/srv/EUS'
  elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
    eus_dir='/srv/EUS'
  else
    eus_dir='/usr/lib/EUS'
  fi
  mkdir -p "${eus_dir}"
  mkdir -p "${eus_dir}/logs"
}

script_logo() {
  cat << "EOF"
                                                                                            
   SSSSSSSSSSSSSSS EEEEEEEEEEEEEEEEEEEEEEUUUUUUUU     UUUUUUUU     TTTTTTTTTTTTTTTTTTTTTTT        IIIIIIIIII
 SS:::::::::::::::SE::::::::::::::::::::EU::::::U     U::::::U     T:::::::::::::::::::::T        I::::::::I
S:::::SSSSSS::::::SE::::::::::::::::::::EU::::::U     U::::::U     T:::::::::::::::::::::T        I::::::::I
S:::::S     SSSSSSSEE::::::EEEEEEEEE::::EUU:::::U     U:::::UU     T:::::TT:::::::TT:::::T        II::::::II
S:::::S              E:::::E       EEEEEE U:::::U     U:::::U      TTTTTT  T:::::T  TTTTTT          I::::I  
S:::::S              E:::::E              U:::::D     D:::::U              T:::::T                  I::::I  
 S::::SSSS           E::::::EEEEEEEEEE    U:::::D     D:::::U              T:::::T                  I::::I  
  SS::::::SSSSS      E:::::::::::::::E    U:::::D     D:::::U              T:::::T                  I::::I  
    SSS::::::::SS    E:::::::::::::::E    U:::::D     D:::::U              T:::::T                  I::::I  
       SSSSSS::::S   E::::::EEEEEEEEEE    U:::::D     D:::::U              T:::::T                  I::::I  
            S:::::S  E:::::E              U:::::D     D:::::U              T:::::T                  I::::I  
            S:::::S  E:::::E       EEEEEE U::::::U   U::::::U              T:::::T                  I::::I  
SSSSSSS     S:::::SEE::::::EEEEEEEE:::::E U:::::::UUU:::::::U            TT:::::::TT              II::::::II
S::::::SSSSSS:::::SE::::::::::::::::::::E  UU:::::::::::::UU             T:::::::::T       ...... I::::::::I
S:::::::::::::::SS E::::::::::::::::::::E    UU:::::::::UU               T:::::::::T       .::::. I::::::::I
 SSSSSSSSSSSSSSS   EEEEEEEEEEEEEEEEEEEEEE      UUUUUUUUU                 TTTTTTTTTTT       ...... IIIIIIIIII
 
EOF
}

start_script() {
  script_location="${BASH_SOURCE[0]}"
  script_name=$(basename "${BASH_SOURCE[0]}")
  eus_directories
  header
  script_logo
  echo -e "    UniFi Easy Update Script!"
  echo -e "\\n${WHITE_R}#${RESET} Starting the Easy Update Script.."
  echo -e "${WHITE_R}#${RESET} Thank you for using my Easy Update Script :-)\\n\\n"
  sleep 4
}
start_script

help_script() {
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${WHITE_R}----${RESET}\\n"; fi
  echo -e "    Easy UniFi Network Application Install Script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_name} [options]
  
  Script options:
    --skip                      Skip manual questions to automate --archive-alerts and --delete-events.
    --skip-install-haveged      Skip installation of haveged.
    --archive-alerts            Archive all alerts from the UniFi Network Application.
    --delete-events             Delete all events from the UniFi Network Application.
    --custom-url [argument]     Manually provide a UniFi Network Application download URL.
                                example:
                                --custom-url https://dl.ui.com/unifi/5.13.32/unifi_sysvinit_all.deb
    --help                      Shows this information :)\\n\\n"
  exit 0
}

rm --force /tmp/EUS/script_options &> /dev/null

while [ -n "$1" ]; do
  case "$1" in
  --skip)
       script_option_skip=true
       echo "--skip" &>> /tmp/EUS/script_options;;
  --skip-install-haveged)
       script_option_skip_install_haveged=true
       echo "--skip-install-haveged" &>> /tmp/EUS/script_options;;
  --archive-alerts)
       script_option_archive_alerts=true
       echo "--archive-alerts" &>> /tmp/EUS/script_options;;
  --delete-events)
       script_option_delete_events=true
       echo "--delete-events" &>> /tmp/EUS/script_options;;
  --custom-url)
       if [[ -n "${2}" ]]; then if echo "${2}" | grep -ioq ".deb"; then custom_url_down_provided=true; custom_download_url="${2}"; else header_red; echo -e "${RED}#${RESET} Provided URL does not have the 'deb' extension...\\n"; help_script; fi; fi
       script_option_custom_url=true
       if [[ "${custom_url_down_provided}" == 'true' ]]; then echo "--custom-url ${2}" &>> /tmp/EUS/script_options; else echo "--custom-url" &>> /tmp/EUS/script_options; fi;;
  --help)
       script_option_help=true
       help_script;;
  esac
  shift
done

# Check script options.
if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi

if [[ "$(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "downloads-distro.mongodb.org")" -gt 0 ]]; then
  grep -riIl "downloads-distro.mongodb.org" /etc/apt/ &>> /tmp/EUS/repository/dead_mongodb_repository
  while read -r glennr_mongo_repo; do
    sed -i '/downloads-distro.mongodb.org/d' "${glennr_mongo_repo}" 2> /dev/null
	if ! [[ -s "${glennr_mongo_repo}" ]]; then
      rm --force "${glennr_mongo_repo}" 2> /dev/null
    fi
  done < /tmp/EUS/repository/dead_mongodb_repository
  rm --force /tmp/EUS/repository/dead_mongodb_repository
fi

if apt-key list 2>/dev/null | grep mongodb -B1 | grep -iq "expired:"; then
  wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc | apt-key add - &> /dev/null
fi

find "${eus_dir}/logs/" -printf "%f\\n" | grep '.*.log' | awk '!a[$0]++' &> /tmp/EUS/log_files
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/${log_file}" ]]; then
    log_file_size=$(stat -c%s "${eus_dir}/logs/${log_file}")
    if [[ "${log_file_size}" -gt "10485760" ]]; then
      tail -n1000 "${eus_dir}/logs/${log_file}" &> "${log_file}.tmp"
      mv "${eus_dir}/logs/${log_file}.tmp" "${eus_dir}/logs/${log_file}"
    fi
  fi
done < /tmp/EUS/log_files
rm --force /tmp/EUS/log_files

start_application_upgrade() {
  header
  echo -e "${WHITE_R}#${RESET} Starting the UniFi Network Application update! \\n\\n"
  sleep 2
}

# Get distro.
get_distro() {
  if [[ -z "$(command -v lsb_release)" ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')
      elif ! grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        if [[ -z "${os_codename}" ]]; then
          os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        fi
      fi
    fi
  else
    os_codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
    if [[ "${os_codename}" == 'n/a' ]]; then
      os_codename=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    fi
  fi
  if [[ "${os_codename}" =~ (precise|maya|luna) ]]; then repo_codename=precise; os_codename=precise
  elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa|freya) ]]; then repo_codename=trusty; os_codename=trusty
  elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then repo_codename=xenial; os_codename=xenial
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then repo_codename=bionic; os_codename=bionic
  elif [[ "${os_codename}" =~ (focal|ulyana|ulyssa|uma|una) ]]; then repo_codename=focal; os_codename=focal
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then repo_codename=stretch; os_codename=stretch
  elif [[ "${os_codename}" =~ (buster|debbie|parrot|engywuck-backports|engywuck|deepin) ]]; then repo_codename=buster; os_codename=buster
  elif [[ "${os_codename}" =~ (bullseye|kali-rolling) ]]; then repo_codename=bullseye; os_codename=bullseye
  else
    repo_codename="${os_codename}"
    os_codename="${os_codename}"
  fi
}
get_distro

if ! grep -iq '^127.0.0.1.*localhost' /etc/hosts; then
  header_red
  echo -e "${WHITE_R}#${RESET} '127.0.0.1   localhost' does not exist in your /etc/hosts file."
  echo -e "${WHITE_R}#${RESET} You will most likely see UniFi Network startup issues if it doesn't exist..\\n\\n"
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to add "127.0.0.1   localhost" to your /etc/hosts file? (Y/n) ' yes_no; fi
  case "$yes_no" in
      [Yy]*|"")
          echo -e "${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} Adding '127.0.0.1       localhost' to /etc/hosts"
          sed  -i '1i # ------------------------------' /etc/hosts
          sed  -i '1i 127.0.0.1       localhost' /etc/hosts
          sed  -i '1i # Added by Ale ( EUS/EIS ) script' /etc/hosts && echo -e "${WHITE_R}#${RESET} Done..\\n\\n"
          sleep 3;;
      [Nn]*) ;;
  esac
fi

if [[ $(echo "${PATH}" | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  #PATH=$PATH:/usr/sbin
  PATH=$PATH:/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
fi

if ! [[ -d /etc/apt/sources.list.d ]]; then
  mkdir -p /etc/apt/sources.list.d
fi

# Check if --show-progrss is supported in wget version
if wget --help | grep -q '\--show-progress'; then echo "--show-progress" &>> /tmp/EUS/wget_option; fi
if [[ -f /tmp/EUS/wget_option && -s /tmp/EUS/wget_option ]]; then IFS=" " read -r -a wget_progress <<< "$(tr '\r\n' ' ' < /tmp/EUS/wget_option)"; fi

# Check if UniFi is already installed.
if ! dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi\\|^i"; then
  header_red
  echo -e "${WHITE_R}#${RESET} UniFi is not installed on your system!"
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to run the Easy Installation Script? (Y/n) ' yes_no; fi
  case "$yes_no" in
      [Yy]*|"") rm --force "${script_location}" &> /dev/null; wget -q https://github.com/SeuTI/Unifi-Controller/blob/main/unifi-latest.sh && bash unifi-latest.sh --skip; exit 0;;
      [Nn]*) exit 0;;
  esac
fi

# If there a RC?
is_there_a_release_candidate='no'

release_wanted () {
  if [[ "${is_there_a_release_candidate}" == 'no' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} There are currently no Release Candidates."
    echo -e "${WHITE_R}#${RESET} Release Stage set to | Stable."
    release_stage="S"
    release_stage_friendly="Stable"
    sleep 4
  else
    header
    echo -e "${WHITE_R}#${RESET} What release stage do you want to upgrade to?\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Stable ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Release Candidate\\n\\n"
    read -rp $'Your choice | \033[39m' release_stage
    case "$release_stage" in
        1*|"")
          release_stage="S"
          release_stage_friendly="Stable"
          if [[ "${unifi}" == '7.0.22' ]]; then
            header_red
            echo -e "${WHITE_R}#${RESET} There are currently no newer Stable Releases."
            echo -e "${WHITE_R}#${RESET} Release Stage set to | Release Candidate.\\n\\n"
            release_stage="RC"
            release_stage_friendly="Release Candidate"
            sleep 4
          fi
          if [[ "${unifi}" =~ (6.0.29|6.0.42|6.1.61|6.1.65|6.1.67|6.1.70|6.2.17|6.5.51|6.5.52|7.0.20|7.0.21) ]]; then
            header_red
            echo -e "${WHITE_R}#${RESET} Your UniFi Network is currently on a Release Candidate version."
            echo -e "${WHITE_R}#${RESET} Release Stage set to | Release Candidate.\\n\\n"
            release_stage="RC"
            release_stage_friendly="Release Candidate"
            sleep 4
          fi;;
        2*) release_stage="RC"; release_stage_friendly="Release Candidate";;
    esac
  fi
  if [[ "${release_stage}" == 'RC' ]]; then rc_version_available="7.0.22"; rc_version_available_secret="7.0.22-8c2c64c175"; fi
}

dpkg_locked_message() {
  header_red
  echo -e "${WHITE_R}#${RESET} dpkg is locked.. Waiting for other software managers to finish!"
  echo -e "${WHITE_R}#${RESET} If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums! \\n\\n"
  sleep 5
  if [[ -z "$dpkg_wait" ]]; then
    echo "glennr_lock_active" >> /tmp/glennr_lock
  fi
}

dpkg_locked_60_message() {
  header
  echo -e "${WHITE_R}#${RESET} dpkg is already locked for 60 seconds..."
  echo -e "${WHITE_R}#${RESET} Would you like to force remove the lock?\\n\\n"
}

# Check if dpkg is locked
if dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            killall apt apt-get 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null
            clear
            clear;;
          [Nn]*) dpkg_wait=true;;
      esac
    fi
  done;
else
  dpkg -i /dev/null 2> /tmp/EUS/dpkg/lock; if grep -q "locked.* another" /tmp/EUS/dpkg/lock; then dpkg_locked=true; rm --force /tmp/EUS/dpkg/lock 2> /dev/null; fi
  while [[ "${dpkg_locked}" == 'true'  ]]; do
    unset dpkg_locked
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            pgrep "apt" >> /tmp/EUS/apt
            while read -r glennr_apt; do
              kill -9 "$glennr_apt" 2> /dev/null
            done < /tmp/EUS/apt
            rm --force /tmp/EUS/apt 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null
            clear
            clear;;
          [Nn]*) dpkg_wait=true;;
      esac
    fi
    dpkg -i /dev/null 2> /tmp/EUS/dpkg/lock; if grep -q "locked.* another" /tmp/EUS/dpkg/lock; then dpkg_locked=true; rm --force /tmp/EUS/dpkg/lock 2> /dev/null; fi
  done;
  rm --force /tmp/EUS/dpkg/lock 2> /dev/null
fi

script_online_version_dots=$(curl https://get.glennr.nl/unifi/update/unifi-update.sh -s | grep "# Version" | head -n 1 | awk '{print $4}')
script_local_version_dots=$(grep "# Version" "${script_location}" | head -n 1 | awk '{print $4}')
script_online_version="${script_online_version_dots//./}"
script_local_version="${script_local_version_dots//./}"

# Script version check.
if [[ "${script_online_version::3}" -gt "${script_local_version::3}" ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
  echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy Update Script..\\n\\n"
  sleep 3
  rm --force "${script_location}" 2> /dev/null
  rm --force unifi-update.sh 2> /dev/null
  # shellcheck disable=SC2068
  wget -q "${wget_progress[@]}" https://get.glennr.nl/unifi/update/unifi-update.sh && bash unifi-update.sh ${script_options[@]}; exit 0
fi

run_apt_get_update() {
  if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi
  if ! [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    if [[ "${hide_apt_update}" == 'true' ]]; then
      echo -e "${WHITE_R}#${RESET} Running apt-get update..."
      if apt-get update &> /tmp/EUS/keys/apt_update; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${YELLOW}#${RESET} Something went wrong during running apt-get update! \\n"; fi
      unset hide_apt_update
    else
      apt-get update 2>&1 | tee /tmp/EUS/keys/apt_update
    fi
    grep -o 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update | sed 's/NO_PUBKEY //g' | tr ' ' '\n' | awk '!a[$0]++' &> /tmp/EUS/keys/missing_keys
  fi
  if [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    #header
    #echo -e "${WHITE_R}#${RESET} Some keys are missing.. The script will try to add the missing keys."
    #echo -e "\\n${WHITE_R}----${RESET}\\n"
    while read -r key; do
      echo -e "${WHITE_R}#${RESET} Key ${key} is missing.. adding!"
      http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
      if [[ -n "$http_proxy" ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
      elif [[ -f /etc/apt/apt.conf ]]; then
        apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
        if [[ -n "${apt_http_proxy}" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
        fi
      else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
      fi
      if [[ "${fail_key}" == 'true' ]]; then
        echo -e "${RED}#${RESET} Failed to add key ${key}!"
        echo -e "${WHITE_R}#${RESET} Trying different method to get key: ${key}"
        gpg -vvv --debug-all --keyserver keyserver.ubuntu.com --recv-keys "${key}" &> /tmp/EUS/keys/failed_key
        debug_key=$(grep "KS_GET" /tmp/EUS/keys/failed_key | grep -io "0x.*")
        wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=${debug_key}" -O- | gpg --dearmor > "/tmp/EUS/keys/EUS-${key}.gpg"
        mv "/tmp/EUS/keys/EUS-${key}.gpg" /etc/apt/trusted.gpg.d/ && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"
      fi
      sleep 1
    done < /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/apt_update
    #header
    #echo -e "${WHITE_R}#${RESET} Running apt-get update again.\\n\\n"
    #sleep 2
    apt-get update &> /tmp/EUS/keys/apt_update
    if grep -qo 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update; then
      if [[ "${hide_apt_update}" == 'true' ]]; then hide_apt_update=true; fi
      run_apt_get_update
    fi
  fi
}

# Check if system runs Unifi OS
if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  unifi_core_system=true
  if [[ -f /proc/ubnthal/system.info ]]; then if grep -iq "shortname" /proc/ubnthal/system.info; then unifi_core_device=$(grep "shortname" /proc/ubnthal/system.info | sed 's/shortname=//g'); fi; fi
  if [[ -f /etc/motd && -s /etc/motd && -z "${unifi_core_device}" ]]; then unifi_core_device=$(grep -io "welcome.*" /etc/motd | sed -e 's/Welcome //g' -e 's/to //g' -e 's/the //g' -e 's/!//g'); fi
  if [[ -f /usr/lib/version && -s /usr/lib/version && -z "${unifi_core_device}" ]]; then unifi_core_device=$(cut -d'.' -f1 /usr/lib/version); fi
  if [[ -z "${unifi_core_device}" ]]; then unifi_core_device='Unknown device'; fi
fi

# Install needed packages if not installed
install_required_packages() {
  sleep 2
  installing_required_package=yes
  header
  echo -e "${WHITE_R}#${RESET} Installing required packages for the script..\\n"
  hide_apt_update=true
  run_apt_get_update
  sleep 2
}
apt_get_install_package() {
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    apt_get_install_package_variable="update"
    apt_get_install_package_variable_2="updated"
  else
    apt_get_install_package_variable="install"
    apt_get_install_package_variable_2="installed"
  fi
  hide_apt_update=true
  run_apt_get_update
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
  echo -e "${WHITE_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n" && sleep 2; else echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package}! \\n"; abort; fi
  unset required_package
}
if ! dpkg -l jq 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing jq..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jq &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install jq in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main universe") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main universe") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="jq"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed jq! \\n" && sleep 2
  fi
fi
if [[ "${unifi_core_system}" != 'true' ]]; then
  if ! dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then
      install_required_packages
    fi
    echo -e "${WHITE_R}#${RESET} Installing dirmngr..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dirmngr &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install dirmngr in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
          echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} main restricted") -eq 0 ]]; then
          echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} main restricted" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
          echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      fi
      required_package="dirmngr"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed dirmngr! \\n" && sleep 2
    fi
  fi
fi
if ! dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing curl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install curl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install curl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="curl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed curl! \\n" && sleep 2
  fi
fi
if ! dpkg -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing apt-transport-https..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install apt-transport-https &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install apt-transport-https in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main universe") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="apt-transport-https"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed apt-transport-https! \\n" && sleep 2
  fi
fi
if ! dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing psmisc..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install psmisc &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install psmisc in the first run...\\n"
    if [[ "${repo_codename}" == "precise" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename}-updates main restricted") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename}-updates main restricted" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="psmisc"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed psmisc! \\n" && sleep 2
  fi
fi
if ! dpkg -l lsb-release 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing lsb-release..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install lsb-release &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install lsb-release in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} main universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} main universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="lsb-release"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed lsb-release! \\n" && sleep 2
  fi
fi
if [[ "${unifi_core_system}" != 'true' && "${script_option_skip_install_haveged}" != 'true' ]]; then
  if ! dpkg -l haveged 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then
      install_required_packages
    fi
    echo -e "${WHITE_R}#${RESET} Installing haveged..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install haveged &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install haveged in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
          echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
        if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
          echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        fi
      fi
      required_package="haveged"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed haveged! \\n" && sleep 2
    fi
  fi
fi
if ! dpkg -l perl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing perl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install perl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install perl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="perl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed perl! \\n" && sleep 2
  fi
fi
if ! dpkg -l adduser 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing adduser..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install adduser &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install adduser in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="adduser"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed adduser! \\n" && sleep 2
  fi
fi
if ! dpkg -l logrotate 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing logrotate..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install logrotate &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install logrotate in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ ${repo_codename} universe") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu/ ${repo_codename} universe" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="logrotate"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed logrotate! \\n" && sleep 2
  fi
fi

mongodb_org_shell_cache=$(apt-cache policy mongodb-org-shell | grep Installed: | awk '{print $2}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')
mongodb_clients_cache=$(apt-cache policy mongodb-clients | grep Installed: | awk '{print $2}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')
mongodb_fail=''

failed_mongodb_org_shell() {
  echo -e "\\n${RED}----${RESET}\\n"
  if [[ "${mongodb_fail}" == 'shell' ]]; then
    echo -e "${RED}#${RESET} Failed to install mongodb-org-shell, multiple options won't work with this package."
  elif [[ "${mongodb_fail}" == 'clients' ]]; then
    echo -e "${RED}#${RESET} Failed to install mongodb-clients, multiple options won't work with this package."
  fi
  echo "${WHITE_R}#${RESET} Note: creating backup etc will not work ( via the script ), I do NOT recommend going forward with a backup "
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to continue the script? (y/N) ' yes_no; fi
  case "$yes_no" in
      [Yy]*) ;;
      [Nn]*|"") abort;;
  esac
}

if [[ "${mongodb_org_shell_cache}" == *'none'* ]] && dpkg -l | grep "mongodb-org-server" | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  header_red
  echo -e "${RED}#${RESET} Mongodb-org-shell is not installed...\\n"
  echo -e "\\n------- mongodb-org-shell installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
  hide_apt_update=true
  run_apt_get_update
  shell_v_to_install=$(dpkg -l | grep "mongodb-org" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g' | sort -V | tail -n 1)
  echo -e "${RED}#${RESET} Trying to install mongodb-org-shell version ${shell_v_to_install}..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-org-shell="${shell_v_to_install}" &>> "${eus_dir}/logs/apt.log"; then
     mongodb_fail=shell
     failed_mongodb_org_shell
  else
    echo -e "${GREEN}#${RESET} Successfully installed mongodb-org-shell version ${shell_v_to_install}! \\n"
  fi
elif [[ "${mongodb_clients_cache}" == *'none'* ]] && dpkg -l | grep "mongodb-server" | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  header_red
  echo -e "${RED}#${RESET} Mongodb-clients is not installed...\\n"
  echo -e "\\n------- mongodb-clients installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
  hide_apt_update=true
  run_apt_get_update
  echo -e "${RED}#${RESET} Trying to install mongodb-clients..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-clients &>> "${eus_dir}/logs/apt.log"; then
     mongodb_fail=clients
     failed_mongodb_org_shell
  else
    echo -e "${GREEN}#${RESET} Successfully installed mongodb-clients! \\n"
  fi
fi

script_cleanup() {
  rm --force "${unifi_api_cookie}" &> /dev/null
  rm -rf /tmp/EUS &> /dev/null
}

prevent_unifi_upgrade() {
  if [[ "${prevented_unifi}" != 'yes' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Preventing Ubiquiti/UniFi package(s) from upgrading!"
    echo -e "${WHITE_R}#${RESET} These changes will be reverted when the script finishes. \\n"
    if ! [[ -d "/tmp/EUS/dpkg" ]]; then mkdir -p /tmp/EUS/dpkg; fi
    dpkg -l | awk '/unifi/ {print $2}' &> /tmp/EUS/dpkg/unifi_list
    if [[ -f /tmp/EUS/dpkg/unifi_list && -s /tmp/EUS/dpkg/unifi_list ]]; then
      while read -r service; do
        echo -e "${WHITE_R}#${RESET} Preventing ${service} from upgrading..."
        if echo "${service} hold" | dpkg --set-selections; then echo -e "${GREEN}#${RESET} Successfully prevented ${service} from upgrading! \\n"; else echo -e "${RED}#${RESET} Failed to prevent ${service} from upgrading...\\n"; abort; fi
      done < /tmp/EUS/dpkg/unifi_list
    fi
    prevented_unifi=yes
    return
  fi
  if [[ "${prevented_unifi}" == 'yes' ]]; then
    if [[ -f /tmp/EUS/dpkg/unifi_list && -s /tmp/EUS/dpkg/unifi_list ]]; then
      while read -r service; do
        echo "${service} install" | dpkg --set-selections 2> /dev/null
      done < /tmp/EUS/dpkg/unifi_list
    fi
    rm --force /tmp/EUS/dpkg/unifi_list &> /dev/null
    unset prevented_unifi
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi=$(dpkg -l | grep "unifi " | awk '{print $3}' | sed 's/-.*//')
first_digit_unifi=$(echo "${unifi}" | cut -d'.' -f1)
second_digit_unifi=$(echo "${unifi}" | cut -d'.' -f2)
third_digit_unifi=$(echo "${unifi}" | cut -d'.' -f3)
unifi_release=$(dpkg -l | grep "unifi " | awk '{print $3}' | sed 's/-.*//' | sed 's/\.//g')
os_desc=$(lsb_release -ds)
java_version=$(dpkg -l | grep "^ii\\|^hi" | grep "openjdk-8" | awk '{print $3}' | grep "^8u" | sed 's/-.*//g' | sed 's/8u//g' | grep -o '[[:digit:]]*' | sort -V | tail -n 1)
mongodb_org_v=$(dpkg -l | grep "mongodb-org" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sort -V | tail -n 1)

if [[ "${first_digit_unifi}" -ge '5' && "${second_digit_unifi}" -ge '13' ]]; then
  if [[ "${third_digit_unifi}" -ge '10' ]]; then
    mongo_version_max="36"
  else
    mongo_version_max="34"
  fi
elif [[ "${first_digit_unifi}" -ge '6' ]]; then
  mongo_version_max="36"
else
  mongo_version_max="34"
fi

unifi_version=''

glennr_unifi_backup=''
executed_unifi_credentials=''
backup_location=''
unifi_write_permission=''

user_name_exist=''
user_email_exist=''
admin_name_super=''
admin_email_super=''
ubic_2fa_token=''
two_factor=''
unifi_backup_cancel=''
application_login=''
run_unifi_firmware_check='yes'

uap_custom=''
usw_custom=''
ugw_custom=''
uap_upgrade_done='no'
usw_upgrade_done='no'
ugw_upgrade_done='no'
uap_upgrade_schedule_done='no'
usw_upgrade_schedule_done='no'
ugw_upgrade_schedule_done='no'
uap_custom_upgrade_message=''
uap_upgrade_message=''
usw_custom_upgrade_message=''
usw_upgrade_message=''
ugw_custom_upgrade_message=''

# UniFi API Variables
if [[ -f "/usr/lib/unifi/data/system.properties" ]]; then
  unifi_https_port=$(grep "^unifi.https.port=" /usr/lib/unifi/data/system.properties | sed 's/unifi.https.port//g' | tr -d '="')
fi
if [[ -z "${unifi_https_port}" ]]; then
  unifi_port_https="8443"
else
  unifi_port_https="${unifi_https_port}"
fi
if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  unifi_os_or_network="UniFi OS"
  unifi_api_baseurl="https://localhost/proxy/network"
else
  unifi_os_or_network="UniFi Network Application"
  unifi_api_baseurl="https://localhost:${unifi_port_https}"
fi
unifi_api_cookie=$(mktemp --tmpdir=/tmp/EUS unifi_api_cookie_XXXXX)
unifi_api_curl_cmd="curl --tlsv1 --silent --cookie ${unifi_api_cookie} --cookie-jar ${unifi_api_cookie} --insecure "

# UniFi Devices ( 3.7.58 )
UGW3=(UGW3) #USG3
UGW4=(UGW4) #USGP4
US24P250=(USW US8 US8P60 US8P150 US16P150 US24 US24P250 US24P500 US48 US48P500 US48P750) #USW
U7PG2=(U7LT U7LR U7PG2 U7EDU U7MSH U7MP U7IW U7IWP) #UAP-AC-Lite/LR/Pro/EDU/M/M-PRO/IW/IW-Pro
BZ2=(BZ2 BZ2LR U2O U5O) #UAP, UAP-LR, UAP-OD, UAP-OD5
U2Sv2=(U2Sv2 U2Lv2) #UAP-v2, UAP-LR-v2
U2IW=(U2IW) #UAP IW
U7P=(U7P) #UAP PRO
U2HSR=(U2HSR) #UAP OD+
U7HD=(U7HD) #UAP HD
USXG=(USXG) #USW 16 XG
U7E=(U7E U7Ev2 U7O) #UAP AC, UAP AC v2, UAP AC OD

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                                                                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

migration_check() {
  header
  echo -e "${WHITE_R}#${RESET} Checking Database migration process."
  echo -e "${WHITE_R}#${RESET} This can take up to 10 minutes before timing out! \\n\\n"
  read -rt 600 < <(tail -n 0 -f /usr/lib/unifi/logs/server.log | grep --line-buffered "DB migration to version (.*) is complete\\|*** Factory Default ***") && unifi_update=true || TIMED_OUT=true
  if [[ "${unifi_update}" == 'true' ]]; then
    unset UNIFI
    unifi=$(dpkg -l | grep "unifi " | awk '{print $3}' | sed 's/-.*//')
    header
    echo -e "${WHITE_R}#${RESET} UniFi Network Application DB migration was successful"
    echo -e "${WHITE_R}#${RESET} Currently your UniFi Network Application is on version ${WHITE_R}$unifi${RESET}\\n\\n"
    echo -e "${WHITE_R}#${RESET} Continuing the UniFi Network Application update! \\n\\n"
    unset unifi_update
    unset TIMED_OUT
    sleep 3
  elif [[ "${TIMED_OUT}" == 'true' ]]; then
    header_red
    echo -e "${RED}#${RESET} DB migration check timed out!"
    echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums! \\n\\n"
    exit 1
  fi
  echo -e "\\n"
}

remove_yourself() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${delete_script}" == 'true' ]]; then if [[ -e "${script_location}" ]]; then rm --force "${script_location}" 2> /dev/null; fi; fi
}

unifi_update_start() {
  header
  echo -e "${WHITE_R}#${RESET} Starting the UniFi Network Application update! \\n\\n"
  sleep 2
}

christmass_new_year() {
  date_d=$(date '+%d' | sed "s/^0*//g; s/\.0*/./g")
  date_m=$(date '+%m' | sed "s/^0*//g; s/\.0*/./g")
  if [[ "${date_m}" == '12' && "${date_d}" -ge '18' && "${date_d}" -lt '26' ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} Ale wishes you a Merry Christmas! May you be blessed with health and happiness!"
    christmas_message=true
  fi
  if [[ "${date_m}" == '12' && "${date_d}" -ge '24' && "${date_d}" -le '30' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May the new year turn all your dreams into reality and all your efforts into great achievements!"
    new_year_message=true
  elif [[ "${date_m}" == '12' && "${date_d}" == '31' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} Tomorrow, is the first blank page of a 365 page book. Write a good one!"
    new_year_message=true
  fi
  if [[ "${date_m}" == '1' && "${date_d}" -le '5' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date '+%Y')
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May this new year all your dreams turn into reality and all your efforts into great achievements"
    new_year_message=true
  fi
}

author() {
  if [[ "${perform_application_upgrade}" == 'true' ]]; then prevent_unifi_upgrade; fi
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' || "${script_option_archive_alerts}" == 'true' || "${script_option_delete_events}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Ale${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://linkme.bio/aleponce${RESET}\\n\\n"
}

backup_save_location() {
  if [[ "${backup_location}" == "custom" ]]; then
    if echo "${auto_dir}" | grep -q '/$'; then
      echo -e "${WHITE_R}#${RESET} Your UniFi Network Application backup is saved here: ${WHITE_R}${auto_dir}glennr-unifi-backups/${RESET}"
    else
      echo -e "${WHITE_R}#${RESET} Your UniFi Network Application backup is saved here: ${WHITE_R}${auto_dir}/glennr-unifi-backups/${RESET}"
    fi
  elif [[ "${backup_location}" == "sd_card" ]]; then
    echo -e "${WHITE_R}#${RESET} Your UniFi Network Application backup is saved here: ${WHITE_R}/data/glennr-unifi-backups/${RESET}"
  elif [[ "${backup_location}" == "sd_card_unifi_os" ]]; then
    echo -e "${WHITE_R}#${RESET} Your UniFi Network Application backup is saved here: ${WHITE_R}/sdcard/glennr-unifi-backups/${RESET}"
  elif [[ "${backup_location}" == "unifi_dir" ]]; then
    echo -e "${WHITE_R}#${RESET} Your UniFi Network Application backup is saved here: ${WHITE_R}/usr/lib/unifi/data/backup/glennr-unifi-backups/${RESET}"
  fi
}

auto_backup_write_warning() {
  if [[ "${application_login}" == 'success' ]]; then
    mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" &> /tmp/EUS/application/settings
    if grep -q 'autobackup_enabled.* true' /tmp/EUS/application/settings && [[ "${unifi_write_permission}" == "false" ]]; then
      rm --force /tmp/EUS/application/settings &> /dev/null
      echo -e "${RED}#${RESET} Your autobackups path is set to '${WHITE_R}${auto_dir}${RESET}', user UniFi is not able to backup to that location.."
      echo -e "${RED}#${RESET} I recommend checking the path and make sure the user UniFi has permissions to that directory.. or use the default location."
    elif grep -q 'autobackup_enabled.* false' /tmp/EUS/application/settings; then
      rm --force /tmp/EUS/application/settings &> /dev/null
      echo -e "${RED}#${RESET} You currently don't have autobackups turned on.."
      echo -e "${RED}#${RESET} I highly recommend turning that on, let it run daily settings only backups..."
    fi
  fi
}

override_inform_host() {
  header
  echo -e "${WHITE_R}#${RESET} Checking if the Hostname/IP override is turned on.."
  mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" &> /tmp/EUS/application/settings
  if grep -q 'override_inform_host.* false' /tmp/EUS/application/settings || ! grep -q 'override_inform_host' /tmp/EUS/application/settings; then
    rm --force /tmp/EUS/application/settings &> /dev/null
    header_red
    echo -e "${RED}#${RESET} Hostname/IP override is currently disabled, I recommend turning this on when doing a mass upgrade."
    echo -e "${RED}#${RESET} The Hostname/IP needs to be accessible for all adopted devices."
    echo -e "\\n${RED}#${RESET} Classic Settings"
    echo -e "${RED}#${RESET} Settings > Controller > Controller Settings > Controller Hostname/IP"
    get_sysinfo
    if [[ -n "$sysinfo_version" ]]; then
      if [[ "${sysinfo_version}" -ge '511' ]]; then
        echo -e "\\n${RED}#${RESET} New Settings"
        echo -e "${RED}#${RESET} Settings > Controller Settings > Advanced Configuration > Controller Hostname/IP"
      fi
    fi
    echo -e "\\n${RED}#${RESET} You can this turn this on right now, or continue without turning it on.\\n\\n"
    read -rp $'\033[39m#\033[0m Can we continue with the device upgrade? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"") ;;
        [Nn]*) cancel_script;;
    esac
  else
    echo -e "${GREEN}#${RESET} Hostname/IP is enabled!" && sleep 2
  fi
}

mail_server_recommendation() {
  mkdir -p /tmp/EUS/application && rm --force /tmp/EUS/application/settings &> /dev/null
  if [[ -d /tmp/EUS/application ]]; then
    mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" &>> /tmp/EUS/application/settings
    if [[ -f /tmp/EUS/application/settings ]]; then
      if grep -iq 'provider.*smtp' /tmp/EUS/application/settings; then
        if grep -i -A 3 "key.*super_smtp" /tmp/EUS/application/settings | grep -iq 'enabled.*false'; then
          echo -e "${RED}#${RESET} You don't seem to have a mail server setup, I highly recommend setting up the cloud mail server if you don't have a mail server yourself. ( requires Cloud Access )"
          echo -e "\\n${RED}#${RESET} Classic Settings"
          echo -e "${RED}#${RESET} Settings > Controller > Mail Server"
          get_sysinfo
          if [[ -n "$sysinfo_version" ]]; then
            if [[ "${sysinfo_version}" -ge '511' ]]; then
              echo -e "\\n${RED}#${RESET} New Settings"
              echo -e "${RED}#${RESET} Settings > Alerts > Settings > Mail Server"
            fi
          fi
        fi
      elif ! grep -iq 'provider.*cloud' /tmp/EUS/application/settings; then
        echo -e "${RED}#${RESET} You don't seem to have a mail server setup, I highly recommend setting up the cloud mail server if you don't have a mail server yourself. ( requires Cloud Access )"
        echo -e "\\n${RED}#${RESET} Classic Settings"
        echo -e "${RED}#${RESET} Settings > Controller > Mail Server"
        get_sysinfo
        if [[ -n "$sysinfo_version" ]]; then
          if [[ "${sysinfo_version}" -ge '511' ]]; then
            echo -e "\\n${RED}#${RESET} New Settings"
            echo -e "${RED}#${RESET} Settings > Alerts > Settings > Mail Server"
          fi
        fi
      fi
    fi
  fi
  rm --force /tmp/EUS/application/settings 2> /dev/null
}

unifi_update_finish() {
  if [[ "${application_login}" == 'success' ]]; then
    application_login_attempt
  fi
  unset UNIFI
  unifi=$(dpkg -l | grep "unifi " | awk '{print $3}' | sed 's/-.*//')
  login_cleanup
  header
  echo -e "${WHITE_R}#${RESET} Your UniFi Network Application has been successfully updated to ${WHITE_R}$unifi${RESET}"
  backup_save_location
  echo ""
  auto_backup_write_warning
  if [[ "${unifi}" == "5.12."* ]]; then
    echo ""
    mail_server_recommendation
  fi
  echo -e "\\n"
  author
  remove_yourself
  script_cleanup
  exit 0
}

unifi_update_latest() {
  login_cleanup
  header
  if [[ "${release_stage}" == 'RC' ]]; then
    echo -e "${WHITE_R}#${RESET} Your UniFi Network Application is already on the latest release candidate! ( ${WHITE_R}$unifi${RESET} )"
  else
    echo -e "${WHITE_R}#${RESET} Your UniFi Network Application is already on the latest stable release! ( ${WHITE_R}$unifi${RESET} )"
  fi
  backup_save_location
  echo ""
  auto_backup_write_warning
  if [[ "${unifi}" == "5.12."* ]]; then
    echo ""
    mail_server_recommendation
  fi
  echo -e "\\n"
  author
  remove_yourself
  script_cleanup
  exit 0
}

os_update_finish() {
  header
  echo -e "${WHITE_R}#${RESET} The latest patches have been successfully installed on your system! \\n\\n"
  author
  remove_yourself
  exit 0
}

event_alert_archive_delete_finish() {
  header
  echo -e "${WHITE_R}#${RESET} All Alerts and Events have been successfully archived/deleted! \\n\\n"
  author
  remove_yourself
  exit 0
}

devices_update_finish() {
  header
  if [[ "${uap_upgrade_done}" == 'no' ]] && [[ "${uap_upgrade_schedule_done}" == 'no' ]] && [[ "${usw_upgrade_done}" == 'no' ]] && [[ "${usw_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done}" == 'no' ]]; then
    echo -e "${WHITE_R}#${RESET} There were 0 devices to ${unifi_upgrade_devices_var_2}.. sorry :)"
  else
    if [[ "${uap_upgrade_schedule_done}" == 'yes' || "${usw_upgrade_schedule_done}" == 'yes' || "${ugw_upgrade_schedule_done}" == 'yes' ]]; then
      echo -e "${WHITE_R}#${RESET} Your UniFi devices have been scheduled to ${unifi_upgrade_devices_var_2}!"
    else
      echo -e "${WHITE_R}#${RESET} Your UniFi devices have been successfully ${unifi_upgrade_devices_var_2}d!"
    fi
  fi
  echo -e "\\n"
  author
  remove_yourself
  exit 0
}

cancel_script() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${script_option_skip}" == 'true' ]]; then
    echo -e "\\n${WHITE_R}#########################################################################${RESET}\\n"
  else
    header
  fi
  echo -e "${WHITE_R}#${RESET} Cancelling the script!\\n\\n"
  exit 0
}

application_startup_message() {
  header
  echo -e "${WHITE_R}#${RESET} UniFi Network Application is starting up..."
  echo -e "${WHITE_R}#${RESET} Please wait a moment.\\n\\n"
}

not_supported_version() {
  debug_check_no_upgrade
  login_cleanup
  script_cleanup
  header
  echo -e "${WHITE_R}#${RESET} Your UniFi Network Application is on a release that is not ( yet ) supported in this script."
  echo -e "${WHITE_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the Community Forums if you need help upgrading your UniFi Network Application.\\n"
  echo -e "${WHITE_R}#${RESET} Current version of your UniFi Network Application | ${WHITE_R}$unifi${RESET}"
  backup_save_location
  echo -e "\\n"
  exit 1
}

get_sysinfo() {
  if [[ "${application_login}" == 'success' ]]; then
    if ! [[ -f /tmp/EUS/application/sysinfo ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/default/stat/sysinfo" &>> /tmp/EUS/application/sysinfo_tmp
      tr -d '[:space:]' < /tmp/EUS/application/sysinfo_tmp > /tmp/EUS/application/sysinfo
      sysinfo_version=$(grep -io '"version":".*"' /tmp/EUS/application/sysinfo | cut -d':' -f2 | cut -d'}' -f1 | tr -d '"' | cut -d'.' -f1-2 | tr -d '.')
    fi
   else
    sysinfo_version=$(dpkg -l | grep "unifi " | awk '{print $3}' | sed 's/-.*//' | cut -d'.' -f1-2 | tr -d '.')
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                          Script options                                                                                         #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

only_archive_or_delete() {
  mongodb_server_version=$(dpkg -l | grep "^ii\\|^hi" | grep "mongodb-server \\|mongodb-org-server " | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')
  header
  if [[ "${script_option_archive_alerts}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} Archiving the Alerts..."
    if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
      # shellcheck disable=SC2016
      mongo --quiet --port 27117 ace --eval 'db.alarm.updateMany({},{$set: {"archived": true}})' | awk '{ modifiedCount=$10 ; print "\033[1;32m#\033[0m Successfully archived " modifiedCount " Alerts" }' # modifiedCount
    else
      # shellcheck disable=SC2016
      mongo --quiet --port 27117 ace --eval 'db.alarm.update({},{$set: {"archived": true}},{multi: true})' | awk '{ nModified=$10 ; print "\033[1;32m#\033[0m Successfully archived " nModified " Alerts" }' # nModified
    fi
    echo -e "\\n"
  fi
  if [[ "${script_option_delete_events}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} Deleting all Alerts..."
    if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
      # shellcheck disable=SC2016
      mongo --quiet --port 27117 ace --eval 'db.alarm.deleteMany({})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Alerts" }' # deletedCount
    else
      # shellcheck disable=SC2016
      mongo --quiet --port 27117 ace --eval 'db.alarm.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
    fi
    echo -e "\\n"
  fi
  author
  remove_yourself
  script_cleanup
  exit 0
}

if [[ "${script_option_archive_alerts}" == 'true' || "${script_option_delete_events}" == 'true' ]]; then only_archive_or_delete; fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  UniFi API Login/Logout/Cleanup                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

username_text() {
  header
  if [[ "${unifi_core_system}" == 'true' ]]; then
    echo -e "${YELLOW}#${RESET} Please use the Owner or any other Super Administrator account."
  else
    echo -e "${YELLOW}#${RESET} Please use your Super Administrator credentials."
  fi
  echo -e "${YELLOW}#${RESET} The credentials will only be used to login to your application installation ( api ), the credentials will not be saved."
  echo -e "\\n${WHITE_R}---${RESET}\\n"
  if [[ "${unifi_core_system}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} What is your UniFi OS Username?\\n\\n"
  else
    echo -e "${WHITE_R}#${RESET} What is your UniFi Network Application Username?\\n\\n"
  fi
}

password_text() {
  header
  if [[ "${unifi_core_system}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} What is your UniFi OS Password?\\n\\n"
  else
    echo -e "${WHITE_R}#${RESET} What is your UniFi Network Application Password?\\n\\n"
  fi
}

two_factor_request() {
  echo -e "${WHITE_R}#${RESET} Insert your 2FA token ( 6 Digits Token )\\n\\n"
  read -rp $' 2FA Token:\033[39m ' ubic_2fa_token
  if [[ -z "$ubic_2fa_token" ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} 2FA Token can't be blank...\\n\\n"
    sleep 3
    unset ubic_2fa_token
    read -rp $' 2FA Token:\033[39m ' ubic_2fa_token
  fi
}

unifi_credentials() {
  username_text
  read -rp $' Username:\033[39m ' username
  if [[ -z "$username" ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} Username can't be blank...\\n\\n"
    sleep 3
    unset username
    username_text
    read -rp $' Username:\033[39m ' username
  fi
  password_text
  read -srp " Password: " password
  if [[ -z "$password" ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} Password can't be blank...\\n\\n"
    sleep 3
    unset password
    password_text
    read -srp " Password: " password
  fi
  clear
}

username_case_sensitive_check() {
  mongo --quiet --port 27117 ace --eval "db.getCollection('admin').find({}).forEach(printjson);" >> /tmp/EUS/accounts/admin_accounts && sed -i 's/\(ObjectId(\|)\|NumberLong(\)//g' /tmp/EUS/accounts/admin_accounts
  jq -r '. | .name, .email' /tmp/EUS/accounts/admin_accounts &>> /tmp/EUS/accounts/admin_name_list
  if grep -ixq "\\b$username\\b" /tmp/EUS/accounts/admin_name_list; then
    username=$(grep -ix "\\b$username\\b" /tmp/EUS/accounts/admin_name_list | head -n1)
  fi
  rm --force /tmp/EUS/accounts/admin_name_list
}

unifi_login() {
  if [[ "${executed_unifi_login}" != 'true' ]]; then
    username_case_sensitive_check
    if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if [[ "${two_factor}" == 'enabled' ]]; then
        jq -n --arg username "$username" --arg password "$password" --arg ubic_2fa_token "$ubic_2fa_token" '{username: $username, password: $password, token: $ubic_2fa_token}' | ${unifi_api_curl_cmd} -d@- --header "Content-Type: application/json" "https://localhost/api/auth/login" &>> /tmp/EUS/application/login
      else
        jq -n --arg username "$username" --arg password "$password" '{username: $username, password: $password}' | ${unifi_api_curl_cmd} -d@- --header "Content-Type: application/json" "https://localhost/api/auth/login" &>> /tmp/EUS/application/login
      fi
    else
      if [[ "${two_factor}" == 'enabled' ]]; then
        jq -n --arg username "$username" --arg password "$password" --arg ubic_2fa_token "$ubic_2fa_token" '{username: $username, password: $password, ubic_2fa_token: $ubic_2fa_token}' | ${unifi_api_curl_cmd} -d@- "$unifi_api_baseurl/api/login" >> /tmp/EUS/application/login
      else
        jq -n --arg username "$username" --arg password "$password" '{username: $username, password: $password}' | ${unifi_api_curl_cmd} -d@- "$unifi_api_baseurl/api/login" >> /tmp/EUS/application/login
      fi
    fi
    unifi_login_check
    super_user_check
    executed_unifi_login=true
  fi
}

unifi_logout() {
  ${unifi_api_curl_cmd} "$unifi_api_baseurl/logout"
  executed_unifi_login=false
}

super_user_check() {
  if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    jq --raw-output '.permissions["network.management"] | .[]' /tmp/EUS/application/login &> /tmp/EUS/accounts/network_permissions
    jq --raw-output '.isSuperAdmin' /tmp/EUS/application/login &> /tmp/EUS/accounts/super_admin
    #if grep -iq 'true' /tmp/EUS/accounts/super_admin; then user_is_super=true; fi
    if grep -iq 'admin' /tmp/EUS/accounts/network_permissions; then user_is_admin=true; fi
    if grep -iq 'readonly' /tmp/EUS/accounts/network_permissions; then user_is_readonly=true; fi
    if [[ "${user_is_readonly}" == 'true' && "${user_is_admin}" == 'true' ]]; then
      header_red
      echo -e "${WHITE_R}#${RESET} The user is an Administrator and Read Only user!"
      echo -e "${WHITE_R}#${RESET} Please remove the read only permission or login with administrator account! \\n\\n"
      read -rp $'\033[39m#\033[0m Would you like to try another account? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"")
            unifi_login_cleanup
            login_cleanup
            unifi_logout
            unifi_credentials
            unifi_login;;
          [Nn]*) unifi_backup_cancel=true;;
      esac
    fi
  else
    mongo --quiet --port 27117 ace --eval "db.getCollection('privilege').find({}).forEach(printjson);" >> /tmp/EUS/accounts/admin_privilege && sed -i 's/\(ObjectId(\|)\)//g' /tmp/EUS/accounts/admin_privilege
    mongo --quiet --port 27117 ace --eval "db.getCollection('site').find({}).forEach(printjson);" >> /tmp/EUS/sites/application_site && sed -i 's/\(ObjectId(\|)\)//g' /tmp/EUS/sites/application_site
    mongo --quiet --port 27117 ace --eval "db.getCollection('admin').find({}).forEach(printjson);" >> /tmp/EUS/accounts/application_admins && sed -i 's/\(ObjectId(\|)\|NumberLong(\)//g' /tmp/EUS/accounts/application_admins
    super_id=$(jq -r '. | select(.name=="super" and .key=="super") | ._id' /tmp/EUS/sites/application_site && rm --force /tmp/EUS/sites/application_site 2> /dev/null)
    # shellcheck disable=SC2086
    jq -r '. | select(.site_id=="'${super_id}'" and .role=="admin") | .admin_id' /tmp/EUS/accounts/admin_privilege &>> /tmp/EUS/accounts/admin_id_list && rm --force /tmp/EUS/accounts/admin_privilege 2> /dev/null
    # shellcheck disable=SC2086
    admin_name=$(jq -r '. | select(.name=="'${username}'") | ._id' /tmp/EUS/accounts/application_admins | head -n1)
    # shellcheck disable=SC2086
    admin_email=$(jq -r '. | select(.email=="'${username}'") | ._id' /tmp/EUS/accounts/application_admins | head -n1)
    if ! grep -Fxq "$admin_name" /tmp/EUS/accounts/admin_id_list; then admin_name_super=false; fi
    if ! grep -Fxq "$admin_email" /tmp/EUS/accounts/admin_id_list; then admin_email_super=false; fi
  fi
  if [[ ( "${admin_name_super}" == 'false' && "${admin_email_super}" == 'false' ) ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} Account/User ${WHITE_R}${username}${RESET} is not a Super Administrator.."
    echo -e "${WHITE_R}#${RESET} Please use the Super Administrator credentials! \\n\\n"
    read -rp $'\033[39m#\033[0m Would you like to try another account? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
          unifi_login_cleanup
          login_cleanup
          unifi_logout
          unifi_credentials
          unifi_login;;
        [Nn]*) unifi_backup_cancel=true;;
    esac
  else
    rm --force /tmp/EUS/accounts/admin_id_list 2> /dev/null
  fi
  rm --force /tmp/EUS/accounts/application_admins 2> /dev/null
}

unifi_login_check () {
  jq -r '. | ._id' /tmp/EUS/accounts/admin_accounts &>> /tmp/EUS/accounts/admin_ids
  # shellcheck disable=SC2086
  user_name=$(jq -r '. | select(.name=="'${username}'") | ._id' /tmp/EUS/accounts/admin_accounts)
  # shellcheck disable=SC2086
  user_email=$(jq -r '. | select(.email=="'${username}'") | ._id' /tmp/EUS/accounts/admin_accounts)
  if ! grep -Fxq "$user_name" /tmp/EUS/accounts/admin_ids; then user_name_exist=false; fi
  if ! grep -Fxq "$user_email" /tmp/EUS/accounts/admin_ids; then user_email_exist=false; fi
  if [[ ( "${user_name_exist}" == 'false' && "${user_email_exist}" == 'false' && "${unifi_core_system}" != 'true' ) ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} Account/User ${WHITE_R}${username}${RESET} does not exist in the database\\n\\n"
    read -rp $'\033[39m#\033[0m Would you like to try another account? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
          unifi_login_cleanup
          account_files_cleanup
          login_cleanup
          unifi_credentials
          unifi_login;;
        [Nn]*) 
          unifi_backup_cancel=true
          unifi_login_cleanup;;
    esac
  elif grep -iq "Ubic2faToken.*Required\\|2fa.*required" /tmp/EUS/application/login; then
    unifi_login_cleanup
    header
    #echo -e "${WHITE_R}#${RESET} You seem to have 2FA enabled on your UBNT account.."
    two_factor=enabled
    two_factor_request
    unifi_login
  elif grep -iq "Invalid2FAToken" /tmp/EUS/application/login; then
    unifi_login_cleanup
    header_red
    echo -e "${WHITE_R}#${RESET} Login error... Invalid 2FA Token"
    two_factor=enabled
    two_factor_request
    unifi_login
  elif grep -iq "Invalid.*username.*password" /tmp/EUS/application/login; then
    unifi_login_cleanup
    header_red
    echo -e "${WHITE_R}#${RESET} Invalid username or password..."
    read -rp $'\033[39m#\033[0m Would you like to try again? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
          unifi_login_cleanup
          account_files_cleanup
          unifi_credentials
          unifi_login;;
        [Nn]*)
          unifi_backup_cancel=true
          unifi_login_cleanup;;
    esac
  elif grep -iq "error\\|Invalid.*username.*password" /tmp/EUS/application/login; then
    header_red
    echo -e "${WHITE_R}#${RESET} ${unifi_os_or_network} credentials are incorrect, login failed.."
    read -rp $'\033[39m#\033[0m Would you like to try again? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
          unifi_login_cleanup
          account_files_cleanup
          unifi_credentials
          unifi_login;;
        [Nn]*)
          unifi_backup_cancel=true
          unifi_login_cleanup;;
    esac
  elif grep -iq "ok\\|id" /tmp/EUS/application/login; then
    application_login=success
    unifi_login_cleanup
    header
    echo -e "${WHITE_R}#${RESET} Login success! \\n"
    sleep 2
  fi
  account_files_cleanup
}

login_cleanup() {
  unset username
  unset password
  unset ubic_2fa_token
  unset user_name
  unset user_email
  unset user_name_exist
  unset user_email_exist
  unifi_login_cleanup
}

unifi_login_cleanup() {
  if ! dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then rm --force /tmp/EUS/application/login 2> /dev/null; fi
  if [[ "${application_login}" != 'success' ]]; then rm --force /tmp/EUS/application/login 2> /dev/null; fi
}

account_files_cleanup() {
  rm --force /tmp/EUS/accounts/admin_accounts 2> /dev/null
  rm --force /tmp/EUS/accounts/admin_ids 2> /dev/null
}

application_login_attempt() {
  unifi_login
  while grep -q "error" /tmp/EUS/application/login &> /dev/null; do
    unifi_login
    unifi_login_cleanup
    application_startup_message
    sleep 5
  done;
  unifi_logout
}

application_statup_message() {
  header
  echo -e "${WHITE_R}#${RESET} UniFi Network application started successfully! \\n\\n"
  sleep 2
}

debug_check () {
  if [[ -z "${site}" ]]; then unifi_list_sites; fi
  get_sysinfo
  if [[ -f /tmp/EUS/application/sysinfo ]]; then
    if grep -iq '"debug_mgmt":"warn"' /tmp/EUS/application/sysinfo || grep -iq '"debug_system":"warn"' /tmp/EUS/application/sysinfo; then
      header
      if [[ "${sysinfo_version}" -ge '511' ]]; then log_level_setting='Verbose'; else log_level_setting='More'; fi
      echo -e "${WHITE_R}#${RESET} Settings log level for management and system to ${log_level_setting}, this is required for the script to get the needed information."
      debug_warn_info=true
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.mgmt\", \"value\":\"info\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.system\", \"value\":\"info\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
      sleep 3
      if ! grep "ok" /tmp/EUS/application/log_levels; then
        echo -e "${RED}#${RESET} Failed to set log level to ${log_level_setting}, please login to your UniFi Network Application and set the MGMT log level to ${log_level_setting}."
        echo -e "\\n${RED}#${RESET} Classic Settings"
        echo -e "${RED}#${RESET} Settings > Maintenance > Service > Log Level"
        if [[ "${sysinfo_version}" -ge '511' ]]; then
          echo -e "\\n${RED}#${RESET} New Settings"
          echo -e "${RED}#${RESET} Settings > Controller Settings > Advanced Configuration > Logging Levels"
        fi
        echo -e "\\n\\n${RED}#${RESET} Run the script again once you completed the step above."
        exit 1
      fi
    fi
  fi
}

debug_check_no_upgrade() {
  if [[ "${debug_warn_info}" == 'true' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Setting log level for management and system back to normal.\\n\\n"
    sleep 3
    ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.mgmt\", \"value\":\"warn\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
    ${unifi_api_curl_cmd} --data "{\"cmd\":\"set-param\", \"key\":\"debug.system\", \"value\":\"info\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &>> /tmp/EUS/application/log_levels
    if ! grep -iq "ok" /tmp/EUS/application/log_levels; then
      echo -e "${RED}#${RESET} Failed to set log level back to normal."
    fi
  fi
}

alert_event_cleanup() {
  #alert_find_m=$(mongo --port 27117 ace --eval 'db.alarm.find({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}})' | grep -c "log.* 127.0.0.1\|log.* 0:0:0:0:0:0:0:1")
  #event_find_m=$(mongo --port 27117 ace --eval 'db.event.find({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}})' | grep -c "log.* 127.0.0.1\|log.* 0:0:0:0:0:0:0:1")
  if [[ "${application_login}" == 'success' ]]; then
    mongodb_server_version=$(dpkg -l | grep "^ii\\|^hi" | grep "mongodb-server \\|mongodb-org-server " | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')
    header
    echo -e "${WHITE_R}#${RESET} What would you like to do with the script login events?"
    echo -e "${WHITE_R}#${RESET} Deleting/Archiving can take a while on big setups.\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Delete the Events/Alerts ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Archive the Alerts ( keeps the Alerts and deletes the Events )"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Skip ( keep the Events/Alerts )\\n\\n\\n"
    read -rp $'Your choice | \033[39m' alert_event_cleanup_question
    case "$alert_event_cleanup_question" in
        1*|"")
          header
          echo -e "${WHITE_R}#${RESET} Deleting the Alerts/Events...\\n"
          sleep 2
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            echo -e "${WHITE_R}#${RESET} Deleting Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.deleteMany({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Alerts" }' # deletedCount
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.deleteMany({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Events" }' # deletedCount
          else
            echo -e "${WHITE_R}#${RESET} Deleting Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.remove({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.remove({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Events" }' # nRemoved
          fi
          echo -e "\\n"
          sleep 2;;
        2*)
          header
          echo -e "${WHITE_R}#${RESET} Archiving the Alerts...\\n"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            echo -e "${WHITE_R}#${RESET} Archiving Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.updateMany({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{$set: {"archived": true}})' | awk '{ modifiedCount=$10 ; print "\033[1;32m#\033[0m Archived " modifiedCount " Alerts" }' # modifiedCount
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.deleteMany({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Events" }' # deletedCount
          else
            echo -e "${WHITE_R}#${RESET} Archiving Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.update({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{$set: {"archived": true}},{multi: true})' | awk '{ nModified=$10 ; print "\033[1;32m#\033[0m Archived " nModified " Alerts" }' # nModified
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.remove({"ip":{ $regex: "127.0.0.1|0:0:0:0:0:0:0:1"}},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
          fi
          echo -e "\\n"
          sleep 2;;
        3*) ;;
    esac
  fi
}
###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                      UniFi Firmware Cache                                                                                       #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_firmware_check() {
  header
  echo -e "${WHITE_R}#${RESET} Checking for Firmware Updates..."
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"check-firmware-update\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" &> /tmp/EUS/firmware/check
  if grep -iq 'ok' /tmp/EUS/firmware/check; then echo -e "${GREEN}#${RESET} Successfully checked for firmware updates"; fi
  rm --force /tmp/EUS/firmware/check 2> /dev/null
  sleep 3
}

unifi_cache_models() {
  header
  echo -e "${WHITE_R}#${RESET} Catching all the device models on your UniFi Network Application.."
  mongo --quiet --port 27117 ace --eval "db.getCollection('device').find({}).forEach(printjson);" | sed 's/\(ObjectId(\|)\|NumberLong(\)\|ISODate(//g' | jq -r '. | .model' | awk '!a[$0]++' &> /tmp/EUS/firmware/device_models
  if [[ -f /tmp/EUS/firmware/device_models && -s /tmp/EUS/firmware/device_models ]]; then echo -e "${GREEN}#${RESET} Successfully found all device models on your UniFi Network Application."; sleep 3; fi
  if grep -iq "UP1" /tmp/EUS/firmware/device_models; then echo "UP1" &>> /tmp/EUS/firmware/special_devices; fi
  if grep -iq "UP6" /tmp/EUS/firmware/device_models; then echo "UP6" &>> /tmp/EUS/firmware/special_devices; fi
  if grep -iq "USMINI" /tmp/EUS/firmware/device_models; then echo "USMINI" &>> /tmp/EUS/firmware/special_devices; fi
  sed -i -e '/UP1/d' -e '/UP6/d' -e '/USMINI/d' -e '/UDM/d' /tmp/EUS/firmware/device_models
}

unifi_cache_remove() {
  unifi_get_site_variable
  header
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-cached\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/cached
  while read -r device_model; do
    # shellcheck disable=SC2086
    fw_versions=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/cached)
    for fw_version in "${fw_versions[@]}"; do
      echo -ne "\\r${WHITE_R}#${RESET} Removing firmware version ${fw_version} for ${device_model}..."
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
      if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed cached firmware version ${fw_version} for ${device_model}!"; fi
      if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to remove cached firmware version ${fw_version} for ${device_model}..."; fi
      rm --force /tmp/EUS/firmware/removed 2> /dev/null
    done
  done < /tmp/EUS/firmware/base_models
  sleep 3
}

unifi_cache_download() {
  header
  echo -e "${GREEN}#${RESET} Downloading/Caching firmware versions for all device models on the UniFi Network Application..."
  echo -e "${GREEN}#${RESET} The duration of the download(s) depends on the internet connection.\\n\\n"
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-cached\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/currently_cached
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-available\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/available
  while read -r device_model; do
    # shellcheck disable=SC2086
    jq -r '.data[] | select(.device == "'${device_model}'") | .base_model' /tmp/EUS/firmware/available &>> /tmp/EUS/firmware/base_models_tmp
    # shellcheck disable=SC2086
    jq -r '.data[] | select(.device == "'${device_model}'") | .path' /tmp/EUS/firmware/currently_cached | cut -d'/' -f1 | awk '!a[$0]++' &>> /tmp/EUS/firmware/base_models_tmp
  done < /tmp/EUS/firmware/device_models
  if [[ -f /tmp/EUS/firmware/base_models_tmp ]]; then
    awk '!a[$0]++' /tmp/EUS/firmware/base_models_tmp &>> /tmp/EUS/firmware/base_models
    rm --force /tmp/EUS/firmware/base_models_tmp
  fi
  while read -r device_model; do
    # shellcheck disable=SC2086
    fw_version=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/available | head -n1)
    # shellcheck disable=SC2086
    cached_fw_version=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/currently_cached &> /tmp/EUS/firmware/all_currently_cached && head -n1 /tmp/EUS/firmware/all_currently_cached )
    cp /tmp/EUS/firmware/all_currently_cached /tmp/EUS/firmware/old_cached_firmware 2> /dev/null
    older_cached_fw=$(cat /tmp/EUS/firmware/old_cached_firmware && sed -i "/${cached_fw_version}/d" /tmp/EUS/firmware/old_cached_firmware)
    # shellcheck disable=SC2086
    if ! jq -r '.data[] | select(.device == "'${device_model}'")' /tmp/EUS/firmware/available | grep -iq "${device_model}"; then
      # shellcheck disable=SC2086
      if jq -r '.data[] | select(.device == "'${device_model}'")' /tmp/EUS/firmware/currently_cached | grep -iq "${device_model}"; then
        echo -e "${YELLOW}#${RESET} Firmware version ${cached_fw_version} for ${device_model} is already cached!" && sleep 1
      fi
    elif [[ "${cached_fw_version}" != "${fw_version}" ]]; then
      if [[ -n "${cached_fw_version}" ]]; then
        echo -ne "${WHITE_R}#${RESET} Removing cached firmware version ${version} for ${device_model}..."
        ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$cached_fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
        if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed cached firmware version ${cached_fw_version} for ${device_model}!"; fi
        if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to remove cached firmware version ${cached_fw_version} for ${device_model}..." && cache_download_failed=yes; fi
        rm --force /tmp/EUS/firmware/removed 2> /dev/null
        removed_cached_fw=true
      fi
    fi
    if [[ -n "${older_cached_fw}" ]]; then
      while read -r version; do
        echo -ne "\\r${WHITE_R}#${RESET} Removing older cached firmware version ${version} for ${device_model}..."
        ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
        if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed older cached firmware version ${version} for ${device_model}!"; fi
        if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to remove cached firmware version ${version} for ${device_model}..." && cache_download_failed=yes; fi
        rm --force /tmp/EUS/firmware/removed 2> /dev/null
        removed_cached_fw=true
      done < /tmp/EUS/firmware/old_cached_firmware
    fi
    # shellcheck disable=SC2086
    if [[ "${removed_cached_fw}" == 'true' ]] || jq -r '.data[] | select(.device == "'${device_model}'")' /tmp/EUS/firmware/available | grep -iq "${device_model}" &> /dev/null; then
      echo -ne "\\r${WHITE_R}#${RESET} Downloading firmware version ${fw_version} for ${device_model}..."
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"download\", \"device\":\"$device_model\", \"version\":\"$fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/download
      if grep -iq 'result.*true' /tmp/EUS/firmware/download; then echo -e "\\r${GREEN}#${RESET} Successfully downloaded firmware version ${fw_version} for ${device_model}!"; fi
      if grep -iq 'result.*false' /tmp/EUS/firmware/download; then echo -e "\\r${RED}#${RESET} Failed to downloaded firmware version ${fw_version} for ${device_model}..." && cache_download_failed=yes; fi
      rm --force /tmp/EUS/firmware/download 2> /dev/null
    fi
    unset removed_cached_fw
  done < /tmp/EUS/firmware/base_models
  if [[ -f /tmp/EUS/firmware/special_devices && -s /tmp/EUS/firmware/special_devices ]]; then
    while read -r device_model; do
      # shellcheck disable=SC2086
      cached_fw_version=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/firmware/currently_cached &> /tmp/EUS/firmware/all_currently_cached && head -n1 /tmp/EUS/firmware/all_currently_cached )
      if [[ -n "${cached_fw_version}" ]]; then 
        echo -ne "\\r${WHITE_R}#${RESET} Removing cached firmware version ${cached_fw_version} for ${device_model}..."
        ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$cached_fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/removed
        if grep -iq 'result.*true' /tmp/EUS/firmware/removed; then echo -e "\\r${GREEN}#${RESET} Successfully removed cached firmware version ${cached_fw_version} for ${device_model}!"; fi
        if grep -iq 'result.*false' /tmp/EUS/firmware/removed; then echo -e "\\r${RED}#${RESET} Failed to removed cached firmware version ${cached_fw_version} for ${device_model}..."; fi
        rm --force /tmp/EUS/firmware/removed 2> /dev/null
      fi
    done < /tmp/EUS/firmware/special_devices
  fi
  rm --force /tmp/EUS/firmware/special_devices &> /dev/null
  sleep 3
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-cached\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/firmware/cached_firmware
  if [[ "${cache_download_failed}" != 'yes' ]]; then
    firmware_cached=yes
  else
    firmware_cached=no
  fi
  rm --force /tmp/EUS/firmware/old_cached_firmware 2> /dev/null
}

firmware_cache_question() {
  header
  echo -e "${WHITE_R}#${RESET} I highly recommand caching the firmware on the UniFi Network Application prior to the device upgrades."
  read -rp $'\033[39m#\033[0m Can we proceed with the firmware download/caching? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
         unifi_cache_models
         unifi_firmware_check
         firmware_cache_directory=$(df -k /usr/lib/unifi/data/ | awk '{print $4}' | tail -n1)
         if [[ "${firmware_cache_directory}" -ge '1000000' ]]; then
           unifi_cache_download
           firmware_cached=yes
         else
           header_red
           echo -e "${RED}#${RESET} There is not enough disk space to download the firmware..\\n\\n"
           sleep 3
         fi;;
      [Nn]*) unifi_firmware_check;;
  esac
}

firmware_remove_script() {
  mkdir -p /root/EUS/
  if [[ -f /root/EUS/remove_firmware_cache.sh && -s /root/EUS/remove_firmware_cache.sh ]] && [[ -f /etc/cron.d/eus_firmware_removal_script && -s /etc/cron.d/eus_firmware_removal_script ]]; then
    header
    scheduled_time_minute=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $1}')
    scheduled_time_hour=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $2}')
    if [[ "${scheduled_time_hour}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_hour="0${scheduled_time_hour}"; fi
    if [[ "${scheduled_time_minute}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_minute="0${scheduled_time_minute}"; fi
    echo -e "${WHITE_R}#${RESET} The script seems to be scheduled already at '${scheduled_time_hour}:${scheduled_time_minute}'.."
    sleep 6
  else
    if wget -qO "/root/EUS/remove_firmware_cache.sh" 'https://github.com/SeuTI/Unifi-Controller/blob/main/remove_firmware_cache.sh'; then
      sed -i "s/change_username/${username}/g" /root/EUS/remove_firmware_cache.sh
      sed -i "s/change_password/${password}/g" /root/EUS/remove_firmware_cache.sh
      chmod +x /root/EUS/remove_firmware_cache.sh
      sed -i 's/\r//' /root/EUS/remove_firmware_cache.sh
      time_minute=$(date '+%M' | sed 's/^0*//')
      time_hour=$(date '+%H' | sed 's/^0*//')
      cron_time_hour=$((time_hour + 1))
      if [[ "${cron_time_hour}" == '24' ]]; then cron_time_hour=0; fi
      if [[ -z "${time_minute}" ]]; then time_minute=0; fi
      tee /etc/cron.d/eus_firmware_removal_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
${time_minute} ${cron_time_hour} * * * root /bin/bash /root/EUS/remove_firmware_cache.sh
EOF
    fi
  fi
}

firmware_cache_remove_question() {
  if [[ "${firmware_cached}" == 'yes' ]]; then
    fw_dir_size=$(du -sch /usr/lib/unifi/data/firmware | grep "total$" | awk '{print $1}')
    header
    if [[ "${uap_upgrade_done}" == 'no' ]] && [[ "${uap_upgrade_schedule_done}" == 'no' ]] && [[ "${usw_upgrade_done}" == 'no' ]] && [[ "${usw_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done}" == 'no' ]]; then
      echo -e "${WHITE_R}#${RESET} There were 0 devices that required an upgrade, therefore we don't need the cached firmware anymore.."
      echo -e "${WHITE_R}#${RESET} Removing cached firmware will free up ${fw_dir_size} on your disk..\\n"
      echo -e "${WHITE_R}#${RESET} What would you like to do with the cached firmware?\\n\\n"
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue and keep the cached firmware. ( default )"
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Remove the cached firmware.\\n\\n"
      read -rp $'Your choice | \033[39m' firmware_choice
      case "$firmware_choice" in
          1|"") ;;
          2) unifi_cache_remove;;
      esac
    elif [[ "${uap_upgrade_schedule_done}" == 'yes' || "${usw_upgrade_schedule_done}" == 'yes' || "${ugw_upgrade_schedule_done}" == 'yes' ]]; then
      if [[ "${two_factor}" != 'enabled' ]]; then
        echo -e "${WHITE_R}#${RESET} Information: Your UniFi Network Application login credentials will be used/copied to that script."
        read -rp $'\033[39m#\033[0m Do you want to schedule a script to remove the cached firmware after the device upgrade schedule (24 hours/1 day later)? (Y/n) ' yes_no
        case "${yes_no}" in
            [Yy]*|"")
               cron_day="$(date -d "+1 day" +"%a" | tr '[:upper:]' '[:lower:]')"
               mkdir -p /root/EUS/
               if [[ -f /root/EUS/remove_firmware_cache.sh && -s /root/EUS/remove_firmware_cache.sh ]] && [[ -f /etc/cron.d/eus_firmware_removal_script && -s /etc/cron.d/eus_firmware_removal_script ]]; then
                 header
                 scheduled_time_hour=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $2}')
                 scheduled_day=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $5}')
                 if [[ "${scheduled_time_hour}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_hour="0${scheduled_time_hour}"; fi
                 echo -e "${WHITE_R}#${RESET} The script already seems to be scheduled for: '${scheduled_day} ${scheduled_time_hour}:00'.."
                 sleep 6
               else
                 if wget -qO "/root/EUS/remove_firmware_cache.sh" 'https://github.com/SeuTI/Unifi-Controller/blob/main/remove_firmware_cache.sh'; then
                   sed -i "s/change_username/${username}/g" /root/EUS/remove_firmware_cache.sh
                   sed -i "s/change_password/${password}/g" /root/EUS/remove_firmware_cache.sh
                   chmod +x /root/EUS/remove_firmware_cache.sh
                   sed -i 's/\r//' /root/EUS/remove_firmware_cache.sh
                   tee /etc/cron.d/eus_firmware_removal_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
${cron_expr} * * ${cron_day} root /bin/bash /root/EUS/remove_firmware_cache.sh
EOF
                 fi
               fi;;
            [Nn]*|*) ;;
        esac
      fi
    else
      echo -e "${WHITE_R}#${RESET} Devices are currently using the cached firmware to upgrade... we have a few options."
      echo -e "${WHITE_R}#${RESET} Removing cached firmware will free up ${fw_dir_size} on your disk..\\n"
      if [[ "${two_factor}" != 'enabled' ]]; then
        echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue and keep the cached firmware. ( default )"
        echo -e " [   ${WHITE_R}2${RESET}   ]  |  Continue and schedule a script to remove the cached firmware after 1 hour."
        echo -e " [   ${WHITE_R}3${RESET}   ]  |  Wait 10 minutes, remove the cached firmware and then continue the script."
      else
        echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue and keep the cached firmware. ( default )"
        echo -e " [   ${WHITE_R}2${RESET}   ]  |  Wait 10 minutes, remove the cached firmware and then continue the script."
      fi
      echo -e "\\n"
      read -rp $'Your choice | \033[39m' firmware_choice
      if [[ "${two_factor}" != 'enabled' ]]; then
        case "$firmware_choice" in
            1|"") ;;
            2)
              header
              echo -e "${WHITE_R}#${RESET} Your UniFi Network Application login credentials will be used/copied to that script."
              echo -e "${WHITE_R}#${RESET} The script will run after 1 hour and will be deleted/erased.\\n\\n"
              read -rp $'\033[39m#\033[0m Do you want to schedule the script? (y/N) ' yes_no
              case "$yes_no" in
                  [Yy]*)
                     header
                     echo -e "${WHITE_R}#${RESET} Scheduling the script..\\n\\n" && sleep 2
                       mkdir -p /root/EUS/
                       if [[ -f /root/EUS/remove_firmware_cache.sh && -s /root/EUS/remove_firmware_cache.sh ]] && [[ -f /etc/cron.d/eus_firmware_removal_script && -s /etc/cron.d/eus_firmware_removal_script ]]; then
                         header
                         scheduled_time_minute=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $1}')
                         scheduled_time_hour=$(grep /root/EUS/remove_firmware_cache.sh /etc/cron.d/eus_firmware_removal_script | awk '{print $2}')
                         if [[ "${scheduled_time_hour}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_hour="0${scheduled_time_hour}"; fi
                         if [[ "${scheduled_time_minute}" =~ (^0$|^1$|^2$|^3$|^4$|^5$|^6$|^7$|^8$|^9$) ]]; then scheduled_time_minute="0${scheduled_time_minute}"; fi
                         echo -e "${WHITE_R}#${RESET} The script seems to be scheduled already at '${scheduled_time_hour}:${scheduled_time_minute}'.."
                         sleep 6
                       else
                         if wget -qO "/root/EUS/remove_firmware_cache.sh" 'https://github.com/SeuTI/Unifi-Controller/blob/main/remove_firmware_cache.sh'; then
                           sed -i "s/change_username/${username}/g" /root/EUS/remove_firmware_cache.sh
                           sed -i "s/change_password/${password}/g" /root/EUS/remove_firmware_cache.sh
                           chmod +x /root/EUS/remove_firmware_cache.sh
                           sed -i 's/\r//' /root/EUS/remove_firmware_cache.sh
                           time_minute=$(date '+%M' | sed 's/^0*//')
                           time_hour=$(date '+%H' | sed 's/^0*//')
                           cron_time_hour=$((time_hour + 1))
                           if [[ "${cron_time_hour}" == '24' ]]; then cron_time_hour=0; fi
                           if [[ -z "${time_minute}" ]]; then time_minute=0; fi
                           tee /etc/cron.d/eus_firmware_removal_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
${time_minute} ${cron_time_hour} * * * root /bin/bash /root/EUS/remove_firmware_cache.sh
EOF
                         fi
                       fi;;
                  [Nn]*|"") ;;
              esac;;
            3)
              sleep 600
              unifi_cache_remove;;
        esac
      else
        case "$firmware_choice" in
            1|"") ;;
            2)
              sleep 600
              unifi_cache_remove;;
        esac
      fi
    fi
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                      UniFi Devices Upgrade                                                                                      #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_get_site_variable() {
  if grep -iq "default" /tmp/EUS/unifi_sites; then
    site='default'
  else
    site=$(awk 'NR==1{print $1}' /tmp/EUS/unifi_sites)
  fi
}

unifi_list_sites() {
  if [[ "${executed_unifi_list_sites}" != 'true' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Catching all the site names! \\n\\n"
    sleep 2
    mkdir -p /tmp/EUS/sites
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/self/sites" | jq -r '.data[] .name' >> /tmp/EUS/unifi_sites # /api/stat/sites
    while read -r site; do
      mkdir -p "/tmp/EUS/sites/${site}/upgrade"
      # shellcheck disable=SC2086
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/self/sites" | jq -r '.data[] | select(.name == "'${site}'") | .desc' >> "/tmp/EUS/sites/${site}/site_desc" # /api/stat/sites
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/sysinfo" | jq -r '.data[] | .timezone' >> "/tmp/EUS/sites/${site}/site_timezone"
      echo -e "${GREEN}#${RESET} Successfully found site with ID ${site}"
    done < /tmp/EUS/unifi_sites
    sleep 2
    unifi_get_site_variable
    executed_unifi_list_sites=true
  fi
}

get_site_desc() {
  site_desc=$(cat "/tmp/EUS/sites/${site}/site_desc")
}

uap_upgrading() {
  echo -e "\\n${GREEN}---${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} The UniFi Access Points are currently ${unifi_upgrade_devices_var_1}..."
  echo -e "${WHITE_R}#${RESET} Waiting 20 seconds before updating the UniFi Switches."
  echo -e "\\n${GREEN}---${RESET}\\n"
  sleep 20
}

usw_upgrading() {
  echo -e "\\n${GREEN}---${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} The UniFi Switches are currently ${unifi_upgrade_devices_var_1}..."
  echo -e "${WHITE_R}#${RESET} Waiting 20 seconds before updating the UniFi Gateways."
  echo -e "\\n${GREEN}---${RESET}\\n"
  sleep 20
}

cached_firmware_url() {
  if [[ "${firmware_cached}" == 'yes' ]]; then
    # shellcheck disable=SC2086
    cached_fw_path=$(jq -r '.data[] | select(.device == "'$model'") | .path' /tmp/EUS/firmware/cached_firmware)
    mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" &> /tmp/EUS/application/settings
    if grep -q 'override_inform_host.*true' /tmp/EUS/application/settings; then
      application_inform_address=$(grep "hostname" /tmp/EUS/application/settings | awk '{print $3}' | tr -d '="')
    else
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select(.uptime >= 0) | .inform_ip' >> /tmp/EUS/device_inform
      application_inform_address=$(tail -n1 /tmp/EUS/device_inform)
    fi
    if [[ -f "/usr/lib/unifi/data/system.properties" ]]; then
      http_unifi_port=$(grep "^unifi.http.port=" /usr/lib/unifi/data/system.properties | sed 's/unifi.http.port//g' | tr -d '="')
    fi
    if [[ -z "${http_unifi_port}" ]]; then
      cache_fw_port="8080"
    else
      cache_fw_port="${http_unifi_port}"
    fi
    rm --force /tmp/EUS/application/settings &> /dev/null
  fi
}

uap_custom_upgrade_commands() {
  get_site_desc
  ${unifi_api_curl_cmd}  --data "{\"url\":\"${firmware_url}\", \"mac\":\"${uap_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade-external" >> "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"
  if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"; then echo -e "${GREEN}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is now upgrading.."; fi
  if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"; then echo -e "${YELLOW}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is already upgrading.."; fi
  rm --force "/tmp/EUS/sites/${site}/upgrade/uap_custom_upgrade_output"
}

uap_upgrade() {
  while read -r site; do
    if [[ "${option_upgrade}" == 'true' ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac" #/tmp/EUS/uaps_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.model == "UP1", .model == "UP6") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac"
    else
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac" #/tmp/EUS/uaps_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.model == "UP1", .model == "UP6") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.model == "UAP6MP", .model == "U6M") and (.version <= "5.66.0") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" &> /dev/null; else while read -r mac_u6qca_special; do sed -i "/${mac_u6qca_special}/d" "/tmp/EUS/sites/${site}/upgrade/uap_mac" &> /dev/null; done < "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"; fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/uap_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/uap_mac"; fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/uap_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/upgrade/uap_mac" ]]; then
      uap_upgrade_done=yes
      if [[ "${uap_upgrade_message}" != "true" ]]; then echo -e "${WHITE_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi Access Points.\\n"; uap_upgrade_message=true; fi
      get_site_desc
      while read -r uap_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${uap_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"; then echo -e "${GREEN}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"; then echo -e "${YELLOW}#${RESET} UAP with MAC address '${uap_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/uap_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/uap_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version < "3.8")) | .model' | sed '/UP1/d' >> /tmp/EUS/uap_models
    if [[ -s /tmp/EUS/uap_models ]]; then
      uap_custom=yes
      uap_upgrade_done=yes
    else
      rm --force /tmp/EUS/uap_models
    fi
    if [[ "${uap_custom}" == 'yes' ]]; then
      while read -r model; do
        # shellcheck disable=SC2086
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uap") and (.version < "3.8") and (.model == "'${model}'") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/${model}_mac" #/tmp/EUS/uaps_upgraded > /dev/null ( tee -a )
        cached_firmware_url
        if [[ "${uap_custom_upgrade_message}" != "true" ]]; then
          echo -e "${WHITE_R}#${RESET} Custom upgrading UniFi Access Points! \\n"
          uap_custom_upgrade_message=true
        fi
        if [[ ${U7PG2[*]} =~ ${model} ]]; then # -- UAP-AC-Lite/LR/Pro/EDU/M/M-PRO/IW/IW-Pro
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ubnt.com/api/firmware-latest?filter=eq~~platform~~U7PG2&filter=eq~~channel~~release" | jq -r '._embedded.firmware[]._links.data.href' | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/U7PG2/4.0.80.10875/BZ.qca956x.v4.0.80.10875.200111.2335.bin"; fi
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${BZ2[*]} =~ ${model} ]]; then # -- UAP, UAP-LR, UAP-OD, UAP-OD5
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/BZ2/4.0.10.9653/BZ.ar7240.v4.0.10.9653.181205.1311.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U2Sv2[*]} =~ ${model} ]]; then # -- UAP-v2, UAP-LR-v2
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U2Sv2/4.0.10.9653/BZ.qca9342.v4.0.10.9653.181205.1310.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U2IW[*]} =~ ${model} ]]; then # -- UAP-IW
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U2IW/4.0.10.9653/BZ.qca933x.v4.0.10.9653.181205.1310.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U7P[*]} =~ ${model} ]]; then # -- UAP-PRO
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U7P/4.0.10.9653/BZ.ar934x.v4.0.10.9653.181205.1310.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U2HSR[*]} =~ ${model} ]]; then # -- UAP-OD+
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U2HSR/4.0.10.9653/BZ.ar7240.v4.0.10.9653.181205.1311.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U7HD[*]} =~ ${model} ]]; then # -- UAP-HD/SHD/XG/BaseStationXG
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ubnt.com/api/firmware-latest?filter=eq~~platform~~U7HD&filter=eq~~channel~~release" | jq -r '._embedded.firmware[]._links.data.href' | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/U7HD/4.0.80.10875/BZ.ipq806x.v4.0.80.10875.200111.1635.bin"; fi
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${U7E[*]} =~ ${model} ]]; then # -- UAP-AC, UAP-AC v2, UAP-AC-OD
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url="http://dl.ui.com/unifi/firmware/U7E/3.8.17.6789/BZ.bcm4706.v3.8.17.6789.190110.0913.bin"
          fi
          while read -r uap_mac; do
            uap_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        fi
      done < /tmp/EUS/uap_models
    fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" && -s "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" ]]; then uap_u6qca_special_custom=yes; uap_upgrade_done=yes; else rm --force "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"; fi
    if [[ "${uap_u6qca_special_custom}" == 'yes' ]]; then
      if [[ "${uap_custom_upgrade_message_u6qca}" != "true" ]]; then echo -e "${WHITE_R}#${RESET} Custom upgrading U6-Pro/U6-Mesh UniFi Access Points! \\n"; uap_custom_upgrade_message_u6qca=true; fi
      if [[ -f "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" && -s "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special" ]]; then
        firmware_url="https://dl.ui.com/unifi/firmware/UAP6MP/5.67.0.13114/BZ.ipq50xx_5.67.0+13114.210608.1558.bin"
        while read -r uap_mac; do
          uap_custom_upgrade_commands
        done < "/tmp/EUS/sites/${site}/upgrade/uap_mac_u6qca_special"
      fi
    fi
  done < /tmp/EUS/unifi_sites
}

usw_custom_upgrade_commands() {
  get_site_desc
  ${unifi_api_curl_cmd}  --data "{\"url\":\"${firmware_url}\", \"mac\":\"${usw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade-external" >> "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"
  if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"; then echo -e "${GREEN}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is now upgrading.."; fi
  if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"; then echo -e "${YELLOW}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is already upgrading.."; fi
  rm --force "/tmp/EUS/sites/${site}/upgrade/usw_custom_upgrade_output"
}

usw_upgrade() {
  while read -r site; do
    if [[ "${option_upgrade}" == 'true' ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.model == "USMINI") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
    else
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version > "3.8") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.model == "USMINI") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.model == "USL16P", .model == "USL24P") and (.version <= "4.0.50") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" #/tmp/EUS/usws_upgraded > /dev/null ( tee -a )
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" &> /dev/null; else while read -r mac_gen2_special; do sed -i "/${mac_gen2_special}/d" "/tmp/EUS/sites/${site}/upgrade/usw_mac" &> /dev/null; done < "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special"; fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/usw_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/usw_mac" &> /dev/null; fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/usw_mac" && -s "/tmp/EUS/sites/${site}/upgrade/usw_mac" ]]; then
      usw_upgrade_done=yes
      if [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${usw_upgrade_message}" != "true" ]]; then echo -e "${WHITE_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi Switches.\\n"; usw_upgrade_message=true; fi
      get_site_desc
      while read -r usw_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${usw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"; then echo -e "${GREEN}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"; then echo -e "${YELLOW}#${RESET} USW with MAC address '${usw_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/usw_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/usw_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version < "3.8")) | .model' | sed '/USMINI/d' >> /tmp/EUS/usw_models
    if [[ -s /tmp/EUS/usw_models ]]; then
      usw_custom=yes
      usw_upgrade_done=yes
    else
      rm --force /tmp/EUS/usw_models
    fi
    if [[ "${usw_custom}" == 'yes' ]]; then
      while read -r model; do
        # shellcheck disable=SC2086
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "usw") and (.version < "3.8") and (.model == "'${model}'") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/${model}_mac" #/tmp/EUS/usws_upgraded > /dev/null ( tee -a )
        cached_firmware_url
        if [[ "${check_uap_upgrade}" != 'yes' ]]; then
          check_uap_upgrades
        fi
        if [[ "${usw_custom_upgrade_message}" != "true" ]]; then
          echo -e "${WHITE_R}#${RESET} Custom ${unifi_upgrade_devices_var_1} UniFi Switches! \\n"
          usw_custom_upgrade_message=true
        fi
        if [[ ${USXG[*]} =~ ${model} ]]; then # -- US-16-XG
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ubnt.com/api/firmware-latest?filter=eq~~platform~~USXG&filter=eq~~channel~~release" | jq -r '._embedded.firmware[]._links.data.href' | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/USXG/4.0.80.10875/US.bcm5341x.v4.0.80.10875.200111.1635.bin"; fi
          fi
          while read -r usw_mac; do
            usw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${US24P250[*]} =~ ${model} ]]; then # -- US/US-POE
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ubnt.com/api/firmware-latest?filter=eq~~platform~~US24P250&filter=eq~~channel~~release" | jq -r '._embedded.firmware[]._links.data.href' | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/US24P250/4.0.80.10875/US.bcm5334x.v4.0.80.10875.200111.2335.bin"; fi
          fi
          while read -r usw_mac; do
            usw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        fi
      done < /tmp/EUS/usw_models
    fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" && -s "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" ]]; then usw_gen2_special_custom=yes; usw_upgrade_done=yes; else rm --force "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special"; fi
    if [[ "${usw_gen2_special_custom}" == 'yes' ]]; then
      if [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${usw_custom_upgrade_message_gen2}" != "true" ]]; then echo -e "${WHITE_R}#${RESET} Custom upgrading Gen2 UniFi Switches! \\n"; usw_custom_upgrade_message_gen2=true; fi
      if [[ -f "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" && -s "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special" ]]; then
        firmware_url="https://dl.ui.com/unifi/firmware/USL16P/4.0.49.10569/US.rtl838x.v4.0.49.10569.190708.1559.bin"
        while read -r usw_mac; do
          usw_custom_upgrade_commands
        done < "/tmp/EUS/sites/${site}/upgrade/usw_mac_gen2_special"
      fi
    fi
  done < /tmp/EUS/unifi_sites
}

ugw_custom_upgrade_commands() {
  get_site_desc
  ${unifi_api_curl_cmd}  --data "{\"url\":\"${firmware_url}\", \"mac\":\"${ugw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade-external" >> "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"
  if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"; then echo -e "${GREEN}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is now upgrading.."; fi
  if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"; then echo -e "${YELLOW}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is already upgrading.."; fi
  rm --force "/tmp/EUS/sites/${site}/upgrade/ugw_custom_upgrade_output"
}

ugw_upgrade() {
  while read -r site; do
    if [[ "${option_upgrade}" == 'true' ]]; then
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version > "4.4.20") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/ugw_mac" #/tmp/EUS/ugws_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uxg") and (.version > "0.1.0") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uxg_mac"
    else
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version > "4.4.20") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/ugw_mac" #/tmp/EUS/ugws_upgraded > /dev/null ( tee -a )
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "uxg") and (.version > "0.1.0") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/uxg_mac"
    fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/uxg_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/uxg_mac"; fi
    if ! [[ -s "/tmp/EUS/sites/${site}/upgrade/ugw_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/upgrade/ugw_mac"; fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/uxg_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/upgrade/uxg_mac" ]]; then
      ugw_upgrade_done=yes
      if [[ "${check_usw_upgrade}" != 'yes' ]]; then check_usw_upgrades; elif [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${uxg_upgrade_message}" != "true" ]]; then echo -e "${WHITE_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi NeXt-Gen Gateways.\\n"; uxg_upgrade_message=true; fi
      get_site_desc
      while read -r uxg_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${uxg_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"; then echo -e "${GREEN}#${RESET} UXG with MAC address '${uxg_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"; then echo -e "${YELLOW}#${RESET} UXG with MAC address '${uxg_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/uxg_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/uxg_mac"
    fi
    if [[ -f "/tmp/EUS/sites/${site}/upgrade/ugw_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/upgrade/ugw_mac" ]]; then
      ugw_upgrade_done=yes
      if [[ "${check_usw_upgrade}" != 'yes' ]]; then check_usw_upgrades; elif [[ "${check_uap_upgrade}" != 'yes' ]]; then check_uap_upgrades; fi
      if [[ "${ugw_upgrade_message}" != "true" ]]; then echo -e "${WHITE_R}#${RESET} ${unifi_upgrade_devices_var_1} UniFi Security Gateways.\\n"; ugw_upgrade_message=true; fi
      get_site_desc
      while read -r ugw_mac; do
        ${unifi_api_curl_cmd} --data "{\"mac\":\"${ugw_mac}\"}" "$unifi_api_baseurl/api/s/${site}/cmd/devmgr/upgrade" >> "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"
        if grep -iq 'ok' "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"; then echo -e "${GREEN}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is now ${unifi_upgrade_devices_var_1}.."; fi
        if grep -iq 'UpgradeInProgress' "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"; then echo -e "${YELLOW}#${RESET} UGW with MAC address '${ugw_mac}' from site '${site_desc}' is already ${unifi_upgrade_devices_var_1}.."; fi
        rm --force "/tmp/EUS/sites/${site}/upgrade/ugw_upgrade_output"
      done < "/tmp/EUS/sites/${site}/upgrade/ugw_mac"
    fi
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version < "4.4.20")) | .model' >> /tmp/EUS/ugw_models
    if [[ -s /tmp/EUS/ugw_models ]]; then
      ugw_custom=yes
      ugw_upgrade_done=yes
    else
      rm --force /tmp/EUS/ugw_models
    fi
    if [[ "${ugw_custom}" == 'yes' ]]; then
      while read -r model; do
        # shellcheck disable=SC2086
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "ugw") and (.version < "4.4.20") and (.model == "'${model}'") and (.adopted == true) and (.uptime >= 0)) | .mac' &>> "/tmp/EUS/sites/${site}/upgrade/${model}_mac" #/tmp/EUS/ugws_upgraded > /dev/null ( tee -a )
        cached_firmware_url
        if [[ "${ugw_custom_upgrade_message}" != "true" ]]; then
          if [[ "${check_usw_upgrade}" != 'yes' ]]; then
            check_usw_upgrades
          elif [[ "${check_uap_upgrade}" != 'yes' ]]; then
            check_uap_upgrades
          fi
          echo -e "${WHITE_R}#${RESET} Custom upgrading UniFi Security Gateways! \\n"
          ugw_custom_upgrade_message=true
        fi
        if [[ ${UGW3[*]} =~ ${model} ]]; then # -- USG3
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ubnt.com/api/firmware-latest?filter=eq~~platform~~UGW3&filter=eq~~channel~~release" | jq -r '._embedded.firmware[]._links.data.href' | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/UGW3/4.4.51.5287926/UGW3.v4.4.51.5287926.tar"; fi
          fi
          while read -r ugw_mac; do
            ugw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        elif [[ ${UGW4[*]} =~ ${model} ]]; then # -- USG-PRO-4
          if [[ "${firmware_cached}" == 'yes' ]]; then
            firmware_url="http://${application_inform_address}:${cache_fw_port}/dl/firmware-cached/${cached_fw_path}"
          else
            firmware_url=$(curl -s "http://fw-update.ubnt.com/api/firmware-latest?filter=eq~~platform~~UGW4&filter=eq~~channel~~release" | jq -r '._embedded.firmware[]._links.data.href' | sed 's/https/http/g')
            if [[ -z "${firmware_url}" ]]; then firmware_url="http://dl.ui.com/unifi/firmware/UGW4/4.4.51.5287926/UGW4.v4.4.51.5287926.tar"; fi
          fi
          while read -r ugw_mac; do
            ugw_custom_upgrade_commands
          done < "/tmp/EUS/sites/${site}/upgrade/${model}_mac"
        fi
      done < /tmp/EUS/ugw_models
    fi
  done < /tmp/EUS/unifi_sites
}

check_uap_upgrades() {
  if [[ "${uap_upgrade_done}" == 'yes' ]]; then
    uap_upgrading
    check_uap_upgrade=yes
  fi
}

check_usw_upgrades() {
  if [[ "${usw_upgrade_done}" == 'yes' ]]; then
    usw_upgrading
    check_usw_upgrade=yes
  fi
}

check_uap_upgraded() {
  if [[ "${uap_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 UAP(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

check_usw_upgraded() {
  if [[ "${usw_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 USW(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

check_uxg_upgraded() {
  if [[ "${ugw_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 UXG(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

check_ugw_upgraded() {
  if [[ "${ugw_upgrade_done}" == 'no' ]]; then echo -e "\\n${GREEN}#${RESET} There were 0 UGW(s) that needed a firmware ${unifi_upgrade_devices_var_2}.."; fi
}

unifi_upgrade_devices() {
  header
  echo -e "\\n${WHITE_R}#${RESET} Starting the device ${unifi_upgrade_devices_var_2}!"
  echo -e "\\n${GREEN}---${RESET}\\n"
  uap_upgrade
  check_uap_upgraded
  usw_upgrade
  check_usw_upgraded
  ugw_upgrade
  check_uxg_upgraded
  check_ugw_upgraded
  sleep 3
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 UniFi Devices Update Scheduling                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

check_uap_scheduled() {
  if [[ "${uap_upgrade_schedule_done}" == 'no' ]] && [[ "${uap_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 UAP(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any UAPs."
    uap_upgrade_schedule_done_message=yes
  fi
}

check_usw_scheduled() {
  if [[ "${usw_upgrade_schedule_done}" == 'no' ]] && [[ "${usw_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 USW(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any USWs."
    usw_upgrade_schedule_done_message=yes
  fi
}

check_uxg_scheduled() {
  if [[ "${uxg_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 UXG(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any UXGs."
    ugw_upgrade_schedule_done_message=yes
  fi
}

check_ugw_scheduled() {
  if [[ "${ugw_upgrade_schedule_done}" == 'no' ]] && [[ "${ugw_upgrade_schedule_done_message}" != 'yes' ]]; then
    echo -e "\\n${GREEN}#${RESET} There were 0 UGW(s) that needed a firmware ${unifi_upgrade_devices_var_2}, script didn't schedule any UGWs."
    ugw_upgrade_schedule_done_message=yes
  fi
}

schedule_time_question() {
  header
  echo -e "${WHITE_R}#${RESET} Information: The device ${unifi_upgrade_devices_var_2} will be exectured at the choosen time at the sites timezone."
  echo -e "${WHITE_R}#${RESET} At what time do you want to schedule your devices to update?"
  echo -e "\\n${WHITE_R}---${RESET}\\n"
  echo -e " [   ${WHITE_R}1 ${RESET}   ]  |  1 AM          ${GREEN}|${RESET}          [   ${WHITE_R}13${RESET}   ]  |  1 PM"
  echo -e " [   ${WHITE_R}2 ${RESET}   ]  |  2 AM          ${GREEN}|${RESET}          [   ${WHITE_R}14${RESET}   ]  |  2 PM"
  echo -e " [   ${WHITE_R}3 ${RESET}   ]  |  3 AM          ${GREEN}|${RESET}          [   ${WHITE_R}15${RESET}   ]  |  3 PM"
  echo -e " [   ${WHITE_R}4 ${RESET}   ]  |  4 AM          ${GREEN}|${RESET}          [   ${WHITE_R}16${RESET}   ]  |  4 PM"
  echo -e " [   ${WHITE_R}5 ${RESET}   ]  |  5 AM          ${GREEN}|${RESET}          [   ${WHITE_R}17${RESET}   ]  |  5 PM"
  echo -e " [   ${WHITE_R}6 ${RESET}   ]  |  6 AM          ${GREEN}|${RESET}          [   ${WHITE_R}18${RESET}   ]  |  6 PM"
  echo -e " [   ${WHITE_R}7 ${RESET}   ]  |  7 AM          ${GREEN}|${RESET}          [   ${WHITE_R}19${RESET}   ]  |  7 PM"
  echo -e " [   ${WHITE_R}8 ${RESET}   ]  |  8 AM          ${GREEN}|${RESET}          [   ${WHITE_R}20${RESET}   ]  |  8 PM"
  echo -e " [   ${WHITE_R}9 ${RESET}   ]  |  9 AM          ${GREEN}|${RESET}          [   ${WHITE_R}21${RESET}   ]  |  9 PM"
  echo -e " [   ${WHITE_R}10${RESET}   ]  |  10 AM         ${GREEN}|${RESET}          [   ${WHITE_R}22${RESET}   ]  |  10 PM"
  echo -e " [   ${WHITE_R}11${RESET}   ]  |  11 AM         ${GREEN}|${RESET}          [   ${WHITE_R}23${RESET}   ]  |  11 PM"
  echo -e " [   ${WHITE_R}12${RESET}   ]  |  12 PM         ${GREEN}|${RESET}          [   ${WHITE_R}24${RESET}   ]  |  12 AM"
  echo -e "\\n"
  read -rp $'Your choice | \033[39m' choice
  case "$choice" in
     1) cron_expr='0 1'; cron_expr_human='1 AM';;
     2) cron_expr='0 2'; cron_expr_human='2 AM';;
     3) cron_expr='0 3'; cron_expr_human='3 AM';;
     4) cron_expr='0 4'; cron_expr_human='4 AM';;
     5) cron_expr='0 5'; cron_expr_human='5 AM';;
     6) cron_expr='0 6'; cron_expr_human='6 AM';;
     7) cron_expr='0 7'; cron_expr_human='7 AM';;
     8) cron_expr='0 8'; cron_expr_human='8 AM';;
     9) cron_expr='0 9'; cron_expr_human='9 AM';;
     10) cron_expr='0 10'; cron_expr_human='10 AM';;
     11) cron_expr='0 11'; cron_expr_human='11 AM';;
     12) cron_expr='0 12'; cron_expr_human='12 PM';;
     13) cron_expr='0 13'; cron_expr_human='1 PM';;
     14) cron_expr='0 14'; cron_expr_human='2 PM';;
     15) cron_expr='0 15'; cron_expr_human='3 PM';;
     16) cron_expr='0 16'; cron_expr_human='4 PM';;
     17) cron_expr='0 17'; cron_expr_human='5 PM';;
     18) cron_expr='0 18'; cron_expr_human='6 PM';;
     19) cron_expr='0 19'; cron_expr_human='7 PM';;
     20) cron_expr='0 20'; cron_expr_human='8 PM';;
     21) cron_expr='0 21'; cron_expr_human='9 PM';;
     22) cron_expr='0 22'; cron_expr_human='10 PM';;
     23) cron_expr='0 23'; cron_expr_human='11 PM';;
     24) cron_expr='0 0'; cron_expr_human='12 AM';;
	 *) 
        header_red
        echo -e "${WHITE_R}#${RESET} '${choice}' is not a valid option..." && sleep 2
        schedule_time_question;;
  esac
}

device_upgrade_schedule() {
  echo -e "uap\\nusw\\nuxg\\nugw" &> /tmp/EUS/device_types
  while read -r device_type; do
    while read -r site; do
      ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/rest/scheduletask" | jq -r '.data[] | select(.execute_only_once == true) | .upgrade_targets | .[] | .mac' &> "/tmp/EUS/sites/${site}/scheduletask"
      if ! [[ -s "/tmp/EUS/sites/${site}/scheduletask" ]]; then rm --force "/tmp/EUS/sites/${site}/scheduletask" &> /dev/null; fi
      get_site_desc
      site_timezone=$(tail -n1 "/tmp/EUS/sites/${site}/site_timezone")
      type_2=$(echo "${device_type}" | tr '[:lower:]' '[:upper:]')
      if [[ "${device_type}" == 'uap' ]]; then type_long="UniFi Access Points"; elif [[ "${device_type}" == 'usw' ]]; then type_long="UniFi Switches"; elif [[ "${device_type}" == 'uxg' ]]; then type_long="UniFi NeXt-Gen Gateways"; elif [[ "${device_type}" == 'ugw' ]]; then type_long="UniFi Security Gateways"; fi
      # shellcheck disable=SC2086
      if [[ "${option_upgrade}" == 'true' ]]; then
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "'${device_type}'") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) < (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true)) | .mac' &>> "/tmp/EUS/sites/${site}/${device_type}_mac"
      else
        ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/device" | jq -r '.data[] | select((.type == "'${device_type}'") and (.upgradable == true) and (.version | split (".")[-1] | tonumber) > (.upgrade_to_firmware | split (".")[-1] | tonumber) and (.adopted == true)) | .mac' &>> "/tmp/EUS/sites/${site}/${device_type}_mac"
      fi
      if ! [[ -s "/tmp/EUS/sites/${site}/${device_type}_mac" ]]; then rm --force "/tmp/EUS/sites/${site}/${device_type}_mac" &> /dev/null; fi
      if [[ -f "/tmp/EUS/sites/${site}/${device_type}_mac" ]] && [[ -s "/tmp/EUS/sites/${site}/${device_type}_mac" ]]; then
        if [[ "${device_type}" == 'uap' ]]; then uap_upgrade_schedule_done=yes; elif [[ "${device_type}" == 'usw' ]]; then usw_upgrade_schedule_done=yes; elif [[ "${device_type}" == 'uxg' ]]; then uxg_upgrade_schedule_done=yes; elif [[ "${device_type}" == 'ugw' ]]; then ugw_upgrade_schedule_done=yes; fi
        if ! [[ -f "/tmp/EUS/${device_type}_schedule_message" ]]; then
          echo -e "${WHITE_R}#${RESET} Scheduling updates for the ${type_long}.\\n"
          touch "/tmp/EUS/${device_type}_schedule_message"
        fi
        while read -r mac; do
          if grep -iq "${mac}" "/tmp/EUS/sites/${site}/scheduletask" &> /dev/null; then
            echo -e "${YELLOW}#${RESET} ${type_2} with MAC address '${mac}' from site '${site_desc}' is already scheduled.."
          else
            schedule_name="EUS ${type_2} Upgrade | ${mac}"
            ${unifi_api_curl_cmd}  --data "{\"cron_expr\":\"${cron_expr} * * *\",\"name\":\"${schedule_name}\",\"execute_only_once\":true,\"action\":\"upgrade\",\"upgrade_targets\":[{\"mac\":\"${mac}\"}]}" "$unifi_api_baseurl/api/s/${site}/rest/scheduletask" >> "/tmp/EUS/sites/${site}/${device_type}_upgrade_schedule_output"
            if grep -iq 'ok' "/tmp/EUS/sites/${site}/${device_type}_upgrade_schedule_output"; then echo -e "${GREEN}#${RESET} ${type_2} with MAC address '${mac}' from site '${site_desc}' is scheduled to ${unifi_upgrade_devices_var_2} at ${cron_expr_human} ${site_timezone}."; fi
            rm --force "/tmp/EUS/sites/${site}/${device_type}_upgrade_schedule_output" 2> /dev/null
          fi
        done < "/tmp/EUS/sites/${site}/${device_type}_mac"
      fi
    done < /tmp/EUS/unifi_sites
    rm --force "/tmp/EUS/${device_type}_schedule_message" &> /dev/null
    if [[ "${device_type}" == 'uap' ]]; then check_uap_scheduled; elif [[ "${device_type}" == 'usw' ]]; then check_usw_scheduled; elif [[ "${device_type}" == 'uxg' ]]; then check_uxg_scheduled; elif [[ "${device_type}" == 'ugw' ]]; then check_ugw_scheduled; fi
  done < /tmp/EUS/device_types
  rm --force /tmp/EUS/device_types &> /dev/null
}

unifi_upgrade_scheduler() {
  schedule_time_question
  header
  echo -e "\\n${WHITE_R}#${RESET} Starting the device ${unifi_upgrade_devices_var_2} scheduler!"
  echo -e "\\n${GREEN}---${RESET}\\n"
  device_upgrade_schedule
  sleep 3
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                          UniFi Backup                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_backup () {
  backup_time=$(date +%Y%m%d_%H%M_%S%N)
  header
  echo -e "${WHITE_R}#${RESET} Creating the backup!"
  echo -e "${WHITE_R}#${RESET} This can take a while for big setups! \\n\\n"
  sleep 2
  auto_dir=$(grep ^autobackup.dir /var/lib/unifi/system.properties 2> /dev/null | sed 's/autobackup.dir=//g')
  if grep -q "^unifi:" /etc/group && grep -q "^unifi:" /etc/passwd; then
    if sudo -u unifi [ -w "${auto_dir}" ]; then touch /tmp/EUS/application/dir_writable; fi
    if [[ -f /tmp/EUS/application/dir_writable ]]; then
      unifi_write_permission=true
      rm --force /tmp/EUS/application/dir_writable 2> /dev/null
    else
      unifi_write_permission=false
    fi
  fi
  if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
    unifi_write_permission=pass
  fi
  # shellcheck disable=SC2012
  if [[ -n "$auto_dir" && "${unifi_write_permission}" =~ (true|pass) || $(ls -ld "${auto_dir}" 2> /dev/null | awk '{print $3":"$4}') == "unifi:unifi" ]]; then
    backup_location=custom
    if echo "${auto_dir}" | grep -q '/$'; then
      if ! [[ -d "${auto_dir}glennr-unifi-backups/" ]]; then mkdir "${auto_dir}glennr-unifi-backups/"; fi
      output="${auto_dir}glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
    else
      if ! [[ -d "${auto_dir}/glennr-unifi-backups/" ]]; then mkdir "${auto_dir}/glennr-unifi-backups/"; fi
      output="${auto_dir}/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
	fi
  elif [[ -d /data/autobackup/ ]]; then
    if ! [[ -d /data/glennr-unifi-backups/ ]]; then mkdir /data/glennr-unifi-backups/; fi
    backup_location="sd_card"
    output="/data/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
  elif [[ -d /sdcard/ ]] && [[ "${eus_dir}" == '/srv/EUS' ]]; then
    if ! [[ -d /sdcard/glennr-unifi-backups/ ]]; then mkdir /sdcard/glennr-unifi-backups/; fi
    backup_location="sd_card_unifi_os"
    output="/sdcard/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
  else
    if ! [[ -d /usr/lib/unifi/data/backup/glennr-unifi-backups/ ]]; then mkdir /usr/lib/unifi/data/backup/glennr-unifi-backups/; fi
    backup_location="unifi_dir"
    output="/usr/lib/unifi/data/backup/glennr-unifi-backups/unifi_backup_${unifi}_${backup_time}.unf"
  fi
  if [[ "${unifi}" =~ ^(5.4.0|5.4.1)$ || "${unifi_release::3}" -lt "54" ]]; then
    path=$($unifi_api_curl_cmd --data "{\"cmd\":\"backup\",\"days\":\"0\"}" "$unifi_api_baseurl/api/s/${site}/cmd/system" | sed -n 's/.*\(\/dl.*unf\).*/\1/p')
  else
    path=$($unifi_api_curl_cmd --data "{\"cmd\":\"backup\",\"days\":\"0\"}" "$unifi_api_baseurl/api/s/${site}/cmd/backup" | sed -n 's/.*\(\/dl.*unf\).*/\1/p')
  fi
  ${unifi_api_curl_cmd} "$unifi_api_baseurl$path" -o "$output" --create-dirs
}

unifi_backup_check() {
  if [[ -f "${output}" && -s "${output}" ]]; then
    while true; do
      header
      echo -e "${WHITE_R}#${RESET} Checking if the backup got created!"
      echo -e "${WHITE_R}#${RESET} Backup Location: ${output}"
      for (( ; ; )); do
        stat_1=$(stat -c%s "${output}")
        sleep 10
        stat_2=$(stat -c%s "${output}")
        if [[ "${stat_1}" -eq "${stat_2}" ]]; then
          header
          echo -e "${GREEN}#${RESET} UniFi Network Application backup was successful!"
          sleep 2
          glennr_unifi_backup=success
          break
        fi
        header_red
        echo -e "${RED}#${RESET} UniFi Network Application backup didn't finish yet!"
      done
      if [[ -f "${output}" && -s "${output}" ]]; then break; fi
    done
    if [[ "${glennr_unifi_backup}" == 'success' ]]; then
      echo -e "${GREEN}#${RESET} Changing backup file permissions to unifi:unifi!"
      if [[ "${backup_location}" == 'custom' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          if echo "$auto_dir" | grep -q '/$'; then
            chown -R unifi:unifi "${auto_dir}glennr-unifi-backups/"
          else
            chown -R unifi:unifi "${auto_dir}/glennr-unifi-backups/"
          fi
        fi
      elif [[ "${backup_location}" == 'sd_card' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          chown -R unifi:unifi /data/glennr-unifi-backups/
        fi
      elif [[ "${backup_location}" == 'sd_card_unifi_os' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          chown -R unifi:unifi /sdcard/glennr-unifi-backups/
        fi
      elif [[ "${backup_location}" == 'unifi_dir' ]]; then
        if ! [[ "${unifi}" =~ ^(5.6.0|5.6.1|5.6.2|5.6.3)$ || "${unifi_release::3}" -lt "56" ]]; then
          chown -R unifi:unifi /usr/lib/unifi/data/backup/glennr-unifi-backups/
        fi
      fi
      sleep 3
    fi
  else
    header_red
    echo -e "${RED}#${RESET} UniFi Network Application backup seems to have failed.."
    read -rp $'\033[39m#\033[0m Do you want to try to perform another backup? (Y/n) ' yes_no
    case "${yes_no}" in
       [Yy]*|"")
          unifi_backup
          unifi_backup_check;;
       [Nn]*|*)
          header
          echo -e "${WHITE_R}#${RESET} Skipping the UniFi Network Application backup.." && sleep 3;;
    esac
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                     Ask For Device Upgrade                                                                                      #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

schedule_or_upgrade_now() {
  header
  echo -e "${WHITE_R}#${RESET} Please choice your device upgrade/downgrade option below."
  echo -e "\\n${WHITE_R}---${RESET}\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Upgrade all devices."
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Downgrade all devices."
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Schedule upgrades for all devices."
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Schedule downgrades for all devices."
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel Script.\\n\\n"
  read -rp $'Your choice | \033[39m' choice
  case "$choice" in
     1)
        option_upgrade=true
        unifi_upgrade_devices_var_1='upgrading'
        unifi_upgrade_devices_var_2='upgrade'
        unifi_upgrade_devices;;
     2)
        option_upgrade=false
        unifi_upgrade_devices_var_1='downgrading'
        unifi_upgrade_devices_var_2='downgrade'
        unifi_upgrade_devices;;
     3)
        option_upgrade=true
        unifi_upgrade_devices_var_1='upgrading'
        unifi_upgrade_devices_var_2='upgrade'
        unifi_upgrade_scheduler;;
     4)
        option_upgrade=false
        unifi_upgrade_devices_var_1='downgrading'
        unifi_upgrade_devices_var_2='downgrade'
        unifi_upgrade_scheduler;;
     5) cancel_script;;
	 *) 
        header_red
        echo -e "${WHITE_R}#${RESET} '${choice}' is not a valid option..." && sleep 2
        schedule_or_upgrade_now;;
  esac
}

run_unifi_devices_upgrade() {
  if [[ "${executed_unifi_credentials}" != 'true' ]]; then
    unifi_credentials
    executed_unifi_credentials=true
  fi
  unifi_login
  unifi_list_sites
  override_inform_host
  firmware_cache_question
  schedule_or_upgrade_now
  firmware_cache_remove_question
}

only_run_unifi_devices_upgrade() {
  unifi_credentials
  unifi_login
  unifi_list_sites
  override_inform_host
  firmware_cache_question
  schedule_or_upgrade_now
  firmware_cache_remove_question
  unifi_logout
  alert_event_cleanup
  script_cleanup
  devices_update_finish
  remove_yourself
  exit 0
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                   5.10.x Upgrades ( 5.6.42 )                                                                                    #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_firmware_requirement() {
  mkdir -p /tmp/EUS/requirement &> /dev/null
  header
  echo -e "${WHITE_R}#${RESET} Checking if all devices pass the minimum required firmware check..."
  mongo --quiet --port 27117 ace --eval "db.getCollection('device').find({}).forEach(printjson);" | sed 's/\(ObjectId(\|)\|NumberLong(\)\|ISODate(//g' | jq '. | {type: .type, model: .model, version: .version, build_id: (.version | split(".") | .[3]), connected_at: .connected_at}' > /tmp/EUS/requirement/device_type_model_version
  sed -i 's/"connected_at": null/"connected_at": 0/g' /tmp/EUS/requirement/device_type_model_version
  while read -r build_id; do
    if [[ "${required_upgrade}" == 'true' ]]; then break; fi
    if [[ "${build_id}" -lt "9636" ]]; then required_upgrade=true; fi
  done < <(jq -r '. | select((.type == "uap" or .type == "usw") and (.model != "UP1") and (.model != "UP6") and (.model != "USMINI") and (.connected_at > 0)) | .build_id' /tmp/EUS/requirement/device_type_model_version | awk '!NF || !seen[$0]++')
  while read -r build_id; do
    if [[ "${required_upgrade}" == 'true' ]]; then break; fi
    if [[ "${build_id}" -lt "12088" ]]; then required_upgrade=true; fi
  done < <(jq -r '. | select((.type == "uap" or .type == "usw")) | select(.model|test("^UA","^US6")) | select(.connected_at > 0) | .build_id' /tmp/EUS/requirement/device_type_model_version | awk '!NF || !seen[$0]++')
  while read -r build_id; do
    if [[ "${required_upgrade}" == 'true' ]]; then break; fi
    if [[ "${build_id}" -lt "5140624" ]]; then required_upgrade=true; fi
  done < <(jq -r '. | select((.type == "ugw") and (.connected_at > 0)) | .build_id' /tmp/EUS/requirement/device_type_model_version | awk '!NF || !seen[$0]++')
  if [[ "${required_upgrade}" == 'true' ]]; then
    echo -e "${YELLOW}#${RESET} There are devices that require to be updated in order to manage them..."
  else
    echo -e "${GREEN}#${RESET} None of the devices need to be upgraded! You're all good!"
  fi
  sleep 3
  if [[ "${required_upgrade}" == 'true' && "${executed_unifi_credentials}" != 'true' ]]; then
    executed_unifi_credentials=true
    header
    echo -e "${WHITE_R}#${RESET} Your devices need a firmware upgrade in order to continue to manage them."
    read -rp $'\033[39m#\033[0m Do you want to use the script to upgrade all your devices? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
           unifi_credentials
           unifi_login;;
        [Nn]*)
           echo -e "\\n${RED}---${RESET}\\n"
           echo -e "${WHITE_R}#${RESET} Taking the risk of not upgrading your devices..."
           run_unifi_firmware_check=no;;
    esac
  fi
  if [[ "${required_upgrade}" == 'true' && "${run_unifi_firmware_check}" != 'no' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Your devices need to be updated in order to work with the newer UniFi Network Application releease..."
    echo -e "${WHITE_R}#${RESET} What would you like to do?"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Update all devices via the script ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Don't upgrade the devices"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  cancel\\n\\n\\n"
    read -rp $'Your choice | \033[39m' required_upgrade_question
    case "$required_upgrade_question" in
        1*|"") run_unifi_devices_upgrade;;
        2*) ;;
        3*) cancel_script;;
    esac
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            OS Update                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

apt_mongodb_check() {
  hide_apt_update=true
  run_apt_get_update
  MONGODB_ORG_CACHE=$(apt-cache madison mongodb-org | awk '{print $3}' | sort -V | tail -n 1 | sed 's/\.//g')
  MONGODB_CACHE=$(apt-cache madison mongodb | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
  MONGO_TOOLS_CACHE=$(apt-cache madison mongo-tools | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
}

os_upgrade () {
  rm --force /tmp/EUS/dpkg/unifi_list &> /dev/null
  rm --force /tmp/EUS/dpkg/mongodb_list &> /dev/null
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
  header
  echo -e "${WHITE_R}#${RESET} You're about to upgrade/update the OS with all it's packages, I recommend"
  echo -e "${WHITE_R}#${RESET} creating a backup/snapshot of the current state of the machine/VM.\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Continue with the upgrade/update"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Create a UniFi Network Application backup before the upgrade/update"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
  read -rp $'Your choice | \033[39m' OS_EASY_UPDATE
  case "$OS_EASY_UPDATE" in
      1*) ;;
      2*)
        header
        echo -e "${WHITE_R}#${RESET} Starting the UniFi Network Application backup.\\n\\n"
        unifi_credentials
        unifi_login
        debug_check
        unifi_list_sites
        unifi_backup
        unifi_backup_check
        unifi_logout
        login_cleanup
        script_cleanup;;
       3|*) cancel_script;;
  esac
  header
  echo -e "${WHITE_R}#${RESET} Starting the OS update/upgrade.\\n"
  sleep 2
  dpkg -l | awk '/unifi/ {print $2}' &> /tmp/EUS/dpkg/unifi_list
  if [[ -f /tmp/EUS/dpkg/unifi_list && -s /tmp/EUS/dpkg/unifi_list ]]; then
    while read -r service; do
      echo -e "${WHITE_R}#${RESET} Preventing ${service} from upgrading..."
      if echo "${service} hold" | dpkg --set-selections; then echo -e "${GREEN}#${RESET} Successfully prevented ${service} from upgrading! \\n"; else echo -e "${RED}#${RESET} Failed to prevent ${service} from upgrading...\\n"; abort; fi
    done < /tmp/EUS/dpkg/unifi_list
  fi
  if dpkg -l mongodb-org 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    if [[ "${mongodb_org_v::2}" == '34' ]]; then
      mongodb_version='3.4'
    elif [[ "${mongodb_org_v::2}" == '36' ]]; then
      mongodb_version='3.6'
    fi
    echo -e "${WHITE_R}#${RESET} Creating a list file for MongoDB"
    sed -i '/mongodb/d' /etc/apt/sources.list
    if ls /etc/apt/sources.list.d/mongodb* > /dev/null 2>&1; then rm /etc/apt/sources.list.d/mongodb*  2> /dev/null; fi
    if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/${mongodb_version} multiverse" &> "/etc/apt/sources.list.d/mongodb-org-${mongodb_version}.list"; then echo -e "${GREEN}#${RESET} Successfully added the source file for MongoDB ${mongodb_version}! \\n"; mongodb_key=true; else echo -e "${RED}#${RESET} Failed to add the source file for MongoDB ${mongodb_version}! \\n"; abort;fi
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
      if echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/${mongodb_version} multiverse" &> "/etc/apt/sources.list.d/mongodb-org-${mongodb_version}.list"; then echo -e "${GREEN}#${RESET} Successfully added the source file for MongoDB ${mongodb_version}! \\n"; mongodb_key=true; else echo -e "${RED}#${RESET} Failed to add the source file for MongoDB ${mongodb_version}! \\n"; abort;fi
    elif [[ "${os_codename}" == "jessie" ]]; then
      if echo "deb https://repo.mongodb.org/apt/debian jessie/mongodb-org/${mongodb_version} main" &> "/etc/apt/sources.list.d/mongodb-org-${mongodb_version}.list"; then echo -e "${GREEN}#${RESET} Successfully added the source file for MongoDB ${mongodb_version}! \\n"; mongodb_key=true; else echo -e "${RED}#${RESET} Failed to add the source file for MongoDB ${mongodb_version}! \\n"; abort;fi
    elif [[ "${os_codename}" =~ (stretch|continuum|buster|bullseye|bookworm) ]]; then
      if echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/${mongodb_version} multiverse" &> "/etc/apt/sources.list.d/mongodb-org-${mongodb_version}.list"; then echo -e "${GREEN}#${RESET} Successfully added the source file for MongoDB ${mongodb_version}! \\n"; mongodb_key=true; else echo -e "${RED}#${RESET} Failed to add the source file for MongoDB ${mongodb_version}! \\n"; abort;fi
    fi
    if [[ "$mongodb_key" == 'true' ]]; then
      echo -e "${WHITE_R}#${RESET} Adding key for MongoDB ${mongodb_version}..."
      if wget -qO - "https://www.mongodb.org/static/pgp/server-${mongodb_version}.asc" | apt-key add - &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added key for MongoDB ${mongodb_version}! \\n"; else abort; fi
    fi
    apt_mongodb_check
    if [[ "${MONGODB_ORG_CACHE::2}" -gt "${mongo_version_max}" ]]; then
      dpkg -l | awk '/ii.*mongodb-org/ {print $2}' &> /tmp/EUS/dpkg/mongodb_list
      if [[ -f /tmp/EUS/dpkg/mongodb_list && -s /tmp/EUS/dpkg/mongodb_list ]]; then
        while read -r package; do
          echo -e "${WHITE_R}#${RESET} Preventing ${package} from upgrading..."
          if echo "${package} hold" | dpkg --set-selections; then echo -e "${GREEN}#${RESET} Successfully prevented ${package} from upgrading! \\n"; else echo -e "${RED}#${RESET} Failed to prevent ${package} from upgrading...\\n"; abort; fi
        done < /tmp/EUS/dpkg/mongodb_list
      fi
    fi
    if [[ "${MONGODB_CACHE::2}" -gt "${mongo_version_max}" || "${MONGO_TOOLS_CACHE::2}" -gt "${mongo_version_max}" ]]; then
      dpkg -l | grep -v 'mongodb-org' | awk '/ii.*mongodb-|ii.*mongo-tools/ {print $2}' &> /tmp/EUS/dpkg/mongodb_list
      if [[ -f /tmp/EUS/dpkg/mongodb_list && -s /tmp/EUS/dpkg/mongodb_list ]]; then
        while read -r package; do
          echo -e "${WHITE_R}#${RESET} Preventing ${package} from upgrading..."
          if echo "${package} hold" | dpkg --set-selections; then echo -e "${GREEN}#${RESET} Successfully prevented ${package} from upgrading! \\n"; else echo -e "${RED}#${RESET} Failed to prevent ${package} from upgrading...\\n"; abort; fi
        done < /tmp/EUS/dpkg/mongodb_list
      fi
    fi
  fi
  sleep 5 && header
  echo -e "${WHITE_R}#${RESET} Upgrading the packages on your machine...\\n${WHITE_R}#${RESET} Below you will see a few of the packages that will upgrade...\\n"
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
  { apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "$1 ( \e[1;34m$2\e[0m -> \e[1;32m$3\e[0m )\n"}';} | while read -r line; do echo -en "${WHITE_R}-${RESET} $line\\n"; echo -en "$line\\n" | awk '{print $1}' &>> /tmp/EUS/upgrade/upgrade_list; done;
  if [[ -f /tmp/EUS/upgrade/upgrade_list ]]; then number_of_updates=$(wc -l < /tmp/EUS/upgrade/upgrade_list); else number_of_updates='0'; fi
  if [[ "${number_of_updates}" == '0' ]]; then echo -e "${WHITE_R}#${RESET} There are were no packages that need an upgrade..."; fi
  sleep 3
  echo -e "\\n${WHITE_R}----${RESET}\\n"
  if [[ -f /tmp/EUS/upgrade/upgrade_list && -s /tmp/EUS/upgrade/upgrade_list ]]; then
    while read -r package; do
      echo -e "\\n------- updating ${package} ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
      echo -ne "\\r${WHITE_R}#${RESET} Updating package ${package}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${package}" &>> "${eus_dir}/logs/upgrade.log"; then
        echo -e "\\r${GREEN}#${RESET} Successfully updated package ${package}!"
      elif tail -n1 /usr/lib/EUS/logs/upgrade.log | grep -ioq "Packages were downgraded and -y was used without --allow-downgrades" "${eus_dir}/logs/upgrade.log"; then
        if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade --allow-downgrades install "${package}" &>> "${eus_dir}/logs/upgrade.log"; then
          echo -e "\\r${GREEN}#${RESET} Successfully updated package ${package}!"
          continue
        else
          echo -e "\\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"
          break
        fi
      fi
      echo -e "\\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"
      break
    done < /tmp/EUS/upgrade/upgrade_list
  fi
  echo -e "\\n------- apt-get upgrade ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${WHITE_R}#${RESET} Running apt-get upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade &>> "${eus_dir}/logs/upgrade.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get upgrade"; abort; fi
  echo -e "\\n------- apt-get dist-upgrade ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${WHITE_R}#${RESET} Running apt-get dist-upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade &>> "${eus_dir}/logs/upgrade.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get dist-upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get dist-upgrade"; abort; fi
  echo -e "${WHITE_R}#${RESET} Running apt-get autoremove..."
  if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
  echo -e "${WHITE_R}#${RESET} Running apt-get autoclean..."
  if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
  if [[ -f /tmp/EUS/dpkg/unifi_list && -s /tmp/EUS/dpkg/unifi_list ]]; then
    while read -r service; do
      echo "${service} install" | dpkg --set-selections 2> /dev/null
    done < /tmp/EUS/dpkg/unifi_list
  fi
  if [[ -f /tmp/EUS/dpkg/mongodb_list && -s /tmp/EUS/dpkg/mongodb_list ]]; then
    while read -r service; do
      echo "${service} install" | dpkg --set-selections 2> /dev/null
    done < /tmp/EUS/dpkg/mongodb_list
  fi
  rm --force /tmp/EUS/dpkg/unifi_list &> /dev/null
  rm --force /tmp/EUS/dpkg/mongodb_list &> /dev/null
  rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
  sleep 5
  os_update_finish
  exit 0
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                Alerts and Events Archive/Delete                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

are_you_sure() {
  header_red
  read -rp $'\033[39m#\033[0m Do you you want to proceed with '"${are_you_sure_var}"'? (y/N) ' yes_no
  case "$yes_no" in
     [Nn]*|"") are_you_sure_proceed=no;;
     [Yy]*) are_you_sure_proceed=yes;;
	 *)
       header_red
       echo -e "${WHITE_R}#${RESET} '${yes_no}' is not a valid option, please answer with yes ( y ) or no ( n )" && sleep 3
       are_you_sure;;
  esac
  if [[ "${are_you_sure_proceed}" == 'no' ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} Cancelling operation: ${are_you_sure_var}"
    exit 1
  fi
}

alert_event_option() {
  header
  echo -e "${WHITE_R}#${RESET} Please take an option below."
  echo -e "${WHITE_R}#${RESET} Note: Archiving/Deleting alerts/events can take a long time on big setups.\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Archive all Alerts.  ( default )"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Delete all Alerts."
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Delete all Events."
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Delete all Events and Alerts."
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel Script.\\n\\n"
  read -rp $'Your choice | \033[39m' alert_event_option_var
  case "$alert_event_option_var" in
      1*|"")
        are_you_sure_var="archiving all alerts"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${WHITE_R}#${RESET} Archiving the Alerts...\\n"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            echo -e "${WHITE_R}#${RESET} Archiving Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.updateMany({},{$set: {"archived": true}})' | awk '{ modifiedCount=$10 ; print "\033[1;32m#\033[0m Successfully archived " modifiedCount " Alerts" }' # modifiedCount
          else
            echo -e "${WHITE_R}#${RESET} Archiving Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.update({},{$set: {"archived": true}},{multi: true})' | awk '{ nModified=$10 ; print "\033[1;32m#\033[0m Successfully archived " nModified " Alerts" }' # nModified
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      2*)
        are_you_sure_var="deleting all alerts"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${WHITE_R}#${RESET} Deleting all Alerts...\\n"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            echo -e "${WHITE_R}#${RESET} Deleting Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.deleteMany({})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Alerts" }' # deletedCount
          else
            echo -e "${WHITE_R}#${RESET} Deleting Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      3*)
        are_you_sure_var="deleting all events"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${WHITE_R}#${RESET} Deleting all Events...\\n"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.deleteMany({})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Events" }' # deletedCount
          else
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Events" }' # nRemoved
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      4*)
        are_you_sure_var="deleting all alerts and events"
        are_you_sure
        if [[ "${are_you_sure_proceed}" == 'yes' ]]; then
          header
          echo -e "${WHITE_R}#${RESET} Deleting all Alerts and Events...\\n"
          if [[ "${mongodb_server_version::2}" -gt "30" ]]; then
            echo -e "${WHITE_R}#${RESET} Deleting Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.deleteMany({})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Alerts" }' # deletedCount
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.deleteMany({})' | awk '{ deletedCount=$7 ; print "\033[1;32m#\033[0m Successfully deleted " deletedCount " Events" }' # deletedCount
          else
            echo -e "${WHITE_R}#${RESET} Deleting Alerts..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.alarm.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Alerts" }' # nRemoved
            echo -e "${WHITE_R}#${RESET} Deleting Events..."
            # shellcheck disable=SC2016
            mongo --quiet --port 27117 ace --eval 'db.event.remove({},{multi: true})' | awk '{ nRemoved=$4 ; print "\033[1;32m#\033[0m Successfully deleted " nRemoved " Events" }' # nRemoved
          fi
          echo -e "\\n"
          sleep 5
        fi;;
      5*) cancel_script;;
	  *)
        header_red
        echo -e "${WHITE_R}#${RESET} '${alert_event_option_var}' is not a valid option..." && sleep 2
        alert_event_option;;
  esac
  sleep 3
  event_alert_archive_delete_finish
  exit 0
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                       MongoDB 3.4 to 3.6                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

mongodb_upgrade_34_36() {
  unifi_video=$(dpkg -l | grep "unifi-video" | awk '{print $3}' | sed 's/-.*//')
  first_digit_unifi_video=$(echo "${unifi_video}" | cut -d'.' -f1)
  second_digit_unifi_video=$(echo "${unifi_video}" | cut -d'.' -f2)
  if dpkg -l | grep "unifi-video" | grep "^ii\\|^hi"; then
    if ! [[ "${first_digit_unifi_video}" -ge '3' && "${second_digit_unifi_video}" -ge '10' ]]; then
      header_red
      echo -e "${RED}#${RESET} You need to upgrade UniFi-Video to 3.10.x or newer.."
      echo -e "${RED}#${RESET} Always backups prior to upgrading anything! \\n\\n"
      exit 0
    fi
  fi
  hide_apt_update=true
  header
  read -rp $'\033[39m#\033[0m Did you take backups of your UniFi Network Application? (y/N) ' yes_no
  case "$yes_no" in
     [Nn]*|"")
        read -rp $'\033[39m#\033[0m Do you want to take a UniFi Network Application backup using the script? (Y/n) ' yes_no
        case "$yes_no" in
           [Yy]*|"")
              header
              echo -e "${WHITE_R}#${RESET} Starting the UniFi Network Application backup.\\n\\n"
              unifi_credentials
              unifi_login
              debug_check
              unifi_list_sites
              unifi_backup
              unifi_backup_check
              unifi_logout
              login_cleanup
              script_cleanup;;
           [Nn]*)
              header_red
              echo -e "${RED}#${RESET} Please take a backup of your UniFi Network Application and then run the script again."
              exit 1;;
        esac;;
     [Yy]*) ;;
  esac
  header
  mongodb_compatibility=$(mongo --quiet --port 27117 --eval 'db.adminCommand( { getParameter: 1, featureCompatibilityVersion: 1 } )' | sed -e 's/ //g' -e 's/"//g')
  echo -e "${WHITE_R}#${RESET} Checking what packages depend on MongoDB..."
  apt-cache rdepends mongodb-org* | sed "/mongo/d" | sed "/Reverse Depends/d" | awk '!a[$0]++' | sed 's/ //g' &> /tmp/EUS/mongodb/reverse_depends
  sed -e 's/unifi-video//g' -e 's/unifi//g' -e '/^$/d' < /tmp/EUS/mongodb/reverse_depends > /tmp/EUS/mongodb/reverse_depends_without_unifi
  if [[ -s /tmp/EUS/mongodb/reverse_depends_without_unifi ]]; then
    echo -e "${RED}#${RESET} The following services depend on MongoDB... Script will cancel this upgrade."
    while read -r service; do echo -e "${RED}-${RESET} ${service}"; done < /tmp/EUS/mongodb/reverse_depends_without_unifi
    exit 0
  else
    echo -e "${GREEN}#${RESET} Only UniFi Depends on MongoDB, we are good to go! \\n"
  fi
  if echo "${mongodb_compatibility}" | grep -iq "featureCompatibilityVersion.*3.4.*ok:1"; then
    echo -e "${GREEN}#${RESET} MongoDB is ready for upgrading! \\n"
  else
    echo -e "${RED}#${RESET} MongoDB is not ready yet for upgrading! \\n${RED}#${RESET} Setting featureCompatibilityVersion to 3.4..."
    if mongo --quiet --port 27117 --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "3.4" } )' | grep -iq "ok.*1"; then
      echo -e "${GREEN}#${RESET} Successfully set featureCompatibilityVersion to 3.4! \\n"
    else
      echo -e "${RED}#${RESET} Failed to set featureCompatibilityVersion to 3.4..." && abort
    fi
  fi
  sleep 2
  echo -e "${WHITE_R}#${RESET} Checking for older MongoDB repository entries..."
  if grep -qriIl "mongo" /etc/apt/sources.list*; then
    echo -e "${YELLOW}#${RESET} Removing old repository entries for MongoDB..."
    sed -i '/mongodb/d' /etc/apt/sources.list
    if ls /etc/apt/sources.list.d/mongodb* > /dev/null 2>&1; then
      rm /etc/apt/sources.list.d/mongodb*  2> /dev/null
    fi
    echo -e "${GREEN}#${RESET} Successfully removed all older MongoDB repository entries! \\n"
  else
    echo -e "${YELLOW}#${RESET} There were no older MongoDB Repository entries! \\n"
  fi
  sleep 2
  if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
    echo -e "${WHITE_R}#${RESET} Adding MongoDB 3.6 repository entry."
    if echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.6 multiverse" &> /etc/apt/sources.list.d/mongodb-org-3.6.list; then echo -e "${GREEN}#${RESET} Successfully added the repository for MongoDB 3.6! \\n"; else abort; fi
    mongodb_key=true
  elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
    echo -e "${WHITE_R}#${RESET} Adding MongoDB 3.6 repository entry."
    if echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" &> /etc/apt/sources.list.d/mongodb-org-3.6.list; then echo -e "${GREEN}#${RESET} Successfully added the repository for MongoDB 3.6! \\n"; else abort; fi
    mongodb_key=true
  elif [[ "${os_codename}" == "jessie" ]]; then
    echo -e "${WHITE_R}#${RESET} Adding MongoDB 3.6 repository entry."
    if echo "deb https://repo.mongodb.org/apt/debian jessie/mongodb-org/3.6 main" &> /etc/apt/sources.list.d/mongodb-org-3.6.list; then echo -e "${GREEN}#${RESET} Successfully added the repository for MongoDB 3.6! \\n"; else abort; fi
    mongodb_key=true
  elif [[ "${os_codename}" =~ (stretch|continuum|buster|bullseye|bookworm) ]]; then
    echo -e "${WHITE_R}#${RESET} Adding MongoDB 3.6 repository entry."
    if echo "deb https://repo.mongodb.org/apt/debian stretch/mongodb-org/3.6 main" &> /etc/apt/sources.list.d/mongodb-org-3.6.list; then echo -e "${GREEN}#${RESET} Successfully added the repository for MongoDB 3.6! \\n"; else abort; fi
    mongodb_key=true
  fi
  sleep 2
  if [[ "$mongodb_key" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} Adding key for MongoDB 3.6..."
    if wget -qO - https://www.mongodb.org/static/pgp/server-3.6.asc | apt-key add - &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added key for MongoDB 3.6! \\n"; else abort; fi
  fi
  sleep 2
  hide_apt_update=true
  run_apt_get_update
  dpkg -l | grep "^ii\\|^hi" | awk '{print$2}' | grep "unifi" | awk '{print $1}' &> /tmp/EUS/mongodb/unifi_package_list
  while read -r unifi_package; do
    echo -e "${WHITE_R}#${RESET} Stopping service ${unifi_package}..."
    if systemctl stop "${unifi_package}"; then echo -e "${GREEN}#${RESET} Successfully stopped service ${unifi_package}! \\n"; else echo -e "${RED}#${RESET} Failed to stop service ${unifi_package}!"; abort; fi
  done < /tmp/EUS/mongodb/unifi_package_list
  dpkg -l | grep mongodb-org | grep "^ii\\|^hi" | awk '{print $2}' &> /tmp/EUS/mongodb/packages_list
  while read -r mongodb_package; do
    echo -e "${WHITE_R}#${RESET} Updating ${mongodb_package}..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}" &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully updated ${mongodb_package}! \\n"; else echo -e "${RED}#${RESET} Failed to update ${mongodb_package}!"; abort; fi
  done < /tmp/EUS/mongodb/packages_list
  while read -r unifi_package; do
    echo -e "${WHITE_R}#${RESET} Starting service ${unifi_package}..."
    if systemctl start "${unifi_package}"; then echo -e "${GREEN}#${RESET} Successfully started service ${unifi_package}! \\n"; else echo -e "${RED}#${RESET} Failed to start service ${unifi_package}!"; abort; fi
  done < /tmp/EUS/mongodb/unifi_package_list
  mongodb_org_v=$(dpkg -l | grep "mongodb-org" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sort -V | tail -n 1)
  if [[ "${mongodb_org_v::2}" == '36' ]]; then
    echo -e "${WHITE_R}#${RESET} Setting featureCompatibilityVersion to the new version..."
    check_count=0
    while [[ "${check_count}" -lt '60' ]]; do
      if [[ "${check_count}" == '3' ]]; then
        header
        echo -e "${WHITE_R}#${RESET} Checking if the MongoDB is responding to continue with setting featureCompatibilityVersion to 3.6... (this can take up to 60 seconds)"
        mongo_setfeaturecompatibilityversion_message=true
      fi
      mongo --quiet --port 27117 --eval 'db.adminCommand( { setFeatureCompatibilityVersion: "3.6" } )' &> /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log
      if sed -e 's/ //g' -e 's/"//g' /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log | grep -iq "ok:1"; then
        if [[ "${mongo_setfeaturecompatibilityversion_message}" == 'true' ]]; then
          echo -e "${GREEN}#${RESET} MongoDB responded! The script will now continue with setting the featureCompatibilityVersionto 3.6! \\n"
          sleep 2
        fi
        echo -e "${GREEN}#${RESET} Successfully set featureCompatibilityVersion to 3.6! \\n"
        success_setfeaturecompatibilityversion=true
        break
      elif sed -e 's/ //g' -e 's/"//g' /tmp/EUS/mongodb/setFeatureCompatibilityVersion.log | grep -iq "connect failed"; then
        ((check_count=check_count+1))
      else
        echo -e "${RED}#${RESET} Failed to set featureCompatibilityVersion to 3.6! \\n${RED}#${RESET} We will keep featureCompatibilityVersion set to 3.4! \\n"
        success_setfeaturecompatibilityversion=false
      fi
    done
    if [[ -z "${success_setfeaturecompatibilityversion}" ]]; then
      echo -e "${RED}#${RESET} Failed to set featureCompatibilityVersion to 3.6! \\n${RED}#${RESET} We will keep featureCompatibilityVersion set to 3.4! \\n"
    fi
    while read -r unifi_package; do
      echo -e "${WHITE_R}#${RESET} Restarting service ${unifi_package}..."
      if service "${unifi_package}" restart; then echo -e "${GREEN}#${RESET} Successfully restarted service ${unifi_package}! \\n"; else echo -e "${RED}#${RESET} Failed to restart service ${unifi_package}!"; abort; fi
    done < /tmp/EUS/mongodb/unifi_package_list
  fi
  rm --force /tmp/EUS/mongodb/unifi_package_list &> /dev/null
  sleep 5
  header
  echo -e "${GREEN}#${RESET} Successfully finished the MongoDB update! \\n\\n"
  author
  exit 0
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                              UniFi Network Application Statistics                                                                               #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

unifi_site_stats() {
  header
  while read -r site; do
    if [[ "${unifi_site_stats_first}" == '1' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; else unifi_site_stats_first="1"; fi
    echo -e "${GREEN}#${RESET} Statistics for site: \"$(cat "/tmp/EUS/sites/${site}/site_desc")\"\\n"
    ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/s/${site}/stat/health" | jq -r '.data[] | select(.subsystem|test("^wlan","^lan","^wan")) | {site_placeholder: {(.subsystem): {users: .num_user, guests: .num_guest, iot: .num_iot, adopted: .num_adopted, disconnected: .num_disconnected, disabled: .num_disabled, pending: .num_pending}}}' | sed '/null/d' | sed "s/site_placeholder/${site}/g" &> "/tmp/EUS/stats/site_${site}_stats.json"
    # shellcheck disable=SC2086
    adopted_devices_wlan=$(jq -r '.["'${site}'"].wlan.adopted | select (.!=null)' "/tmp/EUS/stats/site_${site}_stats.json")
    # shellcheck disable=SC2086
    adopted_devices_lan=$(jq -r '.["'${site}'"].lan.adopted | select (.!=null)' "/tmp/EUS/stats/site_${site}_stats.json")
    # shellcheck disable=SC2086
    adopted_devices_wan=$(jq -r '.["'${site}'"].wan.adopted | select (.!=null)' "/tmp/EUS/stats/site_${site}_stats.json")
	adopted_devices_total=$(("${adopted_devices_wlan}" + "${adopted_devices_lan}" + "${adopted_devices_wan}"))
    echo -e "${WHITE_R}#${RESET} Total adopted devices: ${GREEN}${adopted_devices_total}${RESET}"
    echo -e "${WHITE_R}#${RESET} WLAN: ${adopted_devices_wlan}"
    echo -e "${WHITE_R}#${RESET} LAN: ${adopted_devices_lan}"
    echo -e "${WHITE_R}#${RESET} Gateway: ${adopted_devices_wan}"
  done < /tmp/EUS/unifi_sites
}

application_statistics() {
  if [[ "${executed_unifi_credentials}" != 'true' ]]; then
    unifi_credentials
    executed_unifi_credentials=true
  fi
  unifi_login
  unifi_list_sites
  if ! [[ -d "/tmp/EUS/stats/" ]]; then mkdir -p "/tmp/EUS/stats/"; fi
  total_adopted=$(mongo --quiet --port 27117 ace --eval "db.device.stats();" | jq '.count')
  # shellcheck disable=SC2016
  jq -n --arg total "${total_adopted}" '{"total_adopted":$total}' > "/tmp/EUS/stats/total_adopted.json"
  unifi_site_stats
  jq -s '.' "/tmp/EUS/stats/total_adopted.json" /tmp/EUS/stats/site_*_stats.json > "/tmp/EUS/stats/complete_stats.json"
  json_time=$(date "+%Y%m%d_%H%M")
  if ! [[ -d "${eus_dir}/stats/" ]]; then mkdir -p "${eus_dir}/stats/"; fi
  cp "/tmp/EUS/stats/complete_stats.json" "${eus_dir}/stats/complete_stats_${json_time}.json"
  cp "/tmp/EUS/stats/total_adopted.json" "${eus_dir}/stats/total_adopted_${json_time}.json"
  # shellcheck disable=SC2012
  ls -t "${eus_dir}/stats/complete_stats_*" 2> /dev/null | awk 'NR>10' | xargs rm -f 2> /dev/null
  # shellcheck disable=SC2012
  ls -t "${eus_dir}/stats/total_adopted_*" 2> /dev/null | awk 'NR>10' | xargs rm -f 2> /dev/null
  echo -e "\\n\\n${GREEN}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} Total adopted devices on this UniFi Network Application: ${GREEN}${total_adopted}${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} Statistics json file is saved on the locations below: \\n${WHITE_R}-${RESET} \"${eus_dir}/stats/complete_stats_${json_time}.json\" \\n${WHITE_R}-${RESET} \"${eus_dir}/stats/total_adopted_${json_time}.json\"\\n\\n"
  author
  exit 0
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  Ask to keep script or delete                                                                                   #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

script_removal() {
  if [[ "${installing_required_package}" != 'yes' ]]; then
    echo -e "${GREEN}---${RESET}\\n"
  else
    header
  fi
  read -rp $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"") ;;
      [Nn]*) delete_script=true;;
  esac
}

script_removal

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                       What Should we run?                                                                                       #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header
echo -e "  What do you want to update/do?\\n\\n"
if [[ "${unifi_core_system}" == 'true' ]]; then
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  UniFi Network Application"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  UniFi Devices ( on all sites )"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  UniFi Network Application and UniFi Devices"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Archive/Delete UniFi Network Application Alerts/Events"
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Get UniFi Network Application Statistics"
  echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel\\n\\n"
else
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  UniFi Network Application"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  UniFi Devices ( on all sites )"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  OS ( Operating System )"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  UniFi Network Application and UniFi Devices"
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Archive/Delete UniFi Network Application Alerts/Events"
  echo -e " [   ${WHITE_R}6${RESET}   ]  |  Get UniFi Network Application Statistics"
  if [[ "${mongo_version_max}" == '34' ]]; then
    echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel\\n\\n"
  else
    if [[ "${mongodb_org_v::2}" == '34' && "${repo_codename}" != 'precise' ]]; then
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  MongoDB upgrade to 3.6"
      echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi
fi
read -rp $'Your choice | \033[39m' unifi_easy_update
if [[ "${unifi_core_system}" == 'true' ]]; then
  case "$unifi_easy_update" in
      1) perform_application_upgrade=true;;
      2) only_run_unifi_devices_upgrade;;
      3) perform_application_upgrade=true; run_unifi_devices_upgrade;;
      4) alert_event_option;;
      5) application_statistics;;
      6*|"") cancel_script;;
  esac
else
  if [[ "${mongo_version_max}" == '34' ]]; then
    case "$unifi_easy_update" in
        1) perform_application_upgrade=true;;
        2) only_run_unifi_devices_upgrade;;
        3) os_upgrade;;
        4) perform_application_upgrade=true; run_unifi_devices_upgrade;;
        5) alert_event_option;;
        6) application_statistics;;
        7*|"") cancel_script;;
    esac
  else
    if [[ "${mongodb_org_v::2}" == '34' && "${repo_codename}" != 'precise' ]]; then
      case "$unifi_easy_update" in
          1) perform_application_upgrade=true;;
          2) only_run_unifi_devices_upgrade;;
          3) os_upgrade;;
          4) perform_application_upgrade=true; run_unifi_devices_upgrade;;
          5) alert_event_option;;
          6) application_statistics;;
          7) mongodb_upgrade_34_36;;
          8*|"") cancel_script;;
      esac
    else
      case "$unifi_easy_update" in
          1) perform_application_upgrade=true;;
          2) only_run_unifi_devices_upgrade;;
          3) os_upgrade;;
          4) perform_application_upgrade=true; run_unifi_devices_upgrade;;
          5) alert_event_option;;
          6) application_statistics;;
          7*|"") cancel_script;;
      esac
    fi
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                         Ask For Backup                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header
echo -e "${WHITE_R}#${RESET} Would you like to create a backup of your UniFi Network Application?"
echo -e "${WHITE_R}#${RESET} I highly recommend creating a UniFi Network Application backup!${RESET}\\n\\n"
read -rp $'\033[39m#\033[0m Do you want to proceed with creating a backup? (Y/n) ' yes_no
case "$yes_no" in
    [Yy]*|"")
      header
      echo -e "${WHITE_R}#${RESET} Starting the UniFi Network Application backup! \\n\\n"
      sleep 3
      if [[ "${executed_unifi_credentials}" != 'true' ]]; then
        unifi_credentials
        executed_unifi_credentials=true
      fi
      unifi_login
      if [[ "${unifi_backup_cancel}" != 'true' ]]; then
        unifi_list_sites
        debug_check
        unifi_backup
        unifi_backup_check
      fi;;
    [Nn]*)
      header_red
      echo -e "${WHITE_R}#${RESET} You choose not to create a backup! \\n\\n"
      sleep 2;;
esac

if [[ "${glennr_unifi_backup}" != 'success' ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} You didn't create a backup of your UniFi Network Application! \\n\\n"
  read -rp $'\033[39m#\033[0m Do you want to proceed with updating your UniFi Network Application? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"") ;;
      [Nn]*)
        header_red
        echo -e "${RED}#${RESET} You didn't download a backup!"
        echo -e "${RED}#${RESET} Please download a backup and rerun the script..\\n"
        echo -e "${RED}#${RESET} Cancelling the script!"
       exit 1;;
  esac
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [[ "${perform_application_upgrade}" == 'true' ]]; then prevent_unifi_upgrade; fi
alert_event_cleanup

if [[ "${backup_location}" == "custom" ]]; then
  if echo "$auto_dir" | grep -q '/$'; then
    glennr_backups_a=$(find "${auto_dir}glennr-unifi-backups/" -maxdepth 1 -type f -name "*.unf" | wc -l)
    glennr_backup_old_files=$(find "${auto_dir}glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}')
    glennr_backup_old_files_a=$(find "${auto_dir}glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | wc -l)
  else
    glennr_backups_a=$(find "${auto_dir}/glennr-unifi-backups/" -maxdepth 1 -type f -name "*.unf" | wc -l)
    glennr_backup_old_files=$(find "${auto_dir}/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}')
    glennr_backup_old_files_a=$(find "${auto_dir}/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | wc -l)
  fi
elif [[ "${backup_location}" == "sd_card" ]]; then
  glennr_backups_a=$(find "/data/glennr-unifi-backups/" -maxdepth 1 -type f -name "*.unf" | wc -l)
  glennr_backup_old_files=$(find "/data/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}')
  glennr_backup_old_files_a=$(find "/data/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | wc -l)
elif [[ "${backup_location}" == "sd_card_unifi_os" ]]; then
  glennr_backups_a=$(find "/sdcard/glennr-unifi-backups/" -maxdepth 1 -type f -name "*.unf" | wc -l)
  glennr_backup_old_files=$(find "/sdcard/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}')
  glennr_backup_old_files_a=$(find "/sdcard/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | wc -l)
elif [[ "${backup_location}" == "unifi_dir" ]]; then
  glennr_backups_a=$(find "/usr/lib/unifi/data/backup/glennr-unifi-backups/" -maxdepth 1 -type f -name "*.unf" | wc -l)
  glennr_backup_old_files=$(find "/usr/lib/unifi/data/backup/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}')
  glennr_backup_old_files_a=$(find "/usr/lib/unifi/data/backup/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | wc -l)
fi

if [[ "${glennr_backups_a}" -gt 5 ]]; then
  glennr_backup_free=$(du -sch "${glennr_backup_old_files}" 2> /dev/null | grep total$ | awk '{print $1}')
  header
  echo -e "${WHITE_R}#${RESET} Older backups are detected on your system. ( made by GlennR's Easy Update Script )"
  echo -e "${WHITE_R}#${RESET} Erasing the older backups ( ${glennr_backup_old_files_a} ) will free up ${WHITE_R}${glennr_backup_free}${RESET} on your disk.\\n"
  echo -e "${WHITE_R}#${RESET} The script will keep the 5 latest backups if you choose to erase the older backups.\\n\\n"
  read -rp $'\033[39m#\033[0m Do you want to delete/erase older backups? (y/N) ' yes_no
  case "$yes_no" in
      [Yy]*)
        header
        if [[ "${glennr_backup_old_files_a}" -gt 1 ]]; then echo -e "${WHITE_R}#${RESET} Deleting ${glennr_backup_old_files_a} backup files...\\n\\n"; else echo -e "${WHITE_R}#${RESET} Deleting ${glennr_backup_old_files_a} backup file...\\n\\n"; fi
        sleep 2
        if [[ "${backup_location}" == 'custom' ]]; then
          if echo "$auto_dir" | grep -q '/$'; then
            find "${auto_dir}glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | xargs rm --force 2> /dev/null
          else
            find "${auto_dir}/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | xargs rm --force 2> /dev/null
          fi
        elif [[ "${backup_location}" == 'sd_card' ]]; then
          find "/data/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | xargs rm --force 2> /dev/null
        elif [[ "${backup_location}" == 'sd_card_unifi_os' ]]; then
          find "/sdcard/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | xargs rm --force 2> /dev/null
        elif [[ "${backup_location}" == 'unifi_dir' ]]; then
          find "/usr/lib/unifi/data/backup/glennr-unifi-backups/" -type f -name "*.unf" -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR>5 {print $2}' | xargs rm --force 2> /dev/null
        fi;;
      [Nn]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Keeping the older backups.\\n\\n"
        sleep 2;;
  esac
fi

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  if [[ "${java_version}" -lt '131' ]]; then
    old_openjdk_version=true
  fi
fi

if ! dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8" || [[ "${old_openjdk_version}" == 'true' ]]; then
  header_red
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    echo -e "${RED}#${RESET} OpenJDK 8 is to old...\\n"
    openjdk_variable="Updating"
    openjdk_variable_2="Updated"
    openjdk_variable_3="Update"
  else
    echo -e "${RED}#${RESET} OpenJDK 8 is not installed...\\n" 
    openjdk_variable="Installing"
    openjdk_variable_2="Installed"
    openjdk_variable_3="Install"
  fi
  echo -e "${WHITE_R}#${RESET} Selecting your $(lsb_release -is) distribution."
  sleep 2
  if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
    echo -e "${YELLOW}#${RESET} Selected distribution | ${WHITE_R}$(lsb_release -is) $(lsb_release -cs).\\n"
    sleep 2
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu ${repo_codename} main" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        echo "EB9B1D8886F44E2A" &>> /tmp/EUS/keys/missing_keys
      fi
      required_package="openjdk-8-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
    fi
  elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy) ]]; then
    echo -e "${YELLOW}#${RESET} Selected distribution | ${WHITE_R}$(lsb_release -is) $(lsb_release -cs).\\n"
    sleep 2
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main universe") -eq 0 ]]; then
        echo "deb http://security.ubuntu.com/ubuntu bionic-security main universe" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      required_package="openjdk-8-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
    fi
  elif [[ "${os_codename}" == "jessie" ]]; then
    echo -e "${YELLOW}#${RESET} Selected distribution | ${WHITE_R}$(lsb_release -is) $(lsb_release -cs).\\n"
    sleep 2
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://archive.debian.org/debian jessie-backports main") -eq 0 ]]; then
        echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
        if [[ -n "$http_proxy" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
          if [[ -n "${apt_http_proxy}" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
          fi
        else
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B48AD6246925553 7638D0442B90D010 || abort
        fi
        echo -e "${WHITE_R}#${RESET} Running apt-get update..."
        required_package="openjdk-8-jre-headless"
        if apt-get update -o Acquire::Check-Valid-Until=false &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${RED}#${RESET} Failed to ran apt-get update! \\n"; abort; fi
        echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
        if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports openjdk-8-jre-headless &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2; else echo -e "${RED}#${RESET} Failed to install ${required_package}! \\n"; abort; fi
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
        unset required_package
      fi
    fi
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
    echo -e "${YELLOW}#${RESET} Selected distribution | ${WHITE_R}$(lsb_release -is) $(lsb_release -cs).\\n"
    sleep 2
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main") -eq 0 ]]; then
        echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        echo "EB9B1D8886F44E2A" &>> /tmp/EUS/keys/missing_keys
      fi
      required_package="openjdk-8-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
    fi
  elif [[ "${repo_codename}" =~ (buster|bullseye|bookworm) ]]; then
    echo -e "${YELLOW}#${RESET} Selected distribution | ${WHITE_R}$(lsb_release -is) $(lsb_release -cs).\\n"
    sleep 2
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} openjdk-8-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install openjdk-8-jre-headless &> /dev/null || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} openjdk-8-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.nl.debian.org/debian stretch main") -eq 0 ]]; then
        echo "deb http://ftp.nl.debian.org/debian stretch main" >> /etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      required_package="openjdk-8-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} openjdk-8-jre-headless! \\n" && sleep 2
    fi
  else
    header_red
    echo -e "      ${RED}Please manually install JAVA 8 on your system!${RESET}\\n"
    echo -e "      ${RED}OS Details:${RESET}"
    echo -e "      ${RED}${os_desc}${RESET}\\n"
    exit 0
  fi
fi

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  openjdk_8_installed=true
fi
if dpkg -l | grep "^ii\\|^hi" | grep -i "openjdk-.*-\\|oracle-java.*" | grep -vq "openjdk-8\\|oracle-java8"; then
  unsupported_java_installed=true
fi

if [[ "${openjdk_8_installed}" == 'true' && "${unsupported_java_installed}" == 'true' ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} Unsupported JAVA version(s) are detected, do you want to uninstall them?"
  echo -e "${WHITE_R}#${RESET} This may remove packages that depend on these java versions."
  read -rp $'\033[39m#\033[0m Do you want to proceed with uninstalling the unsupported JAVA version(s)? (y/N) ' yes_no
  case "$yes_no" in
       [Yy]*)
          rm --force /tmp/EUS/java/* &> /dev/null
          mkdir -p /tmp/EUS/java/ &> /dev/null
          mkdir -p "${eus_dir}/logs/" &> /dev/null
          header
          echo -e "${WHITE_R}#${RESET} Uninstalling unsupported JAVA versions..."
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          sleep 3
          dpkg -l | grep "^ii\\|^hi" | awk '/openjdk-.*/{print $2}' | cut -d':' -f1 | grep -v "openjdk-8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          dpkg -l | grep "^ii\\|^hi" | awk '/oracle-java.*/{print $2}' | cut -d':' -f1 | grep -v "oracle-java8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          awk '!a[$0]++' /tmp/EUS/java/unsupported_java_list_tmp >> /tmp/EUS/java/unsupported_java_list; rm --force /tmp/EUS/java/unsupported_java_list_tmp 2> /dev/null
          echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/java_uninstall.log"
          while read -r package; do
            apt-get remove "${package}" -y &>> "${eus_dir}/logs/java_uninstall.log" && echo -e "${WHITE_R}#${RESET} Successfully removed ${package}." || echo -e "${WHITE_R}#${RESET} Failed to remove ${package}."
          done < /tmp/EUS/java/unsupported_java_list
          rm --force /tmp/EUS/java/unsupported_java_list &> /dev/null
          echo -e "\\n";;
       [Nn]*|"") ;;
  esac
fi

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  update_java_alternatives=$(update-java-alternatives --list | grep "^java-1.8.*openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_java_alternatives}" ]]; then
    update-java-alternatives --set "${update_java_alternatives}" &> /dev/null
  fi
  update_alternatives=$(update-alternatives --list java | grep "java-8-openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_alternatives}" ]]; then
    update-alternatives --set java "${update_alternatives}" &> /dev/null
  fi
  header
  echo -e "${WHITE_R}#${RESET} Updating the ca-certificates..." && sleep 2
  rm /etc/ssl/certs/java/cacerts 2> /dev/null
  update-ca-certificates -f &> /dev/null && echo -e "${GREEN}#${RESET} Successfully updated the ca-certificates\\n" && sleep 2
fi

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  java_home_readlink="JAVA_HOME=$( readlink -f "$( command -v java )" | sed "s:bin/.*$::" )"
  if [[ -f /etc/default/unifi ]]; then
    current_java_home=$(grep "^JAVA_HOME" /etc/default/unifi)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/default/unifi
        echo "${java_home_readlink}" >> /etc/default/unifi
      fi
    fi
  else
    current_java_home=$(grep "^JAVA_HOME" /etc/environment)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment
        echo "${java_home_readlink}" >> /etc/environment
        # shellcheck disable=SC1091
        source /etc/environment
      fi
    fi
  fi
fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                               Custom UniFi Network Application Download                                                                #
#                                                                                                                                                                        #
##########################################################################################################################################################################

custom_url_question() {
  header
  echo -e "${WHITE_R}#${RESET} Please enter the UniFi Network Application download URL below."
  read -rp $'\033[39m#\033[0m ' custom_download_url
  custom_url_download_check
}

custom_url_upgrade_check() {
  if [[ -z "${custom_application_version}" ]]; then custom_application_version=$(echo "${custom_download_url}" | grep -io "5.*\\|6.*\\|7.*\\|8.*" | sed 's/-.*//g' | sed 's/\/.*//g'); fi
  current_application_version=$(dpkg -l | grep "unifi " | awk '{print $3}' | sed 's/-.*//g')
  custom_application_digit_1=$(echo "${custom_application_version}" | cut -d'.' -f1)
  custom_application_digit_2=$(echo "${custom_application_version}" | cut -d'.' -f2)
  custom_application_digit_3=$(echo "${custom_application_version}" | cut -d'.' -f3)
  current_application_digit_1=$(echo "${current_application_version}" | cut -d'.' -f1)
  current_application_digit_2=$(echo "${current_application_version}" | cut -d'.' -f2)
  current_application_digit_3=$(echo "${current_application_version}" | cut -d'.' -f3)
  if [[ "${custom_application_digit_1}" -gt "${current_application_digit_1}" ]]; then application_upgrade=yes; fi
  if [[ "${custom_application_digit_2}" -gt "${current_application_digit_2}" ]]; then application_upgrade=yes; fi
  if [[ "${custom_application_digit_3}" -gt "${current_application_digit_3}" ]]; then application_upgrade=yes; fi
  if [[ "${application_upgrade}" == 'yes' ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You're about to upgrade your UniFi Network Application from \"${current_application_version}\" to \"${custom_application_version}\"."
    read -rp $'\033[39m#\033[0m Did you confirm that this upgrade is supported? (y/N) ' yes_no
    case "$yes_no" in
        [Yy]*) custom_url_install;;
        [Nn]*|"")
          echo -e "${WHITE_R}#${RESET} Canceling the script.."
          cancel_script;;
    esac
  elif [[ "${application_upgrade}" != 'yes' ]]; then
    header_red
	echo -e "${WHITE_R}#${RESET} You were about to downgrade your UniFi Network Application from \"${current_application_version}\" to \"${custom_application_version}\".. Cancelling this upgrade..\\n\\n"
    author
    exit 0
  fi
}

custom_url_download_check() {
  mkdir -p /tmp/EUS/downloads &> /dev/null
  unifi_temp="$(mktemp --tmpdir=/tmp/EUS/downloads unifi_sysvinit_all_XXXXX.deb)"
  header
  echo -e "${WHITE_R}#${RESET} Downloading the UniFi Network Application release..."
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/unifi_custom_url_download.log"
  if ! wget -O "$unifi_temp" "${custom_download_url}" &>> "${eus_dir}/logs/unifi_custom_url_download.log"; then
    header_red
    echo -e "${WHITE_R}#${RESET} The URL you provided cannot be downloaded.. Please provide a working URL."
    sleep 3
    custom_url_question
  else
    dpkg -I "${unifi_temp}" | awk '{print tolower($0)}' &> "${unifi_temp}.tmp"
    package_maintainer=$(awk '/maintainer/{print$2}' "${unifi_temp}.tmp")
    custom_application_version=$(awk '/version/{print$2}' "${unifi_temp}.tmp" | grep -io "5.*\\|6.*\\|7.*\\|8.*" | cut -d'-' -f1 | cut -d'/' -f1)
    rm --force "${unifi_temp}.tmp" &> /dev/null
    if [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]]; then
      echo -e "${GREEN}#${RESET} Successfully downloaded the UniFi Network Application release!"
      sleep 2
      custom_url_upgrade_check
    else
      header_red
      echo -e "${WHITE_R}#${RESET} You did not provide a UniFi Network Application that is maintained by Ubiquiti ( UniFi )..."
      read -rp $'\033[39m#\033[0m Do you want to provide the script with anothe URL? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"") custom_url_question;;
          [Nn]*) ;;
      esac
    fi
  fi
}

custom_url_install() {
  if [[ -s "/tmp/EUS/repository/unifi-repo-file" ]]; then
    while read -r unifi_repo_file; do
      unifi_repo_file_version_current=$(grep -io "unifi-[0-9].[0-9]" "${unifi_repo_file}")
      unifi_repo_file_version_new="unifi-${custom_application_digit_1}.${custom_application_digit_2}"
      sed -i "s/${unifi_repo_file_version_current}/${unifi_repo_file_version_new}/g" "${unifi_repo_file}" &>> "${eus_dir}/logs/unifi_repo_file_update.log"
    done < /tmp/EUS/repository/unifi-repo-file
  fi
  header
  echo -e "${WHITE_R}#${RESET} Upgrading your UniFi Network Application from \"${current_application_version}\" to \"${custom_application_version}\"..\\n\\n"
  if DEBIAN_FRONTEND=noninteractive dpkg -i "${unifi_temp}" &>> "${eus_dir}/logs/unifi_update.log"; then echo -e "${GREEN}#${RESET} Successfully updated UniFi Network version from ${unifi_current} to ${application_version_release}! \\n"; else echo -e "${RED}#${RESET} Failed to update the UniFi Network version from ${unifi_current} to ${application_version_release}...\\n"; abort; fi
  rm --force "$unifi_temp" 2> /dev/null
  unifi_update_finish
}

if [[ "${script_option_custom_url}" == 'true' && "${perform_application_upgrade}" == 'true' ]]; then if [[ "${custom_url_down_provided}" == 'true' ]]; then custom_url_download_check; else custom_url_question; fi; fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                           UniFi Network Application download and installation                                                          #
#                                                                                                                                                                        #
##########################################################################################################################################################################

application_upgrade_releases() {
  unifi_current=$(dpkg -l unifi | tail -n1 |  awk '{print $3}' | cut -d'-' -f1)
  application_version_release=$(echo "${application_version}" | cut -d'-' -f1)
  application_version_release_digit_1=$(echo "${application_version_release}" | cut -d'.' -f1)
  application_version_release_digit_2=$(echo "${application_version_release}" | cut -d'.' -f2)
  application_version_release_digit_3=$(echo "${application_version_release}" | cut -d'.' -f3)
  application_current_digit_1=$(echo "${unifi_current}" | cut -d'.' -f1)
  application_current_digit_2=$(echo "${unifi_current}" | cut -d'.' -f2)
  application_current_digit_3=$(echo "${unifi_current}" | cut -d'.' -f3)
  if [[ "${application_version_release_digit_1}" -gt "${application_current_digit_1}" ]]; then application_upgrade=yes; fi
  if [[ "${application_version_release_digit_2}" -gt "${application_current_digit_2}" ]]; then application_upgrade=yes; fi
  if [[ "${application_version_release_digit_3}" -gt "${application_current_digit_3}" ]]; then application_upgrade=yes; fi
  if [[ "${application_upgrade}" != 'yes' ]]; then
    header_red
	echo -e "${WHITE_R}#${RESET} You were about to downgrade your UniFi Network Application from \"${unifi_current}\" to \"${application_version_release}\".. Cancelling this upgrade..\\n\\n"
    author
    exit 0
  fi
  if [[ -s "/tmp/EUS/repository/unifi-repo-file" ]]; then
    while read -r unifi_repo_file; do
      unifi_repo_file_version_current=$(grep -io "unifi-[0-9].[0-9]" "${unifi_repo_file}")
      unifi_repo_file_version_new="unifi-${application_version_release_digit_1}.${application_version_release_digit_2}"
      sed -i "s/${unifi_repo_file_version_current}/${unifi_repo_file_version_new}/g" "${unifi_repo_file}" &>> "${eus_dir}/logs/unifi_repo_file_update.log"
    done < /tmp/EUS/repository/unifi-repo-file
  fi
  header
  echo -e "${WHITE_R}#${RESET} Updating your UniFi Network version from ${unifi_current} to ${application_version_release}! \\n"
  echo -e "${WHITE_R}#${RESET} Downloading UniFi Network version ${application_version_release}..."
  unifi_temp="$(mktemp --tmpdir=/tmp/EUS/downloads unifi_sysvinit_all_"${application_version_release}"_XXXXX.deb)"
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/unifi_download.log"
  if wget "${wget_progress[@]}" -O "$unifi_temp" "https://dl.ui.com/unifi/${application_version}/unifi_sysvinit_all.deb" &>> "${eus_dir}/logs/unifi_download.log"; then echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Network version ${application_version_release}! \\n"; elif wget "${wget_progress[@]}" -O "$unifi_temp" "https://dl.ui.com/unifi/${application_version_release}/unifi_sysvinit_all.deb" &>> "${eus_dir}/logs/unifi_download.log"; then echo -e "${GREEN}#${RESET} Successfully downloaded UniFi Network version ${application_version_release}! \\n"; else echo -e "${RED}#${RESET} Failed to download UniFi Network version ${application_version_release}...\\n"; abort; fi
  echo -e "${WHITE_R}#${RESET} Installing UniFi Network version ${application_version_release} over ${unifi_current}..."
  echo "unifi unifi/has_backup boolean true" 2> /dev/null | debconf-set-selections
  if DEBIAN_FRONTEND=noninteractive dpkg -i "${unifi_temp}" &>> "${eus_dir}/logs/unifi_update.log"; then echo -e "${GREEN}#${RESET} Successfully updated UniFi Network version from ${unifi_current} to ${application_version_release}! \\n"; else echo -e "${RED}#${RESET} Failed to update the UniFi Network version from ${unifi_current} to ${application_version_release}...\\n"; abort; fi
  rm --force "${unifi_temp}" &> /dev/null
  sleep 3
}

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                             5.0.x | 5.1.x | 5.2.x | 5.3.x | 5.4.x | 5.5.x                                                              #
#                                                                                                                                                                        #
##########################################################################################################################################################################

start_application_upgrade

if [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" =~ ^(0|1|2|3|4|5)$ ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${WHITE_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${WHITE_R}${release_stage_friendly}${RESET}\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  5.6.40 ( UAP-AC, UAP-AC v2, UAP-AC-OD, PicoM2 )"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  5.6.42 ( UAP-AC, UAP-AC v2, UAP-AC-OD )"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  6.5.55"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.0.22"
  if [[ "${release_stage}" == 'RC' ]]; then
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  ${rc_version_available}"
    echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel\\n\\n"
  else
    echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
  fi

  read -rp $'Your choice | \033[39m' UPGRADE_VERSION
  case "$UPGRADE_VERSION" in
      1)
        unifi_update_start
        unifi_firmware_requirement
        application_version="5.6.40"
        application_upgrade_releases
        unifi_update_finish;;
      2)
        unifi_update_start
        unifi_firmware_requirement
        application_version="5.6.42"
        application_upgrade_releases
        unifi_update_finish;;
      3)
        unifi_update_start
        unifi_firmware_requirement
        application_version="6.5.55"
        application_upgrade_releases
        unifi_update_finish;;
      4)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.0.22-8c2c64c175"
        application_upgrade_releases
        unifi_update_finish;;
      5)
        if [[ "${release_stage}" == 'RC' ]]; then
          unifi_update_start
          unifi_firmware_requirement
          application_version="${rc_version_available_secret}"
          application_upgrade_releases
          unifi_update_finish
        else
          cancel_script
        fi;;
      6|*) cancel_script;;
  esac

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                       5.6.x                                                                            #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" == '6' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${WHITE_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${WHITE_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "5.6.40" || "${unifi}" == "5.6.41" ]]; then
    unifi_version='5.6.40'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  5.6.42 ( UAP-AC, UAP-AC v2, UAP-AC-OD )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  7.0.22"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
    fi
  elif [[ "${unifi}" == "5.6.42" ]]; then
    unifi_version='5.6.42'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.0.22"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  5.6.40 ( UAP-AC, UAP-AC v2, UAP-AC-OD, PicoM2 )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  5.6.42 ( UAP-AC, UAP-AC v2, UAP-AC-OD )"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  7.0.22"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "5.6.40" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          migration_check
          application_version="7.0.22-8c2c64c175"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="5.6.42"
            application_upgrade_releases
            migration_check
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        4|*) cancel_script;;
    esac
  elif [[ "${unifi_version}" == "5.6.42" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.22-8c2c64c175"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        4|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.40"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="5.6.42"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          unifi_update_start
          unifi_firmware_requirement
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        4)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.22-8c2c64c175"
          application_upgrade_releases
          unifi_update_finish;;
        5)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        6|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                         5.7.x | 5.8.x | 5.9.x                                                                          #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" =~ ^(7|8|9|10|11|12|13|14)$ ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${WHITE_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${WHITE_R}${release_stage_friendly}${RESET}\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.5.55"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.0.22"
  if [[ "${release_stage}" == 'RC' ]]; then
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  ${rc_version_available}"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
  else
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
  fi

  read -rp $'Your choice | \033[39m' UPGRADE_VERSION
  case "$UPGRADE_VERSION" in
      1)
        unifi_update_start
        unifi_firmware_requirement
        application_version="6.5.55"
        application_upgrade_releases
        unifi_update_finish;;
      2)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.0.22-8c2c64c175"
        application_upgrade_releases
        unifi_update_finish;;
      3)
        if [[ "${release_stage}" == 'RC' ]]; then
          unifi_update_start
          unifi_firmware_requirement
          application_version="${rc_version_available_secret}"
          application_upgrade_releases
          unifi_update_finish
        else
          cancel_script
        fi;;
      4|*) cancel_script;;
  esac

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                  6.0.x | 6.1.x | 6.2.x | 6.3.x | 6.4.x                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '6' && "${second_digit_unifi}" =~ ^(0|1|2|3|4)$ ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${WHITE_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${WHITE_R}${release_stage_friendly}${RESET}\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.5.55"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.0.22"
  if [[ "${release_stage}" == 'RC' ]]; then
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  ${rc_version_available}"
    echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
  else
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
  fi

  read -rp $'Your choice | \033[39m' UPGRADE_VERSION
  case "$UPGRADE_VERSION" in
      1)
        unifi_update_start
        unifi_firmware_requirement
        application_version="6.5.55"
        application_upgrade_releases
        unifi_update_finish;;
      2)
        unifi_update_start
        unifi_firmware_requirement
        application_version="7.0.22-8c2c64c175"
        application_upgrade_releases
        unifi_update_finish;;
      3)
        if [[ "${release_stage}" == 'RC' ]]; then
          unifi_update_start
          unifi_firmware_requirement
          application_version="${rc_version_available_secret}"
          application_upgrade_releases
          unifi_update_finish
        else
          cancel_script
        fi;;
      4|*) cancel_script;;
  esac

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  6.5.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '6' && "${second_digit_unifi}" == '5' ]]; then
  release_wanted
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${WHITE_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${WHITE_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "6.5.55" ]]; then
    unifi_version='6.5.55'
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.0.22"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.5.55"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  7.0.22"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "6.5.55" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.22-8c2c64c175"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        3|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="6.5.55"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.22-8c2c64c175"
          application_upgrade_releases
          unifi_update_finish;;
        3)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        4|*) cancel_script;;
    esac
  fi

##########################################################################################################################################################################
#                                                                                                                                                                        #
#                                                                                  7.0.x                                                                                 #
#                                                                                                                                                                        #
##########################################################################################################################################################################

elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '0' ]]; then
  if [[ "${third_digit_unifi}" -gt '22' ]]; then not_supported_version; fi
  release_wanted
  if [[ "${release_stage}" == 'RC' ]]; then if [[ "${unifi}" == "${rc_version_available}" ]]; then debug_check_no_upgrade; unifi_update_latest; fi; fi
  if [[ "${release_stage}" == 'S' ]]; then if [[ "${unifi}" == "7.0.22" ]]; then debug_check_no_upgrade; unifi_update_latest; fi; fi
  header
  echo "  To what UniFi Network Application version would you like to update?"
  echo -e "  Currently your UniFi Network Application is on version ${WHITE_R}$unifi${RESET}"
  echo -e "\\n  Release stage is set to | ${WHITE_R}${release_stage_friendly}${RESET}\\n\\n"
  if [[ "${unifi}" == "7.0.22" ]]; then
    unifi_version='7.0.22'
    #echo -e " [   ${WHITE_R}1${RESET}   ]  |  6.2.17"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}1${RESET}   ]  |  Cancel\\n\\n"
    fi
  else
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  7.0.22"
    if [[ "${release_stage}" == 'RC' ]]; then
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  ${rc_version_available}"
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel\\n\\n"
    else
      echo -e " [   ${WHITE_R}2${RESET}   ]  |  Cancel\\n\\n"
    fi
  fi

  if [[ "${unifi_version}" == "7.0.22" ]]; then
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        2|*) cancel_script;;
    esac
  else
    read -rp $'Your choice | \033[39m' UPGRADE_VERSION
    case "$UPGRADE_VERSION" in
        1)
          unifi_update_start
          unifi_firmware_requirement
          application_version="7.0.22-8c2c64c175"
          application_upgrade_releases
          unifi_update_finish;;
        2)
          if [[ "${release_stage}" == 'RC' ]]; then
            unifi_update_start
            unifi_firmware_requirement
            application_version="${rc_version_available_secret}"
            application_upgrade_releases
            unifi_update_finish
          else
            cancel_script
          fi;;
        3|*) cancel_script;;
    esac
  fi
else
  not_supported_version
fi