####Example: bash submitfiles.sh -c "YOUR_API_CLIENT" -s "YOUR_API_SECRET" -f "/YOURPATH/YOUREXE" -p "140"

#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -c client_id -s client_secret -f myfilepath -p platform "
   echo -e "\t-c your API client"
   echo -e "\t-s your API secret"
   echo -e "\t-f your filepath"
   echo -e "\t-p the platform for sandboxing ex Windows 11 - 140"
   exit 1 # Exit script after printing help
}

while getopts "c:s:f:p:" opt
do
   case "$opt" in
      c ) client_id="$OPTARG" ;;
      s ) client_secret="$OPTARG" ;;
      f ) myfilepath="$OPTARG" ;;
      p ) platform="$OPTARG" ;;
      h ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$client_id" ] || [ -z "$client_secret" ] || [ -z "$myfilepath" ] || [ -z "$platform" ]
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
export URL="https://api.eu-1.crowdstrike.com/samples/entities/samples/v2?file_name="$base_name"&is_confidential=true"

json=$(curl -X POST \
 $URL \
 -H "Authorization: Bearer $token" \
 -H 'Content-Type: application/octet-stream' \
 --data-binary @$myfilepath)

sha=$( jq -r ".resources[0].sha256" <<<"$json" )
filename=$( jq -r ".resources[0].file_name" <<<"$json" )


generate_post_data()
{
  cat <<EOF
{
  "sandbox": [
   {
    "environment_id": $platform,
    "sha256": "$sha",
    "submit_name": "$filename"
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

####Delete samples####
curl --location --request DELETE "https://api.eu-1.crowdstrike.com/samples/entities/samples/v2?ids=$sha" \
--header 'Accept: application/json' \
--header "Authorization: Bearer $token"
