#!/bin/bash -

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/scripts/helpers.sh"

# Initialize files
main()
{
    # TODO Add error checking
    echo "0" > $DOWNLOAD_FILE 2>/dev/null
    echo "0" > $UPLOAD_FILE 2>/dev/null
}
main
