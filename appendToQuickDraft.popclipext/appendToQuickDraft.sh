#!/bin/bash
# #popclip
# name: appendToQuickDraft

word="$POPCLIP_TEXT"

open "quick-draft://x-callback-url/append?text=$POPCLIP_TEXT"

exit 0

