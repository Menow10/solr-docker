#!/usr/bin/env bash
#
# Produce https://github.com/docker-library/official-images/blob/master/library/solr
# Based on https://github.com/docker-library/httpd/blob/master/generate-stackbrew-library.sh
# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
				}
			' '{}' + \
			
	) )"
}
getArches 'solr'

cat <<-EOH
# this file is generated via https://github.com/apache/solr-docker/blob/$(fileCommit "$self")/$self

Maintainers: The Apache Solr Project <dev@solr.apache.org
GitRepo: https://github.com/apache/solr-docker.git
GitFetch: refs/heads/main
EOH

for version in "${versions[@]}"; do
  # We can remove the variant loop when 8.11 is no longer supported
	for variant in '' slim; do
		dir="$version${variant:+-$variant}"
		[ -f "$dir/Dockerfile" ] || continue

		commit="$(dirCommit "$dir")"

	# grep the full version from the Dockerfile, eg: SOLR_VERSION="6.6.1"
		fullVersion="$(git show "$commit:$dir/Dockerfile" | \
			grep -E 'SOLR_VERSION="[^"]+"' | \
			sed -E -e 's/.*SOLR_VERSION="([^"]+)".*$/\1/')"
		if [[ -z $fullVersion ]]; then
			echo "Cannot determine full version from $dir/Dockerfile"
			exit 1
		fi
		versionAliases=(
			"$fullVersion"
			"$version"
		)

		if [[ -n "${aliases[$version]:-}" ]]; then
			versionAliases=( "${versionAliases[@]}"  "${aliases[$version]:-}" )
		fi
		if [ -z "$variant" ]; then
			variantAliases=( "${versionAliases[@]}" )
			if [[ $version == "$latest_version" ]]; then
				variantAliases=( "${variantAliases[@]}"  "latest" )
			fi
		else
			variantAliases=( "${versionAliases[@]/%/-$variant}" )
			if [[ $version == "$latest_version" ]]; then
					variantAliases=( "${variantAliases[@]}"  "$variant" )
			fi
		fi

		variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$dir/Dockerfile")"
		variantArches=(${parentRepoToArches[$variantParent]})
		# Do not produce 32bit images
		variantArches=("${variantArches[@]/*32*}")

		echo
		cat <<-EOE
			Tags: $(sed -E 's/ +/, /g' <<<"${variantAliases[@]}")
			Architectures: $(sed -E 's/ +/, /g' <<<"${variantArches[@]}")
			GitCommit: $commit
			Directory: $dir
		EOE
	done
done
