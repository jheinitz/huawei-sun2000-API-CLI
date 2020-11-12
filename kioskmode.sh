#!/bin/bash

# Tool for get data from Huawei FusionSolar https://eu5.fusionsolar.huawei.com Kiosk mode
# to made this tool usefully first u must login to FusionSolarApp with your username and password. 
# Open webpage and go to "Kiosk View" top right buttons near "Home Page" "Message" and "About"
# Inside "Kiosk View Settings" activate option "Whether to enable" and copy URL which is necessary
# to be pasted inside this script. Login and Password is not necessary to be used to get this data only
# individual URL for each power plant so this URL should be confidential. After swithing "Whether to 
# enable" On and Off and again On new URL is autogenerated so paste to scipt this new data after changing.

# You must have installed on your linux tools like jq, httpie, grep
# sudo apt-get install jq
# sudo apt-get install httpie
# sudo apt-get install grep


# Config
#----------------------
# Here paste URL from your Kiosk mode configuration "Kiosk View Settings" in FussionSolarApp
kiosk_mode_url= <--here data--> 

#data presentation on terminal screen
# true or false show data on screen is not necessary if you use this script automatically to collect data to other software periodically in automatic mode.
show_data_in_terminal=true

# export to InfluxDB data taken from Kiosk mode Cloud Service 
send_data_to_influxDB=false

# export to Domoticz data taken from Kiosk mode Cloud Service 
send_data_to_Domoticz=false

#----------------------





# extract token from url
token=`echo "$kiosk_mode_url" | grep -o 'kk=[[:digit:]].*'`
token=`echo "$token" | grep -o '[[:digit:]].*'`

# echo $token

echo -e "conecting to \e[4m"$kiosk_mode_url"\e[24m"

# Request to unofficial API checkKioskToken
checkKioskToken=$(printf '{"kk": "'$token'"}'| http --follow --timeout 3600 POST https://eu5.fusionsolar.huawei.com/kiosk/checkKioskToken Content-Type:'application/json')

createTime=( $(echo ''$checkKioskToken''  | jq '.data.createTime' ) )
id=( $(echo ''$checkKioskToken''  | jq '.data.id' ) )
language=( $(echo ''$checkKioskToken''  | jq '.data.language' ) )
logoFileId=( $(echo ''$checkKioskToken''  | jq '.data.logoFileId' ) )
permissons="( $(echo ''$checkKioskToken''  | jq '.data.permissons[]' ) )"
state=( $(echo ''$checkKioskToken''  | jq '.data.state' ) )
stationName="( $(echo ''$checkKioskToken''  | jq '.data.stationName' ) )"
title=( $(echo ''$checkKioskToken''  | jq '.data.title' ) )
token_of_the_station=( $(echo ''$checkKioskToken''  | jq '.data.token' ) )
updateTime=( $(echo ''$checkKioskToken''  | jq '.data.updateTime' ) )

# echo $checkKioskToken | jq
# echo $stationName

# show array with aviable panels array
# echo $checkKioskToken | jq '.data.permissons[]'
# 
# permissons=( $(echo $checkKioskToken | jq '.data.permissons[7]') )

# echo $permissons


# shorter time for read in unix cut -3 characters from unix date milisecounds are not necessary
createTime=$(echo ${createTime::-3})

# echo $createTime 
# create_data=$(date -d @$createTime)
# echo $create_data

# shorter time for read in unix cut -3 characters from unix date milisecounds are not necessary
updateTime=$(echo ${updateTime::-3})

# echo $updateTime
# update_data=$(date -d @$updateTime)
# echo $update_data







# Request to unofficial API getStationInfo
getStationInfo=$(printf '{"kk": "'$token'"}'| http --follow --timeout 3600 POST https://eu5.fusionsolar.huawei.com/kiosk/getStationInfo Content-Type:'application/json')

# echo $getStationInfo | jq

stationAddr="( $(echo ''$getStationInfo''  | jq ".data.stationAddr" ) )"
stationCode=( $(echo ''$getStationInfo''  | jq '.data.stationCode' ) )
# stationName=( $(echo ''$getStationInfo''  | jq '.data.stationName' ) )
stationPic=( $(echo ''$getStationInfo''  | jq '.data.stationPic' ) )
timeZone=( $(echo ''$getStationInfo''  | jq '.data.timeZone' ) )

# printf '%s\n' $stationAddr
# printf '%s\n' "$stationName"


# Request to unofficial API getRealTimeKpi
getRealTimeKpi=$(printf '{"kk": "'$token'"}'| http --follow --timeout 3600 POST https://eu5.fusionsolar.huawei.com/kiosk/getRealTimeKpi Content-Type:'application/json')

# echo $getRealTimeKpi | jq

curPower=( $(echo ''$getRealTimeKpi''  | jq '.data.curPower' ) ) # in Kw 
dailyCapacity=( $(echo ''$getRealTimeKpi''  | jq '.data.dailyCapacity' ) ) # in Kw/h 
monthCapacity=( $(echo ''$getRealTimeKpi''  | jq '.data.monthCapacity' ) ) # in Kw/h 
yearCapacity=( $(echo ''$getRealTimeKpi''  | jq '.data.yearCapacity' ) ) # in Mw/h 
allCapacity=( $(echo ''$getRealTimeKpi''  | jq '.data.allCapacity' ) ) # in Mw/h

# echo $allCapacity


# Request to unofficial API socialContribution
socialContribution=$(printf '{"kk": "'$token'"}'| http --follow --timeout 3600 POST https://eu5.fusionsolar.huawei.com/kiosk/socialContribution Content-Type:'application/json')

# echo $socialContribution | jq

forest=( $(echo ''$socialContribution''  | jq '.data.forest' ) ) # saved trees number
CO2=( $(echo ''$socialContribution''  | jq '.data.CO2' ) ) # tons
coal=( $(echo ''$socialContribution''  | jq '.data.coal' ) ) # tons

# echo $coal


# Request to unofficial API getPowers
getPowers=$(printf '{"kk": "'$token'"}'| http --follow --timeout 3600 POST https://eu5.fusionsolar.huawei.com/kiosk/getPowers Content-Type:'application/json')

# echo $getPowers | jq

#hours_with_minutes=( $(echo ''$getPowers''  | jq '.data.xData[]' ) )


hasInverter=( $(echo ''$getPowers''  | jq '.data.hasInverter' ) ) 
hasEnergyStore=( $(echo ''$getPowers''  | jq '.data.hasEnergyStore' ) ) 
hasMeter=( $(echo ''$getPowers''  | jq '.data.hasMeter' ) ) 
hasRadiationDose=( $(echo ''$getPowers''  | jq '.data.hasRadiationDose' ) ) 
hasUserPower=( $(echo ''$getPowers''  | jq '.data.hasUserPower' ) ) 
show15MData=( $(echo ''$getPowers''  | jq '.data.show15MData' ) )

# echo $hasInverter

echo ""
echo "Existing devices in this installation:"

	if [[ $hasInverter == true ]];

		then
		echo -e "[\e[32m+\e[0m] Inverter"
		# first data just a variable taken from JOSN
		inverterCaps=( $(echo ''$getPowers''  | jq '.data.inverterCaps' ) ) 
		
		# conversion from JOSN to bash array for hours with minutes
		count_hours_with_minutes=0

			for s in 1; do 
				hours_with_minutes_array+=( $(echo ''$getPowers''  | jq '.data.xData[]' | grep -o '[[:digit:]][[:digit:]]:[[:digit:]][[:digit:]]') )
				(( count_hours_with_minutes++ ))
			done

		# Print array of hours&minutes number of slots
		# echo ${#hours_with_minutes_array[@]}
		# Print array of hours&minutes 
		# printf '%s\n' "${hours_with_minutes_array[@]}"

		# conversion from JOSN to bash array for inverted power for every 5 minutes
		count_inverted_KW=0

			for s in 1; do 
				inverted_KW_array+=( $(echo ''$getPowers''  | jq '.data.inverterPowers[]' | grep -o '"*.*"') )
				(( count_inverted_KW++ ))
			done

		# Print array of inverted KW number of slots
 		# echo ${#inverted_KW_array[@]}
		# Print array of inverted KW
		# printf '%s\n' "${inverted_KW_array[@]}"
		
		else		
		echo -e "[\e[31m-\e[0m] Inverter"
	fi

	if [[ $hasEnergyStore == true ]];
	
		then
		 # don't know what exactly should be here has no energy store to test API response and how JOSN look's like if Energy storage exists so this is only estimation what variables are aviable based on response of instalation without energy storage
		echo -e "[\e[32m+\e[0m] Energy Storage"
		energyStoreInputCaps=( $(echo ''$getPowers''  | jq '.data.energyStoreInputCaps' ) )
		energyStoreInputPowers=( $(echo ''$getPowers''  | jq '.data.energyStoreInputPowers' ) ) 
		energyStoreOutputCaps=( $(echo ''$getPowers''  | jq '.data.energyStoreOutputCaps' ) ) 
		energyStoreOutputPowers=( $(echo ''$getPowers''  | jq '.data.energyStoreOutputPowers' ) ) 	 
		else		
		echo -e "[\e[31m-\e[0m] Energy Storage"
	fi
	
	if [[ $hasMeter == true ]];
	
		then
		 # don't know what exactly should be here has no meter to test API response and how JOSN look's like if meter exists so this is only estimation what variables are aviable based on response of instalation without this device
		echo -e "[\e[32m+\e[0m] Huawei Meter"
		meterInputCaps=( $(echo ''$getPowers''  | jq '.data.meterInputCaps' ) )
		meterInputPowers=( $(echo ''$getPowers''  | jq '.data.meterInputPowers' ) ) 
		meterOutputCaps=( $(echo ''$getPowers''  | jq '.data.meterOutputCaps' ) ) 
		meterOutputPowers=( $(echo ''$getPowers''  | jq '.data.meterOutputPowers' ) )  
		else		
		echo -e "[\e[31m-\e[0m] Huawei Meter"
	fi
	
	if [[ $hasRadiationDose == true ]];
	
		then
		 # don't know what exactly should be here has no Huawei Solar Radiation Dosimeter to test API response and how JOSN look's like if device exists so this is only estimation what variables are aviable based on response of instalation without this device
		echo -e "[\e[32m+\e[0m] Solar Radiation Dosimeter"
		radiationDosePowers=( $(echo ''$getPowers''  | jq '.data.radiationDosePowers' ) )
		else		
		echo -e "[\e[31m-\e[0m] Solar Radiation Dosimeter"
	fi
	
	if [[ $hasUserPower == true ]];
	
		then
		 # don't know what exactly should be here has no User Power Mesuring device to test API response and how JOSN look's like if device exists so this is only estimation what variables are aviable based on response of instalation without this device
		echo -e "[\e[32m+\e[0m] User Power Mesuring device"
		userPowers=( $(echo ''$getPowers''  | jq '.data.userPowers' ) )
		selfUserPowers=( $(echo ''$getPowers''  | jq '.data.selfUserPowers' ) )
		stationProuductAndUserPower=( $(echo ''$getPowers''  | jq '.data.stationProuductAndUserPower' ) )
		expendPowers=( $(echo ''$getPowers''  | jq '.data.expendPowers' ) )
		else		
		echo -e "[\e[31m-\e[0m] User Power Mesuring device"
	fi


# If variable in config is true show data from kiosk mode on terminal screen
if [[ $show_data_in_terminal == true ]];
	then
	
	# unofficial API checkKioskToken
	echo ""
	time_of_creation=$(date -d @$createTime)
	echo "time&date of Kiosk Mode switched on: "$time_of_creation
	time_of_update=$(date -d @$updateTime)	
	echo "time&date of last modification in Kiosk Mode: "$time_of_update
	echo ""
	echo "id: "$id
	echo "language: "$language
	echo "logo id: "$logoFileId
	echo "Active panels: "$permissons
	echo "state: "$state
	echo "station name: "$stationName
	echo "title: "$title
	echo "token of station: "$token_of_the_station	

	# unofficial API getStationInfo
	echo ""
	echo "station adress: "$stationAddr
	echo "station code: "$stationCode
	echo "station picture id: "$stationPic
	echo "timezone code: "$timeZone
	
	# unofficial API getRealTimeKpi
	echo ""
	echo -e "current power: \e[93m"$curPower"Kw\e[0m" 
	echo -e "daily capacity: \e[93m"$dailyCapacity"Kw/h\e[0m" 
	echo -e "monthly capacity: \e[93m"$monthCapacity"Kw/h\e[0m" 
	echo -e "yearly capacity: \e[93m"$yearCapacity"Mw/h\e[0m" 
	echo -e "all capacity: \e[93m"$allCapacity"Mw/h\e[0m"
	
	# unofficial API socialContribution
	echo ""
	echo -e "\e[32mtrees saved: "$forest" trees\e[0m"
	echo -e "\e[94msaved CO2: "$CO2"t\e[0m"
	echo -e "\e[90msaved coal: "$coal"t\e[0m"
	
	echo ""
	echo "Today Power Production"
	echo ""

	# diplay today power production every 5 minutes 
	count_evry_5_minutes=0
	for s in "${hours_with_minutes_array[@]}"; do 
	
		echo ${hours_with_minutes_array[$count_evry_5_minutes]} ${inverted_KW_array[$count_evry_5_minutes]}										
		(( count_evry_5_minutes++ ))
	done

	
	else
	echo ""
	echo "Data presentation in terminal is off"
fi
