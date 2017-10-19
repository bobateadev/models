#!/bin/bash
function abort(){
    echo "The deploy process is failed" 1>&2
    exit 1
}

if [[ "$TRAVIS_BRANCH" =~ ^v[[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?(-\S*)?$ ]]
then
    # Production Deploy
    echo "Deploying to PROD"
elif [ "$TRAVIS_BRANCH" == "develop" ]
then
    # Development Deploy
    echo "Deploying to DEVELOP"
else
    # All other branches should be ignored
    echo "Cannot deploy image, invalid branch: $TRAVIS_BRANCH"
    exit 1
fi

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

### pull PaddlePaddle.org app and run the deploy_documentation command
# https://github.com/PaddlePaddle/PaddlePaddle.org/archive/master.zip

curl -LOk https://github.com/PaddlePaddle/PaddlePaddle.org/archive/master.zip

unzip master.zip

cd PaddlePaddle.org-master/

cd portal/

sudo pip install -r requirements.txt

mkdir ./tmp
python manage.py deploy_documentation models $TRAVIS_BRANCH ./tmp

###
cd ../..

# deploy to remote server
openssl aes-256-cbc -d -a -in ubuntu.pem.enc -out ubuntu.pem -k $DEC_PASSWD

eval "$(ssh-agent -s)"
chmod 400 ubuntu.pem

ssh-add ubuntu.pem
rsync -r PaddlePaddle.org-master/portal/tmp/ ubuntu@52.76.173.135:/var/content_staging/docs
rsync -r PaddlePaddle.org-master/portal/tmp/ ubuntu@52.76.173.135:/var/content/docs

chmod 644 ubuntu.pem
rm ubuntu.pem

rm -rf $directory_name

rm -rf ./tmp
rm -rf PaddlePaddle.org-master/
rm -rf master.zip

trap : 0
