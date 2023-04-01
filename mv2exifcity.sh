#!/bin/bash

# Intro and licensing
if [ $# -eq 0 ]; then
  echo "This script will prepend the names of cities where the shoots were taken to the filenames of JPEG files provided as arguments. It makes use of reverse geocoding via OpenStreetMap Nominatim."
  echo "https://github.com/eugrus/photonomennovum";
  echo "The following terms apply: https://creativecommons.org/licenses/by-nc-sa/3.0/de/deed.en"; echo ""
  exit 1
fi

# Check for dependencies
tools=(curl exiftool jq sed)
missing=()
for tool in "${tools[@]}"; do
  command -v $tool > /dev/null || missing+=($tool)
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "To run this script install the following missing tools: ${missing[@]}"
  exit 1
fi

# Loop through files provided as arguments to the script
for file in "$@"; do
	
    # Check if the file is a JPEG
    if file --mime-type "$file" | grep -q jpeg; then
    
        echo Processing "$file"	

        # Extract, parse and print the geographic coordinates from the JPEG
        lat=$(exiftool -n -gpslatitude "$file" | sed -e 's/^GPS Latitude\s*:\s*//g')
        echo Latitude: "$lat"
        lon=$(exiftool -n -gpslongitude "$file" | sed -e 's/^GPS Longitude\s*:\s*//g')
        echo Longitude: "$lon"

        # If the geo-coordinates are present, use them to find the city
        if [ -n "$lat" ]; then
        
            # Use the OpenStreetMap Nominatim API to reverse geocode: https://nominatim.org/release-docs/latest/api/Reverse/
            url="https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lon}"
            city=$(curl -s "$url" | jq -r '.address.city')

            # If a city was found, rename the file with the city name prepended to the original name
            if [ -n "$city" ]; then
                echo The city is "$city"
		newname="${city} ${file}"
                mv "$file" "$newname"
                echo "Renamed $file to $newname"
            else
                echo "Skipping $file as no city was found for its geo-coordinates"
	    fi
            else
                echo "Skipping $file as no geo-coordinates are present"
	fi
    else
        echo "Skipping "$file" as it is not a JPEG file"
    fi
done
