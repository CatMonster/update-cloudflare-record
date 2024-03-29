#!/bin/bash
usage() {
  echo "Usage: $0 [-s json_config]" 1>&2
  exit 1
}

get_json_from_cloudflare() {
  curl --request GET "https://api.cloudflare.com/client/v4/zones/$zones/dns_records/$record" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" >temp.json
}

#Getting params
while getopts ":s:" o; do
  case "${o}" in
  s)
    s=${OPTARG}
    ;;
  *)
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "${s}" ]; then
  usage
fi

#Reading values from json config
zones=$(jq -r '.cloudflare.zones' $s)
token=$(jq -r '.cloudflare.token' $s)
record=$(jq -r '.cloudflare.record' $s)

#Getting current record values and cleaning
get_json_from_cloudflare
record_type=$(jq -r '.result.type' 'temp.json')
record_name=$(jq -r '.result.name' 'temp.json')
record_ip=$(jq -r '.result.content' 'temp.json')
record_proxied=$(jq -r '.result.proxied' 'temp.json')
rm temp.json
public_ip=$(curl https://api.ipify.org)

#Updating
if [[ "$public_ip" != "$record_ip" && -n "$public_ip" && -n "$record_ip" ]]; then
  curl --request PUT "https://api.cloudflare.com/client/v4/zones/$zones/dns_records/$record" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    --data '{"type":'\"$record_type\"',"name":'\"$record_name\"',"content":'\"$public_ip\"',"proxied":'$record_proxied'}'

  #Reading updated data from cloudflare
  get_json_from_cloudflare
  record_ip=$(jq -r '.result.content' 'temp.json')
  rm temp.json

  #Checking if record was updated successfully
  if [ "$public_ip" = "$record_ip" ]; then
    recipient=$(jq -r '.mail.recipient' $s)
    subject=$(jq -r '.mail.subject' $s)

    #Replacing mail template placeholders and sending
    sed -e "s/\${last_ip}/$(cat last_ip)/" -e "s/\${current_ip}/$record_ip/" mail_template | mail -s $subject $recipient
    echo $public_ip >last_ip
  fi
fi
