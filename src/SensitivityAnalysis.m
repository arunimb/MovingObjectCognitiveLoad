clear variables


cognitiveLoadType = "alphaDiff"; % Cognitive Load Measure: "alphaDiff", "alphathetadiff"
spectralType = 'fft'; % Power Spectral type: 'fft', 'stockwell'
baselining = 1; % Baseline type: 0 -> Baseline immediately prior to trial, 1 -> Baseline prior to experiment
combinationNo = 10; % Most robust weighting combination, 1 through 13
EEG_threshold = [900 1000 1100];


datadir = '../../../data/TrimData';


electrodeNames = ["AF3" "F7" "F3" "FC5" "T7" "P7" "O1" "O2" "P8" "T8" "FC6" "F4" "F8" "AF4"]; % electrodes on Emotiv Epoc

%% Define electrode coordinates

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
electrodePostions = [AF3 ;F7 ;F3 ;FC5; FC6 ;F4 ;F8 ;AF4];

x = [];
y = [];
sig = [0.1, 0.5, 1]; % standard deviation
MeanL = [AF3 ;F7; F3; FC5; [-100 -100]]; % Left hemishpere centroids, -100,-100 are there for uniform weighting
MeanR = [AF4 ;F8; F4; FC6; [-100 -100]]; % Right hemisphere centroids
comb = [];
counter = 1;
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

Sigma = [sig 0;0 sig];
mu = [MeanL(1)  MeanL(2)];
[X1L,X2L] = meshgrid(linspace(min(x(1:4)),max(x(1:4)),2)',linspace(min(y(1:4)),max(y(1:4)),2)');
XL = [X1L(:) X2L(:)];
p = mvnpdf(XL,mu,Sigma);
p = p/sum(p);
%p = 1/8*ones(size(p));
ZL = reshape(p,2,2);


mu = [MeanR(1)  MeanR(2)];
[X1R,X2R] = meshgrid(linspace(min(x(11:14)),max(x(11:14)),2)',linspace(min(y(11:14)),max(y(11:14)),2)');
XR = [X1R(:) X2R(:)];
p = mvnpdf(XR,mu,Sigma);
p = p/sum(p);
%p = 1/8*ones(size(p));
ZR = reshape(p,2,2);



weightsL = interp2(X1L,X2L,ZL,electrodePostions(1:4,1),electrodePostions(1:4,2));
weightsR = interp2(X1R,X2R,ZR,electrodePostions(5:8,1),electrodePostions(5:8,2));
wts = [weightsL', 0,0,0,0,0,0, weightsR'];

subjects=dir([datadir, filesep, 'Subject*']);
agedata=xlsread([datadir, filesep, 'ageAndGender.xlsx']);
ntr=24;                                 % trials per subject

%Declare empty array
cldata=[];
RsquaredSecondaryTask = [];
pvalueSecondaryTask = [];
estimateSecondaryTask = [];

RsquaredPrimaryTask = [];
pvaluePrimaryTask = [];
estimatePrimarytask = [];

for threshold = 1:3

    for ss=1:size(subjects,1)  % iterate over subjects
        fprintf('processing %s ...\n',subjects(ss).name);
        load([datadir, filesep, subjects(ss).name, filesep, 'userPrimary_manual_0p1_20.mat']);
        st_acc=csvread([datadir, filesep, 'SecondaryTaskAccuracy', filesep, ...
            subjects(ss).name, filesep, 'userSecondary.csv']); % secondary task accuracy
        dt=1/userPrimary.SampleRate;        % sampling rate
        clw=zeros(ntr,1);                   % initialize weighted cognitive load
        reaction_time=clw;
        subject_age=agedata(agedata(:,1)==str2double(subjects(ss).name(8:end)),2);
        for trialno=1:24 % iterate over primary trials
            frontal_data=userPrimary.primaryTask(trialno).data(:,[1:4, 11:14]);
            maxeeg=max(abs(frontal_data(:)));
            reaction_time(trialno)=size(userPrimary.primaryTask(trialno).data',2)*dt;
            if maxeeg < EEG_threshold(threshold)                % don't want to process a trial that has very high eeg
                if baselining == 1
                    [~,~,~,~,~,clw(trialno)]=cogload(userPrimary.baselineTask(trialno).data', ...
                        userPrimary.primaryTask(trialno).data',...
                        dt, wts,cognitiveLoadType,spectralType);
                end
                if baselining == 0
                    [~,~,~,~,~,clw(trialno)]=cogload(userPrimary.baselineTask(1).data', ...
                        userPrimary.primaryTask(trialno).data',...
                        dt, wts,cognitiveLoadType,spectralType);
                end
            end
        end
        % remove all rejected trials
        idx1=clw~=0;

        % remove data for rejected trials
        reaction_time=reaction_time(idx1);
        st_acc=st_acc(idx1,1); % what are columns 5 and 6?

        % zscore
        reaction_time=(reaction_time-mean(reaction_time))/std(reaction_time);
        st_acc=(st_acc-mean(st_acc))/std(st_acc);

        % append to the data array
        try
            if sum(idx1)
                cldata=[cldata;
                    ss*ones(sum(idx1),1), (1:sum(idx1))', clw(idx1), ...
                    reaction_time, st_acc, subject_age*ones(sum(idx1),1)];
            end
        catch
            keyboard
        end

    end

    % regression models
    reactionTime=cldata(:,4);
    cognitiveLoad=cldata(:,3);
    secondaryAccuracy=cldata(:,5);
    d1=dataset(reactionTime, cognitiveLoad);
    mdl1=fitlm(d1, 'cognitiveLoad~reactionTime'); % Primary Task regression
    d2=dataset(secondaryAccuracy, cognitiveLoad);
    mdl2=fitlm(d2, 'cognitiveLoad~secondaryAccuracy'); % secondary Task regression

    RsquaredSecondaryTask(threshold) = mdl2.Rsquared.Ordinary; % get Rsquared value
    pvalueSecondaryTask(threshold) = mdl2.Coefficients.pValue(2); % get p value
    estimateSecondaryTask(threshold) = mdl2.Coefficients.Estimate(2); % get coefficent

    RsquaredPrimaryTask(threshold) = mdl1.Rsquared.Ordinary;% get Rsquared value
    pvaluePrimaryTask(threshold) = mdl1.Coefficients.pValue(2); % get p value
    estimatePrimaryTask(threshold) = mdl1.Coefficients.Estimate(2);% get coefficent
    
    cldata = [];

end
aggregatedMatrix = [estimateSecondaryTask',RsquaredSecondaryTask', pvalueSecondaryTask',estimatePrimaryTask',RsquaredPrimaryTask', pvaluePrimaryTask'];
% Supplementa S3 table
FinalTable = array2table(aggregatedMatrix,'VariableNames',{'Secondary Task estimate'...
    ,'Secondary Task Rsquared','Secondary Task p Value','Primary Task estimate'...
    ,'Primary Task Rsquared','Primary Task p Value'});
disp(FinalTable);
function pos = findLoc(ChannelName)
load('Standard_10-20_81ch.mat');
temp = locations(strcmp(locations.labels,ChannelName),:);
pos = [temp.X temp.Y];
end

