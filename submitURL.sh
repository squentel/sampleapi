####Example: bash submitfiles.sh -c "YOUR_API_CLIENT" -s "YOUR_API_SECRET" -u "yourURL" -p "140"

#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -c client_id -s client_secret -u urltoanalyze -p platform "
   echo -e "\t-c your API client"
   echo -e "\t-s your API secret"
   echo -e "\t-u your url"
   echo -e "\t-p the platform for sandboxing ex Windows 11 - 140"
   exit 1 # Exit script after printing help
}

while getopts "c:s:u:p:" opt
do
   case "$opt" in
      c ) client_id="$OPTARG" ;;
      s ) client_secret="$OPTARG" ;;
      u ) urltoanalyse="$OPTARG" ;;
      p ) platform="$OPTARG" ;;
      h ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$client_id" ] || [ -z "$client_secret" ] || [ -z "$urltoanalyze" ] || [ -z "$platform" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi



export base_name=$(basename ${myfilepath})

####Generate API Token####
json=$(curl --location 'https://api.eu-1.crowdstrike.com/oauth2/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Accept: application/json' \
--data-urlencode "client_id=$client_id" \
--data-urlencode "client_secret=$client_secret")

token=$( jq -r ".access_token" <<<"$json" )


####Upload file to sandbox####

generate_post_data()
{
  cat <<EOF
{
  "sandbox": [
   {
    "environment_id": $platform,
    "url": "$urltoanalyse",
    "submit_name": "$urlshort"
    }
  ]
}
EOF
}


####Submit file for analysis####
 curl --location 'https://api.eu-1.crowdstrike.com/falconx/entities/submissions/v1' \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header "Authorization: Bearer $token" \
--data "$(generate_post_data)"


