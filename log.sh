#!/bin/bash
if [[ $(hostname) -eq "meta" ]]; then
  echo "on meta"
  echo "**** $@" >> ~/Dropbox/docs/org/work-journal.org
else
  echo "not on meta"
  ssh mymeta log.sh "$@"
fi
