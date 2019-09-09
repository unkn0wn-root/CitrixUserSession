# ICA User class
# Methods will be added in new version
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