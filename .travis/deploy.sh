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

DEPLOY_DOCS_SH=https://raw.githubusercontent.com/PaddlePaddle/PaddlePaddle.org/develop/scripts/deploy/deploy_docs.sh

cd ..

mkdir ./tmp

curl $DEPLOY_DOCS_SH | bash -s $CONTENT_DEC_PASSWD $TRAVIS_BRANCH models ./tmp models

trap : 0
