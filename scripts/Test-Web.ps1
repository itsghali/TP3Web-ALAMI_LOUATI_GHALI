param(
    [string]$BaseUrl = 'http://localhost:8080/TP3Web-ALAMI_LOUATI_Ghali/',
    [switch]$WithGemini
)

$ErrorActionPreference = 'Stop'
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$results = [System.Collections.Generic.List[string]]::new()

function Read-Attribute([string]$Tag, [string]$Name) {
    $match = [regex]::Match($Tag, '(?:\s|^)' + [regex]::Escape($Name) + '="([^"]*)"')
    if ($match.Success) { return [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value) }
    return ''
}

function Read-TextArea([string]$Html, [string]$Id) {
    $match = [regex]::Match($Html, '<textarea\b[^>]*id="' + [regex]::Escape($Id) + '"[^>]*>([\s\S]*?)</textarea>')
    if (-not $match.Success) { throw "Textarea absent : $Id" }
    return [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value).Trim()
}

function Assert-Check([bool]$Condition, [string]$Label) {
    if (-not $Condition) { throw "ECHEC : $Label" }
    $results.Add($Label)
    Write-Host "OK : $Label"
}

function Get-Page {
    return (Invoke-WebRequest -Uri $BaseUrl -WebSession $session -UseBasicParsing -TimeoutSec 30).Content
}

function Send-Form([string]$Html, [string]$Button, [string]$Question, [string]$Role, [string]$RoleLabel) {
    $fields = @{}
    $buttonFound = $false
    foreach ($match in [regex]::Matches($Html, '<input\b[^>]*>')) {
        $tag = $match.Value
        $name = Read-Attribute $tag 'name'
        $type = Read-Attribute $tag 'type'
        $value = Read-Attribute $tag 'value'
        if ($type -eq 'hidden' -and $name) { $fields[$name] = $value }
        if ($type -eq 'submit' -and $value -eq $Button) {
            $fields[$name] = $value
            $buttonFound = $true
        }
    }
    if (-not $buttonFound) { throw "Bouton absent : $Button" }
    $fields['form:question'] = $Question
    $fields['form:reponse'] = Read-TextArea $Html 'form:reponse'
    $fields['form:rolesysteme_input'] = $Role
    $fields['form:rolesysteme_editableInput'] = $RoleLabel
    $form = [regex]::Match($Html, '<form\b[^>]*id="form"[^>]*>').Value
    $action = [uri]::new([uri]$BaseUrl, (Read-Attribute $form 'action')).AbsoluteUri
    return (Invoke-WebRequest -Uri $action -Method Post -Body $fields -WebSession $session -UseBasicParsing -TimeoutSec 90).Content
}

$page = Get-Page
Assert-Check ($page -match 'jakarta.faces.ViewState') 'Accueil traite par JSF'
Assert-Check ($page -match 'form:rolesysteme') 'Liste des roles presente'
Assert-Check ($page -notmatch '(?i)mode debug|bb\.debug') 'Interface sans mode debug'

foreach ($resource in @('css/mycsslayout.css', 'js/script.js')) {
    $encodedName = [regex]::Escape($resource)
    $match = [regex]::Match($page, '(?:src|href)="([^"]*jakarta.faces.resource/' + $encodedName + '[^"]*)"')
    if (-not $match.Success) { throw "Ressource absente : $resource" }
    $url = [uri]::new([uri]$BaseUrl, [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value)).AbsoluteUri
    $response = Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing -TimeoutSec 30
    Assert-Check ($response.StatusCode -eq 200) "Ressource $resource accessible"
}

$assistantOption = [regex]::Match($page, '<option\b[^>]*value="([^"]*)"[^>]*>Assistant</option>')
$assistantRole = [System.Net.WebUtility]::HtmlDecode($assistantOption.Groups[1].Value)
$page = Send-Form $page 'Envoyer la question' 'Test sans role' '' ''
Assert-Check ($page -match 'Vous devez indiquer le r.le') 'Role obligatoire'

$page = Send-Form $page 'Envoyer la question' '' $assistantRole 'Assistant'
Assert-Check ($page -match 'Il manque le texte de la question') 'Question vide refusee'
Assert-Check ((Read-TextArea $page 'form:conversation') -eq '') 'Validation sans ajout a la conversation'

if ($WithGemini) {
    $page = Get-Page
    $translator = [regex]::Match($page, '<option\b[^>]*value="([^"]*)"[^>]*>Traducteur[^<]*</option>')
    if (-not $translator.Success) { throw 'Role traducteur absent' }
    $translatorRole = [System.Net.WebUtility]::HtmlDecode($translator.Groups[1].Value)
    $translatorLabel = 'Traducteur Anglais-Fran' + [char]0x00e7 + 'ais'
    $page = Send-Form $page 'Envoyer la question' 'bonjour' $translatorRole $translatorLabel
    $answer = Read-TextArea $page 'form:reponse'
    Assert-Check ($answer -match '(?i)\bhello\b|\bhi\b|good (morning|day)') 'Gemini traduit bonjour en anglais'
    Assert-Check ($page -match '<select\b[^>]*id="form:rolesysteme_input"[^>]*disabled') 'Role fige apres premiere reponse'
    Assert-Check ((Read-TextArea $page 'form:conversation') -match 'bonjour') 'Conversation affichee'

    $page = Send-Form $page 'Nouveau chat' '' $translatorRole $translatorLabel
    Assert-Check ((Read-TextArea $page 'form:conversation') -eq '') 'Nouveau chat efface la conversation'
    Assert-Check ($page -notmatch '<select\b[^>]*id="form:rolesysteme_input"[^>]*disabled') 'Nouveau chat permet un autre role'

    $memoryRole = 'Tu es un assistant. Reponds brievement en francais et garde les informations de la conversation.'
    $page = Send-Form $page 'Envoyer la question' 'Mon prenom est Corentin. Reponds uniquement OK.' $memoryRole $memoryRole
    Assert-Check ((Read-TextArea $page 'form:reponse') -match '(?i)\bOK\b') 'Role personnalise accepte'
    $page = Send-Form $page 'Envoyer la question' 'Quel est mon prenom ? Reponds uniquement avec le prenom.' $memoryRole $memoryRole
    Assert-Check ((Read-TextArea $page 'form:reponse') -match '(?i)Corentin') 'Memoire conservee entre deux questions'

    $page = Send-Form $page 'Nouveau chat' '' $memoryRole $memoryRole
    $page = Send-Form $page 'Envoyer la question' 'Quel est mon prenom ? Si tu ne le connais pas, reponds uniquement INCONNU.' $memoryRole $memoryRole
    $answer = Read-TextArea $page 'form:reponse'
    Assert-Check ($answer -match '(?i)INCONNU' -and $answer -notmatch '(?i)Corentin') 'Nouvelle vue sans memoire du chat precedent'
}

Write-Host ("Termine : {0} controles reussis. Gemini : {1}." -f $results.Count, [bool]$WithGemini)
