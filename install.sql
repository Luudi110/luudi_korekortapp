-- Køres EFTER at esx_license er installeret (esx_license laver selv tabellerne licenses og user_licenses).
-- Tilføjer kørekort typerne, så /grantlicense virker med dem.
INSERT IGNORE INTO `licenses` (`type`, `label`) VALUES
    ('drive', 'Kørekort B (bil)'),
    ('drive_bike', 'Kørekort A (motorcykel)'),
    ('drive_truck', 'Kørekort C (lastbil)');

-- Appens egen tabel oprettes automatisk ved start. Den gemmer kun kortnummer og udstedelsesdato.
