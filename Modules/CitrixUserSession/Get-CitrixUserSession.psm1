<#
.SYNOPSIS
    Get information about Citrix Sessions
.DESCRIPTION
    This function query either specific Citrix Session (user) or server and gets information about users sessions such as:
    Username
    ICARTT
    ClientIP
    SessionID
    Network Latency
    Screen resolution
.EXAMPLE
    PS C:\> Get-CitrixUserSession -Identity dave
    Finds Daves session and then query specific server to gather information about Daves session
.EXAMPLE
    PS C:\> Get-CitrixUserSession -ComputerName XenApp01
    Displays all users sessions information
.EXAMPLE
    PS C:\> Get-CitrixUserSession -ComputerName XenApp01 -RemovePSSession
    Displays all users sessions information and removes PSSession
    Note that switch removes PSSession if you do not have Citrix PSSnapIn installed on your PC/server
    It then connects to Citrix Delivery Controller and imports missing dependencies
    Use -RemovePSSession if you want to cleanup after execution 
.NOTES
    Author: David0
    Twitter: davido_shell
#>
#Requires -Version 5.0
#Requires -RunAsAdministrator

using namespace System.Collections.Generic
using namespace System.IO

#region ICAUser class
# ICAUser class initializing...
class ICAUser {
    [string]$CitrixUser
    [ipaddress]$ClientIP
    [string]$ClientName
    [string]$SessionState
    [int]$UserSessionID
    [int]$ICARTT
    [int]$NetworkLatency
    [int]$Hres
    [int]$Vres

    ICAUser(){
        $this.CitrixUser
        $this.ClientIP
        $this.ClientName
        $this.SessionState
        $this.UserSessionID
        $this.ICARTT
        $this.NetworkLatency
        $this.Hres
        $this.Vres
    }

    ICAUser([string]$CitrixUser, [ipaddress]$ClientIP, [int]$UserSessionID, [int]$ICARTT, [int]$NetworkLatency, [int]$Hres, [int]$Vres){
        $this.CitrixUser = $CitrixUser
        $this.ClientIP = $ClientIP
        $this.UserSessionID = $UserSessionID
        $this.ICARTT = $ICARTT
        $this.NetworkLatency = $NetworkLatency 
        $this.Hres = $Hres
        $this.Vres = $Vres
    }
}
#endregion
function Get-CitrixUserSession {
    [CmdletBinding()]
    param (
        # Use if you want to display all users on specific Citrix Server
        [Parameter(
        Mandatory=$true,
        ParameterSetName = 'ComputerName',
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
        [Alias('comp')]
        [string[]]
        $ComputerName,

        # Use if you just want to display for specific users
        [Parameter(
        Mandatory = $true,
        ParameterSetName = 'User',
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
        [Alias('username')]
        [String[]]
        $Identity,

        # Removes PSSession
        [Parameter()]
        [switch]
        $RemovePSSession
    )
    begin {
        $SessionInfoList = [List[psobject]]::new()
        $MachineName = [List[psobject]]::new()

        [string]$LogFile = "$env:SystemDrive\Temp\CitrixUserInformation_Log.txt"
            if (-not(Test-Path -Path $LogFile)){
                [void]([File]::Create($LogFile))
            }
        if (!(Get-Variable 'ctxddc' -Scope Global -EA 'Ignore')) {
            Write-Host -ForegroundColor Black -BackgroundColor White "[INFO] Can't find any Citrix Deliver Controll information. Need more info..."
            [string]$global:ctxddc = Read-Host "Enter your Citrix Delivery Controller IP/hostname (e.g. CTXDDC001):"    # Citrix Delivery Controller Server
        }
        # Citrix.Broker.Admin Module needs to be loaded before you can proceed with function
        if ($null -eq (Get-Command -Name Get-BrokerSession -ea SilentlyContinue)) {
            try {
                [void](Add-PSSnapin Citrix.Broker.Admin.V2 -ErrorAction Stop)
            }
            catch {
                Write-Host -ForegroundColor White -BackgroundColor Red "[WARNING] Couldn't import Citrix.Broker.Admin.V2 from localhost..."
                "[$(Get-Date)] :: $($_.Exception.Message)" | Out-File $LogFile -Append
            }
        }
        # If adding snapin from localhost fails - trying using PS Remoting
        if ( ($null -eq (Get-Command -Name Get-BrokerSession -ea SilentlyContinue) ) ) {
            Write-Host -ForegroundColor Yellow -BackgroundColor Red "[WARNING] Will now try PS remoting to import Module from $ctxddc"
            try {
                $TempPSSession = New-PSSession -ComputerName $ctxddc -Name Temp-CTXPSSession -ea Stop
                if (-not($TempPSSession)){
                    Write-Error "[ERROR] It seems that you do not have access to $ctxddc. Module not loaded. Aborting..."
                    return
                }
                else{
                    Write-Host -ForegroundColor Black -BackgroundColor White '[INFO] Trying to use PSSession to load missing dependencies[...]'
                    [void](Invoke-Command -Session $TempPSSession -ScriptBlock { Add-PSSnapin Citrix.Broker.Admin.V2 } -ea Stop)
                    # Building splatting hashtable for Import-PSSession
                    $Param = @{
                        Session = $TempPSSession
                        AllowClobber = $true
                        Module = 'Citrix*'
                        CommandName = 'Get-BrokerSession'
                        ErrorAction = 'Stop'
                    }
                    [void](Import-Module (Import-PSSession @Param) -Global)
                }
            }
            catch {
                Write-Error "[ERROR] You either don't have access to $ctxddc or something went wrong. Check log "
                "[$(Get-Date)] :: $($_.Exception.Message)" | Out-File $LogFile -Append
                return
            }
        }
        
        # Only used if Identity is specified. Then it will try to find Server address
        if ($PSBoundParameters['Identity']){
            foreach ($User in $Identity){
                try{
                    if (!(Get-Variable 'domain' -Scope Global -EA 'Ignore')) {
                        Write-Host -ForegroundColor Black -BackgroundColor White "[INFO] Prepering one-time PowerShell session information..."
                        [string]$global:domain = Read-Host "Enter your domain name (e.g. local):"  # Example: domain (not fqdn)
                    }
                    $SessionServer = (Get-BrokerSession -AdminAddress $ctxddc -ea Stop -Filter "Username -eq '$domain\$User' -and Protocol -ne 'RDP'").DNSName
                    $SessionServer = $SessionServer.Substring(0, $SessionServer.IndexOf('.'))
                    $MachineName.Add($SessionServer)
                    $ComputerName = $MachineName
                }
                catch{
                    Write-Error "[ERROR] Couldn't query user. Check log file. Aborting..."
                    "[$(Get-Date)] :: $($_.Exception.Message)" | Out-File $LogFile -Append
                    return
                }
            }
        } 
    }

    process {
        foreach ($Server in $ComputerName){
            try {
                $CitrixSessions = Get-CimInstance -ComputerName $Server -Namespace root\Citrix\euem -Class Citrix_Euem_RoundTrip -ea Stop
                $SessionID = Invoke-Command -ComputerName $Server -ea Stop -ScriptBlock {
                Get-ChildItem "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Citrix\Ica\Session" -Exclude '0','CtxConnections','CtxSessions','RestartICA' 
                }
            }
            catch {
                Write-Error "[ERROR] Couldn't connect to $Server. Check log file for more information."
                "[$(Get-Date)] :: $($_.Exception.Message)" | Out-File $LogFile -Append
                return
            }
            foreach ($Session in $CitrixSessions) {
                if ($Session.SessionID -in $SessionID.PSChildName) {
                    $SessionParam = @{
                    ComputerName = $Server
                    ArgumentList = $Session
                    ErrorAction = 'Stop'
                    }
                    try {
                        # Getting ICA user session properties 
                        $User = Invoke-Command @SessionParam {
                        param ($RemoteVar) 
                        Get-ItemProperty "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Citrix\Ica\Session\$($RemoteVar.SessionID)\Connection"
                        }
                        # Build ICAUser object with all gathered information
                        $SessionInfo = [ICAUser]::new()
                        $SessionInfo.CitrixUser = $User.Username
                        $SessionInfo.ClientIP = $User.ConnectedViaIpAddress
                        $SessionInfo.ClientName = $User.ClientName
                        $SessionInfo.SessionState = if (($User.SessionState) -eq '2') { 'Active/Connected' } else { 'Disconnected' }
                        $SessionInfo.UserSessionID = $Session.SessionID
                        $SessionInfo.ICARTT = $Session.RoundtripTime
                        $SessionInfo.NetworkLatency = $Session.NetworkLatency
                        $SessionInfo.Hres = $User.HRes
                        $SessionInfo.Vres = $User.VRes
                        
                        # Adding foreach user to the List and later output it to the screen 
                        $SessionInfoList.Add($SessionInfo)
                    }
                    catch {
                        Write-Error "[ERROR] Invoke-Command failed! Check log file."
                        "[$(Get-Date)] :: $($_.Exception.Message)" | Out-File $LogFile -Append
                        return
                    }
                }
            }
        }
            if ($PSBoundParameters['Identity']) {
                foreach ($User in $Identity){
                    $SessionInfoList | 
                    Where-Object {$_.CitrixUser -eq $User} | 
                    Select-Object -Unique
                }
            }
            else {
                return $SessionInfoList
            }   
        }
    # Cleanup after PSSession. Removes PSSnapIn and Remote Session  
    end {
        if($RemovePSSession){
            Remove-PSSession -Session $TempPSSession -Confirm:$false
            Write-Host -ForegroundColor Black -BackgroundColor White '[INFO] Powershell session removed and all of imported modules/SnapIns'
        }
    }
}