# Insert metadata into MOOD GeoNetwork

Insert metadata into [geonetwork](https://geonetwork.mood-h2020.eu/geonetwork/) of MOOD

## Goals and overview 
The aim of this project is to :

1. Parse data from [the XLS shared](https://docs.google.com/spreadsheets/d/1_P01ZPObmbhMymaVDM547Rr2RIrw-gGX/edit#gid=699786557)
2. Create a metadata file 
3. Upload it trough GeoNetwork API to MOOD GeoNetwork [application](https://geonetwork.mood-h2020.eu/geonetwork/)

## Manual actions
The XLS file shared has to be formatted to make it easy to parse it. Here are the actions:

1. Export a csv file
2. Remove the 3 first rows (header)
3. Add **n**, and **UUID** Columns
4. Remove datasets already harvested through CSW (Mundialis and ERGO)
