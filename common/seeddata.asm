; Randomizer seed data
rando_seed_data:
    ; $00-$15 - rom name
    ; obsolete: as of archipelago 0.3.0, archipelago uses the ROM title to read and write this data instead of here (same length of 0x15).
    ; however, pre-0.3.0 clients may still read here, so it's kept around a little longer as a copy of the ROM title for backwards compatibility.
    dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
    dw $0000, $0000
    db $00
