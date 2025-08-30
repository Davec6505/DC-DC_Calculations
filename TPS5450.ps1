param(
    # default input voltage
    [double]$Vin = 24.0,
    # default output voltage
    [double]$Vout = 5.0,
    # default load current
    [double]$Iout = 5.0,
    # Switchers frequency (default 500 kHz)
    [double]$Fsw = 500e3,
    # Default 0.6 if not specified
    [double]$Vin_ripple = 0.6,
    # Input filter capacitor CF1 (default 10 uF)
    [double]$CF1 = 10e-6,
    # ESR of input capacitor (default 50 mOhm)
    [double]$ESRmax_cf1 = 1.6e-3,
      # Number of output capacitors in parallel
    [int]$NC = 3,
    # Diode forward voltage drop (default 0.55 V)
    [double]$VD = 0.55,
    # Efficiency (default 82%)
    [double]$efficiency = 0.82,
    # Quality factor (default 1.0)
    [double]$Qf = 1.0,
    # Output file name
    [string]$OutputFile = "TPS5450_Results.txt",
    # Whether to call FILTER.ps1 with calculated parameters (default false)
    [bool]$Filter = $false
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

if (-not $CF1) {
    $CF1 = Read-Host "Enter value for CF1 (input filter capacitor in Farads, e.g., 10e-6 for 10uF)"
}
if (-not $ESRmax_cf1) {
    $ESRmax_cf1 = Read-Host "Enter value for ESRmax (input capacitor ESR in Ohms, e.g., 0.0915)"
}

# Ensure $Kind is set (inductor ripple coefficient, typical 0.2)
if ($Kind -eq $null -or $Kind -le 0) {
    $Kind = 0.2
    Write-Result "Defaulted Kind (inductor ripple coefficient) to $Kind" "Green"
}

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


# Constants
$Vref = 1.221
$Fco  = 12e3


# Calculate feedback resistors
$R1 = 10000  # 10kΩ hard coded
$R2 = [math]::Round(($R1 * $Vref) / ($Vout - $Vref), 0)

# Calculate duty cycle
$D = $Vout / $Vin  # Duty cycle

# More accurate input ripple voltage calculations
# Capacitive component
$dVin_C = ($Iout * $D * (1 - $D)) / ($CF1 * $Fsw)
# ESR component
$dVin_ESR = $Iout * $D * $ESRmax_cf1
# Total input ripple voltage
$dVin_total = $dVin_C + $dVin_ESR

# Calculate input cap RMS ripple current (standard formula)
$Ic_in_rms = $Iout * [math]::Sqrt($D * (1 - $D))

# Calculate total average input current
$Iin_avg = ($Iout * $Vout) / ($Vin * $efficiency)




# Calculate minimum output inductor value (in Henries)
$L_min = ($Vout * ($Vin - $Vout)) / ($Vin * $Kind * $Iout * $Fsw)
$L_min_uH = $L_min * 1e6
if ($L_min -lt 1e-7 -or $L_min -gt 1e-3) {
    Write-Result "Warning: Calculated L_min is out of typical range: $L_min H" "Red"
}

# 6. Calculate Inductor Ripple Current
$IL_rms = [math]::Sqrt(
         [math]::Pow($Iout, 2) + 
         (1/12) * [math]::Pow((($Vout * ($Vin - $Vout)) / ($Vin * $L_min * $Fsw)), 2)
        )


# 7. Calculate Inductor Current Ratings
$IL_peak = $Iout + ((($Vout * ($Vin - $Vout)) / (1.6 * $Vin * $L_min * $Fsw)))

## Output Capacitor Selection
# 8. Cout
# Calculate output capacitance (in Farads)
$Cout = 1 / (3357 * $L_min * $Fco * $Vout)
$Cout_uF = $Cout * 1e6
if ($Cout -lt 1e-6 -or $Cout -gt 1e-2) {
    Write-Result "Warning: Calculated Cout is out of typical range: $Cout F" "Red"
}

# 9. Calculate Corner Frequency 
$f_LC = 1 / (2 * [math]::PI * [math]::Sqrt($L_min * $Cout))

# 10. Calculate Fco
#$Fco = [math]::Pow($f_LC, 2) / (85 * $Vout)

# 10. Calculate individual output capacitor value (in Farads and uF)
$Cout_individual = $Cout / $NC
$Cout_individual_uF = $Cout_individual * 1e6

# Calculate max ESR for total and per capacitor
$ESRmax_total = 1 / (2 * [math]::PI * $Fco)
$ESRmax_individual = $ESRmax_total * $NC

# For display, convert ESR to mOhms
$ESRmax_total_mOhm = $ESRmax_total * 1e3
$ESRmax_individual_mOhm = $ESRmax_individual * 1e3

# 11. Calculate Output Ripple Voltage
#$rippleV = ($ESRmax * $Vout * ($Vin_max - $Vout)) / ($NC * $Vin_max * $Lout * $Fsw)

# 12. Calculate Output Capacitor RMS Ripple Current
#$Icout_rms = 1 / [math]::Sqrt(12) * (($Vout * ($Vin_max - $Vout)) / ($Vin_max * $Lout * $Fsw * $NC))

# --- Calculate/Estimate Key Parameters for Part Selection ---
# 7. Print Summary
Write-Result "" "None"
Write-Result "####################################################################"
Write-Result "###################### TPS5450 Design Summary ######################" "White"

Write-Result "  Input Voltage: $Vin V" "White"
Write-Result "  Output Voltage: $Vout V" "White"
Write-Result "  Load Current: $Iout A" "White"
Write-Result "  Feedback Resistors:" "Cyan"
Write-Result "    - R1: $R1 ohms (fixed)" "Cyan"
Write-Result "    - R2: $R2 ohms" "Cyan"

Write-Result "  Input Parameters:" "Blue"
Write-Result "    - Ripple Voltage (Capacitive):`t$dVin_C V`t[= (Iout * D * (1 - D)) / (CF1 * Fsw)]" "Blue"
Write-Result "    - Ripple Voltage (ESR):      `t$dVin_ESR V`t[= Iout * D * ESRmax_cf1]" "Blue"
Write-Result "    - Ripple Voltage (Total):    `t$dVin_total V`t[= Ripple_C + Ripple_ESR]" "Blue"
Write-Result "    - Average Current @ ${Iout}A:`t$Iin_avg A`t[= (Iout * Vout) / (Vin * efficiency)]" "Blue"
Write-Result "    - Cap RMS Current:           `t$Ic_in_rms A`t[= Iout * sqrt(D * (1 - D))]" "Blue"

Write-Result "  Inductor:" "Green"
Write-Result "    - Min value:                 `t$L_min_uH uH`t(choose standard value or higher) [= (Vout * (Vin - Vout)) / (Vin * Kind * Iout * Fsw)]" "Green"
Write-Result "    - RMS Current:               `t$IL_rms A`t[= sqrt(Iout^2 + (1/12) * ((Vout * (Vin - Vout)) / (Vin * L_min * Fsw))^2)]" "Green"
Write-Result "    - Peak Current:              `t$IL_peak A`t[= Iout + ((Vout * (Vin - Vout)) / (1.6 * Vin * L_min * Fsw))]" "Green"

Write-Result "  Output Capacitor:" "Yellow"
Write-Result "    - Corner Frequency:          `t$f_LC Hz`t[= 1 / (2 * pi * sqrt(L_min * Cout))]" "Yellow"
Write-Result "    - Crossover Frequency:       `t$Fco Hz`t[set by user or default]" "Yellow"
Write-Result "    - Total:                     `t$Cout_uF uF`t(choose low ESR type) [= 1 / (3357 * L_min * Fco * Vout)]" "Yellow"
Write-Result "    - Individual:                `t$Cout_individual_uF uF`t(each capacitor using NC) [= Cout / NC]" "Yellow"
Write-Result "    - Max ESR (total bank):      `t$ESRmax_total_mOhm mOhm`t[= 1 / (2 * pi * Fco)]" "Yellow"
Write-Result "    - Max ESR (per cap):         `t$ESRmax_individual_mOhm mOhm`t[= ESRmax_total * NC]" "Yellow"
Write-Result "    - Number in Parallel: $NC" "Yellow"

Write-Result "  Input Filter Capacitor:" "Yellow"
Write-Result "    - CF1: $CF1 uF" "Yellow"
Write-Result "    - ESR: $ESRmax_cf1 Ohm" "Yellow"


# --- Practical/WEBENCH Output Capacitance Example (6TPE220MAZB) ---
$Cout_practical = 220e-6 * $NC # 220uF
$Cout_practical_uF = $Cout_practical * 1e6
$ESR_practical_individual = 0.018   # 18 mOhm from datasheet
$ESR_practical_total = $ESR_practical_individual  # Only one cap used
$ESR_practical_total_mOhm = $ESR_practical_total * 1e3

Write-Result "  Practical Output Cap Example (WEBENCH):" "Cyan"
Write-Result "    - Total: $Cout_practical_uF uF (6TPE220MAZB)" "Cyan"
Write-Result "    - ESR: $ESR_practical_total_mOhm mOhm (datasheet)" "Cyan"


# --- Practical/WEBENCH Output Capacitance Ripple Calculation ---
# Output ripple due to capacitance (capacitive component)
$rippleV_practical_C = ($Iout / ($Fsw * $Cout_practical))
# Output ripple due to ESR (resistive component)
$rippleV_practical_ESR = $Iout * $ESR_practical_total
# Total output ripple voltage (approximate sum)
$rippleV_practical_total = $rippleV_practical_C + $rippleV_practical_ESR

Write-Result "  Practical Output Ripple Calculation (WEBENCH):" "Cyan"
Write-Result "    - Ripple (Capacitive): $rippleV_practical_C V" "Cyan"
Write-Result "    - Ripple (ESR): $rippleV_practical_ESR V" "Cyan"
Write-Result "    - Total Output Ripple: $rippleV_practical_total V" "Cyan"


Write-Result "####################################################################"
Write-Result "####################################################################"

if ($Filter -eq $true) {
    # --- Call FILTER.ps1 with correct filter parameters ---
    $filterParams = @(
        '-Vin', $Vin,
        '-Vout', $Vout,
        '-Iout', $Iout,
        '-eta', $efficiency,      # Use the same efficiency as in TPS5450 calculation
        '-CF1', $CF1,             # Input filter cap (before inductor)
        '-CF2', $CF1,             # Input filter cap (after inductor, before buck)
        '-LF', $L_min,            # Use calculated minimum inductor value
        '-Fsw', $Fsw,
        '-Qf', $Qf,               # Default Q factor of 1.0
        '-Fco', $Fco,
        '-OutputFile', $OutputFile # Use the same output file for both scripts
    )
    Write-Result "Calling FILTER.ps1 with input filter cap values (not output cap)..." "Cyan"
    & powershell -ExecutionPolicy Bypass -File "./FILTER.ps1" @filterParams
}

