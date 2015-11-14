#!/bin/bash

# du used by default (du, ls, stat, wc)
# (SIZE_TOOL="" to compare, for debugging purposes)
if [ -z ${SIZE_TOOL+1} ]; then SIZE_TOOL="du"; fi

# Check dependency: mkfifo
if ! type mkfifo >/dev/null 2>&1; then
    echo "Dependency not found: mkfifo" >&2
    exit 1
fi

# Options
_Q=0
_B=0
_C=0
while getopts "qbc" opt; do
    case $opt in
        q)  _Q=1
            ;;
        b)  _B=1
            ;;
        c)  _C=1
            ;;
    esac
done
shift $((OPTIND -1))

# Scan current directory by default
also_check=""
if [[ -z "$*" ]]; then also_check="."; fi

# Exit code
code=0

# Loop through dirs
for dir in $also_check "$@"; do
    if [ ! -d "$dir" ]; then
        echo Not a directory: "$dir" >&2
        ((code++))
        continue
    fi

    # Counters
    file_count=0
    total_size=0

    # File name for pipe
    pipe0="/tmp/findpipe-$$"
    pipe="$pipe0"
    num=0
    while [ -e "$pipe" ]; do
        num=$(($num + 1))
        pipe="$pipe0$num"
    done

    # Create temporary pipe
    if [[ $(mkfifo "$pipe") ]]; then
        echo "Error creating pipe $pipe" >&2
        exit 1
    fi

    # Find files
    find "$dir" -type f -print0 >"$pipe" &
    while read -r -d $'\0' file; do
        # File

        # Show status
        if [[ _Q -eq 0 ]]; then
            status_str=$((file_count+1))
            status_str="$status_str... "
            echo -ne "$status_str"
            status_back=""
            for ((i=0; i<${#status_str}; i++)); do status_back+="\b"; done
            echo -ne "$status_back"
        fi

        # Get file size
        du_size=""
        ls_size=""
        stat_size=""
        wc_size=""
        if [[ -z "$SIZE_TOOL" || "$SIZE_TOOL" == "du" ]]; then
            du_size=$(du -b "$file" | cut -f1)
        fi
        if [[ -z "$SIZE_TOOL" || "$SIZE_TOOL" == "ls" ]]; then
            ls_size=$(ls -ln "$file" | cut -f5 -d' ')
        fi
        if [[ -z "$SIZE_TOOL" || "$SIZE_TOOL" == "stat" ]]; then
            stat_size=$(stat --printf="%s" "$file")
        fi
        if [[ -z "$SIZE_TOOL" || "$SIZE_TOOL" == "wc" ]]; then
            wc_size=$(wc -c <"$file")
        fi

        # Compare (debugging)
        if [[ -z "$SIZE_TOOL" ]]; then
            if [[ "$du_size" != "$ls_size" ]]; then
                echo "Warning: Mismatch between du (du_size)" \
                    "and ls (ls_size)" >&2
                ((code++))
            fi
            if [[ "$du_size" != "$stat_size" ]]; then
                echo "Warning: Mismatch between du (du_size)" \
                    "and stat (stat_size)" >&2
                ((code++))
            fi
            if [[ "$du_size" != "$wc_size" ]]; then
                echo "Warning: Mismatch between du (du_size)" \
                    "and wc (wc_size)" >&2
                ((code++))
            fi
        fi

        # Pick size from selected tool
        size=""
        if [[ -z "$SIZE_TOOL" ]]; then
            size=$du_size
        elif [[ "$SIZE_TOOL" == "du" ]]; then
            size=$du_size
        elif [[ "$SIZE_TOOL" == "ls" ]]; then
            size=$ls_size
        elif [[ "$SIZE_TOOL" == "stat" ]]; then
            size=$stat_size
        elif [[ "$SIZE_TOOL" == "wc" ]]; then
            size=$wc_size
        else
            echo "Invalid tool requested: $SIZE_TOOL" >&2
            exit 1
        fi

        # Add
        if [[ ! -z "$size" ]]; then
            ((total_size+=$size))
        fi
        ((file_count++))

    done < "$pipe"
    rm "$pipe"

    # Format size
    human=""
    if type numfmt >/dev/null 2>&1; then
        human=$(numfmt \
            --to=iec --suffix=B --format="%3f" "$total_size")
    else
        if [[ $total_size -lt $((1024**1)) ]]; then
            human=$(echo $(( $total_size / $((1024**0)) )) B)
        elif [[ $total_size -lt $((1024**2)) ]]; then
            human=$(echo $total_size \($(( $total_size / $((1024**1)) )) KB\))
        elif [[ $total_size -lt $((1024**3)) ]]; then
            human=$(echo $total_size \($(( $total_size / $((1024**2)) )) MB\))
        elif [[ $total_size -lt $((1024**4)) ]]; then
            human=$(echo $total_size \($(( $total_size / $((1024**3)) )) GB\))
        else
            human=$(echo $total_size \($(( $total_size / $((1024**3)) )) GB\))
        fi
    fi

    # Summary string (per directory)
    str=""
    if [[ ! -z "$human" && $_B -eq 0 ]]; then
        str="${human}"
    else
        str="${total_size}B"
    fi
    if [[ _C -ne 0 ]]; then
        str="$str, $file_count files"
    fi
    printf -v dots '.%.0s' {1..50}
    printf "%s %s %s\n" "$str" ${dots:${#str}} "$dir"

done

exit $code
