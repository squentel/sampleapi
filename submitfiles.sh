####Replace with your credentials and file complete path and set platform for sandbox analysis####
export client_id="<YOUR_API_CLIENT_ID>"
export client_secret="<YOUR_API_CLIENT_SECRET>"

export myfilepath="<YOUR_FILE_WITH_PATH>"
export base_name=$(basename ${myfilepath})

platform=300

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
