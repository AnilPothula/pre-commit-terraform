#!/usr/bin/env bash
set -eo pipefail

# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"
  common::parse_and_export_env_vars
  # Support for setting PATH to repo root.
  # shellcheck disable=SC2178 # It's the simplest syntax for that case
  ARGS=${ARGS[*]/__GIT_WORKING_DIR__/$(pwd)\/}

  # Suppress tfsec color
  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    # shellcheck disable=SC2178,SC2128 # It's the simplest syntax for that case
    ARGS+=" --no-color"
  fi

  # shellcheck disable=SC2128 # It's the simplest syntax for that case
  common::per_dir_hook "$ARGS" "$HOOK_ID" "${FILES[@]}"
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed in loop
# on each provided dir path. Run wrapped tool with specified arguments
# Arguments:
#   args (string with array) arguments that configure wrapped tool behavior
#   dir_path (string) PATH to dir relative to git repo root.
#     Can be used in error logging
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
  local -r args="$1"
  # shellcheck disable=SC2034 # Unused var.
  local -r dir_path="$2"

  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  tfsec ${args[@]}

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed one time
# in the root git repo
# Arguments:
#   args (string with array) arguments that configure wrapped tool behavior
#######################################################################
function run_hook_on_whole_repo {
  local -r args="$1"

  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  tfsec "$(pwd)" ${args[@]}

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
