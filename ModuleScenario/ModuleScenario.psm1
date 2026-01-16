# Load private helpers first (not exported) so they are available to public commands.
$privateFunctionFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Private") -Filter *.ps1 -ErrorAction SilentlyContinue
foreach ($file in $privateFunctionFiles) {
    . $file.FullName
}

# Load public functions so the module can export them.
$publicFunctionFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "Public") -Filter *.ps1 -ErrorAction SilentlyContinue
foreach ($file in $publicFunctionFiles) {
    . $file.FullName
}

if ($publicFunctionFiles) {
    Export-ModuleMember -Function $publicFunctionFiles.BaseName
}
