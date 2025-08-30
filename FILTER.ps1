<############################################################################################################################
The input current flow of the DC/DC converter alternates with the switching frequency of the 
DC/DC converter. The input capacitor connected to a converter IC input has an equivalent series 
resistance (ESR) causing voltage ripples due to the alternating input current flow. The amplitude of this 
voltage ripple occurring is essentially dependent on the ESR of the used capacitor. 

The main purposes of an input filter are to suppress the noise and surge from the front-stage power supply 
and to decrease the interference signal at the switching frequency and its harmonic frequencies, 
to keep them from emitting noise over the power supply and interfering with other devices that use the power supply. 

Usually a π-type input filter, as shown in Figure 4, is used for filtering the input current, thereby decreasing the 
AC amplitude of the voltage ripple, which can reduce the conducted emissions to an acceptable value.  

Supply  -> Pi filter  - >  Converter
   *-----------------|__LF___|-------------------------*
   |        ||                        ||                |
   PS       CF2                      CF1               Converter
   |        ||                        ||                |
   *----------------------------------------------------* 

An LC filter reduces the noise from in- to output by 40 dB / decade.

To reduce noise from a DC/DC converter, the LC filter should be optimized with a corner frequency of 1/10 of the switching frequency. 
The corner frequency is described in equation (1): it is recommended to select an inductor with an inductance SRF value lower than 
the capacitance value of the filter capacitor. [The higher the inductance, the smaller the SRF.] #- self resonant frequency -#
At low switching frequencies in the range of 60 to 400 KHz, a filter inductor with a metal powder core 
is suitable. At switching frequencies higher than 1 MHz, ferrite core inductors are preferred. 
Exceeding the rated current of the filter inductor may result in damage to the wire winding. 
Therefore, it is recommended to select an inductor with low DCR so as not to reduce the efficiency of the SMPS. 
(1)  fC = 1 / (2π∙√(Lf ∙ Cf2))

It is possible to calculate the effective input current 
of the power module using equation (2): 
(2)  Iin = 𝑉out∙𝐼out/ 𝑉in∙η

The rated current of the filter coil should be higher than the input current. 
The filter capacitor CF2 can be calculated using 
equation (3). 
(3)  Cf2 = 1 / (2π∙0,1∙𝑓sw)^2∙𝐿f

The input current ripple can be estimated using equation (4):
(4)  ΔIin = Iin / (8 ∙ fSW ∙ Lf)
    Where:
    ΔIin = Input current ripple
    fSW = Switching frequency
    Lf = Filter inductor value
    

MLCCs are cheaper than electrolytic capacitors, but have a decreased capacitance as their DC bias voltage is increased. 
As an example, figure 6 shows the voltage bias of a 150 nF, 50V, X7R-rated MLCC. 
With respect to the voltage bias of MLCCs, the  rated voltage of the MLCC is selected to achieve the required capacitance at an applied voltage. 
A general guideline is to select a capacitor rating 2 x higher than the highest occurring voltage on the capacitor.    

The input filter can change or influence the converter transfer function and thus change the loop gain, which is an important measure for the 
control-loop stability of the DC/DC converter. In other words, adding an input filter can lead to control loop instability if certain conditions 
are not met.

The input filter has a Q factor (Q) and an output impedance (ZOutF), while the DC/DC converter has an input impedance (ZInCon), as shown in Figure 7. 


        <--ZoutF   ZInCon-->
*----- Lf---*- -----*-- -------| DC/DC  |------- *VOut
            |       |
 Supply     |       |
           CF1     CIN
            |       |
 *--------- *-------*-----------------------*------*
 FIGURE 7: IMPEDANCE OF INPUT FILTER AND DCDC CONVERTER
An LC input filter has an effect on the control loop of the DC-DC converter, because the output impedance ZOutF of the input filter influences the
DC/DC converter input ZInCon impedance. The input filter decreases the phase margin and thus degrades the transient response performance.

When the input filter’s Q is too large, oscillations may occur whenever the input voltage changes at the DC/DC converter input, 
and its control loop can become unstable after applying. The input filter Q is defined with equation (4): 
(5)  𝑄 =𝑅d∙√𝐶f1 / 𝐿f
Where:Rd = √(𝐶f1 / 𝐿f) if Q = 1;

The stability criterion that applies here is that the output impedance of the input filter ZoutF has to be lower than the 
input impedance of the DC/DC converter input Zin. 
This is described in equation (5): 
(6)  ZOutF ≪ 𝑍InCon
Transfer function: 
 ZOutF = (j∙2π∙f∙Lf) / (1 - (Lf∙Cf1∙(2π∙f)^2) + j∙(2π∙f∙Rd∙Cf1))

In addition, the corner frequency fc of the input filter should be much lower than the crossover frequency fCOCon of the DC/DC converter. 
(7)  fc ≪ 𝑓COCon
Adding an R-C network to the filter as shown in  
Figure 8 lowers the input filter’s Q. 
*------------- Lf ---------------------------*
 |         |        |         |             |
 |         |        |        Cd             |
Supply    CF2      CF1        |          Converter
 |         |        |         Rd            |
 |         |        |         |             |
 *-------------------------------------------*
 FIGURE 8: INPUT FILTER INCLUDING R-C NETWORK

 The purpose of the resistor R is to damp the filter, and the purpose of the capacitor in series is to 
block the DC portion of the input voltage in order to reduce dissipation in the damping resistor. 
Equation (7) is used for calculating the damping resistor Rd for a filter with a Q value of Qf = 1: 
(8)  Rd = √(LF / CF1)

A ceramic capacitor Cd in series with the R-C network has a factor of 5 to 10 of the filter-capacitor capacitance.
(9) (5 ∙ 𝐶F1) < 𝐶d < (10∙𝐶F1)

With respect to price and space, alternatively the filter could be damped by selecting an electrolytic capacitor that 
is connected in parallel to the filter output instead of the R-C network. However, it should be noted that the ESR value 
of the electrolytic capacitor is not sufficient to have adequate filter attenuation.

######################################################################################################################### #>

param(
    [double]$Vin = 24.0,       # Input voltage in Volt (V)
    [double]$Vout = 5.0,       # Output voltage in Volt (V)
    [double]$Iout = 5.0,       # Output current in Ampere (A)
    [double]$eta = 0.85,       # Efficiency (0 < eta <= 1)
    [double]$CF1 = 10e-6,      # Filter capacitor 1 value in Farad (F)
    [double]$CF2 = 10e-6,      # Filter capacitor 2 value in Farad (F)
    [double]$LF = 10e-6,       # Filter inductor value in Henry (H)
    [double]$Fsw = 500e3,      # Switching frequency in Hz
    [double]$Qf = 1.0,         # Filter Q factor (suggested value: 1) if not supplied as argument
    [double]$Fco = 100e3,      # Crossover frequency in Hz
    [string]$OutputFile = "FILTER_Results.txt" # Output file name (default)
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




# Calculate the Corner frequency
#(1)  fC = 1 / (2π∙√(Lf ∙ Cf2))
$fc = 1 / (2 * [Math]::PI * [Math]::Sqrt($CF2 * $LF))



# Effective input current
#(2)  Iin = 𝑉out∙𝐼out/ 𝑉in∙η
$Iin = $Vout * $Iout / ($Vin * $eta)

#The filter capacitor CF2 can be calculated using 
# (3)  Cf2 = 1 / (2π∙0,1∙𝑓sw)^2∙𝐿f
# $CF2 = 1 / ( [math]::Pow((2 * [Math]::PI * 0.1 * $Fsw), 2) * $LF )


#The input current ripple can be estimated using equation (4):
#(4)  ΔIin = Iin / (8 ∙ fSW ∙ Lf)
#    Where:
#    ΔIin = Input current ripple
#    fSW = Switching frequency
#    Lf = Filter inductor value
$deltaIin = ($Iin / (8 * $Fsw * $LF))

#The input filter Q is defined with equation (4): 
#(5)  𝑄 =𝑅d∙√𝐶f1 / 𝐿f
if ($Qf -eq 1) {
    $Rd = [math]::Sqrt($CF1 / $LF)
}
else {
    $Qf = $Rd * [math]::Sqrt($CF1 / $LF)
}


#(6)  ZOutF ≪ 𝑍InCon
#Transfer function: 
# ZOutF = (j∙2π∙f∙Lf) / (1 - (Lf∙Cf1∙(2π∙f)^2) + j∙(2π∙f∙Rd∙Cf1))
Add-Type -AssemblyName System.Numerics

$omega = 2 * [Math]::PI * $Fsw
$j = [System.Numerics.Complex]::ImaginaryOne
$numerator = $j * $omega * $LF
$denominator = 1 - ($LF * $CF1 * [Math]::Pow($omega, 2)) + $j * ($omega * $Rd * $CF1)
$ZOut = $numerator / $denominator
$ZOut_Mag = [Math]::Sqrt([Math]::Pow($ZOut.Real,2) + [Math]::Pow($ZOut.Imaginary,2))
$ZOut_Phase = [Math]::Atan2($ZOut.Imaginary, $ZOut.Real) * 180 / [Math]::PI


# Calculate Cd for RC damping network (choose 5x to 10x CF1, use 5x for example)
$Cd = 5 * $CF1
$Cd_uF = $Cd * 1e6

# Display Rd and Cd in summary
$Rd_mOhm = $Rd * 1e3
Write-Result "  Damping Network Values:" "Cyan"
Write-Result ("    - Rd: {0:N2} Ohm`t[= sqrt(CF1 / LF)]" -f $Rd) "Cyan"
Write-Result ("    - Cd: {0:N0} uF`t[= 5 * CF1] (suggested)" -f $Cd_uF) "Cyan"

#A ceramic capacitor Cd in series with the R-C network has a factor of 5 to 10 of the filter-capacitor capacitance.
#(9) (5 ∙ 𝐶F1) < 𝐶d < (10∙𝐶F1)
$Cd_min = 5 * $CF1
$Cd_max = 10 * $CF1

# Convert CF1, CF2 to uF and LF to uH for display
$CF1_uF = $CF1 * 1e6
$CF2_uF = $CF2 * 1e6
$LF_uH = $LF * 1e6



Write-Result "###################### FILTER CALCULATIONS ######################" "Cyan"
Write-Result "" "None"
Write-Result ("    - Corner frequency (fc):`t{0:N2} Hz`t[= 1 / (2 * pi * sqrt(LF * CF2))]" -f $fc) "Green"
Write-Result ("    - CF2:`t`t`t{0:N2} uF`t[= user input]" -f $CF2_uF) "Blue"
Write-Result ("    - LF:`t`t`t{0:N2} uH`t[= user input]" -f $LF_uH) "Blue"
Write-Result "" "None"
Write-Result ("    - Effective input current (Iin):`t{0:N3} A`t[= (Vout * Iout) / (Vin * eta)]" -f $Iin) "Green"
Write-Result ("    - Vin:`t`t`t{0:N2} V" -f $Vin) "Blue"
Write-Result ("    - Vout:`t`t`t{0:N2} V" -f $Vout) "Blue"
Write-Result ("    - Iout:`t`t`t{0:N2} A" -f $Iout) "Blue"
Write-Result ("    - eta:`t`t`t{0:N2}" -f $eta) "Blue"
Write-Result "" "None"
Write-Result ("    - Filter capacitor CF2:`t{0:N2} uF`t[= 1 / (2 * pi * 0.1 * Fsw)^2 * LF]" -f $CF2_uF) "Green"
Write-Result ("    - Fsw:`t`t`t{0:N0} Hz" -f $Fsw) "Blue"
Write-Result "" "None"
Write-Result ("    - Input current ripple (dIin):`t{0:N4} A`t[= Iin / (8 * Fsw * LF)]" -f $deltaIin) "Green"
Write-Result ("    - Iin:`t`t`t{0:N3} A" -f $Iin) "Blue"
Write-Result ("    - Fsw:`t`t`t{0:N0} Hz" -f $Fsw) "Blue"
Write-Result ("    - LF:`t`t`t{0:N2} uH" -f $LF_uH) "Blue"
Write-Result "" "None"
if ($Qf -eq 1) {
    Write-Result ("    - Rd:`t`t`t{0:N2} Ohm`t[= sqrt(CF1 / LF)]" -f $Rd) "Yellow"
} else {
    Write-Result ("    - Q factor:`t`t{0:N2}`t[= Rd * sqrt(CF1 / LF)]" -f $Qf) "Green"
}
Write-Result ("    - CF1:`t`t`t{0:N2} uF" -f $CF1_uF) "Blue"
Write-Result ("    - LF:`t`t`t{0:N2} uH" -f $LF_uH) "Blue"
Write-Result "" "None"
Write-Result ("    - ZOut (rect): ( {0:N6} + {1:N6}j ) Ohm`t[= (j*2pi*f*Lf) / (1 - (Lf*Cf1*(2pi*f)^2) + j*(2pi*f*Rd*Cf1))]" -f $ZOut.Real, $ZOut.Imaginary) "Magenta"
Write-Result ("    - ZOut (polar): {0:N6} | {1:N2} deg`t[polar: |Z|, angle in degrees]" -f $ZOut_Mag, $ZOut_Phase) "Magenta"
Write-Result ("    - ZOut (magnitude only): {0:N6} Ohm" -f $ZOut_Mag) "Magenta"
Write-Result ("    - LF:`t`t`t{0:N2} uH" -f $LF_uH) "Blue"
Write-Result ("    - CF1:`t`t`t{0:N2} uF" -f $CF1_uF) "Blue"
Write-Result ("    - Rd:`t`t`t{0:N2} Ohm" -f $Rd) "Blue"
Write-Result ("    - Omega:`t`t{0:N2}" -f $omega) "Blue"
Write-Result "Fsw: $Fsw Hz" "Blue"
if ($null -ne $numerator) { Write-Result "Numerator: $($numerator.ToString())" "Blue" } else { Write-Result "Numerator: null" "Red" }
if ($null -ne $denominator) { Write-Result "Denominator: $($denominator.ToString())" "Blue" } else { Write-Result "Denominator: null" "Red" }


Write-Result "" "None"
Write-Result "Filter capacitor Cd range: ' (5 * CF1) < Cd < (10 * CF1) '" "Green"
Write-Result "Cd_min: $Cd_min F" "Blue"
Write-Result "Cd_max: $Cd_max F" "Blue"

# ending printout
Write-Result "" "None"
Write-Result "#################################################################" "Cyan"
Write-Result "  Filter Component Values (for reference):" "Cyan"
Write-Result "    - CF1: $CF1_uF uF" "Cyan"
Write-Result "    - CF2: $CF2_uF uF" "Cyan"
Write-Result "    - LF: $LF_uH uH" "Cyan"
Write-Result ("    - Rd: {0:N2} Ohm" -f $Rd) "Cyan"
Write-Result "    - Cd: $Cd_uF uF" "Cyan"

Write-Result "  Input Filter Values:" "Yellow"
Write-Result "    - CF1: $CF1_uF uF`t[= user input]" "Yellow"
Write-Result "    - CF2: $CF2_uF uF`t[= user input]" "Yellow"
Write-Result "    - LF: $LF_uH uH`t[= user input]" "Yellow"
Write-Result ("    - Rd: {0:N2} Ohm`t[= sqrt(CF1 / LF)]" -f $Rd) "Yellow"
Write-Result "    - Cd: $Cd_uF uF`t[= 5 * CF1]" "Yellow"

Write-Result "  FILTER CALCULATIONS:" "Cyan"
Write-Result ("    - Corner frequency (fc):`t{0} Hz`t[= 1 / (2 * pi * sqrt(LF * CF2))]" -f $fc) "Green"
Write-Result ("    - Effective input current (Iin):`t{0} A`t[= (Vout * Iout) / (Vin * eta)]" -f $Iin) "Green"
Write-Result ("    - Input current ripple (dIin):`t{0} A`t[= Iin / (8 * Fsw * LF)]" -f $deltaIin) "Green"
Write-Result ("    - Q factor:`t{0}`t[= Rd * sqrt(CF1 / LF)]" -f $Qf) "Green"
