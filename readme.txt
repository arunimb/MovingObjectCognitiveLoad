## Contains script for paper [1]

Description of files in data folder:
	/TrimData -> contains filtered and processed EEG Data
		/TrimData/SubjectXXXXX
			/TrimData/SubjectXXXXX/response1.csv contains subjects' response to the trial questions
			/TrimData/SubjectXXXXX/response2.csv contains subjects' response NASA-TLX and Virtual video questionnaire
			/TrimData/SubjectXXXXX/userPrimary_manual_0p1_20.mat contains subjects' EEG data, filtered using a 0.1Hz to 20Hz bandpass filter
			/TrimData/SubjectXXXXX/userPrimary_manual_0p1_20_ASRcorrected.mat contains subjects' EEG data, filtered using EEGlab's automated artifact removal algorithm
			/TrimData/SubjectXXXXX/userSecondary_manual_0p1_20.mat contains subjects' secondary task data
			/TrimData/SecondaryTaskAccuracy/SubjectXXXXX/userSecondary.csv contains scores of subjects' answer to the secondary task questions
			

To replicate the analysis, run the following steps (Step 1 may be skipped to directly work with filtered data):
1)	To preprocess the raw Captured EEG data, open preprocessEEGData.m and set point to the folder containing raw EEG data (available on request).
	Running the script will produce /TrimData/SubjectXXXXX/userPrimary_manual_0p1_20.mat and /TrimData/SubjectXXXXX/userSecondary_manual_0p1_20.mat, where XXXXX stands for randomized subject ID. 
2)	Run the script writeNetCognitiveLoad.m, by default it is set to use ‘fft ‘, to use ‘stockwell’ change the variable specmethod in line 41. The script outputs 6 files:
a.	outputForGLMM_alphaDiff_baseline1.csv
b.	outputForGLMM_alphathetadiff_baseline1.csv
c.	outputForGLMM_alphathetadiff_baselineImmediate.csv
d.	outputForGLMM_alphaDiff_baselineImmediate.csv
e.	Table_ImmediateBaseline.csv
f.	Table_Baseline1.csv
The last two files summarize the first four. The last three lines in the summary files show uniform weighting.

3)	Script cogload_reactionTime_secondaryAccuracy.m will produce figure #5 in the paper
4)	Script FocalAnalysis.m (change lines 6, 7,8, 9, 10 to the required measure). This outputs file outputForGLMM.csv. This file will be used in GLM analysis in R.
5)	For the GLM analysis results, open ‘GLM_notebook.nb.html’ in a web browser. Open ‘GLM_notebook.Rmd’ in R-Studio to make changes.
6)	To produce figure 4 from the paper, run file 'makeTopPlots.m', that will produce the subplots I-XII. Uncomment lines 68 and 69 to produce subplot XIII.

[1] Bhattacharya, A., & Butail, S. (2023). Measurement and analysis of cognitive load associated with moving object classification in underwater environments. International Journal of Human–Computer Interaction. 