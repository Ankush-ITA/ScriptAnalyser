# Ensuring the presence of the Microsoft.Graph module
if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
    Write-Host "🔮 Microsoft.Graph module installed successfully!" -ForegroundColor Cyan
}
else {
    Write-Host "✅ Microsoft.Graph module is already installed." -ForegroundColor Green
}

# Ensuring the presence of the Az.Accounts module
if (-not (Get-Module -Name Az.Accounts -ListAvailable)) {
    Install-Module -Name Az.Accounts -Scope CurrentUser -Force
    Write-Host "🔮 Az.Accounts module installed successfully!" -ForegroundColor Cyan
}
else {
    Write-Host "✅ Az.Accounts module is already installed." -ForegroundColor Green
}

# Ensuring the presence of the Az.Accounts module
if (-not (Get-Module -Name Microsoft.PowerShell.ConsoleGuiTools -ListAvailable)) {
    Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -Force
    Write-Host "🔮 Microsoft.PowerShell.ConsoleGuiTools module installed successfully!" -ForegroundColor Cyan
}
else {
    Write-Host "✅ Microsoft.PowerShell.ConsoleGuiTools module is already installed." -ForegroundColor Green
}



# Import the Microsoft.Graph.Identity.Governance module
Import-Module Microsoft.Graph.Identity.Governance

# Establishing a connection to Microsoft Graph
# Think of this as tuning your crystal ball to the right magical frequency
Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All", "PrivilegedAccess.ReadWrite.AzureADGroup"

# Summoning all groups from the depths of Azure
# Like casting a net into the sea of the cloud to see what mysteries we can uncover
Get-MgGroup








# Preparing the environment for our Azure ritual
# Time to connect to Microsoft Graph with the right spells... I mean, scopes!
# Preparing the environment for our Azure ritual
$context = Get-MgContext

if ($null -eq $context) {
    Write-Host "Graph connection not detected. Requesting user to log in."
    Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All", "PrivilegedAccess.ReadWrite.AzureADGroup"
    Write-Host "🧙‍♂️ Context acquired. Current wizard in control: $($context.Account)" -ForegroundColor Yellow

}
else {
    Write-Host "🧙‍♂️ Already connected to Graph as $($context.Account.Id)" -ForegroundColor Yellow
}


# Inquiring the wizard (you) about their intention to create new groups
$CreateGroups = Read-Host "Do you wish to conjure new groups into existence? (y/n)"
if ($CreateGroups -eq "y") {
    Write-Host "🪄 Ah, a brave decision! Let's define the names and destinies of these new groups." -ForegroundColor Yellow
    $groupsToCreate = Read-Host "Enter your group names and descriptions in the format 'name:description', separated by commas"
    $groupArray = $groupsToCreate -split "," | ForEach-Object {
        $split = $_ -split ":", 2  # Splitting the input to extract name and description
        if ($split.Length -eq 2) {
            Write-Host "🌟 Preparing to conjure group named $($split[0].Trim()) with a purpose of $($split[1].Trim())" -ForegroundColor Cyan
            [PSCustomObject]@{ name = $split[0].Trim(); description = $split[1].Trim() }
        }
        else {
            Write-Host "⚠️ Beware! Invalid format detected for '$_'. A group name and description are required." -ForegroundColor Red
        }
    }
    Write-Host "📝 The list of groups to be conjured has been prepared." -ForegroundColor Yellow
}

$groupsCreated = @()

foreach ($entry in $groupArray) {
    # Consulting the Azure oracles to see if the group already exists
    Write-Host "🔍 Consulting the Azure oracles for the existence of $($entry.name)..." -ForegroundColor Cyan
    $group = Get-MgGroup -Filter "DisplayName eq '$($entry.name)'"
    if ($group) {
        Write-Host "👁️ The group $($entry.name) already exists in the realm of Azure." -ForegroundColor Green
        # Updating the group's description if needed
        if ($entry.description -and $group.description -ne $entry.description) {
            Write-Host "📝 Updating the lore (description) of $($entry.name) to match our records." -ForegroundColor Cyan
            Update-MgGroup -GroupId $group.Id -Description $entry.description
        }
        else {
            Write-Host "🔄 No updates required for $($entry.name). Its lore remains unchanged." -ForegroundColor Gray
        }
        $groupsCreated += $group
    }
    else {
        # The spell to create a new group
        Write-Host "🌟 The group $($entry.name) is not yet part of our realm. Let's bring it to life!" -ForegroundColor Yellow
        $GroupBody = @{
            DisplayName         = $entry.name
            Description         = $entry.description
            MailEnabled         = $false
            MailNickname        = $entry.name
            SecurityEnabled     = $true
            "Owners@odata.bind" = @("https://graph.microsoft.com/v1.0/users/$($context.Account)")
        }
        $newGroup = New-MgGroup -BodyParameter $GroupBody
        Write-Host "✨ Group $($entry.name) has been successfully conjured!" -ForegroundColor Green
        $groupsCreated += $newGroup
    }
}

# Revealing our group crafting achievements
Write-Host "🔮 Behold the groups that have been created or updated in this session:" -ForegroundColor Yellow
foreach ($group in $groupsCreated) {
    Write-Host "📜 Group Name: $($group.DisplayName), ID: $($group.Id)" -ForegroundColor Green
}





# Displaying the groups chosen for PIM enablement
Write-Host "===================================================================================================="
Write-Host "🔮 [$($context.Account)] Final phase initiated: Assigning users to groups in Privileged Identity Management." -ForegroundColor Cyan

# Initiating the process of assigning users to the selected groups
Write-Host "🚀 [$($context.Account)] Commencing the user assignment to groups." -ForegroundColor Magenta

$context = Get-MgContext

if ($null -eq $context) {
    Write-Host "Graph connection not detected. Requesting user to log in."
    Connect-MgGraph -Scopes "User.Read.All", "PrivilegedAccess.ReadWrite.AzureADGroup"
    Write-Host "🧙‍♂️ Context acquired. Current wizard in control: $($context.Account)" -ForegroundColor Yellow

}
else {
    Write-Host "🧙‍♂️ Already connected to Graph as $($context.Account.Id)" -ForegroundColor Yellow
}

# Deciding which groups to enable PIM for
write-host "🔍 No newly created groups detected. Retrieving all available groups for PIM activation." -ForegroundColor Yellow
# Determining the groups for user assignment
if (!$groupsToEnable) {
    Write-Host "🤔 [$($context.Account)] No groups specified for enabling. Retrieving all groups for user assignment selection." -ForegroundColor Yellow
    $groupsToConfigure = Get-MgGroup -All | Select-Object DisplayName, Id | Out-GridView -Title "Select groups for user assignment" -OutputMode Multiple
}
else {
    Write-Host "✨ [$($context.Account)] Preparing to assign users to the recently enabled groups." -ForegroundColor Green
    $groupsToConfigure = $groupsToEnable
}

# Selecting the users to assign to the groups
Write-Host "👥 Selecting users to assign to the groups." -ForegroundColor Cyan
$usersToAssign = Get-MgUser -Filter "AccountEnabled eq true" | Select-Object DisplayName, Id | Out-GridView -Title "Select users for assignment" -OutputMode Multiple

foreach ($group in $groupsToConfigure) {
    foreach ($user in $usersToAssign) {
        # Checking if the user is already assigned to the group
        Write-Host "🔍 Checking if user '$($user.DisplayName)' is already assigned to group '$($group.DisplayName)'." -ForegroundColor Blue
        $isAssigned = Get-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleRequest -Filter "groupId eq '$($group.Id)' and principalId eq '$($user.Id)'"
        
        if (!$isAssigned) {
            Write-Host "👩‍🏫 [$($context.Account)] Assigning user '$($user.DisplayName)' to group '$($group.DisplayName)'." -ForegroundColor Cyan
            # Setting the assignment start and end times
            $startTime = Get-Date
            $endTime = $startTime.AddMonths(12).AddDays(-1)

            # Preparing parameters for the assignment
            $params = @{
                accessId      = "member"
                principalId   = "$($user.Id)"
                groupId       = "$($group.Id)"
                action        = "AdminAssign"
                scheduleInfo  = @{
                    startDateTime = $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    expiration    = @{
                        type        = "AfterDateTime"
                        endDateTime = $endTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    }
                }
                justification = "Entra ID - PIM Group Assignment - $($group.DisplayName) - $($user.DisplayName)"
            }

            # Executing the assignment
            New-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleRequest -BodyParameter $params
            Write-Host "✅ User '$($user.DisplayName)' successfully assigned to group '$($group.DisplayName)'." -ForegroundColor Green
        }
        else {
            Write-Host "🔄 [$($context.Account)] User '$($user.DisplayName)' is already a member of group '$($group.DisplayName)'. No action required." -ForegroundColor Gray
        }
    }
}


