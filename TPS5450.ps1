param(
    [double]$inputVoltage = 24.0,       #default input voltage
    [double]$outputVoltage = 5.0,       #default output voltage
    [double]$loadCurrent = 5.0,         #default load current
    [double]$inputRippleVoltage = 0.6,  # Default 0.6 if not specified
    [int]$NC = 3,                       # Number of output capacitors in parallel
    [double]$CoutDerating = 1.25,       # Derating factor (default 1.25x)
    [double]$CF1 = 10e-6,               # Input filter capacitor CF1 (default 10 uF)
    [double]$efficiency = 0.82,         # Efficiency (default 82%)
    [double]$Qf = 1.0,                  # Quality factor (default 1.0)
    [string]$OutputFile = "TPS5450_Results.txt"  # Output file name
)

# Helper function to write to both console and file, with optional file-only details
function Write-Result {
    param(
        [string]$text,
        [string]$color = "White",
        [string]$fileDetail = $null
    )
    if ($color -ne "None") {
        Write-Host $text -ForegroundColor $color
    }
    else {
        Write-Host $text
    }
    Add-Content -Path $OutputFile -Value $text
    if ($fileDetail) {
        Add-Content -Path $OutputFile -Value $fileDetail
    }
}

# Clear output file at start
Set-Content -Path $OutputFile -Value "TPS5450 Design Calculations Results`r`n####################################################################"

Write-Result "" "None"
Write-Result "--- Calculation Descriptions ---" "White"
# Calculation Descriptions
Write-Result "Feedback Resistors: Sets output voltage using a resistor divider (Vout = 1.221V * (1 + R1/R2))." "Cyan"
Write-Result "Inductor: Sets current ripple and affects transient response (L = (Vout * (Vin - Vout)) / (Vin * dIL * Fsw))." "Green"
Write-Result "Output Capacitor: Sets output voltage ripple, stability, and transient response. Includes ESR, ripple current, and voltage rating checks." "Yellow"
Write-Result "Input Capacitor: Reduces input voltage ripple and supplies current during switching." "Yellow"
Write-Result "Catch Diode: Provides current path during switch-off, must meet voltage/current/power specs." "Magenta"
Write-Result "Output Voltage Limits: Device constraints based on duty cycle, diode drop, and inductor DCR." "DarkYellow"
Write-Result "Power Dissipation: Estimates device self-heating for thermal design." "Red"

# TPS5450 DC-DC Converter Calculations
# Reference: TI TPS5450 Datasheet

$Vref = 1.221
$R1 = 10000  # 10kΩ hard coded
$R2 = [math]::Round($R1 / (($outputVoltage / $Vref) - 1), 0)
Write-Result "" "None"
Write-Result "-- Feedback Resistor Calculation --"
Write-Result "Feedback Resistors: R1 = $R1 ohms (fixed), R2 = $R2 ohms" "Cyan" "    Formula: Vout = Vref * (1 + R1/R2)
    Vref = $Vref V
    R1 = $R1 ohms (fixed)
    R2 = $R2 ohms (calculated)
    Vout = $outputVoltage V (target)"

# 2. Inductor Selection (L = (Vout * (Vin - Vout)) / (Vin * ΔIL * Fsw))
$Fsw = 500000  # 500kHz switching frequency
$deltaIL = 0.3 * $loadCurrent  # 30% ripple current
$L = ($outputVoltage * ($inputVoltage - $outputVoltage)) / ($inputVoltage * $deltaIL * $Fsw)
$L_uH = [math]::Round($L * 1e6, 0)
Write-Result "" "None"
Write-Result "-- Inductor Selection --"
Write-Result "Min value for Inductor: $L_uH uH (choose standard value or higher)" "Green" "    Formula: L = (Vout * (Vin - Vout)) / (Vin * dIL * Fsw)
    Vout = $outputVoltage V
    Vin = $inputVoltage V
    dIL = $deltaIL A (30% of load current)
    Fsw = $Fsw Hz
    L = $([math]::Round($L*1e6,3)) uH (calculated)"


# 3. Output Capacitor Selection (Cout = 1/(3357 * Lout * fco * Vout))

$fco = 20000  # Default crossover frequency, user can adjust as needed
if (($L -ne 0) -and ($fco -ne 0) -and ($outputVoltage -ne 0)) {
    $Cout = 1 / (3357 * $L * $fco * $outputVoltage)
    $Cout_uF = [math]::Round($Cout * 1e6, 1)
}
else {
    $Cout = 0
    $Cout_uF = 0
}

# Output Capacitor Design Factors
# 1. DC Voltage Rating (datasheet: Vout + 0.5*rippleV, then apply derating)
$Cout_Vdc_min = $outputVoltage
if (($Cout_ESR_max -is [double]) -and ($NC -ne 0) -and ($deltaIL -is [double])) {
    $ESR_total = $Cout_ESR_max / $NC
    $rippleV = $deltaIL * $ESR_total
    $Cout_Vdc_min = $outputVoltage + ($rippleV / 2)
}
$Cout_Vdc = [math]::Round($Cout_Vdc_min * $CoutDerating, 2)
# 2. RMS Ripple Current (datasheet Equation 12)
# Irms = sqrt( (deltaIL^2)/12 + (Iout^2) * (Vout/Vin) * (1 - Vout/Vin) ) / sqrt(NC)
$D = $outputVoltage / $inputVoltage
$Irms = [math]::Sqrt(( [math]::Pow($deltaIL, 2) / 12 ) + ( [math]::Pow($loadCurrent, 2) * $D * (1 - $D) )) / [math]::Sqrt($NC)
$Irms = [math]::Round($Irms, 3)
# 3. ESR (max) = 1/(2*pi*Fco*Cout)
if (($fco -ne 0) -and ($Cout -ne 0)) {
    $Cout_ESR_max = 1 / (2 * [math]::PI * $fco * $Cout)
    $Cout_ESR_max = [math]::Round($Cout_ESR_max, 4)
}
else {
    $Cout_ESR_max = 0
}

# 4. LC Corner Frequency
if (($L -ne 0) -and ($Cout -ne 0)) {
    $F_LC = 1 / (2 * [math]::PI * [math]::Sqrt($L * $Cout))
    $F_LC = [math]::Round($F_LC, 1)
    # 5. Closed-loop crossover frequency
    $Fco = ($F_LC * $F_LC) / (85 * $outputVoltage)
    $Fco = [math]::Round($Fco, 1)
    Write-Result "LC Corner Frequency (F_LC): $F_LC Hz" -ForegroundColor DarkYellow

    Write-Result "Closed-loop Crossover Frequency (Fco): $Fco Hz" -ForegroundColor DarkYellow
    ## LC Corner Frequency and crossover frequency calculations removed for bare TPS5450
    if (($Fco -ge 2590) -and ($Fco -le 24000)) {
        Write-Result "Fco is within the recommended range (2590 Hz to 24 kHz)." -ForegroundColor Green
    }
    else {
        Write-Result "Fco is OUTSIDE the recommended range (2590 Hz to 24 kHz)!" -ForegroundColor Red
    }
}
else {
    Write-Result "LC Corner Frequency and Fco: N/A (L or Cout = 0)" -ForegroundColor Red
}
# <-- Add missing closing brace for LC Corner Frequency block

Write-Result "" "None"
Write-Result "-- Output Capacitor Selection --"
Write-Result "Output Capacitor: $Cout_uF uF (choose low ESR type)" "Yellow"
Write-Result "  - Min DC Voltage Rating: $Cout_Vdc V (datasheet: (Vout + 0.5*rippleV) x derating)" "Yellow"
Write-Result "  - Max RMS Ripple Current: $Irms A (datasheet Eq.12)" "Yellow"
if ($Cout_ESR_max -eq 0) {
    Write-Result "  - Max ESR: N/A" "Yellow"
}
else {
    Write-Result "  - Max ESR: $Cout_ESR_max ohms" "Yellow"
}

# Output Ripple Voltage Check (datasheet method: dIL * ESR_total)
if (($Cout_ESR_max -is [double]) -and ($NC -ne 0) -and ($deltaIL -is [double])) {
    $ESR_total = $Cout_ESR_max / $NC
    $rippleV = $deltaIL * $ESR_total
    $rippleV = [math]::Round($rippleV, 6)
    Write-Result "  - Output Ripple Voltage (dIL * ESR_total): $rippleV V" "Blue"
    Write-Result "    (Check if this meets your design requirements)" "Blue"
    $Cout_per = $Cout / $NC
    $Cout_per_uF = [math]::Round($Cout_per * 1e6, 1)
    $Cout_total_uF = [math]::Round($Cout * 1e6, 1)
    Write-Result "  - Capacitance per Output Capacitor: $Cout_per_uF uF" "Blue"

    Write-Result "  - Total Output Capacitance: $Cout_total_uF uF" "Blue"
}
else {
    Write-Result "  - Output Ripple Voltage: N/A (missing data)" "Blue"
}

# 4. Input Capacitor Selection (Cin >= Iout * D * (1 - D) / (ΔVin * Fsw))
$D = $outputVoltage / $inputVoltage  # Duty cycle

Write-Result "" "None"
Write-Result "-- Input Capacitor Selection --"
# Use user-specified input ripple voltage for Cin calculation
if ($inputRippleVoltage -ne 0) {
    $Cin = $loadCurrent * $D * (1 - $D) / ($inputRippleVoltage * $Fsw)
    $Cin_uF = [math]::Round($Cin * 1e6, 1)
    Write-Result "Input Capacitor (for ripple $inputRippleVoltage V): $Cin_uF uF (ceramic or low ESR electrolytic)" "Yellow"
}
else {
    $Cin = 0
    $Cin_uF = 0
    Write-Result "Input Capacitor: N/A (input ripple voltage = 0)" "Yellow"
}

# Calculate input ripple voltage (ΔVin = Iout * D * (1 - D) / (Cin * Fsw))
# Max RMS input ripple current
$Icin_rms = [math]::Round($loadCurrent / 2, 3)
Write-Result "Max RMS Input Ripple Current (Icin): $Icin_rms A" "DarkCyan"
if ($Cin -ne 0) {
    $inputRippleV = $loadCurrent * $D * (1 - $D) / ($Cin * $Fsw)
    $inputRippleV = [math]::Round($inputRippleV, 4)
    Write-Result "Calculated Input Ripple Voltage (standard formula): $inputRippleV V" "Blue"

    # Input ripple voltage using Ioutmax^0.25 / (Cbulk * Fsw)
    $Cbulk = $Cin  # Assume Cbulk is Cin for this calculation
    if ($Cbulk -ne 0) {
        $inputRippleV_alt = [math]::Pow($loadCurrent, 0.25) / ($Cbulk * $Fsw)
        $inputRippleV_alt = [math]::Round($inputRippleV_alt, 4)
        Write-Result "Input Ripple Voltage (Ioutmax^0.25 / (Cbulk * Fsw)): $inputRippleV_alt V" "DarkBlue"
    }
    else {
        Write-Result "Input Ripple Voltage (Ioutmax^0.25 / (Cbulk * Fsw)): N/A (Cbulk = 0)" "DarkBlue"
    }
}
else {
    Write-Result "Calculated Input Ripple Voltage: N/A (Cin = 0)" "Blue"
}

Write-Result "" "None"
Write-Result "--- Catch Diode & Output Voltage Limits (per datasheet) ---" "Magenta"
# --- Catch Diode Selection (per datasheet) ---
# Reverse voltage requirement: VINMAX + 0.5V
$CatchDiode_Vr = $inputVoltage + 0.5
# Peak current requirement: IOUTMAX + 0.5 * deltaIL
$CatchDiode_If_peak = $loadCurrent + 0.5 * $deltaIL
# Forward voltage drop (user can override if needed)
$CatchDiode_Vf = 0.5  # Typical for Schottky
# Estimate diode conduction time (approximate, for efficiency)
$CatchDiode_DiodeTime = 1 - ($outputVoltage + $CatchDiode_Vf) / $inputVoltage
if ($CatchDiode_DiodeTime -lt 0) { $CatchDiode_DiodeTime = 0 }
# Average diode current (approximate)
$CatchDiode_If_avg = $loadCurrent * $CatchDiode_DiodeTime
# Power dissipation in diode
$CatchDiode_Pd = $CatchDiode_If_avg * $CatchDiode_Vf

Write-Result "  Catch Diode:" "Magenta"
Write-Result "    - Reverse Voltage Rating >= $CatchDiode_Vr V" "Magenta"
Write-Result "    - Peak Forward Current >= $CatchDiode_If_peak A" "Magenta"
Write-Result "    - Forward Voltage Drop (typical): $CatchDiode_Vf V" "Magenta"
Write-Result "    - Estimated Avg Current: $([math]::Round($CatchDiode_If_avg,3)) A" "Magenta"
Write-Result "    - Estimated Power Dissipation: $([math]::Round($CatchDiode_Pd,3)) W" "Magenta"
Write-Result "  Output Voltage Limits:" "DarkYellow"
Write-Result "    - Max Output Voltage: $([math]::Round($Vout_max,2)) V (duty cycle, diode, DCR)" "DarkYellow"
Write-Result "    - Min Output Voltage: $([math]::Round($Vout_min,2)) V (on-time, diode, DCR)" "DarkYellow"

# 6. Power Dissipation Estimate (Pd = Iout * (Vin - Vout) * (1 - Efficiency))
$efficiency = 0.9  # Assume 90% efficiency
$Pd = $loadCurrent * ($inputVoltage - $outputVoltage) * (1 - $efficiency)
Write-Result "" "None"
Write-Result "Estimated Power Dissipation: $([math]::Round($Pd,2)) W" "Red"

# 7. Print Summary
Write-Result "" "None"
Write-Result "####################################################################"
Write-Result "--- TPS5450 Design Summary ---" "White"
Write-Result "  Input Voltage: $inputVoltage V" "White"
Write-Result "  Output Voltage: $outputVoltage V" "White"
Write-Result "  Load Current: $loadCurrent A" "White"
Write-Result "  Feedback Resistors:" "Cyan"
Write-Result "    - R1: $R1 ohms (fixed)" "Cyan"
Write-Result "    - R2: $R2 ohms" "Cyan"
Write-Result "  Inductor:" "Green"
Write-Result "    - Min value: $L_uH uH (choose standard value or higher)" "Green"
Write-Result "  Output Capacitor:" "Yellow"
Write-Result "    - Total: $Cout_uF uF (choose low ESR type)" "Yellow"
Write-Result "    - Min DC Voltage Rating: $Cout_Vdc V" "Yellow"
Write-Result "    - Max RMS Ripple Current: $Irms A" "Yellow"
Write-Result "    - Max ESR: $Cout_ESR_max ohms" "Yellow"
Write-Result "    - Output Ripple Voltage: $rippleV V" "Yellow"
Write-Result "    - Capacitance per Output Capacitor: $Cout_per_uF uF" "Yellow"
Write-Result "    - Number in Parallel: $NC" "Yellow"
Write-Result "  Input Capacitor:" "Yellow"
Write-Result "    - Total: $Cin_uF uF (ceramic or low ESR electrolytic)" "Yellow"
Write-Result "    - Max RMS Input Ripple Current: $Icin_rms A" "Yellow"
Write-Result "  Catch Diode: Schottky, If > $loadCurrent A, Vr > $inputVoltage V" "Magenta"
Write-Result "  Estimated Power Dissipation: $([math]::Round($Pd,2)) W" "Red"

Write-Result "####################################################################"
Write-Result "####################################################################"

# --- Call FILTER.ps1 with calculated parameters ---
$filterParams = @(
    '-Vin', $inputVoltage,
    '-Vout', $outputVoltage,
    '-Iout', $loadCurrent,
    '-eta', $efficiency,      # Use the same efficiency as in TPS5450 calculation
    '-CF1', $Cin_uF,             # Default or calculated value if available
    '-CF2', $Cin_uF,             # Default or calculated value if available
    '-LF', $L_uH,               # Default or calculated value if available
    '-Fsw', $Fsw,
    '-Qf', $Qf,               # Default Q factor of 1.0
    '-Fco', $Fco
)
Write-Result "Calling FILTER.ps1 with calculated parameters..." "Cyan"
& powershell -ExecutionPolicy Bypass -File "./FILTER.ps1" @filterParams

