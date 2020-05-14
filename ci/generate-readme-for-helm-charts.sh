#!/bin/bash

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -d "$CURR_DIR" ] || { echo "FATAL: no current dir (maybe running in zsh?)";  exit 1; }
TOP_DIR=$CURR_DIR/..

# shellcheck source=common.sh
source "$CURR_DIR/common.sh"

#########################################################################################################

# This script does some processing to make the clone of 
# datawire/ambassador-chart to helm/charts easy.

# The only file that is different is the README that has some small changes

# Trim the top 11 lines of the README
sed 1,11d $TOP_DIR/README.md > README.md.tmp

# Append the changed beginning of the file 

echo '# Ambassador

###### Notice:

The [helm/charts](https://github.com/helm/charts) repository has been [deprecated and will be obsolete on Nov 13 2020](https://github.com/helm/charts#status-of-the-project).

This chart has been provided as a convience for Ambassador users until that time.

Please see https://github.com/datawire/charts for the official chart.

---

The Ambassador Edge Stack is a self-service, comprehensive edge stack that is Kubernetes-native and built on [Envoy Proxy](https://www.envoyproxy.io/).

## TL;DR;

```console
$ helm repo add stable https://kubernetes-charts.storage.googleapis.com
$ helm install ambassador stable/ambassador
```
' > README-charts.md

# Append the rest of the README

cat README.md.tmp >> README-for-helm-charts.md

# Cleanup

rm README.md.tmp

