#!/usr/bin/env bash

LIST="$HOME/health-checker/urls.txt"
LOG="$HOME/health-checker/health.log"
SLOW=5

while read -r URL; do
  [ -z "$URL" ] && continue
  OUT=$(curl -s -A "Mozilla/5.0" -o /dev/null --max-time 10 -w "%{http_code} %{time_total}" "$URL")
  read CODE TIME <<< "$OUT"

  if [[ "$CODE" =~ ^[23] ]]; then
    if awk -v t="$TIME" -v s="$SLOW" 'BEGIN{exit !(t>s)}'; then
      echo "$(date): SLOW $URL (${TIME}s)" >> "$LOG"
      termux-notification --title "Site slow" --content "$URL took ${TIME}s"
    else
      echo "$(date): OK $URL (${TIME}s)" >> "$LOG"
    fi
  else
    echo "$(date): DOWN $URL (status $CODE)" >> "$LOG"
    termux-notification --title "Site down" --content "$URL returned $CODE"
  fi
done < "$LIST"
