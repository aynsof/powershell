function Get-VmByMacAddress {
  <#
  .SYNOPSIS
    Retrieves the virtual machines with a certain MAC address on a vSphere server.
     
  .DESCRIPTION
    Retrieves the virtual machines with a certain MAC address on a vSphere server.
     
  .PARAMETER MacAddress
    Specify the MAC address of the virtual machines to search for.
     
  .EXAMPLE
    Get-VmByMacAddress -MacAddress 00:0c:29:1d:5c:ec,00:0c:29:af:41:5c
    Retrieves the virtual machines with MAC addresses 00:0c:29:1d:5c:ec and 00:0c:29:af:41:5c.
     
  .EXAMPLE
    "00:0c:29:1d:5c:ec","00:0c:29:af:41:5c" | Get-VmByMacAddress
    Retrieves the virtual machines with MAC addresses 00:0c:29:1d:5c:ec and 00:0c:29:af:41:5c.
     
  .COMPONENT
    VMware vSphere PowerCLI
     
  .NOTES
    Author:  Robert van den Nieuwendijk
    Date:    18-07-2011
    Version: 1.0
  #>
   
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               ValueFromPipelineByPropertyName = $true)]
    [string[]] $MacAddress
  )
   
  begin {
    # $Regex contains the regular expression of a valid MAC address
    $Regex = "^[0-9A-Fa-f][0-9A-Fa-f]:[0-9A-Fa-f][0-9A-Fa-f]:[0-9A-Fa-f][0-9A-Fa-f]:[0-9A-Fa-f][0-9A-Fa-f]:[0-9A-Fa-f][0-9A-Fa-f]:[0-9A-Fa-f][0-9A-Fa-f]$" 
   
    # Get all the virtual machines
    $VMsView = Get-View -ViewType VirtualMachine -Property Name,Guest.Net
  }
   
  process {
    ForEach ($Mac in $MacAddress) {
      # Check if the MAC Address has a valid format
      if ($Mac -notmatch $Regex) {
        Write-Error "$Mac is not a valid MAC address. The MAC address should be in the format 99:99:99:99:99:99."
      }
      else {    
        # Get all the virtual machines
        $VMsView | `
          ForEach-Object {
            $VMview = $_
            $VMView.Guest.Net | Where-Object {
              # Filter the virtual machines on Mac address
              $_.MacAddress -eq $Mac
            } | `
              Select-Object -property @{N="VM";E={$VMView.Name}},
                MacAddress,
                IpAddress,
                Connected
          }
      }
    }
  }
}