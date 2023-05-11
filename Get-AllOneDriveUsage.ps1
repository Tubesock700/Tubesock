
# This script will find all OneDrives in your Tenant that are owned by a single user
# and display the results in the console, along with adding them to a CSV on the user's
# desktop that ran the script.
# It will also gather homeDirectory sizes if requested and compare usage to OneDrive.
# Example: 
#  Get-AllOneDrives -tenanturl "tenant url here" -homeDriveCheck $true
# Note - you will need to run the script as an Admin Account that has access to all of the
# user home directories
param (
	[Parameter(Mandatory = $true)]
	$tenanturl,
	[Parameter(Mandatory = $false)]
	[ValidateSet($True, $False)]
	$homeDriveCheck = $false
	
)
$date = Get-Date -f "MM_dd_HH_mm"
Connect-SPOService -URL $tenanturl
$outFile = [Environment]::GetFolderPath("Desktop") + "\$date OneDriveSites.csv"
$Sites = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "URL -like '-my.sharepoint.com/'" | Sort-Object Title
$results = @()
Try
{
	foreach ($s in $Sites)
	{
		[string]$name = $s.Title
		
		if ($name -match '['']')
		{
			$name = ""
			[string]$name1 = $name.split("''")[0]
			[string]$apostrophe = "`'`'"
			[string]$name2 = $name.split("''")[1]
			$name = $name1 + $apostrophe + $name2
		}
		elseif ($name.length -lt 2)
		{
			Write-Host -ForegroundColor Yellow -BackgroundColor Red "No Title, skipping."
			continue
		}
		if ($homeDriveCheck)
		{
			$ADAccount = Get-ADUser -Filter { DisplayName -like $name } -Properties DisplayName, homeDirectory -ErrorAction Continue | ?{ $_.homeDirectory.length -gt 2 }
			
			if ($ADAccount.Enabled -eq $false)
			{
				Write-Host -ForegroundColor Yellow -BackgroundColor Red "$($s.Title) is disabled, skipping."
				$results += [pscustomobject] @{
					Owner				   = $s.Owner
					OneDrive_Address	   = $s.Url
					OwnerName			   = $s.Title
					OneDriveUsed		   = "Disabled User"
					HomeDirectoryLocation  = "Disabled User"
					HomeDirectory_Usage_GB = "Disabled User"
				}
			}
			else
			{
				Write-Host -ForegroundColor Blue -BackgroundColor Black "Working on $Name"
				$xDriveSize = 0
				$size = 0
				[string]$path = $ADAccount.homeDirectory
				if ($path.length -lt 3)
				{
					$results += [pscustomobject] @{
						Owner				   = $s.Owner
						OneDrive_Address	   = $s.Url
						OwnerName			   = $s.Title
						OneDrive_Usage_GB	   = $name
						HomeDirectoryLocation  = $path
						HomeDirectory_Usage_GB = "Returned No X Drive"
					}
				}
				else
				{
					Get-ChildItem -Path $path -Recurse -ErrorAction Continue | %{ $size += $_.Length }
					$xDriveSize = [System.Math]::Round($size /1gb, 2)
					Write-Host -ForegroundColor Green -BackgroundColor Black "Xdrive size: $xDriveSize"
					$OneDriveSize = [System.Math]::Round(([int]($s.StorageUsageCurrent /1024)), 2)
					Write-Host -ForegroundColor Green -BackgroundColor Black "OneDrive size: $OneDriveSize"
					$results += [pscustomobject] @{
						Owner				   = $s.Owner
						OneDrive_Address	   = $s.Url
						OwnerName			   = $s.Title
						OneDrive_Usage_GB	   = $OneDriveSize
						HomeDirectoryLocation  = $ADAccount.HomeDirectory
						HomeDirectory_Usage_GB = $xDriveSize
					}
				}
			}
		}
		else
		{
			$ADAccount = Get-ADUser -Filter { DisplayName -like $name } -Properties DisplayName -ErrorAction Continue
			
			
			if ($ADAccount.Enabled -eq $false)
			{
				Write-Host -ForegroundColor Yellow -BackgroundColor Red "$($s.Title) is disabled, skipping."
				$results += [pscustomobject] @{
					Owner			  = $s.Owner
					OneDrive_Address  = $s.Url
					OwnerName		  = $s.Title
					OneDrive_Usage_GB = "Disabled User"
				}
			}
			else
			{
				Write-Host -ForegroundColor Blue -BackgroundColor Black "Working on $Name"
				$OneDriveSize = [System.Math]::Round(([int]($s.StorageUsageCurrent /1024)), 2)
				Write-Host -ForegroundColor Green -BackgroundColor Black "OneDrive size: $OneDriveSize"
				$results += [pscustomobject] @{
					Owner			  = $s.Owner
					OneDrive_Address  = $s.Url
					OwnerName		  = $s.Title
					OneDrive_Usage_GB = $OneDriveSize
				}
			}
		}
	}
}
catch
{
	Write-Error $_.Exception
}
Disconnect-SpoService
$results | Export-Csv $outFile -NoTypeInformation
# SIG # Begin signature block
# MIIiVQYJKoZIhvcNAQcCoIIiRjCCIkICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCTlk7TqvMfTmzY
# WQS0gjmm8Fn8aFiyHjLdHcP9Vqdu86CCHJ4wggOiMIICiqADAgECAhAnbesb5ey5
# kEtNwHkupT0bMA0GCSqGSIb3DQEBCwUAMFkxEzARBgoJkiaJk/IsZAEZFgNnb3Yx
# EzARBgoJkiaJk/IsZAEZFgNuZXQxEzARBgoJkiaJk/IsZAEZFgNhZGExGDAWBgNV
# BAMTD0FEQUNFUlQtQ0EtUm9vdDAeFw0xNjExMTUyMTE5NDNaFw0yNjExMTUyMTI5
# NDNaMFkxEzARBgoJkiaJk/IsZAEZFgNnb3YxEzARBgoJkiaJk/IsZAEZFgNuZXQx
# EzARBgoJkiaJk/IsZAEZFgNhZGExGDAWBgNVBAMTD0FEQUNFUlQtQ0EtUm9vdDCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALGWWm7LUy8Y7ZOZU73u9GG0
# irKCw7byG71Gp4Qm0bO2A8/neBZhwTYPsV77imH0IS02DN8dEwy8vA0PHnVCOB5P
# t6gAG/grUlQrhn4cnn0CmO8zqRhW6X+onIjPIlsj3VyEKxpXpgLjo0Zr4xZv13sO
# dFINPVY3S6KUpS6avTs7pCoFpvwdfu0ypUHWETVSmE3K290UQo7KyTKsITxh5m2G
# PPJh5aSauz0WakInQLS4WfKGw58Ca96Q2t6baAswDOBEgZ7QauN8BiTyX4P/twhS
# 61D57cX1Rbi8Kagr8hda/0SgIivo3RpYnAI9TtqXyIGiIU33e6Tb0i2Gpe/A2ScC
# AwEAAaNmMGQwEwYJKwYBBAGCNxQCBAYeBABDAEEwCwYDVR0PBAQDAgGGMA8GA1Ud
# EwEB/wQFMAMBAf8wHQYDVR0OBBYEFGVXWtRfVLVXP01VUs8A/sgVYv2IMBAGCSsG
# AQQBgjcVAQQDAgEAMA0GCSqGSIb3DQEBCwUAA4IBAQATauePe6EXqZNKBU1gHf57
# l3ZZkSJ/UGIxWVMJcumHjYuvX21JL42clBMvAZlF4s5eHQ4hjCSuBRl7j4a5qR42
# q5mHrmy+NeRINlo7JqqTUomDCeYiOWMAYk6TOYq1ZF4QMltiiznt+JMGEGXxvHpd
# KSLbVTi8lzIu6H4bO3AaET2GTMniMX3z0utjEpWv/+SHq0fDlzZRwqNJRbTJgT+R
# I9J9LUjDDISQFfjOrRpev0yyTTjv/jHA20rTgm7oMMjMlG2ToipENSWsuyOtrdHj
# aJzA8mrxVTuzp5p9frlDw03zyo5OT/5VxELR6xY7GEJzypBn0IEUSfk6oNpC0LqI
# MIIFjTCCBHWgAwIBAgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBl
# MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
# d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJv
# b3QgQ0EwHhcNMjIwODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7J
# IT3yithZwuEppz1Yq3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxS
# D1Ifxp4VpX6+n6lXFllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb
# 7iDVySAdYyktzuxeTsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1ef
# VFiODCu3T6cw2Vbuyntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoY
# OAMQjdjUN6QuBX2I9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSa
# M0C/CNdaSaTC5qmgZ92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI
# 8OCiEhtmmnTK3kse5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9L
# BADMfRyVw4/3IbKyEbe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfm
# Q6QYuKZ3AeEPlAwhHbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDr
# McXKchYiCd98THU/Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15Gkv
# mB0t9dmpsh3lGwIDAQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
# FgQU7NfjgtJxXWRM3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGL
# p6chnfNtyA8wDgYDVR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEF
# BQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRw
# Oi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0Eu
# Y3J0MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0G
# CSqGSIb3DQEBDAUAA4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6p
# Grsi+IcaaVQi7aSId229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1W
# z/n096wwepqLsl7Uz9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp
# 8jQ87PcDx4eo0kxAGTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglo
# hJ9vytsgjTVgHAIDyyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8S
# uFQtJ37YOtnwtoeW/VvRXKwYw02fc7cBqZ9Xql4o4rmUMIIF7TCCBNWgAwIBAgIT
# FAAAY5LdSIW7cyud+wAAAABjkjANBgkqhkiG9w0BAQsFADBZMRMwEQYKCZImiZPy
# LGQBGRYDZ292MRMwEQYKCZImiZPyLGQBGRYDbmV0MRMwEQYKCZImiZPyLGQBGRYD
# YWRhMRgwFgYDVQQDEw9BREFDRVJULUNBLVJvb3QwHhcNMjIwOTA2MTMzNzA0WhcN
# MjQwOTA1MTMzNzA0WjB4MQswCQYDVQQGEwJVUzELMAkGA1UECBMCSUQxDjAMBgNV
# BAcTBUJvaXNlMRMwEQYDVQQKEwpBZGEgQ291bnR5MQswCQYDVQQLEwJJVDEqMCgG
# A1UEAxMhUG93ZXJzaGVsbCBTaWduaW5nIGZvciBBZGEgQ291bnR5MIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5lPSnRL+rXcINAcuWZhrBzOuzzvibKMr
# UTlPgXSiwBM07xfZlX/qZU/L3Z3Rhr0wIlU+HiJrEg8+vFJvZOXscvVxRtBQblyd
# d2aqCoxsw1+7VdRvDmo92v9Cjsqi7+05TiI0sP3Tis2/cZx8i+B+G48vVdEnE9bH
# PI0+9vXSTvUDnnPu6GQAQyyAwKwICj9nkCMkOnQ86yk8rwU6j08j9mwRkTMLpyc/
# 7VP6RcdbZv45t14pKRBEAXoTLDj6SwFf01tgUE0QuKJ9XaoopwTMSzOud2k7aio8
# uk4c0stW7jAHJmr19QP2FUx2PJRtgu/Eie+ySGNTiuC2gaCFNpwUQQIDAQABo4IC
# jTCCAokwPQYJKwYBBAGCNxUHBDAwLgYmKwYBBAGCNxUIhuKJD4SCuyKB6ZUZhdH5
# NYOnnEhBhauaPofv70ACAWUCAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0P
# AQH/BAQDAgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYE
# FJQedBoxr/mkS8+iOcRvhkruyWA6MB8GA1UdIwQYMBaAFGVXWtRfVLVXP01VUs8A
# /sgVYv2IMIHQBgNVHR8EgcgwgcUwgcKggb+ggbyGgblsZGFwOi8vL0NOPUFEQUNF
# UlQtQ0EtUm9vdCxDTj1BREFDZXJ0LENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBT
# ZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWFkYSxEQz1u
# ZXQsREM9Z292P2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RD
# bGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDCB8gYIKwYBBQUHAQEEgeUwgeIwgbEG
# CCsGAQUFBzAChoGkbGRhcDovLy9DTj1BREFDRVJULUNBLVJvb3QsQ049QUlBLENO
# PVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3Vy
# YXRpb24sREM9YWRhLERDPW5ldCxEQz1nb3Y/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29i
# amVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwLAYIKwYBBQUHMAGGIGh0
# dHBzOi8vYWRhY2VydC5hZGEubmV0Lmdvdi9vY3NwMA0GCSqGSIb3DQEBCwUAA4IB
# AQBHfltfVGaqHA2vJltStQcL74yFn16GqpYSIC1+wfj/cEBGp0HVIhDltpui0DUy
# LsG2EYLh1uU9Nz1ePGLit0+0YlcMzvKUL4uNORSNIsAdPNyoQzPebfChY025I0tb
# CcfgWVizgjYRfLF5zEEkt5u0mx8gGDukjjrQ7/XeaLJqLJEy/HmwTEV8XF9ORZQ3
# e/vDRJKOlxINYoXEOw+FBfejjBBNGIJN7L3wVRi+lluuRe1VtBkNbtFQSQ5Dr3Be
# 8BEfOTxkZrv6AKlpEvrxlUb8HCWezjaB0NEHUb3qe1ohE0dvKk+xjSJTdqazYYzF
# omivun5npx3OC9N27d/eZHGPMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipe
# WzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1
# OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5
# BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0
# YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1Bkmz
# wT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkL
# f50fng8zH1ATCyZzlm34V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C
# 3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5
# n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUd
# zTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWH
# po9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/
# oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPV
# A+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg
# 0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mM
# DDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6E
# VO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1Ud
# IwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0f
# BDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcB
# MA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBT
# zr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/E
# UExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fm
# niye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szw
# cqMj+sAngkSumScbqyQeJsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8TH
# wcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/
# JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9
# Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm
# 228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVB
# tzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnw
# ZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv2
# 7dZ8/DCCBsAwggSooAMCAQICEAxNaXJLlPo8Kko9KQeAPVowDQYJKoZIhvcNAQEL
# BQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQTAeFw0yMjA5MjEwMDAwMDBaFw0zMzExMjEyMzU5NTlaMEYxCzAJBgNV
# BAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDEkMCIGA1UEAxMbRGlnaUNlcnQgVGlt
# ZXN0YW1wIDIwMjIgLSAyMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# z+ylJjrGqfJru43BDZrboegUhXQzGias0BxVHh42bbySVQxh9J0Jdz0Vlggva2Sk
# /QaDFteRkjgcMQKW+3KxlzpVrzPsYYrppijbkGNcvYlT4DotjIdCriak5Lt4eLl6
# FuFWxsC6ZFO7KhbnUEi7iGkMiMbxvuAvfTuxylONQIMe58tySSgeTIAehVbnhe3y
# YbyqOgd99qtu5Wbd4lz1L+2N1E2VhGjjgMtqedHSEJFGKes+JvK0jM1MuWbIu6pQ
# OA3ljJRdGVq/9XtAbm8WqJqclUeGhXk+DF5mjBoKJL6cqtKctvdPbnjEKD+jHA9Q
# Bje6CNk1prUe2nhYHTno+EyREJZ+TeHdwq2lfvgtGx/sK0YYoxn2Off1wU9xLokD
# EaJLu5i/+k/kezbvBkTkVf826uV8MefzwlLE5hZ7Wn6lJXPbwGqZIS1j5Vn1TS+Q
# Hye30qsU5Thmh1EIa/tTQznQZPpWz+D0CuYUbWR4u5j9lMNzIfMvwi4g14Gs0/EH
# 1OG92V1LbjGUKYvmQaRllMBY5eUuKZCmt2Fk+tkgbBhRYLqmgQ8JJVPxvzvpqwcO
# agc5YhnJ1oV/E9mNec9ixezhe7nMZxMHmsF47caIyLBuMnnHC1mDjcbu9Sx8e47L
# ZInxscS451NeX1XSfRkpWQNO+l3qRXMchH7XzuLUOncCAwEAAaOCAYswggGHMA4G
# A1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAW
# gBS6FtltTYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUYore0GH8jzEU7ZcLzT0q
# lBTfUpwwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNy
# bDCBkAYIKwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAgEAVaoqGvNG83hXNzD8deNP1oUj8fz5lTmb
# Jeb3coqYw3fUZPwV+zbCSVEseIhjVQlGOQD8adTKmyn7oz/AyQCbEx2wmIncePLN
# fIXNU52vYuJhZqMUKkWHSphCK1D8G7WeCDAJ+uQt1wmJefkJ5ojOfRu4aqKbwVNg
# CeijuJ3XrR8cuOyYQfD2DoD75P/fnRCn6wC6X0qPGjpStOq/CUkVNTZZmg9U0rIb
# f35eCa12VIp0bcrSBWcrduv/mLImlTgZiEQU5QpZomvnIj5EIdI/HMCb7XxIstiS
# DJFPPGaUr10CU+ue4p7k0x+GAWScAMLpWnR1DT3heYi/HAGXyRkjgNc2Wl+WFrFj
# DMZGQDvOXTXUWT5Dmhiuw8nLw/ubE19qtcfg8wXDWd8nYiveQclTuf80EGf2JjKY
# e/5cQpSBlIKdrAqLxksVStOYkEVgM4DgI974A6T2RUflzrgDQkfoQTZxd639ouiX
# dE4u2h4djFrIHprVwvDGIqhPm73YHJpRxC+a9l+nJ5e6li6FV8Bg53hWf2rvwpWa
# SxECyIKcyRoFfLpxtU56mWz06J7UWpjIn7+NuxhcQ/XQKujiYu54BNu90ftbCqhw
# fvCXhHjjCANdRyxjqCU4lwHSPzra5eX25pvcfizM/xdMTQCi2NYBDriL7ubgclWJ
# LCcZYfZ3AYwxggUNMIIFCQIBATBwMFkxEzARBgoJkiaJk/IsZAEZFgNnb3YxEzAR
# BgoJkiaJk/IsZAEZFgNuZXQxEzARBgoJkiaJk/IsZAEZFgNhZGExGDAWBgNVBAMT
# D0FEQUNFUlQtQ0EtUm9vdAITFAAAY5LdSIW7cyud+wAAAABjkjANBglghkgBZQME
# AgEFAKBMMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMC8GCSqGSIb3DQEJBDEi
# BCAlj+vp/jQ9fjl/R1v7JIkDX7toFiXX456MFpgeadsm9DANBgkqhkiG9w0BAQEF
# AASCAQAblGhmMsDBb5iaQd/dyNf4KuIHwVylq4Cv+65zIREJ6UC2D5WoVqbsuA0H
# mvlktMh9P19dQTWW/f39QlHDdXzIoqEKZZwCg0wzViP0DldyK+fJ5u5YjRXgpF0i
# zpektSCzD87vYUEvigKk+WfF4vVutY3HPimBqSgmvXWK/8+seoOhSe5JtaNYCk/1
# 69q9jir6z8IDPFufJUTi30kJkjF0wwZeBkoOJhO5e5kf77BDLe6dfbOKshNVlZDH
# Xw1lkBR+SEE11u3QEMGqL0BiaTv9XjfBIGT9s09Hlz6xUApfT8Czl2LBnqITHySU
# cazQimccNkD17i5dN9FoDFkDr8/doYIDIDCCAxwGCSqGSIb3DQEJBjGCAw0wggMJ
# AgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTsw
# OQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVT
# dGFtcGluZyBDQQIQDE1pckuU+jwqSj0pB4A9WjANBglghkgBZQMEAgEFAKBpMBgG
# CSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIzMDUxMTIx
# MTgwNFowLwYJKoZIhvcNAQkEMSIEINWuQ+4V9YKUI0KCgMU+Om48rWsL7TX5FpQM
# xrPRUt9YMA0GCSqGSIb3DQEBAQUABIICAGdHhw+SrmtubduESFP5EnZ6oLlvGaQQ
# n3zpI4EanwBlZosLVKNrQxFQABqT4HKXsWfhBJWNPO21D9Y/rIn5B5iscSBIh5yq
# MsdtGxWIKCBhj9viGQy0So6QDK0r+tJviJvqnkr/HzJatEQjJ3kfvLaCuEWVxPhO
# CyOrdlxZfHHGKA7BsqDz26tMgw8g9e2U8ZxMg1INvmIAKRCJjdk0BkVeLUEP+LFR
# GpajiQzTb4rWeOF5G2ZAxuM+QmaFcsr3JAJggE2mNf+WZ69jwf2K54Gt0uldRCOD
# e0X+DUrKjmcFeeiX27wIzbf5okEKagc2l1cXnOjwBQVezgBAaRCsqcQC4PJXd+/l
# mLSnLzKmyFpd2+QxxQvfzy/QpgrBqsjFmWgfBMPwyCMzvdGLxpav56lapde7dm+V
# aMgBR30NewJUrZJSiUvAl7gS1VljsNQ/AtYWjLURkMCHum2VsR625nwTye7qD/0N
# FCLftrahAys8X0HXT41InolLih5KrUiPj9A5j1DorCckm9AEid32HNWxDuTy8Msj
# hdvAX3NqIB4Sc5+hABdRf2aVOB/xj6IBhl/3eVjzIFrm7dBXqm8qyyHqZ0dsTesv
# IfFc6aY/tAeDAC4HId2QG4MwPYurHZWKLZCgFsAjXYO+//bQ8BFUoW+4JrbtfbkI
# 0Rww9OfTtgmt
# SIG # End signature block
