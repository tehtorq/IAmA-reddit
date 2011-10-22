#!/bin/bash
#rm release/app/models/* # for metrix
rm release/app/assistants/*
coffee -b -o release/ -c coffee/
