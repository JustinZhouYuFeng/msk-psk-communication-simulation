# MSK and 2PSK Communication Simulation

This repository contains MATLAB simulation code and processing-chain notes for a communication-principles seminar project.

The project covers:

- 2PSK/BPSK modulation, coherent demodulation, AWGN channel, BER simulation, and phase ambiguity analysis.
- MSK modulation, continuous-phase waveform generation, spectrum comparison, AWGN coherent correlation detection, BER simulation, and parameter-effect comparison.

## Directory Layout

```text
.
├── 2psk/
│   ├── run_all.m
│   ├── topic2_2psk_full_code.m
│   ├── src/
│   └── docs/
├── msk/
│   ├── MSK_Live_AllInOne_Source.m
│   ├── MSK_AllInOne.m
│   └── draw_*.py / draw_*.m
├── combined_src/
│   ├── simulate_2psk.m
│   ├── simulate_msk.m
│   └── simulate_extras.m
├── docs/
│   └── processing_chain.md
├── tools/
└── run_all_combined.m
```

## Run

Run the 2PSK module:

```matlab
cd('2psk')
run_all
```

Run the MSK module:

```matlab
cd('msk')
MSK_Live_AllInOne_Source
```

Run the compact combined version:

```matlab
run_all_combined
```

Generated figures and result summaries are written to each module's output folder.

## Main Parameter Locations

2PSK parameters:

```text
2psk/src/default_2psk_config.m
```

MSK parameters:

```text
msk/MSK_Live_AllInOne_Source.m
```

Important MSK comparison parameters include:

```matlab
cfg.parameterRbVec = [500 1000 2000];
cfg.parameterFcVec = [3000 4000 5000];
cfg.EbNoDbVec = 0:1:10;
```

See `docs/processing_chain.md` for the complete processing-chain explanation.
