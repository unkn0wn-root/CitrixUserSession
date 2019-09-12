# Citrix User Session Module
Get all user sessions from Citrix Apps and Desktops all query just one user.

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
    
    Ver. 1.2
