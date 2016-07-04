#! /usr/bin/env sh

# Install golang tools under the fucking GFW

BASE=${GOPATH}/src/golang.org/x
mkdir -p $BASE && cd $BASE

TOOLS=("crypto" "net" "sys" "text" "tools")

GOLANG_GITHUB_URL=https://github.com/golang/

for repo in "${TOOLS[@]}"; do
    if [ ! -d $repo ]; then
        echo "clone $repo"
        git clone $GOLANG_GITHUB_URL$repo.git
    fi
done

for repo in "${TOOLS[@]}"; do
    echo "install $repo"
    (cd $repo && go install -v ./...)
done
