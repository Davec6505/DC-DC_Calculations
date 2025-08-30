
# TPS5450 DC-DC Converter Design Calculator

This project provides a comprehensive PowerShell script (`TPS5450.ps1`) to automate all key design calculations for the Texas Instruments TPS5450 DC-DC converter. The script follows datasheet formulas and best-practice application notes, including advanced input filter design and stability checks. Results are output to both the console (with color coding) and a detailed results file.


## Table of Contents
- [TPS5450 DC-DC Converter Design Calculator](#tps5450-dc-dc-converter-design-calculator)
  - [Table of Contents](#table-of-contents)
  - [Block Diagram](#block-diagram)
  - [Input Filter Diagram](#input-filter-diagram)
  - [Example Output](#example-output)
  - [Overview](#overview)
  - [How to Use](#how-to-use)
  - [Parameters](#parameters)
  - [Calculation Sections](#calculation-sections)
    - [1. Feedback Resistors](#1-feedback-resistors)
    - [2. Inductor Selection](#2-inductor-selection)
    - [3. Output Capacitor Selection](#3-output-capacitor-selection)
    - [4. Input Capacitor Selection](#4-input-capacitor-selection)
    - [5. Catch Diode Selection](#5-catch-diode-selection)
    - [6. Output Voltage Limits](#6-output-voltage-limits)
    - [7. Power Dissipation Estimate](#7-power-dissipation-estimate)
    - [8. Input Filter Design](#8-input-filter-design)
    - [9. Stability Checks](#9-stability-checks)
  - [References](#references)
## Block Diagram

```
         +-------------------+      +----------+      +----------+
Vin ---->| Input Filter (L,C)|----->| TPS5450   |----->| Output   |----> Vout
         |  (LF, CF1, Rd, Cd)|     |  Buck IC  |     | Filter   |
         +-------------------+      +----------+      +----------+
```

*Note: For a full schematic, see the datasheet or your PCB CAD tool.*

## Input Filter Diagram

```
Vin ---LF---+---+---+----> To TPS5450 VIN
           |   |
          Cd  CF1
           |   |
          Rd   |
           |   |
          GND GND
```

*LF: Input filter inductor, CF1: filter cap, Rd: damping resistor, Cd: damping cap.*
## Example Output

Below is a sample output from the script for a typical 12V to 5V, 3A design:

## Output Notation & Formatting

All results are shown in a unified output file, with formulas, engineering units, and clear tabbed alignment. Key complex results (such as filter output impedance ZOut) are displayed in:
- Rectangular form: (a + bj)
- Polar form: |Z| ∠ θ°
- Magnitude only: |Z|

**Example ZOut Output:**
```
  - ZOut: ( 0.00144 + -0.03181j ) Ohm   [= (j*2π*f*Lf) / (1 - (Lf*Cf1*(2π*f)^2) + j·(2π*f*Rd*Cf1))]
  - ZOut: 0.03184 ∠ -87.41° Ohm         [polar: |Z| ∠ θ]
  - |ZOut|: 0.03184 Ohm                 [magnitude only]
```

All filter and converter calculations are grouped and annotated for clarity in the same output file.

```
TPS5450 Design Calculations Results
=====================================

--- Calculation Descriptions ---
Feedback Resistors: Sets output voltage using a resistor divider (Vout = 1.221V * (1 + R1/R2)).
Inductor: Sets current ripple and affects transient response (L = (Vout * (Vin - Vout)) / (Vin * dIL * Fsw)).
Output Capacitor: Sets output voltage ripple, stability, and transient response. Includes ESR, ripple current, and voltage rating checks.
Input Capacitor: Reduces input voltage ripple and supplies current during switching.
Catch Diode: Provides current path during switch-off, must meet voltage/current/power specs.
Output Voltage Limits: Device constraints based on duty cycle, diode drop, and inductor DCR.
Power Dissipation: Estimates device self-heating for thermal design.

-- Feedback Resistor Calculation --
Feedback Resistors: R1 = 10000 ohms (fixed), R2 = 3231 ohms
    Formula: Vout = Vref * (1 + R1/R2)
    Vref = 1.221 V
    R1 = 10000 ohms (fixed)
    R2 = 3231 ohms (calculated)
    Vout = 5 V (target)

-- Inductor Selection --
Min value for Inductor: 6 uH (choose standard value or higher)
    Formula: L = (Vout * (Vin - Vout)) / (Vin * dIL * Fsw)
    Vout = 5 V
    Vin = 12 V
    dIL = 0.9 A (30% of load current)
    Fsw = 500000 Hz
    L = 6.481 uH (calculated)
LC Corner Frequency (F_LC): 2916.1 Hz
Closed-loop Crossover Frequency (Fco): 20008.6 Hz
Fco is within the recommended range (2590 Hz to 24 kHz).

-- Output Capacitor Selection --
Output Capacitor: 459.6 uF (choose low ESR type)
  - Min DC Voltage Rating: 6.25 V (datasheet: (Vout + 0.5*rippleV) x derating)
  - Max RMS Ripple Current: 0.867 A (datasheet Eq.12)
  - Max ESR: 0.0173 ohms
  - Output Ripple Voltage (dIL * ESR_total): 0.00519 V
    (Check if this meets your design requirements)
  - Capacitance per Output Capacitor: 153.2 uF
  - Total Output Capacitance: 459.6 uF

-- Input Capacitor Selection --
Input Capacitor (for ripple 0.1 V): 14.6 uF (ceramic or low ESR electrolytic)
Max RMS Input Ripple Current (Icin): 1.5 A
Calculated Input Ripple Voltage (standard formula): 0.1 V
Input Ripple Voltage (Ioutmax^0.25 / (Cbulk * Fsw)): 0.1805 V

--- Catch Diode & Output Voltage Limits (per datasheet) ---
  Catch Diode:
    - Reverse Voltage Rating >= 12.5 V
    - Peak Forward Current >= 3.45 A
    - Forward Voltage Drop (typical): 0.5 V
    - Estimated Avg Current: 1.625 A
    - Estimated Power Dissipation: 0.813 W
  Output Voltage Limits:
    - Max Output Voltage: 0 V (duty cycle, diode, DCR)
    - Min Output Voltage: 0 V (on-time, diode, DCR)

Estimated Power Dissipation: 2.1 W
====================================================================
--- TPS5450 Design Summary ---
  Input Voltage: 12 V
  Output Voltage: 5 V
  Load Current: 3 A
  Feedback Resistors:
    - R1: 10000 ohms (fixed)
    - R2: 3231 ohms
  Inductor:
    - Min value: 6 uH (choose standard value or higher)
  Output Capacitor:
    - Total: 459.6 uF (choose low ESR type)
    - Min DC Voltage Rating: 6.25 V
    - Max RMS Ripple Current: 0.867 A
    - Max ESR: 0.0173 ohms
    - Output Ripple Voltage: 0.00519 V
    - Capacitance per Output Capacitor: 153.2 uF
    - Number in Parallel: 3
  Input Capacitor:
    - Total: 14.6 uF (ceramic or low ESR electrolytic)
    - Max RMS Input Ripple Current: 1.5 A
  Catch Diode: Schottky, If > 3 A, Vr > 12 V
  Estimated Power Dissipation: 2.1 W
====================================================================
====================================================================

--- Input Filter Design Calculations (per best practice) ---
Effective Input Current (Iin_eff): 1.389 A
    Formula: Iin_eff = (Vout * Iout) / (Vin * efficiency)
Filter Capacitor CF2: 0.000072 F
    Formula: CF2 = 1 / [(2π * 0.1 * Fsw)^2 * LF]
Input Filter Q Factor: 1.000
    Formula: Q = Rd * sqrt(CF1 / LF)
Damping Resistor Rd (for Q=1): 0.118 ohms
    Formula: Rd = sqrt(LF / CF1)
Recommended Cd: 0.000050 F < Cd < 0.000100 F
    Formula: 5*CF1 < Cd < 10*CF1
Warning: Filter inductor current rating may be inadequate!
  Input Filter Inductor (LF): 0.14 uH
  Input Filter Capacitor (CF1): 10.00 uF
  Filter Capacitor (CF2): 72.37 uF
  Damping Resistor (Rd for Q=1): 0.118 ohms
  Damping Capacitor (Cd): 65.00 uF (recommend 5-10x CF1)
  Q Factor: 1.000
  Effective Input Current: 1.389 A
Converter Input Impedance (Zin_con) at Fco: 0.00 ohms
    Formula: Zin_con = Vin / (Iout * 2π * Fco)
Input Filter Output Impedance (ZoutF): 0.01 ohms
    Formula: ZoutF = LF / CF1 (at resonance)
Warning: Input filter output impedance (ZoutF) is not much less than converter input impedance (Zin_con). Risk of instability!
Warning: Input filter corner frequency is not much less than converter crossover frequency. Risk of instability!
```

## Overview
This script is intended for engineers designing with the TPS5450 step-down (buck) converter. It automates all major calculations required for robust, stable, and efficient converter design, including:
- Feedback network
- Inductor and capacitor sizing
- Ripple and ESR checks
- Catch diode selection
- Input filter design (per TI/ROHM app note best practices)
- Stability and impedance margin checks

## How to Use

Run the script in PowerShell with your design parameters. Example:

```powershell
.\TPS5450.ps1 -Vin 24 -Vout 5 -Iout 5 -CF1 10e-6 -efficiency 0.82 -Qf 1 -OutputFile MyResultsPS.txt -Filter $true
```

All results and calculation breakdowns will be shown in the console and saved to the specified output file. Both converter and filter results are included.

### Troubleshooting
- If you do not see filter results in your output file, ensure you are using the latest script version and passing `-Filter $true` and `-OutputFile` parameters.
- If output is misaligned, check your PowerShell font or output file encoding.

## Parameters
- `Vin` (V): Input voltage to the converter
- `Vout` (V): Desired output voltage
- `Iout` (A): Maximum load current
- `Vin_ripple` (V): Allowed input voltage ripple (default: 0.12V)
- `CF1` (F): Input filter capacitor value (Choose X7R low esr)
- `NC`: Number of output capacitors in parallel (default: 1)
- `ESRmax_cf1` : ESR of capacitor for CF1 chosen from datasheet of CF1
- `Cd` (F): Damping capacitor value
- `F_LC` (Hz): Input filter corner frequency (optional)
- `Q`: Input filter quality factor (optional)
- `Rd` (Ω): Damping resistor (optional)

## Calculation Sections

### 1. Feedback Resistors
**Purpose:** Sets the output voltage using a resistor divider. 
**Formula:** `Vout = Vref * (1 + R1/R2)`
- R1 is fixed (10kΩ), R2 is calculated.

### 2. Inductor Selection
**Purpose:** Sets current ripple and affects transient response. 
**Formula:** `L = (Vout * (Vin - Vout)) / (Vin * ΔIL * Fsw)`
- ΔIL is 30% of load current by default.

### 3. Output Capacitor Selection
**Purpose:** Sets output voltage ripple, stability, and transient response. 
- **Capacitance:** `Cout = 1/(3357 * L * fco * Vout)`
- **ESR:** `ESR_max = 1/(2πfcoCout)`
- **Ripple Current:** `Irms = sqrt((ΔIL²/12) + (Iout² * D * (1-D))) / sqrt(NC)`
- **Voltage Rating:** `Vout + 0.5*rippleV`, then apply derating.

### 4. Input Capacitor Selection
**Purpose:** Reduces input voltage ripple and supplies current during switching. 
**Formula:** `Cin >= Iout * D * (1 - D) / (ΔVin * Fsw)`

### 5. Catch Diode Selection
**Purpose:** Provides a current path during switch-off. 
- **Reverse Voltage:** `VINMAX + 0.5V`
- **Peak Current:** `IOUTMAX + 0.5 * ΔIL`
- **Power Dissipation:** `If_avg * Vf`

### 6. Output Voltage Limits
**Purpose:** Ensures output voltage stays within device constraints (duty cycle, diode drop, inductor DCR).

### 7. Power Dissipation Estimate
**Purpose:** Estimates device self-heating for thermal design. 
**Formula:** `Pd = Iout * (Vin - Vout) * (1 - Efficiency)`

### 8. Input Filter Design
**Purpose:** Designs a two-stage LC input filter for EMI and stability, per best-practice app notes.
- **Effective Input Current:** `Iin_eff = (Vout * Iout) / (Vin * efficiency)`
- **Filter Capacitor CF2:** `CF2 = 1 / [(2π * 0.1 * Fsw)² * LF]`
- **Q Factor:** `Q = Rd * sqrt(CF1 / LF)`
- **Damping Resistor:** `Rd = sqrt(LF / CF1)` (for Q=1, unless user supplies Rd)
- **Damping Capacitor:** `Cd` (recommend 5–10x CF1)

### 9. Stability Checks
**Purpose:** Ensures the input filter does not destabilize the converter.
- **Converter Input Impedance:** `Zin_con = Vin / (Iout * 2π * Fco)`
- **Filter Output Impedance:** `ZoutF = LF / CF1`
- **Stability Criteria:** `ZoutF << Zin_con` and filter corner frequency << crossover frequency.

## References
- [TI TPS5450 Datasheet](https://www.ti.com/lit/ds/symlink/tps5450.pdf)
- [TI Application Note: Input Filter Design for Switching Power Supplies](https://www.ti.com/lit/an/slva912/slva912.pdf)
- [ROHM Application Note: Input Filter Design](https://www.rohm.com/electronics-basics/power-management/dcdc-input-filter)

---
For questions or improvements, please open an issue or pull request.
