## Calculating cognitive load for moving object classification

This repository contains scripts for the following paper

Bhattacharya, A. and Butail, S. (2023). Measurement and analysis of cognitive load associated with moving object classification in underwater environments. _International Journal of Human-Computer Interaction_.

### Description of data

*   /TrimData ? contains filtered and processed EEG Data
*   /TrimData/SubjectXXXXX
*   /TrimData/SubjectXXXXX/response1.csv contains subjects' response to the trial questions
*   /TrimData/SubjectXXXXX/response2.csv contains subjects' response NASA-TLX and Virtual video questionnaire
*   /TrimData/SubjectXXXXX/userPrimary\_manual\_0p1\_20.mat contains subjects' EEG data, filtered using a 0.1Hz to 20Hz bandpass filter
*   /TrimData/SubjectXXXXX/userPrimary\_manual\_0p1\_20\_ASRcorrected.mat contains subjects' EEG data, filtered using EEGlab's automated artifact removal algorithm
*   /TrimData/SubjectXXXXX/userSecondary\_manual\_0p1\_20.mat contains subjects' secondary task data
*   /TrimData/SecondaryTaskAccuracy/SubjectXXXXX/userSecondary.csv contains scores of subjects' answer to the secondary task questions

### How to use the code

To replicate the analysis, run the following steps (Step 1 may be skipped to directly work with filtered data):

1.  To preprocess the raw Captured EEG data, open preprocessEEGData.m and set point to the folder containing raw EEG data (available on request). Running the script will produce /TrimData/SubjectXXXXX/userPrimary\_manual\_0p1\_20.mat and /TrimData/SubjectXXXXX/userSecondary\_manual\_0p1\_20.mat, where XXXXX stands for randomized subject ID.
2.  Run the script writeNetCognitiveLoad.m, by default it is set to use 'fft'. To use ‘stockwell’ transform change the variable specmethod in line 41. The script uses sTransform.m, which is a function written by Robert Stockwell. Similar functions may be used. The script outputs 6 files (The last two files summarize the first four. The last three lines in the summary files show uniform weighting):
    1.  outputForGLMM\_alphaDiff\_baseline1.csv
    2.  outputForGLMM\_alphathetadiff\_baseline1.csv
    3.  outputForGLMM\_alphathetadiff\_baselineImmediate.csv
    4.  outputForGLMM\_alphaDiff\_baselineImmediate.csv
    5.  Table\_ImmediateBaseline.csv
    6.  Table\_Baseline1.csv
3.  Script cogload\_reactionTime\_secondaryAccuracy.m will produce figure #5 in the paper
4.  Script FocalAnalysis.m (change lines 6, 7,8, 9, 10 to the required measure). This outputs file outputForGLMM.csv. This file will be used in GLM analysis in R.
5.  For the GLM analysis results, open GLM\_notebook.nb.html‚ in a web browser. Open GLM\_notebook.R in R-Studio to make changes.
6.  To produce figure 4 from the paper, run file 'makeTopPlots.m', that will produce the subplots I-XII. Uncomment lines 68 and 69 to produce subplot XIII.