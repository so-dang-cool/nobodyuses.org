#!/bin/sh

RS=""

sources_root="$(dirname "$0")"
site_template="$sources_root/site.html.template"

cd "$sources_root" || exit 1

# Clean before we start

find "$sources_root" -type f -name '*.html' -delete
find "$sources_root" -type f -name 'sitemap*' -delete

# Generate pages

{
  find . -type f -name '*.md' >tmp
  while IFS= read -r content
  do
    path="$(dirname "$content")"
    TITLE="$(basename "$content" | cut -d '.' -f 1)"

    postname="$(basename "$content" .md | tr '[:upper:]' '[:lower:]')"
    case "$postname" in
      *.index) dest=index.html ;;
      *)       filename="$(echo "$postname" | rev | cut -d '.' -f 1 | rev)"
               mkdir -p "$path/$filename"
               dest="$filename/index.html" ;;
    esac

    CONTENT="$(pandoc --from commonmark --to html5 "$content")"
    ROOT="$(dirname "$path/$dest" | sed -E 's/\/[^\/]+/\/../g')"

    export TITLE
    export CONTENT
    export ROOT
    envsubst \
      <"$site_template" \
      >"$path/$dest"

    echo "$(echo "$dest" | sed 's/index\.html$//')$RS$TITLE" >> "$path/sitemap"
  done <tmp
  rm tmp
}

# Generate page lists

{
  find . -type f -name sitemap >tmp
  while IFS= read -r list
  do
    path="$(dirname "$list")"

    if [ -f "$path/$dest" ]
    then
      dest=sitemap.html
    else
      dest=index.html
    fi

    if [ -f "$path/.title" ]
    then
      things="$(cat "$path/.title")"
    else
      things=Things
    fi

    TITLE="Nobody Uses these $things"
    CONTENT="<ul>$(sort -r "$list" | awk -F "$RS" 'NF { print("<li><a href=\"./"$1"\">"$2"</a></li>") }')</ul>"
    ROOT="$(dirname "$path/$dest" | sed -E 's/\/[^\/]+/\/../g')"

    export TITLE
    export CONTENT
    export ROOT
    envsubst \
      <"$site_template" \
      >"$path/$dest"

    rm "$list"
  done <tmp
  rm tmp
}
