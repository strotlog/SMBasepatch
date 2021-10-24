#!/usr/bin/env bash
# Remember to commit an updated build.bat as well if making changes

echo Building Super Metroid Randomizer

find . -name build.py -exec python3 {} \;

cd resources
python3 create_dummies.py 00.sfc ff.sfc
./asar --no-title-check --symbols=wla --symbols-path=../build/multiworld.sym ../src/main.asm 00.sfc
./asar --no-title-check --symbols=wla --symbols-path=../build/multiworld.sym ../src/main.asm ff.sfc
python3 create_ips.py 00.sfc ff.sfc multiworld.ips
rm 00.sfc ff.sfc

for f in ../src/variapatches/ips/*.ips; do python3 merge_ips.py $f multiworld.ips; done

cp multiworld.ips ../build/basepatch.ips > /dev/null

cd ..
echo Done
