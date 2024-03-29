#!/bin/bash

##
# This script is based on the setup-skeleton script by Spatie.
# See https://github.com/spatie/package-skeleton-laravel
##

# 'return' when run as "source <script>" or ". <script>", 'exit' otherwise
[[ "$0" != "${BASH_SOURCE[0]}" ]] && safe_exit="return" || safe_exit="exit"

script_name=$(basename "$0")

ask_question(){
    # ask_question <question> <default>
    local ANSWER
    read -r -p "$1 ($2): " ANSWER
    echo "${ANSWER:-$2}"
}

confirm(){
    # confirm <question> (default = N)
    local ANSWER
    read -r -p "$1 (y/N): " -n 1 ANSWER
    echo " "
    [[ "$ANSWER" =~ ^[Yy]$ ]]
}

git_name=$(git config user.name)
author_name=$(ask_question "Author name" "$git_name")

git_email=$(git config user.email)
author_email=$(ask_question "Author email" "$git_email")

username_guess=${author_name//[[:blank:]]/}
author_username=$(ask_question "Author username" "$username_guess")

current_directory=$(pwd)
folder_name=$(basename "$current_directory")

vendor_name_unsanitized=$(ask_question "Vendor name" "District09")
package_name=$(ask_question "Package name" "$folder_name")
package_description=$(ask_question "Package description" "")

class_name=$(echo "$package_name" | sed 's/[-_]/ /g' | awk '{for(j=1;j<=NF;j++){ $j=toupper(substr($j,1,1)) substr($j,2) }}1' | sed 's/[[:space:]]//g')

class_name=$(ask_question "Class Name" "$class_name")

# Calculated values.
current_year="$(date +%Y)"
vendor_name="$(tr '[:lower:]' '[:upper:]' <<< ${vendor_name_unsanitized:0:1})${vendor_name_unsanitized:1}"
vendor_name_lowercase=`echo "$vendor_name_unsanitized" | tr '[:upper:]' '[:lower:]'`
package_name_underscore=`echo "$package_name" | tr '-' '_'`
class_name_safe="${class_name//'\'/\\\\\\\\}"

echo
echo -e "Author: $author_name ($author_username, $author_email)"
echo -e "Package: $vendor_name_lowercase\\$package_name <$package_description>"
echo -e "Class namespace: \\$vendor_name\\$class_name"

echo
files=$(grep -E -r -l -i ":author|:vendor|:package|:district09|:classname" --exclude-dir=vendor ./* ./.github/* | grep -v "$script_name")

echo "This script will replace the above values in all relevant files in the project directory."
if ! confirm "Modify files?" ; then
    $safe_exit 1
fi

echo

for file in $files ; do
    echo "Updating file $file"
    temp_file="$file.temp"
    < "$file" \
      sed "s/:author_name/$author_name/g" \
    | sed "s/:author_username/$author_username/g" \
    | sed "s/:author_email/$author_email/g" \
    | sed "s/:vendor_name/$vendor_name_lowercase/g" \
    | sed "s/:package-name/$package_name/g" \
    | sed "s/:package_name/$package_name_underscore/g" \
    | sed "s/:District09/$vendor_name/g" \
    | sed "s/:ClassName/$class_name_safe/g" \
    | sed "s/:package_description/$package_description/g" \
    | sed "s/:year/$current_year/g" \
    | sed "/^\*\*Note:\*\* Run/d" \
    > "$temp_file"
    rm -f "$file"
    new_file=`echo $file | sed -e "s/District09/${class_name}/g"`
    mv "$temp_file" "$new_file"
done

echo
if confirm "Execute composer install and run GrumPHP" ; then
    composer install && composer grumphp
fi

echo
if confirm "Let this script delete itself (since you only need it once)?" ; then
    echo "Delete $0 !"
    rm -- "$0"
fi
