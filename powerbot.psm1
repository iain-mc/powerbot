[System.Uri]$doomBaseUri = "http://192.168.56.101:6666/api/"
Export-ModuleMember -Variable doomBaseUri

[int]$restTimeout = 10
Export-ModuleMember -Variable restTimeout

function Move-Player
{
    #Function Patameters
    Param
    (
        [Parameter(Mandatory=$false)]
        [System.Uri]
        $BaseUri = $DoomBaseUri,
        
        [Parameter(Mandatory=$true, ParameterSetName="Move")]
        [validateSet("Forward","Backward", "StrafeL", "StrafeR")]
        [String]
        $Direction,

        [Parameter(Mandatory=$true, ParameterSetName="Move")]
        [Int]
        $Distance,

        [Parameter(Mandatory=$true, ParameterSetName="Turn")]
        [ValidateSet("Left","Right")]
        [String]
        $Turn,

        [Parameter(Mandatory=$true, ParameterSetName="Turn")]
        [ValidateRange(0,359)]
        [Int]
        $Angle
    )

    if($PSCmdlet.ParameterSetName -eq "Move")
    {
        $actions = @{"Forward" = "forward";
                    "Backward" = "backward";
                     "StrafeR" = "strafe-right";
                     "StrafeL" = "strafe-left"}
        $uri = New-Object System.Uri($baseUri, 'player/actions')
        $jsonBody = ConvertTo-Json @{"type" = "$($actions[$Direction])"; "amount" = $distance}
    }

    if($PSCmdlet.ParameterSetName -eq "Turn")
    {
        $uri = New-Object System.Uri($baseUri, 'player/turn') 
        $jsonBody = ConvertTo-Json @{"type" = "$($turn.ToLower())"; "target_angle" = $angle}    
    }

    Invoke-WebRequest -Uri $uri -Method Post -Body $jsonBody -TimeoutSec $restTimeout
}
Export-ModuleMember -Function move-player

function Shoot-Weapon
{
    Param 
    (
        [Parameter(Mandatory=$false)]
        [System.Uri]
        $BaseUri = $DoomBaseUri
    )

    $uri = New-Object System.Uri($baseUri, 'player/actions')
    Invoke-WebRequest -Uri $uri -Method Post -Body '{"type":"shoot"}' -TimeoutSec $restTimeout
}
Export-ModuleMember -Function Shoot-Weapon 

function Switch-Weapon 
{
    Param 
    (
        [Parameter(Mandatory=$false)]
        [System.Uri]
        $BaseUri = $DoomBaseUri,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -gt 0})]
        [int]
        $Weapon
    )

    $uri = New-Object System.Uri($baseUri, 'player/actions')
    $jsonBody = ConvertTo-Json @{"type" = "switch-weapon"; "amount" = $Weapon}        
    Invoke-WebRequest -Uri $uri -Method Post -Body $jsonBody -TimeoutSec $restTimeout
}
Export-ModuleMember -Function Switch-Weapon 

function Get-Player
{
    Param(
        [Parameter(Mandatory=$false)]
        [System.Uri]
        $BaseUri = $DoomBaseUri
    )

    $uri = New-Object System.Uri($BaseUri, 'player')
    $player = Invoke-WebRequest -Uri $uri -Method Get
    
    if($player.statuscode -like '2*')
    {
        return $player.content | ConvertFrom-Json
    }
}
Export-ModuleMember -Function Get-Player

function Update-Player
{
    Param(
        [Parameter(Mandatory=$false)]    
        [System.Uri]
        $BaseUri = $DoomBaseUri,
        
        [Parameter(Mandatory=$false)]
        [Int]
        $Kills,

        [Parameter(Mandatory=$false)]
        [Int]
        $Weapon,

        [Parameter(Mandatory=$false)]
        [Int]
        $Angle,
        
        [Parameter(Mandatory=$false)]
        [Int]
        $Health,

        [Parameter(Mandatory=$false)]
        [Int]
        $Armor,
        
        [Parameter(Mandatory=$false)]
        [Int]
        $Distance,

        [Parameter(Mandatory=$false)]
        [Int]
        $Items,

        [Parameter(Mandatory=$false)]
        [Int]
        $Attacking,

        [Parameter(Mandatory=$false)]
        [ValidateSet('red','YELLO', 'BLUE')]
        [String[]]
        $AddKeyCards,             

        [Parameter(Mandatory=$false)]
        [ValidateSet('CF_GODMODE','CF_NOCLIP')]
        [String[]]
        $AddCheatFlags,

        [Parameter(Mandatory=$false)]
        [ValidateSet('SPECIAL', 'SOLID', 'SHOOTABLE', 'NOGRAVITY', 'NOCLIP', 'SHADOW', 'CORPSE')]
        [String[]]
        $AddFlags,

        [Parameter(Mandatory=$false)]
        [ValidateSet('red','YELLO', 'BLUE')]
        [String[]]
        $RemoveKeyCards,             

        [Parameter(Mandatory=$false)]
        [ValidateSet('CF_GODMODE','CF_NOCLIP')]
        [String[]]
        $RemoveCheatFlags,

        [Parameter(Mandatory=$false)]
        [ValidateSet('MF_SPECIAL', 'MF_SOLID', 'SHOOTABLE', 'NOGRAVITY', 'NOCLIP', 'SHADOW', 'CORPSE')]
        [String[]]
        $RemoveFlags
    )

    $paramHash = @{}
    foreach($key in $PSBoundParameters.keys)
    {
        switch ($key) 
        {
            Kills       { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Weapon      { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Secrets     { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Type        { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Angle       { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Health      { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Armor       { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Distance    { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            Attacking   { $paramHash[$key.ToLower()] = $PSBoundParameters[$key] }
            AddKeyCards    { $paramHash['keyCards'] = @{}; $PSBoundParameters[$key] | %{$paramHash['keyCards'][$_]=1}}
            AddCheatFlags  { $paramHash['cheatFlags']  = @{}; $PSBoundParameters[$key] | %{$paramHash['cheatFlags'][$_]=1}}
            AddFlags       { $paramHash['flags'] = @{}; $PSBoundParameters[$key] | %{$paramHash['flags'][$_]=1}}
            RemoveKeyCards    { $paramHash['keyCards'] = @{}; $PSBoundParameters[$key] | %{$paramHash['keyCards'][$_]=0}}
            RemoveCheatFlags  { $paramHash['cheatFlags']  = @{}; $PSBoundParameters[$key] | %{$paramHash['cheatFlags'][$_]=0}}
            RemoveFlags       { $paramHash['flags'] = @{}; $PSBoundParameters[$key] | %{$paramHash['flags'][$_]=0}}
        }
    }
    
    $jsonBody = $paramHash | ConvertTo-Json
    $uri = New-Object System.Uri($BaseUri, 'player')
    $player = Invoke-WebRequest -Uri $uri -Method Patch -Body $jsonBody

    write-host $jsonBody
    if($player.statuscode -like '2*')
    {
        $player.content | ConvertFrom-Json
    }
    $jsonBody
}
Export-ModuleMember -Function Update-Player

function Get-World
{

    Param(
        [Parameter(Mandatory=$false)]    
        [System.Uri]
        $BaseUri = $DoomBaseUri
    )

    $uri = New-Object System.Uri($BaseUri, 'world')
    $world = Invoke-WebRequest -Uri $uri -Method Get   
    
    if($world.statuscode -like '2*')
    {
        return $world.content | ConvertFrom-Json
    }
}
Export-ModuleMember -Function Get-World