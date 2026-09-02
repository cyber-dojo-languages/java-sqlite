#!/bin/bash
# Invoked as [bash record_aot_caches.sh ...], and that ignores the shebang line,
# so the shell options have to be set here to have any effect. Set on the shebang
# alone they are silently absent, and a workload that failed to compile or a test
# that failed to pass leaves an image the build then reports as a success.
set -Eeu -o pipefail

# Records the two AOT caches a kata's test run replays.
#
# A kata runs in a container thrown away afterwards, so every [test] press pays
# a full JVM startup twice: once for javac and once for the JUnit runner. That
# is not a component of the wait, it is most of it. An AOT cache holds the
# classes each of those JVMs loads, in the form the JVM wants them, and reading
# one back costs a fraction of loading them again.
#
# There are two caches because there are two JVMs, and a cache is validated
# against the classpath of the JVM that reads it. javac's is the compiler;
# the runner's is JUnit and the SQLite driver. One cache could not satisfy both.
#
# A learner's own classes never enter either cache, which is what makes them
# keep working as the learner edits. The runner's cache is recorded against the
# jars alone, and cyber-dojo.sh puts the sandbox directory after them, because a
# cache validates when what it was recorded against is a prefix of what reads it.
# The workload below therefore has to reach the recording JVM as a jar rather
# than as a directory: a directory on the classpath is refused outright when a
# cache is written, and would not be a prefix of anything afterwards.

readonly JARS_DIR="${1:?usage: record_aot_caches.sh <jars-dir>}"
readonly WORK_DIR=/tmp/record_aot_caches
readonly CACHE_DIR=/aot
readonly JAVAC_CACHE="${CACHE_DIR}/javac.aot"
readonly RUNNER_CACHE="${CACHE_DIR}/junit-runner.aot"
readonly WORKLOAD_JAR="${JARS_DIR}/aot-workload.jar"

mkdir -p "${WORK_DIR}" "${CACHE_DIR}"
cp /tmp/throwaway_kata/*.java "${WORK_DIR}"
cd "${WORK_DIR}"

javac -cp "$(ls ${JARS_DIR}/*.jar | tr '\n' ':')" *.java
jar --create --file "${WORKLOAD_JAR}" *.class

# Built after the jar exists, so that the classpath recorded here is the same
# list, in the same order, that cyber-dojo.sh builds at run time.
readonly CLASSES="$(ls ${JARS_DIR}/*.jar | tr '\n' ':')"

# Recorded from the same command line cyber-dojo.sh runs, so that the classes
# held are the ones a kata actually loads.
javac -J-XX:AOTCacheOutput="${JAVAC_CACHE}" \
      -cp "${CLASSES}" \
      *.java

java -XX:AOTCacheOutput="${RUNNER_CACHE}" \
     -cp "${CLASSES}" \
     org.junit.runner.JUnitCore \
     GreeterTest

# The sandbox user reads these at run time and owns none of them.
chmod 0644 "${JAVAC_CACHE}" "${RUNNER_CACHE}" "${WORKLOAD_JAR}"

cd /
rm -rf "${WORK_DIR}"

ls --format=long "${JAVAC_CACHE}" "${RUNNER_CACHE}"
