#!/bin/bash
# Invoked as [bash install_jars.sh ...], and that ignores the shebang line, so
# the shell options have to be set here to have any effect. Set on the shebang
# alone they are silently absent, and a failed download leaves a half-filled
# jars directory that the build then reports as a success.
set -Eeu -o pipefail

# Installs the jars a kata compiles and runs against, resolved by Maven at image
# build time rather than committed to this repo. A committed jar is a binary
# nobody can review and nobody remembers to update; resolving instead means the
# image tracks releases and the repo holds only the names in pom.xml.
#
# Maven is installed here and removed again in the same layer, so it is a build
# tool rather than something a kata's container carries around.

readonly JARS_DIR="${1:?usage: install_jars.sh <jars-dir>}"
readonly POM_DIR=/tmp/install_jars

# A milestone or release candidate counts as a release to Maven, so without
# this a rebuild can quietly move a kata onto an unfinished library.
readonly PRERELEASES='.*-M\d+,.*-RC\d+,.*-alpha.*,.*-beta.*,.*-SNAPSHOT'

apk add --no-cache maven

mkdir -p "${JARS_DIR}" "${POM_DIR}"
cp /tmp/pom.xml "${POM_DIR}"
cd "${POM_DIR}"

# The versions in pom.xml are a floor. This moves each to the newest release,
# so a rebuild picks up what has been published since, and the build log records
# what that turned out to be.
mvn --batch-mode --no-transfer-progress versions:use-latest-releases \
    -DgenerateBackupPoms=false \
    -DallowSnapshots=false \
    -Dmaven.version.ignore="${PRERELEASES}"

echo '--- resolved versions ---'
mvn --batch-mode --no-transfer-progress dependency:list \
    -DexcludeTransitive=false \
    -DoutputAbsoluteArtifactFilename=false

# Transitive dependencies come too: what a kata needs on its classpath is the
# whole graph, not just the libraries it names.
mvn --batch-mode --no-transfer-progress dependency:copy-dependencies \
    -DoutputDirectory="${JARS_DIR}" \
    -DincludeScope=runtime

# The sandbox user reads these at run time and owns none of them.
chmod 0644 "${JARS_DIR}"/*.jar

# Returns the version Maven resolved for one artifact, read from the name of
# the jar it copied, so the record is what the image holds.
jar_version()
{
  local -r artifact="${1}"
  ls "${JARS_DIR}" | sed -n "s/^${artifact}-\([0-9][0-9.]*[0-9]\)\.jar$/\1/p"
}

# Appends one test framework to the test_frameworks list the base image
# wrote in /versions.json, keeping any entry an earlier image added. Stops
# the build if the list is not found, rather than record nothing. Short grep
# flags because busybox grep has no long ones.
add_test_framework()
{
  local -r name="${1}"
  local -r version="${2}"
  local -r entry="{\"name\": \"${name}\", \"version\": \"${version}\"}"
  if [ -z "${version}" ]; then
    echo "Found no version for ${name} in ${JARS_DIR}" >&2
    exit 1
  fi
  if grep -q '"test_frameworks": \[\]' /versions.json; then
    sed -i "s|\"test_frameworks\": \[\]|\"test_frameworks\": [${entry}]|" /versions.json
  else
    sed -i "/\"test_frameworks\": \[/s|}\]|}, ${entry}]|" /versions.json
  fi
  if ! grep -q -F "${entry}" /versions.json; then
    echo "Could not add ${name} to /versions.json" >&2
    cat /versions.json >&2
    exit 1
  fi
}

add_test_framework SQLite "$(jar_version sqlite-jdbc)"
add_test_framework JUnit "$(jar_version junit)"
cat /versions.json

cd /
rm -rf "${POM_DIR}" /tmp/pom.xml ~/.m2
apk del maven

ls --format=long "${JARS_DIR}"
