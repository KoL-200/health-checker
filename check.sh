#!/usr/bin/env bash

LIST="$HOME/health-checker/urls.txt"
LOG="$HOME/health-checker/health.log"
STATE="$HOME/health-checker/state"
SLOW=10
THRESHOLD=3

mkdir -p "$STATE"

while read -r URL; do
  [ -z "$URL" ] && continue

  KEY=$(echo -n "$URL" | md5sum | cut -d' ' -f1)
  FILE="$STATE/$KEY"
  FAILS=$(cat "$FILE" 2>/dev/null || echo 0)

  OUT=$(curl -s -A "Mozilla/5.0" -o /dev/null --max-time 10 -w "%{http_code} %{time_total}" "$URL")
  read CODE TIME <<< "$OUT"

  if [[ "$CODE" =~ ^[23] ]]; then
    if [ "$FAILS" -ge "$THRESHOLD" ]; then
      echo "$(date): RECOVERED $URL" >> "$LOG"
      termux-notification --title "Site recovered" --content "$URL is back up"
    fi
    echo 0 > "$FILE"

    if awk -v t="$TIME" -v s="$SLOW" 'BEGIN{exit !(t>s)}'; then
      echo "$(date): SLOW $URL (${TIME}s)" >> "$LOG"
    else
      echo "$(date): OK $URL (${TIME}s)" >> "$LOG"
    fi
  else
    FAILS=$((FAILS + 1))
    echo "$FAILS" > "$FILE"
    echo "$(date): FAIL $FAILS/$THRESHOLD $URL (status $CODE)" >> "$LOG"

    if [ "$FAILS" -eq "$THRESHOLD" ]; then
      termux-notification --title "Site down" --content "$URL failed $THRESHOLD checks in a row (status $CODE)"
    fi
  fi
done < "$LIST"
