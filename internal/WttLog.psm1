<#
.SYNOPSIS
WttLog wrappers for PowerShell tests 

.DESCRIPTION
Provides both thin wrappers around typical low level WTTLog commands, such as:
    * Start-WttLog, Stop-WttLog
    * Start-WttTest, Stop-WttTest
    * Write-WttLogMessage, Write-WttLogError

Also provides a few higher level abstractions designed to simplify test code:
    * Run-CommandAsWttTest
    * Run-WttTest

Requires that the wttlog.dll assembly be loadable (if WTT client and/or studio are installed, it is)

.EXAMPLE
Import-Module WttLog
Start-WttLog "MyCmdTests.wtl"
Invoke-CommandAsWttTest { mytest.exe -scenario 1 }
Invoke-CommandAsWttTest { mytest.exe -scenario 2 }
Stop-WttLog

.EXAMPLE
Import-Module WttLog
Start-WttLog "MyResilientTests.wtl"
Invoke-WttTest "scenario 1" -Setup {
    set-up
} -Test {
    set-something -value invalid -erroraction stop
} -Cleanup {
    tear-down
}
Stop-WttLog

.EXAMPLE
Import-Module WttLog
Start-WttLog "MyLessResilientTests.wtl"

Start-WttTest "Test 1"
Write-WttLogMessage "Just a message"
Write-WttLogError "Causes the test to fail"
Stop-WttTest

Start-WttTest "Test 2"
Stop-WttTest "Blocked"

Stop-WttLog
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$null = [Reflection.Assembly]::LoadWithPartialName("Microsoft.Wtt.Log")

$WttLogger = $null
$WttTestStatus = ""
$WttTestName = $null
$WttTestGuid = $null

$WttWriteHostColors = @{
   "Pass" = "DarkGreen";
   "Fail" = "DarkRed";
   "Blocked" = "DarkCyan";
   "Warn" = "Yellow";
   "Message" = "Black";
}

function Start-WttLog
{
    Param (
        [string]$FileName,

        [ValidateSet("overwrite","append")]
        [string]$WriteMode="overwrite",

        [switch]$PassThru
    )

    if ($script:WttLogger -ne $null) {
        throw "Already started WttLog"
    }
    try
    {
        # The TestLogger constructor requires an absolute path to use a quoted log file location
        # Since a user might input a FileName with spaces, we want to make sure we can always quote it
        # Thus, we always convert to an absolute path
        $AbsoluteFileName = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FileName)

        $script:WttLogger = New-Object Microsoft.DistributedAutomation.Logger.TestLogger "`$LocalPub(`$LogFile:file=`"$AbsoluteFileName`",WriteMode=$WriteMode)"
        $script:WttLogger.add_TestStarted({
            Write-Verbose ("Test Started: $($_ | Out-String)")
        })

        $script:WttLogger.add_TestEnded({
            Write-Verbose ("Test Ended: $($_ | Out-String)")
        })
        if ($PassThru) {
            $script:WttLogger
        }

        Write-WttLogMessage "Logging with WttLog.psm1 to $AbsoluteFileName"
        $script:WttLogger.TraceMachineInfo()
    }
    catch
    {
        Write-Host -BackgroundColor $WttWriteHostColors["Blocked"] "Failed to load WTTLogger"
        Write-Host -BackgroundColor $WttWriteHostColors["Blocked"] ($_ | Out-String)
    }
}



function Stop-WttLog()
{
    if ($script:WttLogger -eq $null) {
        throw "No WttLog is started"
    }

    Write-Host -BackgroundColor $WttWriteHostColors["Message"] "Ending Test Log"
    
    #auto-generated passed, warned, failed, blocked, and skipped counts
    #$rollup = New-Object Microsoft.DistributedAutomation.Logger.LevelRollup 0, 0, 0, 0, 0
    
    #$script:WttLogger.Trace($rollup) | Out-Null
    $script:WttLogger.Dispose() | Out-Null
    $script:WttLogger = $null
}



function Start-WttTest($name)
{
    if ($script:WttLogger -eq $null) {
        throw "No WttLog is started"
    }
    if ($script:WttTestName -ne $null) {
        throw "Already in WTTTest $script:WttTestName - cannot nest test cases"
    }

    Write-Host -BackgroundColor $WttWriteHostColors["Message"] "++++++++++++ Starting Test Case $name ++++++++++++`n"

    $script:WttTestStatus = "Pass"
    $script:WttTestGuid = ([GUID]::NewGUID().ToString())
    $script:WttTestName = $name
    if ($script:WttLogger)
    {
        $script:wttLogger.StartTest($script:wttTestName, $script:wttTestGuid, "") | Out-Null
    }
}

function Stop-WttTest($result = $script:wttTestStatus)
{
    if ($script:WttLogger -eq $null) {
        throw "No WttLog is started"
    }
    if ($script:WttTestName -eq $null) {
        throw "No WttTest is started"
    }

    Write-Host -BackgroundColor $WttWriteHostColors[$Result] "------------ Ending Test Case $script:wttTestName : $result ------------`n"

    $script:WttLogger.EndTest($script:WttTestName, $script:WttTestGuid, [Microsoft.DistributedAutomation.Logger.TestResult]$Result, $null)
    
    $script:WttTestName = $null
    $script:WttTestGuid = $null
}



function Write-WttLogError($Exception, [switch]$Fatal)
{
    if ($script:WttLogger -eq $null) {
        throw "No WttLog is started"
    }

    $ExceptionString = $Exception | Out-String

    Write-Host -BackgroundColor $WttWriteHostColors["Fail"] "****** ERROR: $ExceptionString"

    $script:WttTestStatus = "Fail"

    $TraceMessage = New-Object Microsoft.DistributedAutomation.Logger.LevelError $ExceptionString
    $script:WttLogger.Trace($TraceMessage) | Out-Null

    if ($Fatal) {
        throw $Exception
    }
}

function Write-WttLogMessage($Message)
{
    if ($script:WttLogger -eq $null) {
        throw "No WttLog is started"
    }

    $MessageString = $Message | Out-String

    Write-Host -BackgroundColor $WttWriteHostColors["Message"] $MessageString

    $TraceMessage = New-Object Microsoft.DistributedAutomation.Logger.LevelMessage $MessageString
    $script:WttLogger.Trace($TraceMessage) | Out-Null
}

function Write-WttLogWarning($Message)
{
    if ($script:WttLogger -eq $null) {
        throw "No WttLog is started"
    }

    $MessageString = $Message | Out-String

    Write-Host -BackgroundColor $WttWriteHostColors["Warn"] $MessageString

    $TraceMessage = New-Object Microsoft.DistributedAutomation.Logger.LevelWarning $MessageString
    $script:WttLogger.Trace($TraceMessage) | Out-Null
}

<#
.SYNOPSIS
Runs the command in the given script block as a WTT test, logging its output and succeeding based on its exit code
.EXAMPLE
Invoke-CommandAsWttTest { netsh wlan connect APEX-NETStress }
.EXAMPLE
Invoke-CommandAsWttTest -Name "netsh expecting failure" -SuccessExitCode 1 -Command { netsh wlan connect BADSSID }
#>
function Invoke-CommandAsWttTest {
    [CmdletBinding(DefaultParameterSetName="SuccessCode")]
    Param (
        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Command,

        [Parameter(Mandatory=$false)]
        [string]
        $Name = "",

        [Parameter(Mandatory=$false, ParameterSetName="SuccessCode")]
        [int[]]
        $SuccessExitCode = @(0),

        [Parameter(Mandatory=$false, ParameterSetName="FailureCode")]
        [int[]]
        $FailureExitCode = @(),

        [switch]
        $ExitOnFailure
    )

    if ($Name -eq "") {
        $Name = "$Command"
    }

    Start-WttTest $Name
    try {
        Write-WttLogMessage "Executing command: `"$Command`""

        $Output = & $Command
        $ExitCode = $LastExitCode

        Write-WttLogMessage $Output
        Write-WttLogMessage "Command completed with exit code $ExitCode"

        if ($PsCmdlet.ParameterSetName -eq "SuccessCode" -and $ExitCode -notin $SuccessExitCode) {
            Write-WttLogError "Exit code $ExitCode does not match expected success code(s): $SuccessExitCode"
        } elseif ($ExitCode -in $FailureExitCode) {
            Write-WttLogError "Exit code $ExitCode matches one of the expected failure code(s): $FailureExitCode"
        }
    } catch {
        Write-WttLogError "A powershell error occured while executing the command"
        Write-WttLogError $_
    }

    if ($ExitOnFailure -and $script:WttTestStatus -ne "Pass") {
        Stop-WttTest
        Stop-WttLog
        exit 3
    }

    Stop-WttTest
}

<#
.SYNOPSIS
Runs a WTTLogger test whose contents are the given script block, with reasonable exception handling
.DESCRIPTION
Runs a test case which can include user-defined setup logic and cleanup logic, handling any exceptions in either
the test code or the setup/cleanup code reasonably by ensuring that Stop-WttTest will always get called even in
terminating errors and that any errors (terminating or not) cause the test to be marked as "Fail" (or if in a setup/
cleanup block, "Blocked").

Using Run-Test absolves you of the need to call Start-WttTest and Stop-WttTest. You are still required to call
Start-WttLog and Stop-WttLog.

Within test or cleanup code, it is recommended that you use Write-WttLogError to indicate continuable test failures
and throw an exception to indicate a non-continuable test failure.
.EXAMPLE
Invoke-Test { Set-Something -Value "OughtToBeValid" }
.EXAMPLE
Invoke-Test "Validate Rename-NetAdapter" -Setup {
    if ((Get-TestAdapter) -eq $null) { throw "Could not find test adapter" }
} -Test {
    Get-TestAdapter | Rename-NetAdapter "Foolish name"
    if ((Get-TestAdapter).Name -ne "Foolish name") { Write-WttLogError "Couldn't rename adapter" }
} -Cleanup {
    Reset-TestAdapter
} -ExitOnFailure
#>
function Invoke-WttTest {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [string]
        $Name = "",

        [Parameter(Mandatory=$false)]
        [ScriptBlock]
        $Setup = $null,

        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Test,

        [Parameter(Mandatory=$false)]
        [ScriptBlock]
        $Cleanup = $null,

        [switch]
        $ExitOnFailure,

        [switch]
        $ContinueOnCleanupFailure
    )

    if ($Name -eq "") {
        $Name = "$Test"
    }
    $ExitAfterCleanup = $false

    Start-WttTest $Name

    if ($Setup -ne $null) {
        Write-WttLogMessage "--- Entering test setup"
        $Error.Clear()

        $SetupFailed = $false
        try {
            & $Setup
        } catch {
            Write-WttLogError "Test setup threw a terminating error"
            Write-WttLogError $_
            $SetupFailed = $true
        }

        if ($Error.Count -gt 0) {
            Write-WttLogError "Test setup generated $($Error.Count) non-terminating error(s)"
            $SetupFailed = $true
        }

        if ($SetupFailed) {
            Stop-WttTest "Blocked"
            return
        }

        Write-WttLogMessage "--- Completed test setup successfully"
    }

    $Error.Clear()
    $TestFailed = $false
    try {
        $Output = & $Test

        if ($Output -ne $null) {
            Write-WttLogMessage "Test completed with output: $Output"
        }
    } catch {
        Write-WttLogError "Test threw a terminating error"
        Write-WttLogError $_
        $TestFailed = $true
    }

    if ($Error.Count -gt 0) {
        Write-WttLogError "Test generated $($Error.Count) non-terminating error(s)"
        $TestFailed = $true
    }
    
    if ($TestFailed -and $ExitOnFailure) {
        if ($Cleanup -ne $null) {
            Write-WttLogMessage "Will exit test script after finishing test cleanup"
        }
        $ExitAfterCleanup = $true
    }

    $CleanupFailed = $false
    if ($Cleanup -ne $null) {
        Write-WttLogMessage "--- Entering test cleanup"
        $Error.Clear()

        try {
            & $Cleanup
        } catch {
            Write-WttLogError "Test cleanup threw a terminating error"
            Write-WttLogError $_
            $CleanupFailed = $true
        }

        if ($Error.Count -gt 0) {
            Write-WttLogError "Test cleanup generated $($Error.Count) non-terminating error(s)"
            $CleanupFailed = $true
        }
        
        if ($CleanupFailed) {
            Write-WttLogError "Future results may be invalid"

            if ($ContinueOnCleanupError) {
                Write-WttLogMessage "Continuing testing past cleanup failure"
                $script:WttTestStatus = "Blocked"
            } else {
                Write-WttLogMessage "Invoking fail-fast for entire test script"
                Stop-WttTest "Blocked"
                Stop-WttLog
                exit 2
            }
        } else {
            Write-WttLogMessage "--- Completed test cleanup successfully"
        }
    }

    Stop-WttTest
    if ($ExitAfterCleanup) {
        Write-WttLogMessage "Exiting test script due to fatal test error"
        Stop-WttLog
        exit 1
    }
}

Export-ModuleMember -Function @(
        "Start-WttLog",
        "Stop-WttLog",
        "Start-WttTest",
        "Stop-WttTest",
        "Write-WttLogMessage",
        "Write-WttLogError",
        "Write-WttLogWarning",
        "Invoke-WttTest",
        "Invoke-CommandAsWttTest"
    )