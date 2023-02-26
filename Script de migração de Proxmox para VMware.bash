#!/bin/bash

#vars
vmID="nil"
vmDisk="nil"
vmDiskID="nil"
DstHost="nil"
DstHostUser="nil"
VolStorage="nil"
SSHPASS="nil"

rm -f /root/DiscosParaMigrar/tmp/*

echo 

BAR='############## Início do Script de migração de Proxmox para VMware ESXi ##############'   # this is full bar, e.g. 20 chars

for i in {1..80}; do
    echo -ne "\r${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep .05                 # wait 100ms between "frames"
done

echo 
echo 

echo "Instalando dependências..."
echo 
apt install sshpass -y

#echo 
#echo "-- Preparando para criar a conexão com o host de destino..."
#echo 

#read -p "Por favor, insira o ip ou hostname do VMware ESXi: " DstHost
#echo 
#read -p "Agora insira o usuário do VMware: " DstHostUser
#echo 
#read -s -p "Insira sua senha: " SSHPASS
#echo 
#echo 

#sshpass -p $SSHPASS ssh-copy-id $DstHostUser@$DstHost
#echo 

# Listando as VMs do KVM
echo "== Buscando e exibindo a lista de VM's deste nó!"
echo 
echo -ne '#####                     (33%)\r'
sleep .09
echo -ne '#########                 (40%)\r'
sleep .09
echo -ne '#############             (66%)\r'
sleep .09
echo -ne '################          (81%)\r'
sleep .09
echo -ne '###################       (92%)\r'
sleep .09
echo -ne '#########################  (100%)\r'
echo -ne '\n'
qm list
echo 

read -p "Por favor, digite a ID da VM a ser convertida para o VMware ESXi: " vmID
echo 

## Checando se o diretório de migração existe..."
echo "-- Verificando a existência do diretório de serviço...."
echo 
echo -ne '#####                     (33%)\r'
sleep .09
echo -ne '#########                 (40%)\r'
sleep .09
echo -ne '#############             (66%)\r'
sleep .09
echo -ne '################          (81%)\r'
sleep .09
echo -ne '###################       (92%)\r'
sleep .09
echo -ne '#########################  (100%)\r'
echo -ne '\n'
echo 

if [ -d /root/DiscosParaMigrar ] 
then
    echo -e "-- Diretório existe!" '\n'
else
    echo "-- Criando o diretório (DiscosParaMigrar) !"
        echo -ne '#####                     (33%)\r'
        sleep .02
        echo -ne '#############             (66%)\r'
        sleep .02
        echo -ne '#######################   (100%)\r'
        echo -ne '\n'
    mkdir -p /root/DiscosParaMigrar/tmp
fi

echo "-- Lista de discos dessa VM"
echo 

# Exportando para tratação
qm config $vmID >> /root/DiscosParaMigrar/tmp/$vmID-Configs.txt
echo 

# Para exibição
qm config $vmID | grep -i scsi | grep disk- | cut -d\ '' -f 2 | cut -d , -f 1
# Exportando somente as informações dos discos da VM para o arquivo para ser tratado
qm config $vmID | grep -i scsi | grep disk- | cut -d , -f 1 >> /root/DiscosParaMigrar/tmp/$vmID-Disk.txt
echo 

# Criando as variáveis das configurações da VM
export vmDiskID0=$(cat /root/DiscosParaMigrar/tmp/$vmID-Disk.txt | grep -i scsi0 | cut -d\  -f 2)
export vmDiskID1=$(cat /root/DiscosParaMigrar/tmp/$vmID-Disk.txt | grep -i scsi1 | cut -d\  -f 2)
export vmDiskID2=$(cat /root/DiscosParaMigrar/tmp/$vmID-Disk.txt | grep -i scsi2 | cut -d\  -f 2)
echo 
export vmDisk0=$(cat /root/DiscosParaMigrar/tmp/$vmID-Disk.txt | grep -i scsi0 | cut -d : -f3)
export vmDisk1=$(cat /root/DiscosParaMigrar/tmp/$vmID-Disk.txt | grep -i scsi1 | cut -d : -f3)
export vmDisk2=$(cat /root/DiscosParaMigrar/tmp/$vmID-Disk.txt | grep -i scsi2 | cut -d : -f3)
echo 
echo 
export PATHvmDiskID0=$(pvesm path $vmDiskID0)
export PATHvmDiskID1=$(pvesm path $vmDiskID1)
export PATHvmDiskID2=$(pvesm path $vmDiskID2)
echo 
echo "Os caminhos reais dos discos estão listados abaixo"
echo 
echo -e '\n'$PATHvmDiskID0'\n'$PATHvmDiskID1'\n'$PATHvmDiskID2'\n'
echo 
echo "Estes são os discos da VM $vmID "
echo 
echo -e '\n'$vmDisk0'\n'$vmDisk1'\n'$vmDisk2'\n'
echo 

#read -p "Agora, digite o número do Disco(verifique essa informação na saida acima): " vmDiskID
#echo ""

echo "## Preparando o disco da VM para conversão!"
echo 


# Checando se o disco 1 da VM selecionada já foi convertido
if [ -f /root/DiscosParaMigrar/$vmDisk0.vmdk ] 
then
    echo "-- O disco dessa VM já foi convertido para VMDK."
    echo "-- Pulando para etapa seguinte...."
    BAR='- > - > - > - > - > - > - > - > - > - >'   # this is full bar, e.g. 20 chars

    for i in {1..80}; do
    echo -ne "\r${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep .02                 # wait 100ms between "frames"
    done
    echo 

else
    echo "-- Convertendo disco 1 da VM $vmID para VMDK."
        echo 
        echo "-- OBS.: ESSE PROCESSO DE CONVERSÃO PODE DEMORAR. DEPENDE DO TAMANHO DA VM!"
    cd  /root/DiscosParaMigrar
    echo "---------------------------------------------------------------------------"
    qemu-img convert -p -f raw \
                $PATHvmDiskID0 -O vmdk \
                /root/DiscosParaMigrar/$vmDisk0.vmdk
    echo "---------------------------------------------------------------------------"
        echo "-- Conversão concluída."
        echo 
fi

# Checando se o disco 2 da VM selecionada já foi convertido
if [ -f /root/DiscosParaMigrar/$vmDisk1.vmdk ] 
then
    echo "-- O disco 2 dessa VM já foi convertido para VMDK."
    echo "-- Pulando para etapa seguinte...."
    BAR='- > - > - > - > - > - > - > - > - > - >'   # this is full bar, e.g. 20 chars

    for i in {1..80}; do
    echo -ne "\r${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep .02                 # wait 100ms between "frames"
    done
    echo 

else
    echo "-- Convertendo disco 2 da VM $vmID para VMDK."
        echo 
        echo "-- OBS.: ESSE PROCESSO DE CONVERSÃO PODE DEMORAR. DEPENDE DO TAMANHO DA VM!"
    cd  /root/DiscosParaMigrar
    echo "---------------------------------------------------------------------------"
    qemu-img convert -p -f raw \
                $PATHvmDiskID1 -O vmdk \
                /root/DiscosParaMigrar/$vmDisk1.vmdk
    echo "---------------------------------------------------------------------------"
        echo "-- Conversão concluída."
        echo 
fi

# Checando se o disco 3 da VM selecionada já foi convertido
if [ -f /root/DiscosParaMigrar/$vmDisk2.vmdk ] 
then
    echo "-- O disco 3 dessa VM já foi convertido para VMDK."
    echo "-- Pulando para etapa seguinte...."
    BAR='- > - > - > - > - > - > - > - > - > - >'   # this is full bar, e.g. 20 chars

    for i in {1..80}; do
    echo -ne "\r${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep .02                 # wait 100ms between "frames"
    done
    echo 

else
    echo "-- Convertendo disco 3 da VM $vmID para VMDK."
        echo 
        echo "-- OBS.: ESSE PROCESSO DE CONVERSÃO PODE DEMORAR. DEPENDE DO TAMANHO DA VM!"
    cd  /root/DiscosParaMigrar
    echo "---------------------------------------------------------------------------"
    qemu-img convert -p -f raw \
                $PATHvmDiskID2 -O vmdk \
                /root/DiscosParaMigrar/$vmDisk2.vmdk
    echo "---------------------------------------------------------------------------"
        echo "-- Conversão concluída."
        echo 
fi
echo 
echo "-- PREPARANDO PARA EXPORTAR O DISCO PARA O VMWARE..."

#exit

echo 
echo "-- Preparando para criar a conexão com o host de destino..."
echo 

read -p "Por favor, insira o ip ou hostname do VMware ESXi: " DstHost
echo 
read -p "Agora insira o usuário do VMware: " DstHostUser
echo 
read -s -p "Insira sua senha: " SSHPASS
echo 
echo 

sshpass -p $SSHPASS ssh-copy-id $DstHostUser@$DstHost
echo 

sshpass -p $SSHPASS ssh $DstHostUser@$DstHost du -h vmfs/volumes/ | grep -i Proxmox | cut -d / -f 3 | tail -1 >> /root/DiscosParaMigrar/tmp/$vmID-StorageID.txt
echo 

#echo "-- ATENÇÃO! AGORA OBSERVE AS LINHAS ACIMA, E COPIE O TRECHO REPRESENTADO PELOS "x"."
#echo "Exemplo: ( vmfs/volumes/ xxxxxxxx-xxxxxxx-xxxx-xxxxxxxxxxxx /Proxmox )"
#echo ""

#read -p "Agora cole aqui o trecho copiado na ação anterior: " VolStorage

export VolStorage=$(tail -1 /root/DiscosParaMigrar/tmp/$vmID-StorageID.txt)

scp /root/DiscosParaMigrar/*.vmdk $DstHostUser@$DstHost:/vmfs/volumes/$VolStorage/Proxmox/ 
echo 
echo 
echo 
echo "TRANSFERÊNCIA CONCLUÍDA!"
echo 

sshpass -p $SSHPASS ssh $DstHostUser@$DstHost vmkfstools -i /vmfs/volumes/$VolStorage/Proxmox/$vmDisk0.vmdk \
        /vmfs/volumes/$VolStorage/Proxmox/$vmDisk0-thin.vmdk -d thin 
sshpass -p $SSHPASS ssh $DstHostUser@$DstHost vmkfstools -i /vmfs/volumes/$VolStorage/Proxmox/$vmDisk1.vmdk \
        /vmfs/volumes/$VolStorage/Proxmox/$vmDisk1-thin.vmdk -d thin
sshpass -p $SSHPASS ssh $DstHostUser@$DstHost vmkfstools -i /vmfs/volumes/$VolStorage/Proxmox/$vmDisk2.vmdk \
        /vmfs/volumes/$VolStorage/Proxmox/$vmDisk2-thin.vmdk -d thin
sshpass -p $SSHPASS ssh $DstHostUser@$DstHost rm /vmfs/volumes/$VolStorage/Proxmox/$vmDisk0.vmdk
sshpass -p $SSHPASS ssh $DstHostUser@$DstHost rm /vmfs/volumes/$VolStorage/Proxmox/$vmDisk1.vmdk
sshpass -p $SSHPASS ssh $DstHostUser@$DstHost rm /vmfs/volumes/$VolStorage/Proxmox/$vmDisk2.vmdk
echo ""

echo -e "O disco $vmDisk0.vmdk exportado para o VMWare ESXi dentro da pasta Proxmox \n (previamente criada)"
echo 

read -N 1 -p "Quer apagar os discos convertidos. Continue (y/N)? " answer
echo 
if [ "${answer,,}" == "y" ]
then
    rm -f /root/DiscosParaMigrar/*.vmdk
    sleep 1
	echo
    echo 'Discos convertidos apagados da pasta de armazenamento.'
	echo

else
	echo
    echo "-- O(s) disco(s) convertidos da VM $vmID não serão apagados."
	echo
fi

echo -e "Processo concluido!\n\n OBSERVAÇÃO:\n Agora crie uma VM dentro do VMWare e importe para\n ela o(s) disco(s) exportado(s) do Proxmox por este script "

rm -f /root/DiscosParaMigrar/tmp/*
unset SSHPASS
unset vmDisk0
unset vmDisk1
unset vmDisk2
unset vmDiskID0
unset vmDiskID1
unset vmDiskID2
unset vmID
unset vmDiskID
unset DstHost
unset DstHostUser
unset PATHvmDiskID0
unset PATHvmDiskID1
unset PATHvmDiskID2
unset VolStorage
echo 
