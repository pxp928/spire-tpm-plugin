#! /bin/sh

for target_binary in tpm_attestor_server tpm_attestor_agent get_tpm_pubhash
do
   if [[ "$(docker images -q $target_binary:simulator 2> /dev/null)" == "" ]]; then
      docker build --build-arg BINARY=$target_binary -t $target_binary:simulator ..
   fi
done

docker-compose -f docker-compose.yaml up
