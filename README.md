# Citrix User Session Module
Get all user sessions from Citrix Apps and Desktops all query just one user.<p>

This module query either specific Cirix Session (user) or server and gets information about users sessions such as:
* Username
* ICARTT
* Client IP
* Session ID
* Network Latency
* Screen Resolution

.EXAMPLE

    PS C:\> Get-CitrixUserSession -identity dave
    
    Finds Daves session and then query specific server to gather information about Daves session
    
.EXAMPLE

    PS C:> Get-CitrixUserSession -ComputerName XenApp01
    
    Displays all users sessions
    
.EXAMPLE

    PS C:> Get-CitrixUserSession -ComputerName XenApp01 -RemovePSSession
    
    Displays all users sessions information and removes PSSession
    Note that switch -RemovePSSession, removes Powershell session. This is done by creating PSSession to an remote machine
    which has Citrix PSSnapIn installed or module which is required to run this module. Then this session is created on
    your local machine so using -RemovePSSession does remove Powershell session. You will be prompted if function cannot
    find Citrix Module/PSSnapIn on your local machine.
    
    Current version is: 1.4.1
