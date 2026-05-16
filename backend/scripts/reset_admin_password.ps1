# Met a jour le compte admin (1er utilisateur ADMIN) : username + mot de passe depuis .env
$ErrorActionPreference = "Stop"
$Backend = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $Backend ".env"
if (-not (Test-Path $envFile)) { Write-Error "backend\.env introuvable" }

$vars = @{}
Get-Content $envFile | ForEach-Object {
  if ($_ -match '^\s*([^#=]+)=(.*)$') { $vars[$Matches[1].Trim()] = $Matches[2].Trim() }
}
$user = $vars['ADMIN_USERNAME']
$pass = $vars['ADMIN_PASSWORD']
if (-not $user -or -not $pass) { Write-Error "ADMIN_USERNAME et ADMIN_PASSWORD requis dans .env" }

Set-Location $Backend
$hash = node -e "require('bcrypt').hash(process.argv[1], 10).then(h=>console.log(h))" $pass
$pgPass = $vars['DATABASE_PASSWORD']
if (-not $pgPass) { $pgPass = 'postgres' }
$env:PGPASSWORD = $pgPass
$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
$db = $vars['DATABASE_NAME']
if (-not $db) { $db = 'alfakhir' }

$sql = @"
UPDATE users u
SET username = '$($user.Replace("'","''"))',
    password_hash = '$hash'
FROM roles r
WHERE u.role_id = r.id AND r.name = 'ADMIN'
  AND u.id = (
    SELECT u2.id FROM users u2
    INNER JOIN roles r2 ON u2.role_id = r2.id
    WHERE r2.name = 'ADMIN'
    ORDER BY u2."createdAt" ASC
    LIMIT 1
  );
"@
& $psql -U postgres -h localhost -d $db -c $sql
Write-Host "Compte admin mis a jour : $user" -ForegroundColor Green
