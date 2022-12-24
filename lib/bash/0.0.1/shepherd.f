#export CURL_ARGS=( "-sS" $ALLOW_INSECURE "-H" "Authorization: bearer "$TOKEN )

shepherd_project=covid
shepherd_flock=hcgbuafwdev-oke

shepherd_uri_scheme=https
shepherd_uri_authority=devops.oci.oraclecorp.com
shepherd_uri_path=api/shepherd/v0/projects/${shepherd_project}/flocks/${shepherd_flock}/releases
shepherd_uri_query=limit=1000&includeArchived=$include_archived
shepherd_uri=${shepherd_uri_scheme}://${shepherd_uri_authority}/${shepehrd_uri_path}?${shepherd_uri_query}


#https://devops.oci.oraclecorp.com/api/shepherd/v0/projects/covid/flocks/hcgbuafwdev-oke/releases?limit=1000&includeArchived=$include_archived

curl ${shepheed_uri}
