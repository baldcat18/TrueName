@{
	ModuleVersion = '1.0.0'
	GUID = 'f07ca9b5-548c-435a-80d2-7e986ff12a42'
	Author = 'BaldCat'
	Copyright = '(c) 2023 BaldCat. All rights reserved.'
	Description = 'Gets the true name of the filename that you get by following symbolic links, network drive, virtual drives created using the SUBST command.'
	PowerShellVersion = '5.1'
	CompatiblePSEditions = @('Core', 'Desktop')
	RootModule = 'TrueName.psm1'
	FunctionsToExport = @('Get-TrueName')
	CmdletsToExport = @()
	AliasesToExport = @()
	PrivateData = @{
		PSData = @{
			Tags = @('File', 'Directory', 'FileSystem')
		}
	}
}
