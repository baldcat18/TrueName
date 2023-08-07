using namespace System.Collections.Generic
using namespace System.IO

function Get-TrueName {
	<#
	.SYNOPSIS
	Get the true name of a file or directory.
	.DESCRIPTION
	Gets the true name of the filename that you get by following symbolic links, network drive, virtual drives created using the SUBST command.
	.PARAMETER Path
	Specifies the path to one or more files or directorys for which you want to get the true names.
	Wildcard characters are permitted.
	.PARAMETER LiteralPath
	Specifies the path to one or more files or directorys for which you want to get the true names.
	The value of LiteralPath is used exactly as it's typed. No characters are interpreted as wildcards.
	.INPUTS
	System.Object
		You can pipe a string that contains a path to this function.
	.OUTPUTS
	System.String
	.EXAMPLE
	PS> Get-TrueName "C:\Users\All Users\Application Data\Microsoft"
	.EXAMPLE
	PS> net.exe use Z: \\localhost\C$\Windows
	PS> Get-TrueName Z:\System32
	#>
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	[OutputType([string])]
	param (
		[Parameter(ParameterSetName = 'Path', Mandatory,
			ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
		[string[]]$Path,
		[Parameter(ParameterSetName = 'LiteralPath', ValueFromPipelineByPropertyName, Mandatory)]
		[Alias('PSPath')]
		[string[]]$LiteralPath
	)

	begin {
		$ErrorActionPreference = 'Stop'
		$fileSystemProvider = Get-PSProvider FileSystem

		if ($PSVersionTable['PSVersion'].Major -le 5 -or $IsWindows) {
			$driveRoot = @{}
			Get-CimInstance Win32_MappedLogicalDisk | ForEach-Object { $driveRoot[$_.Name] = $_.ProviderName }

			subst.exe | ForEach-Object {
				$t = $_ -split '\\: => '
				$driveRoot[$t[0]] = $t[1]
			}
		}
	}

	process {
		try {
			$pathInFo = Resolve-Path @PSBoundParameters
		} catch {
			$PSCmdlet.WriteError($_)
			return
		}

		$pathInFo | ForEach-Object {
			try {
				$providerPath = $_.ProviderPath
				if ($_.Provider -ne $fileSystemProvider) {
					return $providerPath
				}

				# Windows Virtual Drive
				if ($_.Drive) {
					$drive = "$($_.Drive.Name):"
					if ($driveRoot.ContainsKey($drive)) {
						return Get-TrueName -LiteralPath $providerPath.Replace($drive, $driveRoot[$drive])
					}
				}

				# Soft Link
				$currrent = $providerPath
				$pathStack = [List[string]]::new()
				for (; ; ) {
					$info = Get-Item -LiteralPath $currrent -Force
					if (isSoftlink $info) {
						$target = $info.ResolvedTarget
						if (!$target) {
							$target = $info.Target
							if (!(Split-Path $target -IsAbsolute)) {
								$target = "$((Resolve-Path -LiteralPath $currrent).ProviderPath)/../$target"
							}
						}
						$pathStack.Reverse()
						return Get-TrueName -LiteralPath $("$target/$($pathStack -join '/')" -replace '/$')
					}
					if (!$info.Directory -and !$info.Parent) { break }
					$pathStack.Add($info.Name)
					$currrent = Split-Path -LiteralPath $currrent
				}

				return $providerPath
			} catch {
				$PSCmdlet.WriteError($_)
			}
		}
	}
}

function isSoftlink {
	[OutputType([bool])]
	param ([FileSystemInfo]$info)

	switch ($info.LinkType) {
		SymbolicLink { return $true }
		AppExeCLink { return $true }
		Junction {
			$target = $info.Target
			if ($target -is [array]) { $target = $target[0] } # for PowerShell5.1
			$mountpointPattern = '^Volume\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\}\\$'
			return $target -notmatch $mountpointPattern
		}
		Default { return $false }
	}
}
