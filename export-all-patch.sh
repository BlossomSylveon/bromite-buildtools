#!/bin/bash

VERSION=$(cat ~/bromite/build/RELEASE)
CURRENT_RELEASE=$(git -C ~/chromium/src/ rev-parse --verify refs/tags/$VERSION)

ALLPATCHS_E=$(git -C ~/chromium/src/ rev-list HEAD...$CURRENT_RELEASE)

mkdir ~/bromite/build/patches-new

NO_NAME=1

for patch in $ALLPATCHS_E; do

	PATCH_FILE=$(git -C ~/chromium/src/ show -s $patch | grep FILE: | sed 's/FILE://g' | sed 's/^[ \t]*//;s/[ \t]*$//')
	if [[ "$PATCH_FILE" == *"Automated-domain-substitution"* ]]; then
		continue
	fi

	if [ -z "$PATCH_FILE" ]
	then
		PATCH_FILE=$(git -C ~/chromium/src/ show -s $patch | tail -n 1)
		if [[ "$PATCH_FILE" != *".patch" ]]; then
			PATCH_FILE=00$(git -C ~/chromium/src/ show -s $patch | head -n 5 | tail -n 1 | xargs | tr " " - | tr [:punct:] -).patch
			echo New Patch: ${PATCH_FILE}
		fi
	fi

	bash ~/bromite-buildtools/export-single-patch.sh $patch $PATCH_FILE

done

PATCH_LIST=~/bromite/build/bromite_patches_list.txt
mkdir ~/bromite/build/patches-new/changed
mkdir ~/bromite/build/patches-new/contrib
for current_file in $(cat $PATCH_LIST); do
	if [[ "$current_file" == *".patch" ]]; then
		if [[ $current_file =~ ^changed/.* ]]; then
			mv ~/bromite/build/patches-new/$(basename $current_file) ~/bromite/build/patches-new/changed
		elif [[ $current_file =~ ^contrib/.* ]]; then
			mv ~/bromite/build/patches-new/$(basename $current_file) ~/bromite/build/patches-new/contrib || true
		fi
	fi
done
