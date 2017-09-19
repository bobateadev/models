#!/bin/bash
function abort(){
    echo "The deploy process is failed" 1>&2
    exit 1
}

trap 'abort' 0

directory_name="build"

if [ -d $directory_name ]
then
    rm -rf $directory_name
fi

mkdir $directory_name

mkdir $directory_name/.tools
mkdir $directory_name/index

python .pre-commit-hooks/convert_markdown_into_html.py README.md

mv index.html $directory_name/index

cp -a .tools/. $directory_name/.tools

# deploy to remote server
openssl aes-256-cbc -d -a -in ubuntu.pem.enc -out ubuntu.pem -k $DEC_PASSWD

eval "$(ssh-agent -s)"
chmod 400 ubuntu.pem

ssh-add ubuntu.pem
rsync -r build/ ubuntu@52.76.173.135:/var/content/models

chmod 644 ubuntu.pem
rm ubuntu.pem

rm -rf $directory_name

trap : 0
