#Script Created by Brian Farrugia 2022 - Feel free to use and modify.
#The Script Uses the module SSH-POSH. Install-Module Posh-SSH
#Imports the server list from a text file with a column of just the hostname
#Attempts to connect to each server and saves the output in a CSV File 
$SSH_Creds = Get-Credential #SSH Credentials
$SSH_Hosts=Get-Content "C:\Temp\hosts.csv" # Source List
$OutFile="c:\Temp\hosts_output.csv" #Destination Path
#Creating an Object for Connection Failures
$NoSSH_Host=[pscustomobject]@{
              'Host'=""
              'Output'=""
              }

foreach ($SSH_Host in $SSH_Hosts){
#Check if the SSH Session has been established
TRY{

    $SSH_Session = New-SSHSession -ComputerName $SSH_Host -Credential $SSH_Creds -AcceptKey -ErrorAction Stop
    $SSH_SessionStream = New-SSHShellStream -SSHSession $SSH_Session -TerminalName tty

    } CATCH {
#Show Warning of Connection Fails and set connection variables as false
                Write-Warning -Message "Could not Connect to $SSH_Host"
                $SSH_Session = $false
                $SSH_SessionStream = $false
    }
#IF the connection was successful get version and save to csv
If ($SSH_Session) {
Write-Host "Connected to Host - $SSH_Host"
$SSH_OSVersion = Invoke-SSHCommand -SSHSession $SSH_Session -Command "if test -f /etc/centos-release ; then cat /etc/centos-release; else cat /etc/os-release | grep PRETTY_NAME= ; fi"
#Check if OS is Cents if not REmove extra text from output
if(!($SSH_OSVersion.Output -like "*CentOS*")){
$SSH_OSVersion.Output=$SSH_OSVersion.Output.split('"')[1]
}
$SSH_OSVersion | Select  Host,@{l="OSVersion";e={$_.Output -join " "}} | export-csv -Path $OutFile -force -Append -NoTypeInformation
$SSH_SessionStream.close()
$SSH_Session | Remove-SSHSession | Out-Null
}
#If connection was unsuccessful save the details to CSV
else
{
$NoSSH_Host.Host=$SSH_Host
$NoSSH_Host.Output="Could not Connect"
$NoSSH_Host| Select  Host,@{l="OSVersion";e={$_.Output -join " "}} | export-csv -Path $OutFile -force -Append -NoTypeInformation
}
}
