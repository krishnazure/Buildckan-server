Login-AzureRmAccount
#Get-AzureRmVMImageSku -Location westus -PublisherName new-signature  -Offer cloud-management-portal | Select PublisherName, Offer, Skus

#Login-AzureRmAccount  
$ResourceGroupName = "cka22"
$machinename=$ResourceGroupName + "mname"
$Location = "South Central US"

## Network
$InterfaceName = $ResourceGroupName+ "ckanservernetwork"
$Subnet1Name = "Subnet1"
$VNetName = "ckanservervnet09"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"

## Compute
$VMName = $ResourceGroupName + "ckanserver"
$ComputerName = $ResourceGroupName +"comp"
$VMSize = "A2"
$OSDiskName = $machinename +"osdisk"
$DataDiskName = $machinename +"datadisk"

## CKAN Server
$imagePublisher = "tsa-public-service"
$imageOffer = "ckan-server"
$OSSku = "basepackage"

#DataDisk
$DataStorageAccount = $VMName +"datadisk"
             
            New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location


            $StorageAccount = New-AzureRmStorageAccount  -ResourceGroupName $ResourceGroupName  -Name $OSDiskName -Type "Standard_LRS" -Location $location
            $DataStorageAccount = New-AzureRmStorageAccount  -ResourceGroupName $ResourceGroupName  -Name $DataDiskName -Type "Standard_LRS" -Location $location

            ## Setup local VM object
            $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
            $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $ComputerName
            $VirtualMachine = Set-AzureRmVMSourceImage -VM $virtualMachine -PublisherName $imagePublisher -Offer $imageOffer -Skus $OSSku  -Version “latest”

            $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
            $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
            $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage

            $DataDiskVhdUri01 = $DataStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + "data1.vhd"
            $DataDiskVhdUri02 = $DataStorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + "data2.vhd"

            $VirtualMachine = Add-AzureRmVMDataDisk -VM $VirtualMachine -Name 'DataDisk1' -Caching 'ReadOnly' -DiskSizeInGB 1023 -Lun 0 -VhdUri $DataDiskVhdUri01 -CreateOption Empty
            $VirtualMachine = Add-AzureRmVMDataDisk -VM $VirtualMachine -Name 'DataDisk2' -Caching 'ReadOnly' -DiskSizeInGB 1023 -Lun 1 -VhdUri $DataDiskVhdUri02 -CreateOption Empty

            # NIC
            $InterfaceName = $VMName + "vip" 
            $PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
            $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $VNetSubnetAddressPrefix
            $VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
            $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp.Id


            
 