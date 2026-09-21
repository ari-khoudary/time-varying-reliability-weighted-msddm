# simulation code & results for our time-varying reliability-weighted sequential sampling model

This repository houses all code related to the model first described in Khoudary, Peters*, Bornstein* (2022) [_Precision-weighted evidence integration predicts time-varying influence of memory on perceptual decisions_](https://aaron.bornstein.org/cv/pubs/2022_kpb_ccn.pdf), and further developed in Khoudary, Peters\*, Bornstein\* (preprint) [Memory retrieval explains dynamic effects of expectations on perceptual decisions]. 

## directory structure
- `ccn_2022`: materials used for the results reported in Khoudary, Peters*, Bornstein* (2022) [_Precision-weighted evidence integration predicts time-varying influence of memory on perceptual decisions_](https://aaron.bornstein.org/cv/pubs/2022_kpb_ccn.pdf)
- `data`: simulated data used to generate main text & supplementary figures in the preprint
- `plotting_code`: reads in data from `data` to generate main text & supplementary figures. higher-level figure layout was done manually outside of MATLAB.
- `simulation_code`: wrapper scripts & the main function that implements our model (`doSampling_dotProduct_bernoulli.m`)

Please direct questions and/or comments about this code to ari.khoudary [at] uci.edu.
