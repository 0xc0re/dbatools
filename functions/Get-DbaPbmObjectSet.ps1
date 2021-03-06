﻿function Get-DbaPbmObjectSet {
    <#
    .SYNOPSIS
    Returns object sets from policy based management.

    .DESCRIPTION
    Returns object sets from policy based management.

    .PARAMETER SqlInstance
    SQL Server name or SMO object representing the SQL Server to connect to. This can be a collection and receive pipeline input to allow the function to be executed against multiple SQL Server instances.

    .PARAMETER SqlCredential
    Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER ObjectSet
    Filters results to only show specific object set
    
    .PARAMETER IncludeSystemObject
    By default system objects are filtered out. Use this parameter to include them.

    .PARAMETER InputObject
    Allows piping from Get-DbaPbmStore
    
    .PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
    Tags: Policy, PoilcyBasedManagement, PBM
    Author: Chrissy LeMaire (@cl), netnerds.net
    Website: https://dbatools.io
    Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
    License: MIT https://opensource.org/licenses/MIT

    .LINK
    https://dbatools.io/Get-DbaPbmObjectSet

    .EXAMPLE
    Get-DbaPbmObjectSet -SqlInstance sql2016

    Returns all object sets from the sql2016 PBM instance

    .EXAMPLE
    Get-DbaPbmObjectSet -SqlInstance sql2016 -SqlCredential $cred

    Uses a credential $cred to connect and return all object sets from the sql2016 PBM instance
#>
    [CmdletBinding()]
    param (
        [Alias("ServerInstance", "SqlServer")]
        [DbaInstanceParameter[]]$SqlInstance,
        [Alias("Credential")]
        [PSCredential]$SqlCredential,
        [string[]]$ObjectSet,
        [Parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Dmf.PolicyStore[]]$InputObject,
        [switch]$IncludeSystemObject,
        [switch]$EnableException
    )
    process {
        foreach ($instance in $SqlInstance) {
            Write-Message -Level Verbose -Message "Connecting to $instance"
            $InputObject += Get-DbaPbmStore -SqlInstance $instance -SqlCredential $SqlCredential
        }
        foreach ($store in $InputObject) {
            $all = $store.ObjectSets
            
            if (-not $IncludeSystemObject) {
                $all = $all | Where-Object IsSystemObject -eq $false
            }
            
            if ($ObjectSet) {
                $all = $all | Where-Object Name -in $ObjectSet
            }
                        
            foreach ($currentset in $all) {
                Write-Message -Level Verbose -Message "Processing $currentset"
                Add-Member -Force -InputObject $currentset -MemberType NoteProperty ComputerName -value $store.ComputerName
                Add-Member -Force -InputObject $currentset -MemberType NoteProperty InstanceName -value $store.InstanceName
                Add-Member -Force -InputObject $currentset -MemberType NoteProperty SqlInstance -value $store.SqlInstance
                Select-DefaultView -InputObject $currentset -Property ComputerName, InstanceName, SqlInstance, Id, Name, Facet, TargetSets, IsSystemObject
            }
        }
    }
}