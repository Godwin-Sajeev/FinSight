#!/bin/sh

# Sanitization Script: Replace "Abhinav" with "Godwin Sajeev"

git filter-branch --force --env-filter '
    CORRECT_NAME="Godwin Sajeev"
    CORRECT_EMAIL="godwin.sajeev@example.com"
    if [ "$GIT_COMMITTER_NAME" = "Abhinav" ] || [ "$GIT_COMMITTER_NAME" = "ABHINAV" ]
    then
        export GIT_COMMITTER_NAME="$CORRECT_NAME"
        export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
    fi
    if [ "$GIT_AUTHOR_NAME" = "Abhinav" ] || [ "$GIT_AUTHOR_NAME" = "ABHINAV" ]
    then
        export GIT_AUTHOR_NAME="$CORRECT_NAME"
        export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
    fi
' --msg-filter "sed 's/Abhinav/Godwin Sajeev/gI'" --tag-name-filter cat -- --branches --tags
