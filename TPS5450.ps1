param(
    [double]$inputVoltage,
    [double]$outputVoltage,
    [double]$loadCurrent,
    [double]$inputRippleVoltage = 0.12,  # Default 0.12V if not specified
    [int]$NC = 1,  # Number of output capacitors in parallel
    [double]$CoutDerating = 1.25,  # Derating factor (default 1.25x)
    [string]$OutputFile = "TPS5450_Results.txt",  # Output file name
    [double]$CF1 = 1e-6,  # Input filter capacitor CF1 (default 1 uF)
    [double]$Cd = 5e-6,   # Damping capacitor (default 5 uF)
    [double]$F_LC = 0,    # Input filter corner frequency (default 0 = auto)
    [double]$Q = 0.7      # Input filter quality factor (recommended 0.5–0.8)
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
Set-Content -Path $OutputFile -Value "TPS5450 Design Calculations Results`r`n====================================="

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
    # Range check
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
Write-Result "===================================================================="
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
Write-Result "===================================================================="
Write-Result "===================================================================="
# Input Filter Design Calculations (after TPS5450 summary)
Write-Result "" "None"
Write-Result "--- Input Filter Design Calculations ---" "Cyan"
# Note about filter coil current rating
Write-Result "The rated current of the filter coil (Lf) should be higher than the effective input current (In)." "Cyan"
# Effective input current calculation (from input-filter-for-dcdc-converter_an-e.pdf, eq. 2)
# In = (Vout - Vin) / (Vin * efficiency)
$In_eff = ($outputVoltage - $inputVoltage) / ($inputVoltage * $efficiency)
Write-Result "Effective Input Current (In): $([math]::Round($In_eff,4)) A" "Cyan" "    Formula: In = (Vout - Vin) / (Vin * efficiency)
    Vout = $outputVoltage V
    Vin = $inputVoltage V
    efficiency = $efficiency
    In = $([math]::Round($In_eff,4)) A (calculated)"
# Filter capacitor CF2 calculation (eq. 3)
# CF2 = 1 / ( (2 * pi * 0.1 * Fsw)^2 * Lf )
$CF2 = 1 / ( [math]::Pow(2 * [math]::PI * 0.1 * $Fsw, 2) * $Lf )
$CF2_uF = [math]::Round($CF2 * 1e6, 2)
Write-Result "Filter Capacitor CF2: $CF2_uF uF" "Cyan" "    Formula: CF2 = 1 / ( (2π * 0.1 * Fsw)^2 * Lf )
    Fsw = $Fsw Hz
    Lf = $([math]::Round($Lf*1e6,2)) uH
    CF2 = $CF2_uF uF (calculated)"



# Input Filter Q, Impedance, and Damping Calculations (Q fixed at 1, solve for Rd using F_LC)
$Q = 1
# Rd = 1 / (2 * pi * Q * F_LC * Cf1)
$Rd = 1 / (2 * [math]::PI * $Q * $F_LC * $CF1)
$Rd = [math]::Round($Rd, 3)
Write-Result "" "None"
Write-Result "-- Input Filter Damping Resistor (Rd) Calculation (Q=1, using F_LC) --"
Write-Result "Damping Resistor (Rd): $Rd ohms (for Q=1, using F_LC)" "Cyan" "    Formula: Rd = 1 / (2π * Q * F_LC * Cf1)
    F_LC = $F_LC Hz
    Q = $Q
    Cf1 = $CF1 F
    Rd = $Rd ohms (calculated)"

# 1. Quality Factor (Q) Calculation (fixed)
Write-Result "" "None"
Write-Result "-- Input Filter Quality Factor (Q) --"
Write-Result "Quality Factor (Q): $Q (fixed)" "Cyan" "    Q is set to 1 for optimal damping per app note."

# 2. Input Impedance (Zin) Calculation
# Zin = Rd + s * Lf (s = j * 2 * pi * f)
# For DC analysis, s = 0, so Zin = Rd
$Zin = $Rd
Write-Result "" "None"
Write-Result "-- Input Impedance (Zin) Calculation --"
Write-Result "Input Impedance (Zin): $Zin ohms" "Cyan" "    Formula: Zin = Rd + s * Lf
    For DC analysis, s = 0, so Zin = Rd
    Zin = $Zin ohms (calculated)"

# 3. Damping Factor (DF) Calculation
# DF = 1 / (2 * pi * fco * Cd)
$DF = 1 / (2 * [math]::PI * $fco * $Cd)
$DF = [math]::Round($DF, 3)
Write-Result "" "None"
Write-Result "-- Input Filter Damping Factor (DF) Calculation --"
Write-Result "Damping Factor (DF): $DF" "Cyan" "    Formula: DF = 1 / (2π * fco * Cd)
    fco = $fco Hz
    Cd = $Cd F
    DF = $DF (calculated)"

# 4. Damping Ratio (ζ) Calculation
# ζ = 1 / (2 * Q)
$zeta = 1 / (2 * $Q)
$zeta = [math]::Round($zeta, 3)
Write-Result "" "None"
Write-Result "-- Input Filter Damping Ratio (ζ) Calculation --"
Write-Result "Damping Ratio (ζ): $zeta" "Cyan" "    Formula: ζ = 1 / (2 * Q)
    Q = $Q
    ζ = $zeta (calculated)"

# 5. Step Response Time (tr) Calculation
# tr = 0.7 * (Rd + 2 * Lf / Rd) * Cf1
$tr = 0.7 * ($Rd + 2 * $Lf / $Rd) * $CF1
$tr = [math]::Round($tr, 3)
Write-Result "" "None"
Write-Result "-- Input Filter Step Response Time (tr) Calculation --"
Write-Result "Step Response Time (tr): $tr" "Cyan" "    Formula: tr = 0.7 * (Rd + 2 * Lf / Rd) * Cf1
    Rd = $Rd ohms
    Lf = $([math]::Round($Lf*1e6,2)) uH
    Cf1 = $CF1 F
    tr = $tr (calculated)"

# 6. Filter Coil Current Rating Check
# Check if the rated current of the filter coil (Lf) is higher than the effective input current (In)
$In_eff_abs = [math]::Abs($In_eff)
Write-Result "" "None"
Write-Result "-- Filter Coil Current Rating Check --"
if ($In_eff_abs -lt $Lf) {
    Write-Result "Filter coil current rating is adequate." "Green"
}
else {
    Write-Result "Filter coil current rating MAY BE INADEQUATE!" "Red"
    Write-Result "  - Effective Input Current (In): $In_eff_abs A" "Red"
    Write-Result "  - Filter Coil Current Rating (Lf): $Lf A" "Red"
}

# 7. Print Input Filter Summary
Write-Result "" "None"
Write-Result "===================================================================="
Write-Result "--- Input Filter Design Summary ---" "White"
Write-Result ("  Input Filter Inductor (Lf, calculated): {0:E6} H" -f $Lf) "White"
if ($Lf -lt 1e-6) {
    $Lf_nH = $Lf * 1e9
    Write-Result ("  Input Filter Inductor (Lf): {0:N2} nH" -f $Lf_nH) "White"
    if ($Lf_nH -lt 10) {
        Write-Result "  Warning: Calculated Lf is less than 10 nH. This is likely not physically realizable. Consider reducing CF1 or F_LC." "Red"
    }
}
else {
    Write-Result ("  Input Filter Inductor (Lf): {0:N2} uH" -f ($Lf * 1e6)) "White"
}
Write-Result "  Input Filter Capacitor (CF1): $CF1 F" "White"
Write-Result "  Damping Resistor (Rd): $Rd ohms (for Q=1)" "White"
Write-Result "  Damping Capacitor (Cd): $Cd F" "White"
Write-Result "  Quality Factor (Q): $Q" "White"
Write-Result "  Input Impedance (Zin): $Zin ohms" "White"
Write-Result "  Damping Factor (DF): $DF" "White"
Write-Result "  Damping Ratio (ζ): $zeta" "White"
Write-Result "  Step Response Time (tr): $tr" "White"
Write-Result "  Effective Input Current (In): $([math]::Round($In_eff_abs,4)) A" "White"
Write-Result "===================================================================="

<###############################################
# Example Usage:
#
# Basic usage with required parameters:
#   .\TPS5450.ps1 -inputVoltage 12 -outputVoltage 5 -loadCurrent 3
#
# Specify input ripple voltage and number of output capacitors:
#   .\TPS5450.ps1 -inputVoltage 12 -outputVoltage 5 -loadCurrent 3 -inputRippleVoltage 0.1 -NC 3
#
# Specify output file and input filter inductor:
#   .\TPS5450.ps1 -inputVoltage 12 -outputVoltage 5 -loadCurrent 3 -OutputFile TPS5450_Results.txt -Lf 10e-6
#
# Specify all input filter and damping network parameters:
#   .\TPS5450.ps1 -inputVoltage 12 -outputVoltage 5 -loadCurrent 3 -Lf 10e-6 -CF1 1e-6 -Rd 1 -Cd 5e-6
#
# All parameters (with defaults):
#   .\TPS5450.ps1 -inputVoltage <V> -outputVoltage <V> -loadCurrent <A> -inputRippleVoltage <V> -NC <n> -CoutDerating <factor> -OutputFile <file> -Lf <H> -CF1 <F> -Rd <ohm> -Cd <F>
#
# For help on parameters:
#   Get-Help .\TPS5450.ps1 -Full
#
# Typical values for input filter design:
#   - Filter inductor (Lf): 0.47 µH to 22 µH (nH to low µH for EMI)
#   - Filter capacitor (CF1): 1 µF to 100 µF
#   - Quality factor (Q): 0.5 to 0.8
###############################################>