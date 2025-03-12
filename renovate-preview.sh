#!/usr/bin/env bash

set -euo pipefail

showDebugOutput=false
packageFilesJSON="$(mktemp)"
while [[ $# -gt 0 ]]; do
	case "$1" in
	--help)
		renovate --help
		echo ""
		echo "Preview Options:"
		echo "  --debug                                      Prints the renovate debug log to stdout"
		echo "  --package-files <file>                       Stores the captured packageFiles JSON file to <file> for further analysis"
		exit 0
		;;
	--package-files)
		packageFilesJSON=$2
		shift 2
		;;
	--debug)
		showDebugOutput=true
		shift
		;;
	--)
		shift
		POSITIONAL_ARGS+=("$@")
		break
		;;
	*)
		POSITIONAL_ARGS+=("$1")
		shift
		;;
	esac
done

set +e
OUTPUT=$(
	LOG_LEVEL=DEBUG renovate --onboarding=false --platform=local "${POSITIONAL_ARGS[@]}"
)
ret=$?
set -e

if [ $showDebugOutput == true ] || [ $ret -ne 0 ]; then
	echo -e "$OUTPUT"
fi

if [ $ret -ne 0 ]; then
	exit $ret
fi

# Renovate outputs extensive debug information, including package files with version and update details.
# The first sed extracts only the lines containing updates (yielding nearly valid JSON),
# the second sed fixes the JSON by replacing "config: {" with "{",
# and jq then formats and sorts the output.
# The resulting JSON is saved for summary generation (and maybe further analysis).
echo "$OUTPUT" |
	sed -n '/DEBUG: packageFiles with updates (repository=local)/,/DEBUG: detectSemanticCommits() (repository=local)/{//!p;}' |
	sed '1s/.*/{/' |
	jq --sort-keys >"$packageFilesJSON"

# Print a summary of available updates, grouped by manager and update type (e.g., major, minor)
jq -r '
  to_entries
  | map({
      manager: .key,
      updates: (
        .value
         | map(.deps[]?
             | select(.updates and (.updates | length > 0))
             | . as $dep
             | $dep.updates[]
               | { packageName: $dep.packageName,
                   currentVersion: $dep.currentVersion,
                   newVersion: .newVersion,
                   newVersionAgeInDays: .newVersionAgeInDays,
                   updateType: .updateType,
                   homepage: $dep.homepage }
           )
      ),
      warnings: (
        .value
         | map(.deps[]?
             | select(.warnings and (.warnings | length > 0))
             | { packageName: .packageName,
                 currentValue: .currentValue,
                 warnings: .warnings }
           )
      )
    })
  | map(select((.updates | length > 0) or (.warnings | length > 0)))
  | map(
      "\u001b[1;36mManager:\u001b[0m " + (.manager | ascii_upcase) + "\n" +
      (
         (if (.updates | length > 0) then
            "Updates:\n" +
            ((.updates | sort_by(.updateType) | group_by(.updateType))
             | map(
                 "\u001b[1;35m" + (.[0].updateType) + ":\u001b[0m\n" +
                 (map(
                    " - " + .packageName
                    + " [\u001b[1;33m" + .currentVersion + "\u001b[0m -> \u001b[1;32m" + .newVersion + "\u001b[0m]"
                    + (if (.newVersionAgeInDays != null or ((.homepage // "") | length) > 0) then
                        " (" +
                           (if .newVersionAgeInDays != null then "age: " + (.newVersionAgeInDays | tostring) + "d" else "" end)
                           + (if ((.homepage // "") | length) > 0 then (if .newVersionAgeInDays != null then " - " else "" end) + .homepage else "" end)
                        + ")"
                      else "" end)
                 ) | join("\n"))
             )
             | join("\n\n"))
         else "" end)
         +
         (if (.warnings | length > 0) then
            (if (.updates | length > 0) then "\n\n" else "" end)
            + "\u001b[1;31mWarnings:\u001b[0m\n" +
            ((.warnings)
             | map(
                " - " + .packageName
                + " [\u001b[1;33m" + .currentValue + "\u001b[0m]"
                + " - " + (.warnings | map(.message) | join(" | "))
             )
             | join("\n"))
         else "" end)
      )
  )
  | join("\n\n")
' "$packageFilesJSON"
