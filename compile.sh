#!/bin/bash
rm release/app/models/*
coffee -b -o release/ -c coffee/
