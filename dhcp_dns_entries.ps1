# 
# Ugly little PS to faciliate the creation of DHCP DNS entries
#

$zone_name = "domain.local"
$prefix = "172.16"
$vlans = 1..10
$ip_range = 10..250
$items = @{name = "gw"; octet3 = 1},
         @{name = "vrrp1"; octet3 = 2},
         @{name = "vrrp2"; octet3 = 3},
         @{name = "dhcp"; octet3 = 4}

ForEach ($vlan in $vlans)
{
    Write-Host "`nProcessing VLAN $vlan..."
    ForEach ($item in $items)
    {
        $hostname = "$($item.name).v$vlan"
        $octet3 = $item.octet3
        $fqdn = "$hostname.$zone_name"
        $ip = "$prefix.$vlan.$octet3"
        $octets = $ip.split('.')
        $octet0 = $octets[0]
        $octet1 = $octets[1]
        $octet2 = $octets[2]
        $octet3 = $octets[3]
        $ptr_zone = "$octet2.$octet1.$octet0.in-addr.arpa"

        Write-Host "Checking DNS for A record: $fqdn"     
        Try
        {
            $record = Get-DnsServerResourceRecord -Name $hostname -ZoneName $zone_name -RRType A -ErrorAction Stop
            $record_ip = $record[0].RecordData.IPv4Address.IPAddressToString

            If ($record_ip -eq $ip)
            {
                Write-Debug "Record matches expected IP: $ip"
            }
            Else
            {
                Write-Warning "Record did not match expected IP: $ip (was $record_ip)"
            }
        }
        Catch [Microsoft.Management.Infrastructure.CimException]
        {
            Write-Host "Adding DNS A record for $fqdn with IP $ip"
            Try
            {
                Add-DnsServerResourceRecordA -Name $hostname -ZoneName $zone_name -IPv4Address $ip -ErrorAction Stop
            }
            Catch [Microsoft.Management.Infrastructure.CimException]
            {
                Write-Warning $_.Exception.Message
            }
        }
        
        Write-Host "Checking DNS for PTR record: $ip"     
        Try
        {
            $record = Get-DnsServerResourceRecord -Name $octet3 -ZoneName $ptr_zone -RRType ptr -ErrorAction Stop
            $record_name = $record[0].RecordData.PtrDomainName
     
            If ($record_name -eq $fqdn + '.')
            {
                Write-Debug "Record matches expected hostname: $fqdn"
            }
            Else
            {
                Write-Warning "Record did not match expected IP: $fqdn (was $record_name)"
            }
        }
        Catch [Microsoft.Management.Infrastructure.CimException]
        {
            Write-Host "Adding DNS PTR record for IP $ip with hostname $fqdn"
            Try
            {
                Add-DnsServerResourceRecordPtr -Name $octet3 -ZoneName $ptr_zone -PtrDomainName $fqdn
            }
            Catch [Microsoft.Management.Infrastructure.CimException]
            {
                Write-Warning $_.Exception.Message
            }
        }
    }

    ForEach ($octet3 in $ip_range)
    {
        $octets = $prefix.split('.')
        $octet0 = $octets[0]
        $octet1 = $octets[1]
        $octet2 = $vlan
        $ip = "$octet0.$octet1.$octet2.$octet3"
        $hostnb = "{0:000}" -f $octet3
        $hostname = "dhcp-$hostnb.v$i"
        $fqdn = "$hostname.$zone_name"

        Write-Host "Checking DNS for A record: $fqdn"     
        Try
        {
            $record = Get-DnsServerResourceRecord -Name $hostname -ZoneName $zone_name -RRType A -ErrorAction Stop
            $record_ip = $record[0].RecordData.IPv4Address.IPAddressToString

            If ($record_ip -eq $ip)
            {
                Write-Debug "Record matches expected IP: $ip"
            }
            Else
            {
                Write-Warning "Record did not match expected IP: $ip (was $record_ip)"
            }
        }
        Catch [Microsoft.Management.Infrastructure.CimException]
        {
            Write-Host "Adding DNS A record for $fqdn with IP $ip"
            Try
            {
                Add-DnsServerResourceRecordA -Name $hostname -ZoneName $zone_name -IPv4Address $ip -ErrorAction Stop
            }
            Catch [Microsoft.Management.Infrastructure.CimException]
            {
                Write-Warning $_.Exception.Message
            }
        }

        Write-Host "Checking DNS for PTR record: $ip"     
        Try
        {
            $record = Get-DnsServerResourceRecord -Name $octet3 -ZoneName $ptr_zone -RRType ptr -ErrorAction Stop
            $record_name = $record[0].RecordData.PtrDomainName
     
            If ($record_name -eq $fqdn + '.')
            {
                Write-Debug "Record matches expected hostname: $fqdn"
            }
            Else
            {
                Write-Warning "Record did not match expected IP: $fqdn (was $record_name)"
            }
        }
        Catch [Microsoft.Management.Infrastructure.CimException]
        {
            Write-Host "Adding DNS PTR record for IP $ip with hostname $fqdn"
            Try
            {
                Add-DnsServerResourceRecordPtr -Name $octet3 -ZoneName $ptr_zone -PtrDomainName $fqdn
            }
            Catch [Microsoft.Management.Infrastructure.CimException]
            {
                Write-Warning $_.Exception.Message
            }
        }
    }
} 
