# Citrix User Session Module
Get all user sessions from Citrix Apps and Desktops all query just one user.<p>

.DESCRIPTION</p>
    This function query either specific Citrix Session (user) or server and gets information about users sessions such as:</p>
    Username</p>
    ICARTT</p>
    ClientIP</p>
    SessionID</p>
    Network Latency</p>
    Screen resolution</p>
.EXAMPLE</p>
    &emsp;PS C:\> Get-CitrixUserSession -Identity dave</p>
    &emsp;Finds Daves session and then query specific server to gather information about Daves session</p>
.EXAMPLE</p>
    &emsp;PS C:\> Get-CitrixUserSession -ComputerName XenApp01</p>
    &emsp;Displays all users sessions information</p>
.EXAMPLE</p>
    &emsp;PS C:\> Get-CitrixUserSession -ComputerName XenApp01 -RemovePSSession</p>
    &emsp;Displays all users sessions information and removes PSSession 
    
    Ver. 1.2
