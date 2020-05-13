#!/bin/bash

pm_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
[ -d "$pm_dir" ] || {
	echo "FATAL: no current dir (maybe running in zsh?)"
	exit 1
}
TOP_DIR=$(realpath $pm_dir/..)

# shellcheck source=common.sh
source "$pm_dir/common.sh"

#################################################################################################

# the directory with Values and other stuff used for generating manifests in Travis
PROFILES_DIR="$pm_dir/profiles"

# the directory where manifest are left for being published
ARTIFACTS_DIR="$TOP_DIR/artifacts"

# directory with the input CRDs
CRDS_DIR="$TOP_DIR/crds"

# the main values.yaml file
MAIN_VALUES_YAML=$TOP_DIR/values.yaml

#################################################################################################

# parses a YAML file, exporting the full tree as variables with a prefix
# for example, with a prefix "yaml_" "namespace.yaml" is exported as "yaml_namespace_name"
parse_yaml() {
	local prefix=$2
	local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
	sed -ne "s|^\($s\):|\1|" \
		-e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
		-e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
		awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

generate() {
	info "Preparing manifests in $ARTIFACTS_DIR"
	mkdir -p $ARTIFACTS_DIR
	rm -f $ARTIFACTS_DIR/*.yaml

	for target in $PROFILES_DIR/*; do
		[ -d "$target" ] || continue
		name=$(basename $target)

		info "Will add values from ${MAIN_VALUES_YAML}"
		args="--values ${MAIN_VALUES_YAML}"
		eval $(parse_yaml $MAIN_VALUES_YAML "yaml_")

		values_yaml="$target/values.yaml"
		if [ -f $values_yaml ]; then
			info "Will add values from ${values_yaml}"
			args="$args --values ${values_yaml}"
			eval $(parse_yaml $values_yaml "yaml_")
		fi

		artifact_crds_manif="${ARTIFACTS_DIR}/${name}-crds.yaml"
		artifact_manif="${ARTIFACTS_DIR}/${name}.yaml"

		info "Creating CRD for ${name}: $artifact_crds_manif"
		cat $CRDS_DIR/*.yaml >$artifact_crds_manif

		info "Trying to get some info from the values.yaml"
		release_name="ambassador"
		if [ -n "$yaml_nameOverride" ]; then
			info "... using release name '$yaml_nameOverride' (obtained from the 'nameOverride' in the YAML files)"
			release_name="$yaml_nameOverride"
		fi

		namespace="ambassador"
		if [ -n "$yaml_namespace_name" ]; then
			info "... using namespace '$yaml_namespace_name' (obtained from the 'namespace.name' in the YAML files)"
			args="$args -n $yaml_namespace_name"
		fi

		info "Creating manifest for '${name}': ${artifact_manif}"
		helm template $release_name $args $TOP_DIR --skip-crds >$artifact_manif

		append_yaml="$target/append.yaml"
		if [ -f $append_yaml ]; then
			info "Appending ${append_yaml} to $artifact_manif"
			cat $artifact_manif $append_yaml >$artifact_manif
		fi
	done

	info "Files generated in $ARTIFACTS_DIR: $(ls $ARTIFACTS_DIR/*.yaml | tr '\n' ' ')"
}

push() {
	info "Pushing manifests"
	# TODO
}

#################################################################################################

if [ $# -eq 0 ]; then
	info "No command(s) provided."
	info "Usage: $0 [generate|push]"
	exit 0
else
	while [[ $# -gt 0 ]]; do
		opt="$1"
		shift #expose next argument

		case "$opt" in
		generate)
			generate
			;;

		push)
			push
			;;

		*)
			echo "$HELP_MSG"
			echo
			abort "Unknown command '$opt'"
			;;
		esac

	done
fi
