$ExportCSV= [Environment]::GetFolderPath('MyDocuments') + "\LastLogonTimeReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
#$ExportCSV= [Environment]::GetFolderPath('MyDocuments') + "\LastLogonTimeReport.csv"
$Result=""
$Output=@()
$MBUserCount=0
$OutputCount=0

$Module = Get-Module -Name AzureAdPreview -ListAvailable  
if($Module.count -eq 0) 
{ 
 Write-Host AzureADPreview module is not available  -ForegroundColor yellow  
 $Confirm= Read-Host Are you sure you want to install module? [Y] Yes [N] No 
 if($Confirm -match "[yY]") 
 { 
  Install-Module AzureADPreview
  Import-Module AzureADPreview
 } 
 else 
 { 
  Write-Host MSOnline module is required to connect AzureAD.Please install module using Install-Module MSOnline cmdlet. 
  Exit
 }
} 

Connect-AzureAD

$UserList = get-azureAdUser -All $true

$UserList | ForEach-Object {
    $Print=0
    $MBUserCount++
    Write-Progress -Activity "`n     Processed mailbox count: $MBUserCount "`n"  Currently Processing: $DisplayName"
    If ($_.UserType -ne "Guest") {
        $licensed=$False
        
        For ($i=0; $i -le ($_.AssignedLicenses | Measure).Count ; $i++) { 
            If( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) {
                $licensed=$true 
            } 
        }
        If( $licensed -eq $true) {
            Try {
                $_.DisplayName         
                $UserObjectId = $_.ObjectId
                $UserLastLogonDate = (Get-AzureADAuditSignInLogs -Top 1  -Filter "userid eq '$UserObjectId' and status/errorCode eq 0").CreatedDateTime}
                #$UserLastLogonDate = (Get-AzureADAuditSignInLogs -Top 1).CreatedDateTime}
            Catch { Write-Host "Can't read Azure Active Directory Sign in Logs for" $_.DisplayName }
            
            If ($UserLastLogonDate -ne $Null) {
                $LastSignInDate = Get-Date($UserLastLogonDate) 
                $Days = New-TimeSpan($LastSignInDate)}
                
                #Write-Host "Guest" $_.DisplayName "last signed in on" $LastSignInDate "or" $Days.Days "days ago"  }
            If ( $UserLastLogonDate -eq $Null) { 
                $LastSigninDate ="Never Logged In"
                $Days ="-"
            }
                #Write-Host "No Azure Active Directory sign-in data available for" $_.DisplayName "(" $_.Mail ")" }
         
        #$UserLastLogonDate = $Null
         if($Days -ne "-"){
             if(($Days -ne "") -and ([int]$Days.days -gt 20)){
             $Print=1
             }
         }
         if($LastSignInDate -eq "Never Logged In"){
                $Print=1
         }
       Start-Sleep -s 3
       }
       }
       
        if($Print -eq 1)
     {
        $Result=@{'UserPrincipalName'=$_.UserPrincipalName;'DisplayName'=$_.DisplayName;'LastLogonTime'=$LastSigninDate;'CreationTime'=$_.WhenCreated;'InactiveDays'=$Days.days}
        $Output= New-Object PSObject -Property $Result
        $Output | Select-Object UserPrincipalName,DisplayName,LastLogonTime,CreationTime,InactiveDays | Export-Csv -Path $ExportCSV -Notype -Append
 }
 Start-Sleep -s 1

}



Invoke-Item "$ExportCSV"
