# Get an API token
Request-FalconToken -ClientId '<YOUR_CLIENT_ID>' -ClientSecret '<YOUR_CLIENT_SECRET>' -Cloud eu-1

# Set the path of the archive
$fullPath="C:\Software\test.zip"
$fileNameSimple = (Get-Item $fullPath).Name

#Send zip archive to the Sandbox - Add sleep if needed
$archive=Send-FalconSampleArchive -IsConfidential $True -Name $fileNameSimple -Path $fullPath
$sha= $archive[0].sha256
Start-Sleep -Seconds 10

#Expand Archive - All files - Add sleep if needed
$extraction=Expand-FalconSampleArchive -ExtractAll $true -sha256 $sha
$id=$extraction[0].id
#Start-Sleep -Seconds 5


#Get list of files extracted - Add sleep if needed
$result=Get-FalconSampleExtraction -Id $id -FileList
#Start-Sleep -Seconds 2


#Loop based on number of files extracted
If ($result.Length –lt 1) {
    echo  $result[0].name
    New-FalconSubmission -EnvironmentId win10_x64 -SubmitName $result[0].name -Sha256 $result[0].sha256
}
Else {
    #Submit eachi file for analisis
    for ($i=0; $i -lt $result.Length; $i++) {
        echo  $result[$i].name
        New-FalconSubmission -EnvironmentId win10_x64 -SubmitName $result[$i].name -Sha256 $result[$i].sha256
    }
}
