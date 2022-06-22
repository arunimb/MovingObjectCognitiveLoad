clear variables

datadir = '../../../data/TrimData/';
outputDir  = '';
subjects=dir([datadir, filesep, 'Subject*']);

%% Define electrode names
electrodeNames = ["AF3" "F7" "F3" "FC5" "T7" "P7" "O1" "O2" "P8" "T8" "FC6" "F4" "F8" "AF4"];
%% Retrieve x,y, coordinate from location file
AF3 = findLoc(electrodeNames(1));
F7 = findLoc(electrodeNames(2));
F3 = findLoc(electrodeNames(3));
FC5 = findLoc(electrodeNames(4));
T7 = findLoc(electrodeNames(5));
P7 = findLoc(electrodeNames(6));
O1 = findLoc(electrodeNames(7));
O2 = findLoc(electrodeNames(8));
P8 = findLoc(electrodeNames(9));
T8 = findLoc(electrodeNames(10));
FC6 = findLoc(electrodeNames(11));
F4 = findLoc(electrodeNames(12));
F8 = findLoc(electrodeNames(13));
AF4= findLoc(electrodeNames(14));
electrodePostions = [AF3 ;F7 ;F3 ;FC5; FC6 ;F4 ;F8 ;AF4]; % define electrode positions

%% aggregated x,y locations of focal electrodes
x = [];
y = [];
for i = 1:numel(electrodeNames)
    temp = findLoc(electrodeNames(i));
    x(i) = temp(1); y(i) = temp(2);
end

%% Define Gaussain Centroids and standard deviation
sig = [0.1, 0.5, 1]; %standard deviation of weights
MeanL = [AF3 ;F7; F3; FC5; [-100 -100]]; % Left hemishpere centroids, -100,-100 are there for uniform weighting
MeanR = [AF4 ;F8; F4; FC6; [-100 -100]]; % Right hemisphere centroids
%% Define Cog Load measures
cogLoadType = {'alphathetadiff','alphaDiff'};
baseLineType = {'first', 'immediate'}; %cogLoad varying w/ trial 1 baseline, cogLoad w/ every trial baseline
specmethod = 'fft'; % 'fft' or 'stockwell'
threshold = 1000; %Define max eeg amplitude
accumulatorMatrix = [];  % matrix cleared when cogLoadType is changed
finalMatrix = []; % Final matrix to be written to file
for bType = 1:2 %iterate baseline type
    uniformFlag = 0;
    for type = 1:2 % iterate cognitive load type
        for meanLoc = 1:5 % iterate weight location 1-AF3 AF4, 2- F7 F8, 3-F3 F4, 4- FC5 FC6, 5- uniform
            for stndd = 1:3 % iterate standard deviation
                %% Assign weights to electrodes
                Sigma = [sig(stndd) 0;0 sig(stndd)];
                mu = [MeanL(meanLoc,1)  MeanL(meanLoc,2)];
                [X1L,X2L] = meshgrid(linspace(min(x(1:4)),max(x(1:4)),2)',linspace(min(y(1:4)),max(y(1:4)),2)');
                XL = [X1L(:) X2L(:)];
                p = mvnpdf(XL,mu,Sigma);
                p = p/sum(p);
                ZL = reshape(p,2,2);


                mu = [MeanR(meanLoc,1)  MeanR(meanLoc,2)];
                [X1R,X2R] = meshgrid(linspace(min(x(11:14)),max(x(11:14)),2)',linspace(min(y(11:14)),max(y(11:14)),2)');
                XR = [X1R(:) X2R(:)];
                p = mvnpdf(XR,mu,Sigma);
                p = p/sum(p);
                ZR = reshape(p,2,2);


                weightsL = interp2(X1L,X2L,ZL,electrodePostions(1:4,1),electrodePostions(1:4,2));
                weightsR = interp2(X1R,X2R,ZR,electrodePostions(5:8,1),electrodePostions(5:8,2));
                if (sum(MeanL(meanLoc,:))== -200) % check for uniform weighting
                    weightsL = 1/8*ones(4,1);
                    weightsR = 1/8*ones(4,1);
                end
                wts = [weightsL', 0,0,0,0,0,0, weightsR'];


                for ss=1:size(subjects,1) % Cycle user

                    fprintf('processing %s ...\n',subjects(ss).name);

                    load([datadir, subjects(ss).name, filesep, 'userPrimary_manual_0p1_20.mat']);
                    st_acc=csvread([datadir, filesep, 'SecondaryTaskAccuracy', filesep, ...
                        subjects(ss).name, filesep, 'userSecondary.csv']); % secondary task accuracy
                    dt=1/userPrimary.SampleRate;        % sampling rate
                    clw = [];
                    reaction_time=[];
                    %subject_age=agedata(agedata(:,1)==str2double(subjects(ss).name(8:end)),2);
                    subject_parameters = [];
                    c = 1; % to remove skip trials greater that maxeeg

                    acceptedTrials = [];
                    for trialno=1:24
                        frontal_data=userPrimary.primaryTask(trialno).data(:,[1:4, 11:14]); % Only the *F* electrodes
                        maxeeg=max(abs(frontal_data(:)));

                        reaction_time=size(userPrimary.primaryTask(trialno).data',2)*dt;
                        if maxeeg<threshold                  % setting a very high limit to allow all data

                            subject_parameters= [userPrimary.parameters(trialno).data(1) userPrimary.parameters(trialno).data(2) userPrimary.parameters(trialno).data(3) userPrimary.parameters(trialno).data(4) userPrimary.parameters(trialno).data(5)];
                            if (baseLineType(bType) == "immediate")
                                [~,~,~,~,~,clw]=cogload(userPrimary.baselineTask(trialno).data', ...
                                    userPrimary.primaryTask(trialno).data',...
                                    dt, wts,cogLoadType(type),specmethod);
                            end

                            if (baseLineType(bType) == "first")
                                [~,~,~,~,~,clw]=cogload(userPrimary.baselineTask(1).data', ...
                                    userPrimary.primaryTask(trialno).data',...
                                    dt, wts,cogLoadType(type),specmethod);
                            end
                            accumulatorMatrix = vertcat(accumulatorMatrix,[ss,trialno,meanLoc,sig(stndd),reaction_time,st_acc(trialno,1),clw,subject_parameters]);
                            acceptedTrials = [acceptedTrials,trialno];
                        end
                        c = c + 1;
                    end
                    if(~isempty(accumulatorMatrix))
                        % zscore them
                        accumulatorMatrix(:,5)=(accumulatorMatrix(:,5)-mean(accumulatorMatrix(:,5)))/std(accumulatorMatrix(:,5)); %z-Score Reaction time

                        accumulatorMatrix(:,6)=(accumulatorMatrix(:,6)-mean(accumulatorMatrix(:,6)))/std(accumulatorMatrix(:,6)); % z-Score Secondary Task Accuracy

                        finalMatrix = vertcat(finalMatrix,accumulatorMatrix);
                        accumulatorMatrix =[];
                    end


                end
            end
        end
        %% Write to file the final matrices
        if (baseLineType(bType) == "immediate")
            if string(cogLoadType(type))=="alphathetadiff"
                outputTable = array2table(finalMatrix,...
                    'VariableNames',{'Subject','Trial','Gaussian_Centroid','Standard_Deviation','Reaction_Time','Secondary_Task_Acc','Net_Cognitive_Load','Speed','Number_of_Fish','Turbidity','CameraDistance','Fish_Type'});
                writetable(outputTable,['../data/outputTables/outputForGLMM_alphathetadiff_baselineImmediate.csv'],'Delimiter',',');
            end
            if string(cogLoadType(type))=="alphaDiff"
                outputTable = array2table(finalMatrix,...
                    'VariableNames',{'Subject','Trial','Gaussian_Centroid','Standard_Deviation','Reaction_Time','Secondary_Task_Acc','Net_Cognitive_Load','Speed','Number_of_Fish','Turbidity','CameraDistance','Fish_Type'});
                writetable(outputTable,['../data/outputTables/outputForGLMM_alphaDiff_baselineImmediate.csv'],'Delimiter',',');
            end
        end


        if (baseLineType(bType) == "first")
            if string(cogLoadType(type))=="alphathetadiff"
                outputTable = array2table(finalMatrix,...
                    'VariableNames',{'Subject','Trial','Gaussian_Centroid','Standard_Deviation','Reaction_Time','Secondary_Task_Acc','Net_Cognitive_Load','Speed','Number_of_Fish','Turbidity','CameraDistance','Fish_Type'});
                writetable(outputTable,['../data/outputTables/outputForGLMM_alphathetadiff_baseline1.csv'],'Delimiter',',');
            end
            if string(cogLoadType(type))=="alphaDiff"
                outputTable = array2table(finalMatrix,...
                    'VariableNames',{'Subject','Trial','Gaussian_Centroid','Standard_Deviation','Reaction_Time','Secondary_Task_Acc','Net_Cognitive_Load','Speed','Number_of_Fish','Turbidity','CameraDistance','Fish_Type'});
                writetable(outputTable,['../data/outputTables/outputForGLMM_alphaDiff_baseline1.csv'],'Delimiter',',');
            end
        end

        accumulatorMatrix = [];
        finalMatrix = [];
    end
end

totalCombinations = numel(sig)*size(MeanL,1); % Total number of combinations
data = readmatrix("../data/outputTables/outputForGLMM_alphathetadiff_baselineImmediate.csv");
strideLength = size(data,1)/totalCombinations; % Number of rows to skip
rowStart = 1;



%% Immediate baseline calculations
statisticsContainer1_1 = [];
for i = 1:totalCombinations
    tempData = data(rowStart:rowStart+strideLength-1,:);
    weightLoc = mean(tempData(:,3));
    stndd = mean(tempData(:,4));
    reactionTime = tempData(:,5);
    cognitiveLoad = tempData(:,7);
    secondaryAccuracy = tempData(:,6);
    d=dataset(reactionTime, cognitiveLoad);
    mdl1=fitlm(d, 'cognitiveLoad~reactionTime');
    d=dataset(secondaryAccuracy, cognitiveLoad);
    mdl2=fitlm(d, 'cognitiveLoad~secondaryAccuracy');
    tempStats = [table2array(mdl2.Coefficients(2,1)),(mdl2.Rsquared.Ordinary),table2array(mdl2.Coefficients(2,4)),table2array(mdl1.Coefficients(2,1)),(mdl1.Rsquared.Ordinary),table2array(mdl1.Coefficients(2,4))];
    statisticsContainer1_1 = [statisticsContainer1_1; [weightLoc,stndd,tempStats]];%gaussian Location, standard deviation, Secondary Task Accuracy estimate, Secondary Task Accuracy R^2, Secondary Task Accuracy P value, Primary Task estimate, Primary Task R^2, Primary Task P value
    rowStart = rowStart + strideLength;
end

data = readmatrix("../data/outputTables/outputForGLMM_alphadiff_baselineImmediate.csv");
rowStart = 1;
statisticsContainer1_2 = [];
for i = 1:totalCombinations
    tempData = data(rowStart:rowStart+strideLength-1,:);
    weightLoc = mean(tempData(:,3));
    stndd = mean(tempData(:,4));

    reactionTime = tempData(:,5);
    cognitiveLoad = tempData(:,7);
    secondaryAccuracy = tempData(:,6);
    d=dataset(reactionTime, cognitiveLoad);
    mdl1=fitlm(d, 'cognitiveLoad~reactionTime');
    d=dataset(secondaryAccuracy, cognitiveLoad);
    mdl2=fitlm(d, 'cognitiveLoad~secondaryAccuracy');
    tempStats = [table2array(mdl2.Coefficients(2,1)),(mdl2.Rsquared.Ordinary),table2array(mdl2.Coefficients(2,4)),table2array(mdl1.Coefficients(2,1)),(mdl1.Rsquared.Ordinary),table2array(mdl1.Coefficients(2,4))];
    statisticsContainer1_2 = [statisticsContainer1_2; tempStats];%Secondary Task Accuracy estimate, Secondary Task Accuracy R^2, Secondary Task Accuracy P value, Primary Task estimate, Primary Task R^2, Primary Task P value
    rowStart = rowStart + strideLength;
end
statisticsContainer1 = horzcat(statisticsContainer1_1,statisticsContainer1_2); %alphathetadiff, alphadiff
%gaussian Location, standard deviation, Secondary Task Accuracy estimate, Secondary Task Accuracy R^2, Secondary Task Accuracy P value, Primary Task estimate, Primary Task R^2, Primary Task P value
%Print to file statistics for immediate baseline baseline

Table_ImmediateBaseline = array2table(statisticsContainer1,'VariableNames',{'Gaussian Location', 'standard deviation', 'Secondary Task Accuracy estimate atd', 'Secondary Task Accuracy R^2 atd', ...
    'Secondary Task Accuracy P value atd', 'Primary Task estimate atd', 'Primary Task R^2 atd', 'Primary Task P value atd' , 'Secondary Task Accuracy estimate ad', ...
    'Secondary Task Accuracy R^2 ad','Secondary Task Accuracy P value ad', 'Primary Task estimate ad', 'Primary Task R^2 ad', 'Primary Task P value ad'});
writetable(Table_ImmediateBaseline,['../data/outputTables/Table_ImmediateBaseline.csv'],'Delimiter',',');
%% 1st baseline calculations

data = readmatrix("../data/outputTables/outputForGLMM_alphathetadiff_baseline1.csv");
rowStart = 1;
statisticsContainer2_1 = [];
for i = 1:totalCombinations
    tempData = data(rowStart:rowStart+strideLength-1,:);
    weightLoc = mean(tempData(:,3));
    stndd = mean(tempData(:,4));

    reactionTime = tempData(:,5);
    cognitiveLoad = tempData(:,7);
    secondaryAccuracy = tempData(:,6);
    d=dataset(reactionTime, cognitiveLoad);
    mdl1=fitlm(d, 'cognitiveLoad~reactionTime');
    d=dataset(secondaryAccuracy, cognitiveLoad);
    mdl2=fitlm(d, 'cognitiveLoad~secondaryAccuracy');
    tempStats = [table2array(mdl2.Coefficients(2,1)),(mdl2.Rsquared.Ordinary),table2array(mdl2.Coefficients(2,4)),table2array(mdl1.Coefficients(2,1)),(mdl1.Rsquared.Ordinary),table2array(mdl1.Coefficients(2,4))];
    statisticsContainer2_1 = [statisticsContainer2_1; [weightLoc,stndd,tempStats]];%gaussian Location, standard deviation, Secondary Task Accuracy estimate, Secondary Task Accuracy R^2, Secondary Task Accuracy P value, Primary Task estimate, Primary Task R^2, Primary Task P value
    rowStart = rowStart + strideLength;
end

data = readmatrix("../data/outputTables/outputForGLMM_alphadiff_baseline1.csv");
rowStart = 1;
statisticsContainer2_2 = [];
for i = 1:totalCombinations
    tempData = data(rowStart:rowStart+strideLength-1,:);
    weightLoc = mean(tempData(:,3));
    stndd = mean(tempData(:,4));

    reactionTime = tempData(:,5);
    cognitiveLoad = tempData(:,7);
    secondaryAccuracy = tempData(:,6);
    d=dataset(reactionTime, cognitiveLoad);
    mdl1=fitlm(d, 'cognitiveLoad~reactionTime');
    d=dataset(secondaryAccuracy, cognitiveLoad);
    mdl2=fitlm(d, 'cognitiveLoad~secondaryAccuracy');
    tempStats = [table2array(mdl2.Coefficients(2,1)),(mdl2.Rsquared.Ordinary),table2array(mdl2.Coefficients(2,4)),table2array(mdl1.Coefficients(2,1)),(mdl1.Rsquared.Ordinary),table2array(mdl1.Coefficients(2,4))];
    statisticsContainer2_2 = [statisticsContainer2_2; tempStats];%gaussian Location, standard deviation, Secondary Task Accuracy estimate, Secondary Task Accuracy R^2, Secondary Task Accuracy P value, Primary Task estimate, Primary Task R^2, Primary Task P value
    rowStart = rowStart + strideLength;
end
statisticsContainer2 = horzcat(statisticsContainer2_1,statisticsContainer2_2); %alphathetadiff, alphadiff

%Print to file statistics for first baseline
Table_Baseline1 = array2table(statisticsContainer2,'VariableNames',{'Gaussian Location', 'standard deviation', 'Secondary Task Accuracy estimate atd', 'Secondary Task Accuracy R^2 atd', ...
    'Secondary Task Accuracy P value atd', 'Primary Task estimate atd', 'Primary Task R^2 atd', 'Primary Task P value atd' , 'Secondary Task Accuracy estimate ad', ...
    'Secondary Task Accuracy R^2 ad','Secondary Task Accuracy P value ad', 'Primary Task estimate ad', 'Primary Task R^2 ad', 'Primary Task P value ad'});

writetable(Table_Baseline1,['../data/outputTables/Table_Baseline1.csv'],'Delimiter',',');



function pos = findLoc(ChannelName)
load('Standard_10-20_81ch.mat');
temp = locations(strcmp(locations.labels,ChannelName),:);
pos = [temp.X temp.Y];
end
