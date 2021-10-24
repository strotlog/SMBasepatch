@echo off
:: Remember to commit an updated build.sh as well if making changes

echo Building Super Metroid Randomizer

for /r %%f in (build*.py) do python %%f

cd resources
python create_dummies.py 00.sfc ff.sfc
asar --no-title-check --symbols=wla --symbols-path=..\build\multiworld.sym ..\src\main.asm 00.sfc
asar --no-title-check --symbols=wla --symbols-path=..\build\multiworld.sym ..\src\main.asm ff.sfc
python create_ips.py 00.sfc ff.sfc multiworld.ips
del 00.sfc ff.sfc

for %%f in (..\src\variapatches\ips\*.ips) do python merge_ips.py %%f multiworld.ips

copy multiworld.ips ..\build\basepatch.ips > NUL

cd ..
echo Done
