#!/bin/bash
set -o errexit # Nozero exit code of any of the commands below will fail the test.
set -o nounset
set -o pipefail

die_modlist() {
    echo "ERROR: go list -mod=readonly -m all failed with the message listed above."
    echo "Cachito used in ART builds will fail to resolve dependencies offline."
    echo "Typically, a pinned version is missing in go.mod, e.g.:"
    echo "    replace k8s.io/foo => k8s.io/foo v0.26.0"
    exit 1
}

echo "Checking that all modules can be resolved offline"
go list -mod=readonly -m all || die_modlist

COMPAT=
# Relax compat for go 1.17
if grep -q "^go 1.17" go.mod; then
    COMPAT="-compat=1.17"
fi

echo "Checking that vendor/ is correct"
go mod tidy $COMPAT
go mod vendor
CHANGES=$(git status --porcelain)
if [ -n "$CHANGES" ] ; then
    echo "ERROR: detected vendor inconsistency after 'go mod tidy; go mod vendor':"
    echo "$CHANGES"
    exit 1
fi
