#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: ./generate_cf_certs_and_keys.sh [options] <PATH TO DIR>"
  echo "Options:"
  echo "    -y|--yes    Always overwrite files"
  echo "    -n|--no     Never overwrite files"
  exit 1
fi

MODE=ask
while true
do
  case $1 in
    -y|--yes)
      MODE=overwrite
      shift
      ;;
    -n|--no)
      MODE=keep
      shift
      ;;
    *)
      break
      ;;
  esac
done

certs_and_keys_dir=$1

mkdir -p $certs_and_keys_dir/cf
pushd $certs_and_keys_dir/cf


for file in ha_proxy_ssl_pem loginha_proxy_ssl_pem jwt_signing_key; do
  var=${file}_flag
  declare "${var}=false"
  if [ -f $file ]; then
    action=
    [ "$MODE" == "overwrite" ] && action=y
    [ "$MODE" == "keep" ] && action=n
    if [ -z "$action" ]
    then
      echo -n "$file already exists. Do you want to recreate it? (y/n)"
      read action
    fi

    if [[ $action == 'y' ]]; then
     declare "${var}=true"
    fi
  else
    declare "${var}=true"
  fi
done

if [[ $ha_proxy_ssl_pem_flag == true ]]; then
  echo -e "\n\n=== GENERATING HAPROXY CERT ===\n"
  openssl genrsa -out haproxy.key 2048 &&
    echo -e "\n\n\n\n\n\n\n" | openssl req -new -x509 -days 3650 -key haproxy.key -out haproxy_cert.pem

  cat haproxy_cert.pem haproxy.key > ha_proxy_ssl_pem
  rm haproxy_cert.pem haproxy.key
fi

if [[ $loginha_proxy_ssl_pem_flag == true ]]; then
  echo -e "\n\n=== GENERATING LOGIN HAPROXY CERT ===\n"
  openssl genrsa -out loginhaproxy.key 2048 &&
    echo -e "\n\n\n\n\n\n\n" | openssl req -new -x509 -days 3650 -key loginhaproxy.key -out loginhaproxy_cert.pem

  cat loginhaproxy_cert.pem loginhaproxy.key > loginha_proxy_ssl_pem
  rm loginhaproxy_cert.pem loginhaproxy.key
fi

if [[ $jwt_signing_key_flag == true ]]; then
  echo -e "\n\n=== GENERATING JWT KEY ===\n"
  rm -f jwt_signing_key jwt_verification_key
  openssl genrsa -out jwt_signing_key  2048
  openssl rsa -pubout -in jwt_signing_key -out jwt_verification_key
fi

ls -l

popd

echo -e "\n\nFinished generating certs and keys."
