###################################################################################
###### Author : SaravanaGanesh Ulagamani###########################################
##### Script will delete all the EKS cluster in all region in AWS with access #####
##### and secret key also will delete the nodegroup and fargate profle first ######
##### then it will delete the cluster                                      ########
###################################################################################

# Import the AWS module
Import-Module AWSPowerShell

# Set your AWS access key and secret key
$accessKey = "XXXXXXXXXXXXXXXX"
$secretKey = "XXXXXXXXXXXXXXXX"
$sessiontoken = "XXXXXXXXXXXXX"

# Set your AWS credentials
Set-AWSCredentials -AccessKey $accessKey -SecretKey $secretKey -SessionToken $sessiontoken


# Get a list of all AWS regions
$regions = Get-EC2Region | Select-Object -ExpandProperty Region

# Loop through each region
foreach ($region in $regions) {
    Write-Host "-------------------- $region---------------------"
    Write-Host "Deleting clusters in region: $region"
    Write-Host " "
    # Get a list of EKS clusters in the current region
    $clusters = Get-EKSClusterList -Region $region 
    if ($clusters){
            # Loop through each cluster and delete it
            foreach ($cluster in $clusters) {
                Write-Host "-------------------- $cluster---------------------"
                Write-Host "Deleting cluster: $cluster"
                Write-Host " "
                #Fargate profile identify and delete 
                $fps = Get-EKSFargateProfileList -ClusterName $cluster -Region $region
                if ($fps) {

                    foreach ($fp in $fps) {
                        Write-Host "Fargate Profile for the cluster $cluster in the Region $region : $fp"
                        Write-Host " "
                        Remove-EKSFargateProfile -ClusterName $cluster -FargateProfileName $fp -Region $region
                        Write-Host "Deleting Fargate profile $fp........ "
                        
                        $fpv = Get-EKSFargateProfile -FargateProfileName $fp -ClusterName $cluster | Select-Object -ExpandProperty Status
                        Write-Host $fpv
                        Do {
                            $fpvs = Get-EKSFargateProfileList -ClusterName $cluster -Region $region
                            Start-Sleep -Seconds 5
                            Write-Host "Deleteing... $fp"
                        } until (-not $fpvs)
                    }

                } else {
                    Write-Host "No Fargate profiles found for Cluster $cluster in Region $region."
                    Write-Host " "
                }

                #NodeGRoup identify and delete 
                $nodeGroups = Get-EKSNodegroupList -clusterName $cluster -Region $region
                # Output the node groups
                    if ($nodeGroups) {
                        
                        foreach ($ng in $nodeGroups) {
                            Write-Host "Node Groups for Cluster $cluster in Region $region : $ng"
                            Write-Host " "
                            $ngv = $ng
                            Remove-EKSNodegroup -ClusterName $cluster -NodegroupName $ng -Region $region
                            Write-Host "Deleting NodeGroup $ng........ "
                            Start-Sleep -Seconds 60
                        }
                    
                    } else {
                        Write-Host "No node groups found for Cluster $cluster in Region $region."
                        Write-Host " "
                    }

              Remove-EKSCluster -ClusterName $cluster -Region $region
}
    }else {
        Write-Host "No Cluster found on the Region $region "
        Write-Host " "
    }
}
Write-Host "-------------------------------------------------------"
Write-Host "Deletion of all clusters across all regions completed."
Write-Host " "
Write-Host "-------------------------------------------------------"
Write-Host "once again verifying cluster in all region.... "
Start-Sleep -Seconds 3

foreach ($region in $regions) {
    Write-Host "-------------------- $region---------------------"
    Write-Host "verifying clusters in region: $region"
    Write-Host " "

    # Get a list of EKS clusters in the current region
    $clusters = Get-EKSClusterList -Region $region 

    if ($clusters){
        # Loop through each cluster and delete it
        foreach ($cluster in $clusters) {
            Write-Host "-------------------- $cluster---------------------"
            Write-Host "cluster : $cluster has found on the Region $region"
            Write-Host " "
        }
        Write-Host "rerun the script again to delete the cluster in the Region $region"
        Write-Host " "
    } else {
        Write-Host "No cluster in the region $region" 
        Write-Host " "
    }
}
