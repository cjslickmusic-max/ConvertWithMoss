# Inline sample-progress hooks for patched ConvertWithMoss AbstractDetector.java
param(
  [Parameter(Mandatory = $true)]
  [string]$DetectorPath
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $DetectorPath)) { throw "Missing $DetectorPath" }

$text = Get-Content -LiteralPath $DetectorPath -Raw
if ($text -match 'machineProgressSamplesInFile') {
  Write-Host "[ok] sample progress already present"
  exit 0
}

$text = $text -replace '(private int\s+machineProgressDone\s+=\s+0;\r?\n)', "`$1`r`n    /** Samples (zones) processed inside the current instrument file (RUS per-sample progress). */`r`n    private int                               machineProgressSamplesInFile        = 0;`r`n`r`n"
$text = $text -replace '(if \(MachineProgressReporter\.isEnabled \(\)\)\r?\n\s+\{\r?\n)(\s+// Per-file pct)', "`$1                    this.machineProgressSamplesInFile = 0;`r`n`r`n`$2"

$within = @'

    /** Within-file pct while samples are loaded (unknown total -> asymptotic toward fileHi-1). */
    private int calcMachineProgressPercentWithinCurrentFile ()
    {
        if (this.machineProgressTotal <= 0)
            return this.machineProgressDone > 0 ? 100 : 0;

        final int fileLo = (int) (this.machineProgressDone * 100L / (long) this.machineProgressTotal);
        final int fileHi = Math.min (100, (int) ((this.machineProgressDone + 1L) * 100L / (long) this.machineProgressTotal));
        if (fileHi <= fileLo + 1)
            return Math.min (99, fileLo + 1);

        final double span = (double) (fileHi - 1 - fileLo);
        final double t = 1.0 - Math.exp (-this.machineProgressSamplesInFile / 25.0);
        return fileLo + (int) Math.round (span * t);
    }

'@

$text = $text -replace '(private int calcMachineProgressPercentAfterFinishingCurrentFile \(\)\r?\n\s+\{\r?\n\s+return this\.calcMachineProgressPercent \(\);\r?\n\s+\}\r?\n)', "`$1`r`n$within"

$createZone = @'
protected ISampleZone createSampleZone (final File sampleFile) throws IOException
    {
        final ISampleZone zone = new DefaultSampleZone (FileUtils.getNameWithoutType (sampleFile),
            createSampleData (sampleFile, this.notifier));

        if (MachineProgressReporter.isEnabled ())
        {
            ++this.machineProgressSamplesInFile;
            MachineProgressReporter.report (this.calcMachineProgressPercentWithinCurrentFile (),
                "sample", sampleFile.getName ());
        }

        return zone;
    }
'@

$text = $text -replace 'protected ISampleZone createSampleZone \(final File sampleFile\) throws IOException\r?\n\s+\{\r?\n\s+return new DefaultSampleZone \(FileUtils\.getNameWithoutType \(sampleFile\), createSampleData \(sampleFile, this\.notifier\)\);\r?\n\s+\}', $createZone

Set-Content -LiteralPath $DetectorPath -Value $text -NoNewline
Write-Host "[inline] sample progress hooks applied"
