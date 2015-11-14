#!/bin/bash

# Check dependencies
for d in find xargs stat awk printf; do
    if ! type $d >/dev/null 2>&1; then
        echo "Dependency not found: $d" >&2
        exit 1
    fi
done

# Scan current directory by default
also_check=""
if [[ -z "$*" ]]; then also_check="."; fi

# Exit code
code=0

# Loop through dirs
for dir in $also_check "$@"; do
    if [ ! -d "$dir" ]; then
        echo Not a directory: "$dir" >&2
        code=1
        continue
    fi

    # find -> ls -> awk (count)
    b=$(find "$dir" -type f -exec ls -ln {} \; | \
        awk '{total += $5} END {print total, ""}')
    b=$(echo "$b" | tr -d '[[:space:]]')
    [[ -z "$b" ]] && b=0

    # Suffix: bytes B
    str=$(echo -e "$b B")

    # Format size
    if [[ $b -lt $((1024**1)) ]]; then
        str=$(echo $(( $b / $((1024**0)) )) B)
    elif [[ $b -lt $((1024**2)) ]]; then
        str=$(echo $str \($(( $b / $((1024**1)) )) KB\))
    elif [[ $b -lt $((1024**3)) ]]; then
        str=$(echo $str \($(( $b / $((1024**2)) )) MB\))
    elif [[ $b -lt $((1024**4)) ]]; then
        str=$(echo $str \($(( $b / $((1024**3)) )) GB\))
    else
        str=$(echo $str \($(( $b / $((1024**3)) )) GB\))
    fi

    # Output: size ... directory
    printf -v dots '.%.0s' {1..50}
    printf "%s %s %s\n" "$str" ${dots:${#str}} "$dir"

done

exit $code
