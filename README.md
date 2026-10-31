# luudi_korekortapp

Kørekort app til lb-phone (ESX).

## Installation

1. Installér **esx_license** (officiel ESX resource) og kør dens SQL.
2. Kør `install.sql` fra denne mappe.
3. I `server.cfg`, efter es_extended, ox_lib, oxmysql, esx_license, p_policejob og lb-phone:
   ```
   ensure luudi_korekortapp
   ```

## Udstede og fratage kørekort

p_policejob har allerede kommandoerne (kun admins):

```
/grantlicense [id] drive        -> kategori B
/grantlicense [id] drive_bike   -> kategori A
/grantlicense [id] drive_truck  -> kategori C
/revokelicense [id] drive
```

## Klip

Klip kommer fra p_policejob's strafpoint (bøder med point). Grænsen står i
`p_policejob/modules/tickets/config.lua` (`suspendThreshold = 12`). Hvis du ændrer den,
så ret også `Config.Points.threshold` i `config.lua` her.

## Deling

* **Send bevis til nærmeste politi**: sender direkte til den nærmeste betjent inden for 5 meter.
* **AirShare**: viser betjente inden for 10 meter. Betjenten skal acceptere.
* Betjente (job `police`) ser fanen **Modtaget** med de kort, de har fået.
