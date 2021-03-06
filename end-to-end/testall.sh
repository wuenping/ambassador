#!/bin/sh

set -e
set -o pipefail

HERE=$(cd $(dirname $0); pwd)
BUILD_ALL=${BUILD_ALL:-false}

cd "$HERE"
source "$HERE/kubernaut_utils.sh"

if [ "$BUILD_ALL" = true ]; then
  sh buildall.sh
fi

if [ -z "$SKIP_KUBERNAUT" ]; then
    get_kubernaut_cluster
else
    echo "WARNING: your current kubernetes context will be WIPED OUT"
    echo "by this test. Current context:"
    echo ""
    kubectl config current-context
    echo ""

    while true; do
        read -p 'Is this really OK? (y/N) ' yn

        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# For linify
export MACHINE_READABLE=yes
export SKIP_CHECK_CONTEXT=yes

failures=0

for dir in 0*; do
    attempt=0

    while [ $attempt -lt 2 ]; do
        echo
        echo "================================================================"
        echo "${attempt}: ${dir}..."

        attempt=$(( $attempt + 1 ))

        if sh $dir/test.sh 2>&1 | python linify.py test.log; then
            echo "${dir} PASSED"
            break
        else
            echo "${dir} FAILED"
            failures=$(( $failures + 1 ))

            echo "================ start captured output"
            cat test.log
            echo "================ end captured output"
        fi
    done
done

exit $failures
