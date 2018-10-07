#!/usr/bin/env bash

STABLE_VERSION_ID='935864920'
TEST_VERSION_ID='1440373530'
API_URL='http://steamworkshopdownloader.com/api/workshop/'

OLD_SOURCE_PATH='/tmp'
DOWNLOAD_PATH='/tmp'
FILE_PATH='/home/ubuntu/max/files'

#shellcheck
source ~/.bashrc

function Invoke_workshop_api() {
  SOURCE=$(curl "${API_URL}""${1}" | tee "${OLD_SOURCE_PATH}/${2}")
  File_Size=$(echo "${SOURCE}" | jq '.["file_size"]')
  File_Url=$(echo "${SOURCE}" | jq '.["file_url"]' | awk -F '"' '{printf $2}')
}

function Get_max_verison() {
  cd "${DOWNLOAD_PATH}" || exit 1
  unzip "${DOWNLOAD_PATH}/max_${version}.zip"
  MAX_Version=$(cat strings.po | grep "MAX汉化" | awk -F '[' '{printf $2}' | cut -d ']' -f1)
  echo "${MAX_Version}"
  if [[ -f 'strings.po' ]]; then
    rm -f strings.po
  fi
}

function download() {
  for version in STABLE TEST; do
    if [[ -f "${OLD_SOURCE_PATH}/OLD_SOURCE_${version}" ]]; then
      Old_File_Url=$(cat "${OLD_SOURCE_PATH}"/OLD_SOURCE_${version} | jq '.["file_url"]' | awk -F '"' '{printf $2}')
    fi
    eval Invoke_workshop_api \$"${version}_VERSION_ID" "OLD_SOURCE_${version}"
    if [[ -z $(echo ${SOURCE} | grep "No item") ]]; then
      if [[ "${File_Url}" != "${Old_File_Url}" || ! -f "${FILE_PATH}/max_${version}.zip" ]]; then
        curl -fsSL --connect-timeout 120 "${File_Url}" -o "${DOWNLOAD_PATH}/max_${version}.zip"
        if [[ "$?" -eq 0 ]]; then
          echo "Download max_${version}.zip succeed"
        else
          echo "Download max_${version}.zip fail..."
          continue
        fi
        max_size=$(ls -la ${DOWNLOAD_PATH}/max_${version}.zip | awk -F " " '{printf $5}')
        if [[ "${max_size}" == "${File_Size}" ]]; then
          if [[ -f "${FILE_PATH}/*_${version}.zip" ]]; then
            rm -rf "${FILE_PATH}/*_${version}.zip"
          fi
          Get_max_verison
          mv "${DOWNLOAD_PATH}/max_${version}.zip" "${FILE_PATH}"
          mv "${FILE_PATH}/max_${version}.zip" "${FILE_PATH}/${MAX_Version}_${version}.zip"
          rm -rf "${FILE_PATH}"/Last_update_max_${version}*
          touch "${FILE_PATH}/Last_update_max_${version}_${MAX_Version} $(date)"
        else
          if [[ -f "${DOWNLOAD_PATH}/max_${version}.zip" ]]; then
            rm -rf "${DOWNLOAD_PATH}/max_${version}.zip"
          fi
        fi
      else
        echo "File_Url ${File_Url}"
        echo "Old_File_Url ${Old_File_Url}"
        echo "They are the same.Update skip..."
        if [[ -f "${FILE_PATH}/max_${version}.zip" ]]; then
          echo "${FILE_PATH}/max_${version}.zip"
        fi
      fi
    else
      echo "Can't not find the ${version} verison ."
    fi
  done
}
download
