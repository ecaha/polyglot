@{
    RootModule        = 'ModuleScenario.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '9b63f4d2-86d0-4d8e-bb8c-d0717fed2627'
    Author            = 'polyglot'
    CompanyName       = 'polyglot'
    Copyright        = "(c) 2026 polyglot. All rights reserved."
    Description       = 'Minimal module scaffolding for infrastructure utilities.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @('Get-OpsDiskUtil', 'Get-OpsComputerUtilization', 'Get-OpsComputerUtilizationReport')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{}
}
