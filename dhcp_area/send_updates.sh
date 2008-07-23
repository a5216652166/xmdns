#!/bin/bash

export diff=`svn diff | wc | awk '{print $1}'`

## write a dhcp update mechanism ...

