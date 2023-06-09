Install-Module SharePointPnPPowerShellOnline -Force
#Import PowerShell module for SharePoint Online
#Import-Module Microsoft.Online.Sharepoint.PowerShell -DisableNameChecking
$credentials = "chakkiralapadma.s@infosys.com"
$Site= ”https://infosystechnologies.sharepoint.com/” 
Connect-PnPOnline -Url $Site -Credentials $credentials
$CustomerData = Import-CSV “C:\Users\chakkiralapadma.s\Documents\AEP\Results.csv”

 
#Get All SharePoint Sites
#Get-SPOSite -Identity https://infosystechnologies-my.sharepoint.com/:u:/r/personal/chakkiralapadma_s_ad_infosys_com/Documents/github.url?csf=1&web=1&e=98HGOP


#Read more: https://www.sharepointdiary.com/2018/12/install-update-uninstall-sharepoint-online-powershell-module.html#ixzz85N8y2WiY
$baseUrl = "https://api.github.com"
$owner = "Sraavi1309"
$repo = "Test-SC"
$exportFilePath = "https://infosystechnologies-my.sharepoint.com/:u:/g/personal/chakkiralapadma_s_ad_infosys_com/EZjDBUptQmlDqslCNerIiHsBjWsZXRX-gfVyehorNAb8Ag?e=cQNKox"
$token = "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"

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/vnd.github.v3+json"
    }

$allWorkflows = "$baseUrl/repos/$owner/$repo/actions/workflows?per_page=100&page=1"

$responseAllWorkflows = Invoke-RestMethod -Uri $allWorkflows -Headers $headers

$aResults = @()

foreach($workflow in $responseAllWorkflows.workflows)
{
    $workflowId = $workflow.id
    $workflowRunURL = "$baseUrl/repos/$owner/$repo/actions/workflows/$workflowId/runs"

    $page = 1
    $perPage = 100  # Maximum number of records per page
    $allRuns = @()

    do 
        {
            $url = $workflowRunURL + "?per_page=$perPage&page=$page"
            $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

            $runs = $response.workflow_runs
            $allRuns += $runs

            $page++
        } while ($runs.Count -gt 0)


    foreach($workflowRun in $allRuns)
    {
        $workflowChild = ""
        $allReferedWorkflow = @()
        $referencedWorkflow = ""
        $workflowRunId = $workflowRun.id
        $workflowName = $workflowRun.name
        $workflowState = $workflow.state #Enabled/Disabled/ManuallyDisabled
        $workflowConslusion = $workflowRun.conclusion #Success/Failure
        $workflowstatus = $workflowRun.status #completed/queued/inprogress

        if($workflowRun.run_attempt -gt 1)
        {
            $workflowCreatedDate = $workflowRun.run_started_at
        }
        else
        {
            $workflowCreatedDate = $workflowRun.created_at            
        }
        $workflowCompletedDate = $workflowRun.updated_at

        if($workflowRun.referenced_workflows.Count -gt 0)
        {            
            foreach($refWorkflow in $workflowRun.referenced_workflows.path)
            {
                $string = $refWorkflow
                $pattern = "/([^/]+\.yml)"

                $match = [regex]::Match($string, $pattern)
                if ($match.Success) {
                    $workflowChild = $match.Groups[1].Value
                    Write-Output $workflowChild
                    $allReferedWorkflow+=$workflowChild
                } else {
                    Write-Output "No match found."
                }
            }
            $referencedWorkflow = $allReferedWorkflow -join ","            
        }

        $hItemDetails = [PSCustomObject]@{
            WorkflowName = $workflowName
            WorkflowRunId = $workflowRunId
            WorkflowRunCreatedDate = $workflowCreatedDate
            WorkflowRunCompletedDate = $workflowCompletedDate
            WorkflowConclusion = $workflowConslusion #Success/Failure
            WorkflowState = $workflowState #Enabled/Disabled/ManuallyDisabled
            WorkflowStatus = $workflowstatus #completed/queued/inprogress
            ReferenceWorkflow = $referencedWorkflow
            WorkflowId = $workflowId
    }
   $aResults += $hItemDetails 
  }

}

$aResults | Export-Csv $exportFilePath


