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
    date="$(expr "$TITLE" : '\([[:digit:]]*-[[:digit:]]*-[[:digit:]]*\)')"

    if [ -n "$date" ]
    then
      TITLE="$date $(echo "$TITLE" | cut -d '-' -f 4- | sed 's/-/ /g')"
    else
      TITLE="$(echo "$TITLE" | sed 's/-/ /g')"
    fi

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
    dest=index.html

    if [ -f "$path/$dest" ]
    then
      dest=sitemap.html
    fi

    if [ "$path" = '.' ]
    then
      TITLE="Sitemap"
    else
      TITLE="Category: $(basename "$path" | tr '-' ' ' )"
    fi

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
