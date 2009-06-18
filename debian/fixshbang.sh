#!/bin/sh -e

top=$1
ruby=$2

cd $top
for f in usr/bin/*
do
  sed -e 's|^#!.*ruby|#!'$ruby'|' < $f > $f.new && mv $f.new $f
  chmod 755 $f
done

