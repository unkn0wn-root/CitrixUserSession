    class Logger {
        [datetime]$CreateTime
        [string]$Name 
        [string]$Path
        hidden [string]$FullPath
        
        Logger(){}

        [Logger]Create([string]$Path,[string]$Name) {
            $LogFile = New-Item -Path $Path -Name $Name -ItemType File -Force
            $this.CreateTime = $LogFile.LastWriteTime
            $this.Name = $LogFile.Name
            $this.Path = $LogFile.DirectoryName
            $this.FullPath = $LogFile.DirectoryName + '\' + $LogFile.Name
            return $this
        }
        static [void]Add([string]$Path,[string]$Message) {
            Add-Content -Path $Path -Value "[$(Get-Date)] :: $Message"
        }
    }