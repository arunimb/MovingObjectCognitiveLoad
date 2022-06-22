clear variables

datadir = '../../../data/TrimData'; % Raw data 
outputDir  = '../data/outputTables/';

cogLoadType = {'alphaDiff'};
baseLineType = {'immediate'}; %'first' or 'immediate' %cogLoad varying w/ trial 1 baseline, cogLoad w/ every trial baseline
specmethod = 'fft'; % 'fft' or 'stockwell'
threshold = 1000; % Define max eeg amplitude
combinationNo = 10; % Set what combination to use 1 through 13

subjects=dir([datadir, filesep, 'Subject*']);
agedata=xlsread([datadir, filesep, 'ageAndGender.xlsx']);

% Define Electrode names
electrodeNames = ["AF3" "F7" "F3" "FC5" "T7" "P7" "O1" "O2" "P8" "T8" "FC6" "F4" "F8" "AF4"];

% Store electrode locations
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
electrodePostions = [AF3 ;F7 ;F3 ;FC5; FC6 ;F4 ;F8 ;AF4]; % store frontal electrode positions

% declare empty array for gaussian centroid position
x = []; 
y = [];


sig = [0.1, 0.5, 1]; % standard deviation 
MeanL = [AF3 ;F7; F3; FC5; [-100 -100]]; % Left hemishpere centroids, -100,-100 are there for uniform weighting
MeanR = [AF4 ;F8; F4; FC6; [-100 -100]]; % Right hemisphere centroids
comb = [];
counter = 1;

% create all combinations of gaussian centroid position and standard
% deviation
for meanLoc = 1:5 % iterate weight location 1-AF3 AF4, 2- F7 F8, 3-F3 F4, 4- FC5 FC6, 5- uniform
    for stndd = 1:3 % iterate stan
        comb(counter,:) = [sig(stndd) , MeanL(meanLoc,:), MeanR(meanLoc,:)];
        counter = counter +1;
    end
end

sig = comb(combinationNo,1);
MeanL = comb(combinationNo,2:3);
MeanR = comb(combinationNo,4:5);
for i = 1:numel(electrodeNames)
    temp = findLoc(electrodeNames(i));
    x(i) = temp(1); y(i) = temp(2);
end

cldata=[];
finalData = [];


ntr=24;                                 % trials per subject

accumulatorMatrix = [];
finalMatrix = [];
cumulativeIndex = 0;
for type = 1:1
    for meanLoc = 1:1
        for stndd = 1:1
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
            wts = [weightsL', 0,0,0,0,0,0, weightsR'];
            for ss=1:size(subjects,1)


                fprintf('processing %s ...\n',subjects(ss).name);

                load([datadir, filesep, subjects(ss).name, filesep, 'userPrimary_manual_0p1_20.mat']);
                st_acc=csvread([datadir, filesep, 'SecondaryTaskAccuracy', filesep, ...
                    subjects(ss).name, filesep, 'userSecondary.csv']); % secondary task accuracy
                dt=1/userPrimary.SampleRate;        % sampling rate
                clw = [];
                reaction_time=[];
                subject_age=agedata(agedata(:,1)==str2double(subjects(ss).name(8:end)),2);
                subject_parameters = [];
                c = 1; % to remove skip trials greater that maxeeg

                acceptedTrials = [];
                for trialno=1:24
                    frontal_data=userPrimary.primaryTask(trialno).data(:,[1:4, 11:14]);
                    maxeeg=max(abs(frontal_data(:)));

                    reaction_time=size(userPrimary.primaryTask(trialno).data',2)*dt;
                    if maxeeg<threshold                  % don't want to process a trial that has very high eeg

                        subject_parameters= [userPrimary.parameters(trialno).data(1) userPrimary.parameters(trialno).data(2) userPrimary.parameters(trialno).data(3) userPrimary.parameters(trialno).data(4) userPrimary.parameters(trialno).data(5)];

                        if (baseLineType == "immediate")
                            [~,~,~,~,~,clw]=cogload(userPrimary.baselineTask(trialno).data', ...
                                userPrimary.primaryTask(trialno).data',...
                                dt, wts,cogLoadType(type),specmethod);
                        end

                        if (baseLineType == "first")
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
                    %reaction_time=reaction_time/max(reaction_time);
                    %             accumulatorMatrix(:,4)=(accumulatorMatrix(:,4)-mean(accumulatorMatrix(:,4)))/std(accumulatorMatrix(:,4)); % z-Score Secondary Task Accuracy
                    accumulatorMatrix(:,6)=(accumulatorMatrix(:,6)-mean(accumulatorMatrix(:,6)))/std(accumulatorMatrix(:,6)); % z-Score Secondary Task Accuracy

                    finalMatrix = vertcat(finalMatrix,accumulatorMatrix);
                    accumulatorMatrix = [];
                end

            end
        end
    end

    if string(cogLoadType(type))=="alphathetadiff"
        outputTable = array2table(finalMatrix,...
            'VariableNames',{'Subject','Trial','Gaussian_Centroid','Standard_Deviation','Reaction_Time','Secondary_Task_Acc','Net_Cognitive_Load','Speed','Number_of_Fish','Turbidity','CameraDistance','Fish_Type'});
        writetable(outputTable,[outputDir 'outputForGLMM.csv'],'Delimiter',',');
    end
    if string(cogLoadType(type))=="alphaDiff"
        outputTable = array2table(finalMatrix,...
            'VariableNames',{'Subject','Trial','Gaussian_Centroid','Standard_Deviation','Reaction_Time','Secondary_Task_Acc','Net_Cognitive_Load','Speed','Number_of_Fish','Turbidity','CameraDistance','Fish_Type'});
        writetable(outputTable,[outputDir 'outputForGLMM.csv'],'Delimiter',',');
    end
end

function pos = findLoc(ChannelName)
load('Standard_10-20_81ch.mat');
temp = locations(strcmp(locations.labels,ChannelName),:);
pos = [temp.X temp.Y];
end
