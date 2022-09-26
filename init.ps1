az group create -l WestEurope -n "tfstate-ddos-exp-rg"
az storage account create -n "tfstatestoreddosexp" -g "tfstate-ddos-exp-rg" -l WestEurope --sku Standard_LRS
az storage container create -n "tf-state" --account-name "tfstatestoreddosexp" --public-access container