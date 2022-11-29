#!/bin/bash

#vars
vmID="nil"
vmDiskID="nil"
DstHost="nil"
DstHostUser="nil"
VolStorage="nil"
SSHPASS="nil"

echo ""

BAR='############## Início do Script de migração de Proxmox para VMware ESXi ##############'   # this is full bar, e.g. 20 chars

for i in {1..80}; do
    echo -ne "\r${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep .05                 # wait 100ms between "frames"
done

echo ""
echo ""

echo "Instalando dependências..."
echo ""
apt install sshpass -y

# List already existing VM's and ask for vmID
echo "== Buscando e exibindo a lista de VM's deste nó!"
echo ""
echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'
qm list
echo ""

read -p "Por favor, digite a ID da VM a ser convertida para o VMware ESXi: " vmID
echo ""

echo "-- Lista de discos dessa VM"
echo ""
qm config $vmID
echo ""

read -p "Agora, digite o número do Disco(verifique essa informação na saida acima): " vmDiskID
echo ""
# Ask user for version

echo "## Preparando o disco da VM para conversão!"
echo ""

## Checking if temp dir is available..."
echo "-- Verificando a existência do diretório de serviço...."
echo ""
echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'
echo ""

if [ -d /root/DiscosParaMigrar ] 
then
    echo "-- Diretório existe!"
else
    echo "-- Criando o diretório (DiscosParaMigrar) !"
        echo -ne '#####                     (33%)\r'
        sleep 1
        echo -ne '#############             (66%)\r'
        sleep 1
        echo -ne '#######################   (100%)\r'
        echo -ne '\n'
    mkdir /root/DiscosParaMigrar
fi

# Check if image is available and download if needed
if [ -f /root/DiscosParaMigrar/vm-$vmID-disk-$vmDiskID*.vmdk ] 
then
    echo "-- O disco dessa VM já foi convertido para VMDK."
    echo "-- Pulando para etapa seguinte...."
    BAR='- > - > - > - > - > - > - > - > - > - >'   # this is full bar, e.g. 20 chars

    for i in {1..80}; do
    echo -ne "\r${BAR:0:$i}" # print $i chars of $BAR from 0 position
    sleep .02                 # wait 100ms between "frames"
    done
    echo ""

else
    echo "-- Convertendo disco da VM $vmID para VMDK."
        echo ""
        echo "-- OBS.: ESSE PROCESSO DE CONVERSÃO PODE DEMORAR. DEPENDE DO TAMANHO DA VM!"
    cd  /root/DiscosParaMigrar
    echo "---------------------------------------------------------------------------"
    qemu-img convert -p -f raw \
                /dev/pve2/vm-$vmID-disk-$vmDiskID* -O vmdk \
                /root/DiscosParaMigrar/vm-$vmID-disk-$vmDiskID*.vmdk
    echo "---------------------------------------------------------------------------"
        echo "-- Conversão concluída."
        echo ""
fi

echo "-- PREPARANDO PARA EXPORTAR O DISCO PARA O VMWARE..."

echo ""

read -p "Por favor, insira o ip do VMware ESXi: " DstHost
echo ""
read -p "Agora insira o usuário do VMware: " DstHostUser
echo ""
read -s -p "Insira sua senha: " SSHPASS
echo ""
echo ""

sshpass -p $SSHPASS ssh $DstHostUser@$DstHost du -h vmfs/volumes/ | grep Proxmox
echo ""

echo "-- ATENÇÃO! AGORA OBSERVE AS LINHAS ACIMA, E COPIE O TRECHO REPRESENTADO PELOS "x"."
echo "Exemplo: ( vmfs/volumes/ xxxxxxxx-xxxxxxx-xxxx-xxxxxxxxxxxx /Proxmox )"
echo ""

read -p "Agora cole aqui o trecho copiado na ação anterior: " VolStorage

scp /root/DiscosParaMigrar/vm-$vmID-disk-$vmDiskID*.vmdk $DstHostUser@$DstHost:/vmfs/volumes/$VolStorage/Proxmox/ 
echo ""
echo ""
echo ""
echo "TRANSFERÊNCIA CONCLUÍDA!"
echo ""

rm -f /root/DiscosParaMigrar/vm-$vmID-disk-$vmDiskID*.vmdk

sshpass -p $SSHPASS ssh $DstHostUser@$DstHost vmkfstools -i /vmfs/volumes/$VolStorage/Proxmox/vm-$vmID-disk-$vmDiskID*.vmdk \
        /vmfs/volumes/$VolStorage/Proxmox/vm-$vmID-disk-$vmDiskID*-thin.vmdk -d thin 
sshpass -p $SSHPASS ssh $DstHostUser@$DstHost rm /vmfs/volumes/$VolStorage/Proxmox/vm-$vmID-disk-$vmDiskID*.vmdk
echo ""

echo -e "O disco vm-$vmID-disk-$vmDiskID*.vmdk exportado para o VMWare ESXi dentro da pasta Proxmox \n (previamente criada)"
echo ""

echo -e "Processo concluido!\n\n OBSERVAÇÃO:\n Agora crie uma VM dentro do VMWare e importe para\n ela o disco exportado do Proxmox por este script "

unset SSHPASS
echo ""