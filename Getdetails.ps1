Install-Module Microsoft.Online.SharePoint.PowerShell -force
$baseUrl = "https://api.github.com"
$owner = "Sraavi1309"
$repo = "Test-SC"
$exportFilePath = "C:\Users\chakkiralapadma.s\Documents\AEP\Results.csv"
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


