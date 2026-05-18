#!/usr/bin/env bash

SERVICE="$1"

OK=0
CRITICAL=2
UNKNOWN=3

if [[ -z "$SERVICE" ]]; then
    echo "UNKNOWN - empty service name"
    exit $UNKNOWN
fi

# systemd check (primary method)
if command -v systemctl >/dev/null 2>&1; then
    /usr/bin/systemctl is-active --quiet "$SERVICE"
    RC=$?

    if [[ $RC -eq 0 ]]; then
        echo "OK - $SERVICE running"
        exit $OK
    fi

    if [[ $RC -eq 3 ]]; then
        echo "UNKNOWN - service $SERVICE not found"
        exit $UNKNOWN
    fi

    echo "CRITICAL - $SERVICE not running"
    exit $CRITICAL
fi

# fallback legacy service command
if command -v service >/dev/null 2>&1; then
    OUTPUT=$(service "$SERVICE" status 2>&1)

    if echo "$OUTPUT" | grep -qiE "running|active"; then
        echo "OK - $SERVICE running"
        exit $OK
    fi

    if echo "$OUTPUT" | grep -qiE "not found|unrecognized|unknown"; then
        echo "UNKNOWN - service $SERVICE not found"
        exit $UNKNOWN
    fi

    echo "CRITICAL - $SERVICE not running"
    exit $CRITICAL
fi

echo "UNKNOWN - no service manager available"
exit $UNKNOWN
