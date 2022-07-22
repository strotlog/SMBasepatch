#!/usr/bin/env bash

if [ -z "$ASAR" ]; then
    ASAR=$(which asar)
fi
if [ -z "$ASAR" ] || [ ! -f "$ASAR" ]; then
    echo Error: asar is required, please add it to PATH or set env var ASAR pointing to the executable >&2
    exit 1
fi
ASAR=$(realpath $ASAR) # in case it has a relative path
ROOTDIR=$(realpath .)

if python3 --version >/dev/null 2>/dev/null; then
    PYTHON=python3
else
    if ! python -c "import sys; assert sys.version_info[0] > 2" 2>/dev/null; then
        echo Error: Python 3 is not installed >&2
        exit 1
    fi
    PYTHON=python
fi

for f in variapatches/*.asm; do
    basename="$(basename $f .asm)"
    if [ ! -f variapatches/ips/$basename.ips ]; then
        echo WARNING: $f does not have a corresponding ips file in variapatches/ips !
    fi
done

echo Building Super Metroid Multiworld Basepatch

for subdir in $(ls -d vanilla romhacks/*); do

    mkdir -p build/$subdir
    $PYTHON resources/create_dummies.py build/00.sfc build/ff.sfc
    pushd $ROOTDIR/$subdir > /dev/null
    $ASAR --no-title-check --symbols=wla --symbols-path=$ROOTDIR/build/$subdir/multiworld.sym main.asm $ROOTDIR/build/00.sfc
    $ASAR --no-title-check --symbols=wla --symbols-path=$ROOTDIR/build/$subdir/multiworld.sym main.asm $ROOTDIR/build/ff.sfc
    if [[ $? != 0 ]]; then
        popd > /dev/null
        exit 1
    fi
    popd > /dev/null
    $PYTHON resources/create_ips.py build/00.sfc build/ff.sfc build/$subdir/multiworld-basepatch.ips
    echo Built: build/$subdir/multiworld-basepatch.ips
    rm build/00.sfc build/ff.sfc

    $PYTHON resources/sym2json.py build/$subdir/multiworld.sym common/*.asm > build/$subdir/sm-basepatch-symbols.json

    if [ -f $subdir/variapatches.includelist ]; then

        # start with an empty patch and then merge all variapatches into it
        echo -ne "PATCHEOF" > build/$subdir/variapatches.ips
        for ipsref in $(cat $subdir/variapatches.includelist | grep -v "^#" | grep -v "^\/\/" | grep -v "^;"); do
            if [ ! -f variapatches/ips/$ipsref ]; then
                echo Error: $ipsref referenced in $subdir/variapatches.includelist: file not found at variapatches/ips/$ipsref
                exit 1
            fi
            ipsfile="variapatches/ips/$ipsref"
            basename="$(basename $ipsfile .ips)"
            if [ ! -f variapatches/$basename.asm ]; then
                echo WARNING: $ipsfile does not have a corresponding asm file in variapatches !
            else
                if [ variapatches/$basename.asm -nt $ipsfile ]; then
                    echo WARNING: $ipsfile is older than variapatches/$basename.asm . Possible old ips patch that needs to be re-compiled - re-compiling is manual and may require xkas-plus.
                fi
            fi
            echo -n " "
            $PYTHON resources/merge_ips.py $ipsfile build/$subdir/variapatches.ips
        done
        echo "Merged: build/$subdir/variapatches.ips"
    fi

done

echo
echo Done
