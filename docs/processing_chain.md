# Processing Chain

## 2PSK Processing Chain

1. Random bit generation

   Generate a binary sequence and map bits to polar symbols:

   ```text
   bit 1 -> +1
   bit 0 -> -1
   ```

2. Baseband waveform generation

   Each polar symbol is expanded to multiple samples according to the sampling rate and bit rate.

3. Carrier modulation

   The polar baseband sequence modulates a carrier:

   ```text
   s(t) = a_k cos(2 pi f_c t)
   ```

   where `a_k` is `+1` or `-1`.

4. AWGN channel

   Add white Gaussian noise according to the selected `Eb/N0`.

5. Coherent demodulation

   Multiply the received signal by a locally generated carrier and integrate over each bit interval.

6. Decision

   The receiver decides according to the sign of the integration result:

   ```text
   integration result > 0 -> bit 1
   integration result <= 0 -> bit 0
   ```

7. BER evaluation

   Compare recovered bits with transmitted bits and plot simulated BER against theoretical BER.

8. Phase ambiguity analysis

   Change local carrier phase and observe the BER degradation caused by phase mismatch.

## MSK Processing Chain

1. Random bit generation

   Generate binary data and convert it to NRZ symbols:

   ```text
   bit 1 -> +1
   bit 0 -> -1
   ```

2. Frequency-deviation assignment

   MSK uses the minimum frequency spacing condition:

   ```text
   h = 0.5
   Delta_f = Rb / 2
   single-side frequency deviation fd = Rb / 4
   ```

3. Continuous phase accumulation

   The instantaneous frequency deviation is integrated to form a continuous phase trajectory. This is the main difference from ordinary discontinuous 2FSK.

4. MSK waveform generation

   Generate passband and equivalent complex-baseband MSK waveforms from the continuous phase.

5. Spectrum comparison

   Compare MSK with ordinary 2FSK to show the sidelobe reduction caused by phase continuity.

6. AWGN channel

   Add Gaussian noise under different `Eb/N0` values.

7. Coherent correlation detection

   For each bit interval, build two candidate reference signals:

   ```text
   ref1: current bit is 1
   ref0: current bit is 0
   ```

   Then compute the correlation statistics:

   ```text
   corr1 = real(rx * ref1')
   corr0 = real(rx * ref0')
   ```

8. Decision

   The decision rule is:

   ```text
   corr1 > corr0 -> bit 1
   corr1 <= corr0 -> bit 0
   ```

   This is a correlation-detector implementation of the same matched-filter/integration decision idea used in coherent demodulation.

9. BER evaluation

   The simulated BER is compared with the coherent theoretical reference:

   ```text
   Q(sqrt(Eb/N0))
   ```

10. Parameter comparison

   The MSK module compares:

   - `Rb`: changes bit duration, minimum frequency spacing, waveform speed, and bandwidth.
   - `fc`: shifts the passband spectrum center without changing the baseband shape.
   - `Eb/N0`: changes AWGN strength and therefore BER.
   - `NBitsSystem`: changes Monte Carlo statistical stability.

## Related Source Files

2PSK:

```text
2psk/run_all.m
2psk/src/default_2psk_config.m
2psk/src/simulate_2psk_system.m
```

MSK:

```text
msk/MSK_Live_AllInOne_Source.m
msk/MSK_AllInOne.m
```

Combined compact simulation:

```text
run_all_combined.m
combined_src/simulate_2psk.m
combined_src/simulate_msk.m
combined_src/simulate_extras.m
```
