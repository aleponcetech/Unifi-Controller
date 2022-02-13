#!/bin/bash
###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                      UniFi Devices Upgrade                                                                                      #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if ! env | grep 'LC_ALL\|LANG' | grep -iq 'en_US\|C.UTF-8'; then
  export LC_ALL=C &> /dev/null
  set_lc_all=true
fi

script_location="${BASH_SOURCE[0]}"
username='change_username'
password='change_password'
rm -rf /tmp/EUS/unattended &> /dev/null
mkdir -p /tmp/EUS/unattended/sites
mkdir -p /tmp/EUS/unattended/firmware
mkdir -p /tmp/EUS/unattended/controller

# UniFi API Variables
unifi_https_port=$(grep "^unifi.https.port=" /usr/lib/unifi/data/system.properties | sed 's/unifi.https.port//g' | tr -d '="')
if [[ -z "${unifi_https_port}" ]]; then
  unifi_port_https="8443"
else
  unifi_port_https="${unifi_https_port}"
fi
unifi_api_baseurl="https://localhost:${unifi_port_https}"
unifi_api_cookie=$(mktemp)
unifi_api_curl_cmd="curl --tlsv1 --silent --cookie ${unifi_api_cookie} --cookie-jar ${unifi_api_cookie} --insecure "

unifi_login() {
  ${unifi_api_curl_cmd} --data "{\"username\":\"$username\", \"password\":\"$password\"}" "$unifi_api_baseurl/api/login" >> /tmp/EUS/unattended/controller/login
}

unifi_logout() {
  ${unifi_api_curl_cmd} "$unifi_api_baseurl/logout"
}

unifi_list_sites() {
  ${unifi_api_curl_cmd} "$unifi_api_baseurl/api/stat/sites" | jq -r '.data[] .name' >> /tmp/EUS/unattended/unifi_sites
  while read -r site; do
    mkdir -p "/tmp/EUS/unattended/sites/${site}"
  done < /tmp/EUS/unattended/unifi_sites
}

unifi_get_site_variable() {
  if grep -iq "default" /tmp/EUS/unattended/unifi_sites; then
    site='default'
  else
    site=$(awk 'NR==1{print $1}' /tmp/EUS/unattended/unifi_sites)
  fi
}

unifi_cache_models() {
  mongo --quiet --port 27117 ace --eval "db.getCollection('device').find({}).forEach(printjson);" | sed 's/\(ObjectId(\|)\|NumberLong(\)//g' | jq -r '. | .model' &> /tmp/EUS/unattended/firmware/device_models
}

unifi_cache_remove() {
  ${unifi_api_curl_cmd} --data "{\"cmd\":\"list-cached\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" >> /tmp/EUS/unattended/firmware/cached
  while read -r device_model; do
    jq -r '.data[] | .path' /tmp/EUS/unattended/firmware/cached | cut -d'/' -f1 | awk '!a[$0]++' &> /tmp/EUS/unattended/firmware/base_models
  done < /tmp/EUS/unattended/firmware/device_models
  while read -r device_model; do
    # shellcheck disable=SC2086
    fw_versions=$(jq -r '.data[] | select(.device == "'${device_model}'") | .version' /tmp/EUS/unattended/firmware/cached)
    for fw_version in "${fw_versions[@]}"; do
      ${unifi_api_curl_cmd} --data "{\"cmd\":\"remove\", \"device\":\"$device_model\", \"version\":\"$fw_version\"}" "$unifi_api_baseurl/api/s/${site}/cmd/firmware" &> /dev/null
    done
  done < /tmp/EUS/unattended/firmware/base_models
}

unifi_login
unifi_list_sites
unifi_get_site_variable
unifi_cache_models
unifi_cache_remove
unifi_logout
rm --force "${unifi_api_cookie}" &> /dev/null
rm -rf /tmp/EUS/unattended/ &> /dev/null
if grep -iq "remove_firmware_cache" /etc/crontab; then sed -i "/remove_firmware_cache.sh/d" /etc/crontab &> /dev/null; fi
if [[ -f /etc/cron.d/eus_firmware_removal_script ]]; then rm --force /etc/cron.d/eus_firmware_removal_script &> /dev/null; fi
rm --force "${script_location}" &> /dev/null
rmdir /root/EUS &> /dev/null
if [[ ${set_lc_all} == 'true' ]]; then unset LC_ALL &> /dev/null; fi