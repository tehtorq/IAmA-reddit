#!/bin/bash
rm *.ipk
palm-package --use-v1-format release/
palm-install *.ipk
palm-launch com.tehtorq.reddit-hb

