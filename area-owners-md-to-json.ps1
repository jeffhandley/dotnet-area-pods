$markdownPath = $ARGS[0] ?? "area-owners.md"

if ((Test-Path $markdownPath) -eq $False) {
    Write-Error "'$markdownPath' not found. Specify the path to the area-owners.md file if it is not in the current directory." -ErrorAction Stop
}

$markdownLines = Get-Content $markdownPath
$teamCache = New-Object System.Collections.Generic.Dictionary"[String,String[]]"

$pods = @{
    "adamsitnik"="adam-david-jeremy";
    "bartonjs"="akhil-carlos-viktor";
    "buyaa-n"="buyaa-steve";
    "carlossanlop"="akhil-carlos-viktor";
    "eiriktsarpalis"="eirik-krzysztof-layomi-tarek";
    "dakersnar"="drew-michael-tanner";
    "ericstj"="eric-jeff";
    "antonfirsov"="networking"
}

Function Parse-LabelLine {
    param ([String]$line)

    $cols = $line -split "\|"

    $label = $cols[1].Trim()
    $lead = $cols[2].Trim().Replace("@", "")
    $owners = $cols[3].Trim().Replace("@", "").Replace(",", "") -split " "

    $people = $owners -notmatch "/"
    $teams = $owners -match "/"
    $teamMembers = @()

    foreach ($team in $teams) {
        $teamParts = $team -split "/"
        $org = $teamParts[0]
        $teamName = $teamParts[1]

        if ($teamCache.Keys.Contains($team)) {
            $teamMembers = $teamCache[$team]
        } else {
            Write-Host "Loading members of team $org/$teamName"

            try {
                $teamMembers = (gh api orgs/$org/teams/$teamName/members -q ".[].login")
                $teamCache[$team] = $teamMembers
            }
            catch {
                Write-Host "Could not load team members for $org/$teamName"
            }
        }
    }

    $allOwners = ((($people + $teamMembers) | Sort-Object -Unique) + $teams)
    $firstOwner = $($people + $teamMembers) -NotMatch "ericstj" -NotMatch "jeffhandley" | Sort-Object -Unique | Select-Object -Index 0
    if ($firstOwner -eq $Null) { $firstOwner = "ericstj" }

    if ($pods[$firstOwner]) {
        [Ordered]@{
            lead = [String]$lead;
            pod = [String]$pods[$firstOwner];
            owners = [String[]]$allOwners;
            label = [String]$label;
        }
    } else {
        [Ordered]@{
            lead = [String]$lead;
            owners = [String[]]$allOwners;
            label = [String]$label;
        }
    }
}

[Object[]]$areas = ($markdownLines | Select-String -Pattern "^\|\s*area-").Line | Foreach-Object -Process {Parse-LabelLine $_}
[Object[]]$operatingSystems = ($markdownLines | Select-String -Pattern "^\|\s*os-").Line | Foreach-Object -Process {Parse-LabelLine $_}
[Object[]]$architectures = ($markdownLines | Select-String -Pattern "^\|\s*arch-").Line | Foreach-Object -Process {Parse-LabelLine $_}

$data = [Ordered]@{ architectures = $architectures; operatingSystems = $operatingSystems; areas = $areas }
$data | ConvertTo-Json -Depth 5
