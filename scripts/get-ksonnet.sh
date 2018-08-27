#!/bin/bash
set -e
show_help () {
cat << USAGE
usage: $0 [ -v VERSION ]
    -v : Specify the version of the software. 
USAGE
exit 0
}
# Get Opts
while getopts "hv:" opt; do # 选项后面的冒号表示该选项需要参数
    case "$opt" in
    h)  show_help
        ;;
    v)  VERSION=$OPTARG
        ;;
    ?)  # 当有不认识的选项的时候arg为?
        echo "unkonw argument"
        exit 1
        ;;
    esac
done
[ -z "$*" ] && show_help
chk_var () {
if [ -z "$2" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no input for \"$1\", try \"$0 -h\"."
  sleep 3
  exit 1
fi
}
chk_var -v $VERSION
FILE=ks_${VERSION}_linux_amd64.tar.gz
URL=https://github.com/ksonnet/ksonnet/releases/download/v${VERSION}/${FILE}
if [ -f "/tmp/$FILE" ]; then
  yes | cp /tmp/${FILE} ./
fi
if [ ! -f "./$FILE" ]; then
  while true; do
    wget $URL && break
  done
fi
if [[ ! -x "$(command -v ks)" ]]; then
  while true; do
    tar -zxvf $FILE 
    mv ks_${VERSION}_linux_amd64/ks /usr/local/bin
    if [[ -x "$(command -v ks)" ]]; then
      echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - ks installed."
      break
    fi
  done
else
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [INFO] - ks already existed. "
fi
