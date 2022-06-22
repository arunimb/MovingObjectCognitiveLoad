To start the analysis: Note that “TrimData” contains raw EEG data and is approximately 1.2 GB folder that is available upon request. Files “writeNetCognitiveLoad.m” and “FocalAnalysis.m ” require this dataset.
1)	Run file writeNetCognitiveLoad.m, by default it is set to use ‘fft ‘, to use ‘stockwell’ change the variable specmethod in line 41. The script outputs 6 files:
a.	outputForGLMM_alphaDiff_baseline1.csv
b.	outputForGLMM_alphathetadiff_baseline1.csv
c.	outputForGLMM_alphathetadiff_baselineImmediate.csv
d.	outputForGLMM_alphaDiff_baselineImmediate.csv
e.	Table_ImmediateBaseline.csv
f.	Table_Baseline1.csv
The last two files are summary of the other four files. The last three lines in the summary files show uniform loading which is why the values are duplicated.

2)	Once the weighting has been decided upon, note the combination. Run file FocalAnalysis.m . Change lines 6, 7,8, 9, 10 to the required measure. This outputs file outputForGLMM.csv. This file will be used in GLM analysis in R.
3)	For the GLM analysis results, open ‘GLM_notebook.nb.html’ in a we browser. Open ‘GLM_notebook.Rmd’ in R-Studio to make changes.
