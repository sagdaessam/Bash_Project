source ./lib.sh
directory="${1:-.}"
require_dir "$directory"

if [ $? -ne 0 ]
then
    exit 1
fi



scan_directory() {

    local dir="$1"
    local files_count=0
    local folders_count=0

    echo "Scanning directory: $dir"

    for item in "$dir"/*
    do
        if [ -e "$item" ]
        then
            if [ -d "$item" ]
            then
                echo "[dir ] ${item##*/}"
                folders_count=$((folders_count+1))

            elif [ -f "$item" ]
            then
                echo "[file] ${item##*/}"
                files_count=$((files_count+1))
            fi
        fi
    done

    echo "Files: $files_count"
    echo "Folders: $folders_count"

    log_action "Scanned directory: $dir"
}


permission_audit() {

    local dir="$1"
    local unreadable_count=0
    local executable_count=0
    local permissions

    echo "Permission Audit:"

    for file in "$dir"/*
    do
        if [ -f "$file" ]
        then
            permissions=""

            if [ -r "$file" ]
            then
                permissions="${permissions}r"
            else
                permissions="${permissions}-"
                unreadable_count=$((unreadable_count+1))
            fi

            if [ -w "$file" ]
            then
                permissions="${permissions}w"
            else
                permissions="${permissions}-"
            fi

            if [ -x "$file" ]
            then
                permissions="${permissions}x"
                executable_count=$((executable_count+1))
            else
                permissions="${permissions}-"
            fi

            echo "$permissions   ${file##*/}"
        fi
    done

    echo "Unreadable files: $unreadable_count"
    echo "Executable files: $executable_count"

    log_action "Permission audit completed: $dir"
}


extension_report() {

    local dir="$1"
    local file
    local filename
    local extension

    declare -A extensions

    extensions[txt]=0
    extensions[log]=0
    extensions[sh]=0
    extensions[jpg]=0
    extensions[other]=0

    for file in "$dir"/*
    do
        if [ -f "$file" ]
        then
            filename="${file##*/}"

            if [[ "$filename" == *.* ]]
            then
                extension="${filename##*.}"
            else
                extension="other"
            fi

            if [ "$extension" == "txt" ]
            then
                extensions[txt]=$((extensions[txt]+1))

            elif [ "$extension" == "log" ]
            then
                extensions[log]=$((extensions[log]+1))

            elif [ "$extension" == "sh" ]
            then
                extensions[sh]=$((extensions[sh]+1))

            elif [ "$extension" == "jpg" ]
            then
                extensions[jpg]=$((extensions[jpg]+1))

            else
                extensions[other]=$((extensions[other]+1))
            fi
        fi
    done

    echo "Extension Report:"

    for extension in txt log sh jpg other
    do
        echo "$extension : ${extensions[$extension]}"
    done

    log_action "Extension report completed: $dir"
}


search_file() {

    local dir="$1"
    local search_text
    local found=0

    read -r -p "Enter file name to search: " search_text

    for file in "$dir"/*
    do
        if [ -f "$file" ]
        then
            filename="${file##*/}"

            if [[ "$filename" == *"$search_text"* ]]
            then
                echo "Found: $filename"
                found=1
            fi
        fi
    done

    if [ "$found" -eq 0 ]
    then
        echo "No matching files found."
    fi

    log_action "Searched for: $search_text"
}


backup_all() {

    local dir="$1"
    local backup_dir="$dir/backups"
    local saved_count=0
    local skipped_count=0
    local filename
    local backup_name
    local current_date

    mkdir -p "$backup_dir"

    current_date=$(date +%Y%m%d_%H%M%S)

    for file in "$dir"/*
    do
        if [ -f "$file" ]
        then
            filename="${file##*/}"

            if [ -r "$file" ]
            then
                backup_name="${filename%.*}_${current_date}.bak"

                if cp "$file" "$backup_dir/$backup_name"
                then
                    echo "Backed up: $filename"
                    saved_count=$((saved_count+1))
                else
                    log_error "Could not backup: $filename"
                    skipped_count=$((skipped_count+1))
                fi

            else
                log_error "Unreadable file skipped: $filename"
                skipped_count=$((skipped_count+1))
            fi
        fi
    done

    echo "Saved files: $saved_count"
    echo "Skipped files: $skipped_count"

    log_action "Backup completed: $saved_count saved, $skipped_count skipped"
}


list_backups() {

    local dir="$1"
    local backup_dir="$dir/backups"
    local found=0

    echo "Available Backups:"

    for file in "$backup_dir"/*
    do
        if [ -f "$file" ]
        then
            echo "${file##*/}"
            found=1
        fi
    done

    if [ "$found" -eq 0 ]
    then
        echo "(no backups yet)"
    fi

    log_action "Listed backups"
}
restore_backup() {

    local dir="$1"
    local backup_dir="$dir/backups"
    local backup_name
    local backup_path
    local destination

    read -r -p "Enter backup name: " backup_name

    backup_path="$backup_dir/$backup_name"

    if [ ! -f "$backup_path" ]
    then
        log_error "Backup does not exist."
        log_action "Restore failed: $backup_name"
        return 1
    fi

    destination="$dir/restored_$backup_name"

    if [ -e "$destination" ]
    then
        log_error "Destination already exists. Original file will not be overwritten."
        log_action "Restore failed: destination exists"
        return 1
    fi

    if cp "$backup_path" "$destination"
    then
        log_info "File restored successfully: ${destination##*/}"
        log_action "Restored: $backup_name"
    else
        log_error "Restore failed."
        log_action "Restore failed: $backup_name"
        return 1
    fi
}


show_menu() {

    local dir="$1"
    local choice

    while true
    do
        
        echo "1. Scan Directory"
        echo "2. Permission Audit"
        echo "3. Extension Report"
        echo "4. Search File"
        echo "5. Backup All"
        echo "6. List Backups"
        echo "7. Restore Backup"
        echo "8. Exit"
        echo "=================================="

        read -r -p "Enter your choice: " choice

        if [ "$choice" -eq 1 ] 2>/dev/null
        then
            scan_directory "$dir"

        elif [ "$choice" -eq 2 ] 2>/dev/null
        then
            permission_audit "$dir"

        elif [ "$choice" -eq 3 ] 2>/dev/null
        then
            extension_report "$dir"

        elif [ "$choice" -eq 4 ] 2>/dev/null
        then
            search_file "$dir"

        elif [ "$choice" -eq 5 ] 2>/dev/null
        then
            backup_all "$dir"

        elif [ "$choice" -eq 6 ] 2>/dev/null
        then
            list_backups "$dir"

        elif [ "$choice" -eq 7 ] 2>/dev/null
        then
            restore_backup "$dir"

        elif [ "$choice" -eq 8 ] 2>/dev/null
        then
            echo "Goodbye!"
            break

        else
            log_error "Wrong choice. Please try again."
        fi
    done
}

main() {

    local dir="$1"
    local action="$2"

    if [ -z "$action" ]
    then
        show_menu "$dir"

    elif [ "$action" == "scan" ]
    then
        scan_directory "$dir"

    elif [ "$action" == "perms" ]
    then
        permission_audit "$dir"

    elif [ "$action" == "ext" ]
    then
        extension_report "$dir"

    elif [ "$action" == "backup" ]
    then
        backup_all "$dir"

    else
        log_error "Invalid action: $action"
        echo "Available actions: scan, perms, ext, backup"
        return 1
    fi
}

main "$directory" "$2"
