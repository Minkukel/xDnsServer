﻿function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Zone,

        [parameter(Mandatory = $true)]
        [ValidateSet("ARecord", "CName")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [System.String]
        $Target
    )

    Write-Verbose "Looking up DNS record for $Name in $Zone"
    $record = Get-DnsServerResourceRecord -ZoneName $Zone -Name $Name -ErrorAction SilentlyContinue
    
    if ($record -eq $null) 
    {
        return @{}
    }
    if ($Type -eq "CName") 
    {
        $Recorddata = ($record.RecordData.hostnamealias).TrimEnd('.')
    }
    else
    {
        $Recorddata = $record.RecordData.IPv4address.IPAddressToString
    }

    return @{
        Name = $record.HostName
        Zone = $Zone
        Target = $Recorddata
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Zone,

        [parameter(Mandatory = $true)]
        [ValidateSet("ARecord", "CName")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [System.String]
        $Target
    )

    $DNSParameters = @{Name=$Name; ZoneName=$Zone} 

    if ($Type -eq "ARecord")
    {
        $DNSParameters.Add('A',$true)
        $DNSParameters.Add('IPv4Address',$target)
    }
    if ($Type -eq "CName")
    {
        $DNSParameters.Add('CName',$true)
        $DNSParameters.Add('HostNameAlias',$Target)
    }

    Write-Verbose "Creating $Type for DNS $Target in $Zone"
    Add-DnsServerResourceRecord @DNSParameters
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Zone,

        [parameter(Mandatory = $true)]
        [ValidateSet("ARecord", "CName")]
        [System.String]
        $Type,

        [parameter(Mandatory = $true)]
        [System.String]
        $Target
    )

    Write-Verbose "Testing for DNS $Name in $Zone"
    $result = @(Get-TargetResource -Name $Name -Zone $Zone -Target $Target -Type $Type)

    if ($result.Count -eq 0) {return  $false} 
    else {
        if ($result.Target -ne $Target) { return $false }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

