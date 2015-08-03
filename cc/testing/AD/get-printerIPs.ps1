$Printservers = "ccnxprnt-prod01"



# Get printer information
ForEach ($Printserver in $Printservers)
{   $Printers = Get-WmiObject Win32_Printer -ComputerName $Printserver
    ForEach ($Printer in $Printers)
    {
        if ($Printer.Name -notlike "Microsoft XPS*")
        {
            #$Sheet.Cells.Item($intRow, 1) = $Printserver
            #$Sheet.Cells.Item($intRow, 2) = $Printer.Name
            #$Sheet.Cells.Item($intRow, 3) = $Printer.Location
            
            If ($Printer.PortName -notlike "*\*")
            {   $Ports = Get-WmiObject Win32_TcpIpPrinterPort -Filter "name = '$($Printer.Portname)'" -ComputerName $Printserver
                ForEach ($Port in $Ports)
                {
                    #$Sheet.Cells.Item($intRow, 4) = $Port.HostAddress
                    write-host $printer.name "," $port.hostaddress
                }
            }
        }
    }
}