param(
    [string]$PayaraHome = '',
    [string]$JavaHome = ''
)

$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$workspacePath = Split-Path $projectPath -Parent

if ([string]::IsNullOrWhiteSpace($env:GEMINI_KEY)) {
    throw 'Definir GEMINI_KEY dans l environnement avant de lancer Payara. Ne pas enregistrer la cle dans le projet.'
}
if (-not $PayaraHome) { $PayaraHome = Join-Path $workspacePath 'payara/payara7' }
if (-not $JavaHome) { $JavaHome = $env:JAVA_HOME }
if (-not $JavaHome) {
    $jdk = Get-ChildItem (Join-Path $workspacePath 'jdk-25') -Directory | Select-Object -First 1
    if ($jdk) { $JavaHome = $jdk.FullName }
}
if (-not $JavaHome -or -not (Test-Path (Join-Path $JavaHome 'bin/java.exe'))) {
    throw 'JDK absent. Fournir -JavaHome avec le chemin du JDK 25.'
}
$asadmin = Join-Path $PayaraHome 'bin/asadmin.bat'
if (-not (Test-Path $asadmin)) { throw 'Payara absent. Fournir -PayaraHome avec le chemin de payara7.' }
$version = & (Join-Path $JavaHome 'bin/java.exe') --version | Out-String
if ($version -notmatch '(?m)^(?:openjdk|java) 25(?:[.\s]|$)') { throw 'Le cours demande Java 25.' }

$previousJavaHome = $env:JAVA_HOME
$previousAsJava = $env:AS_JAVA
Push-Location $projectPath
try {
    $env:JAVA_HOME = $JavaHome
    $env:AS_JAVA = $JavaHome
    & (Join-Path $projectPath 'mvnw.cmd') -B -ntp package
    if ($LASTEXITCODE -ne 0) { throw 'Compilation Maven echouee.' }

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connection = $client.ConnectAsync('localhost', 4848)
        $running = $false
        try { $running = $connection.Wait(1000) -and $client.Connected } catch { $running = $false }
    } finally { $client.Dispose() }
    if (-not $running) {
        & $asadmin start-domain domain1
        if ($LASTEXITCODE -ne 0) { throw 'Demarrage Payara echoue.' }
    }

    $war = Join-Path $projectPath 'target/TP3Web-ALAMI_LOUATI_Ghali-1.0-SNAPSHOT.war'
    & $asadmin deploy --force=true --name TP3Web-ALAMI_LOUATI_Ghali --contextroot TP3Web-ALAMI_LOUATI_Ghali $war
    if ($LASTEXITCODE -ne 0) { throw 'Deploiement Payara echoue.' }
    Write-Host 'Application : http://localhost:8080/TP3Web-ALAMI_LOUATI_Ghali/'
} finally {
    $env:JAVA_HOME = $previousJavaHome
    $env:AS_JAVA = $previousAsJava
    Pop-Location
}
