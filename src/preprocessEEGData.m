close all
clear all
clc

addpath('../../../../data/RawData/');

fishSpecies = ['CommonCarp','EurasianRuffe','YellowPerch','RoundGoby'];
userIDs = {'48977','67874','75775','74314','39223','65548','17119','70605','33184','27693', ...
    '84618','69483','38156','76552','43875','23445','82346','79520','95023','31710','18688','19714'};

sampleRate = horzcat(ones(1,13)*128,ones(1,9)*256);
prePath = '../../../../data/RawData/';
postpath = 'data/TrimData/';
filterFlag = 1;
calculateCogloadFlag = 1;
plotRawEEGFlag = 1;
for uu = 1:numel(userIDs) %%Iterate over all Users
    %origEEGData = readmatrix(pathStr1(i));
    pathStr = strcat(prePath,'Subject',userIDs(uu),'/response1.csv');
    %pathStr2 = strcat(prePath,'Subject',userIDs(uu),'\\ManuallyFilteredData.mat');
    %load(pathStr2);
    pathStr3 = [prePath 'Subject' char(userIDs(uu)) '/subjectEEG.csv'];
    userAnswer = readmatrix(char(pathStr));
    temp = readtable(char(pathStr));
    %Convert Fish names into numbers = [EurasianRuffe, RoundGoby,
    %YellowPerch] = [0, 1, 2]
    for i = 1:size(temp,1)
        if(string(table2array(temp(i,7))) == 'EurasianRuffe')
            userAnswer(i,7) = 0;
        end
        if(string(table2array(temp(i,7)))== 'RoundGoby')
            userAnswer(i,7) = 1;
        end
        if(string(table2array(temp(i,7))) == 'YellowPerch')
            userAnswer(i,7) = 2;
        end
    end
    rawEEGData = readmatrix(pathStr3);
    %rawEEGData(:,4:17) = ManuallyFilteredData;
    if (isnan(userAnswer(2,1)))
        userAnswer = userAnswer(3:end,:);
    end

    % Extract primary task parameters
    % Order of parameters:- [speed, number of fish,fog strength, camera
    % distance, type of fish,trial type]
    parameters = zeros(24,5);
    count = 1;
    for i = 1:48
        if(userAnswer(i,4)== 0)
            parameters(count,1:4)= userAnswer(i,8:11);
            parameters(count,5)= userAnswer(i,7);
            count = count + 1;
        end
    end

    %%% File Columns : Cognitive load Channels[1....14], Primary
    %%% Task reaction time, speed, number of fish,fog strength, camera
    %%% distance, type of fish,Secondary Task reaction time, Secondary Task Accuracy, Secondary
    %%% task user answer, Secondary task true answer
    %writematrix(dumm,writePath,'WriteMode','append');

    rawEEGData = rawEEGData(2:end,:);  %Removing the first row (emotiv recommendation)
    beginIndex = find(rawEEGData(:,23) == 49); % Look for Experiment start index
    endIndex = find(rawEEGData(:,23) == 53); % Look for Experiment end index
    rawEEGData = rawEEGData(beginIndex:endIndex,:); %Trim data before experiment start and after experiment end
    %% Filter Data
    onlyEEGData = rawEEGData(:,4:17); %Extract only EEG voltage data from array

    for i = 1:14
        onlyEEGData(:,i) = EEGFilter(onlyEEGData(:,i),sampleRate(uu)); %Filter each channel by a 1-13Hz bandpass filter
    end


    %% Primary Task calculation
    markerColumn = rawEEGData(:,23); % Extract marker data
    baselineMarkers = find(markerColumn == 50); % find indices with baseline marker
    primaryTaskMarkers = find(markerColumn == 51);  % find indices with primary task marker

    baselineMarkersIndexRange = zeros(1,3); % start index, end index, trial type
    c = 1;
    % Order baseline markers in pairs (2 consecutive baseline markers consititue one baseline measurement)
    for i = 1:2:numel(baselineMarkers)
        baselineMarkersIndexRange(c,1) = baselineMarkers(i);
        baselineMarkersIndexRange(c,2) = baselineMarkers(i+1);
        c = c+ 1;
    end
    % baselineMarkersIndexRange has 2 extra baseline measurements : (i)
    % measurement just before break and (ii) Measurement just after last trial
    baselineMarkersIndexRangeBreakCorrected = vertcat(baselineMarkersIndexRange(1:24,:),baselineMarkersIndexRange(26:49,:)); % remove the the middle baseline and the last baseline

    for i = 1:size(baselineMarkersIndexRangeBreakCorrected,1)
        baselineMarkersIndexRangeBreakCorrected(i,3) = userAnswer(i,4);
    end

    primaryTaskMarkersIndexRange = zeros(1,4);%Trial start index, Trial end index, Base start Index, Base end index
    c = 1;
    % Order primary task markers in pairs (2 consecutive primary markers consititue one primary trial measurement)
    for i = 1:2:numel(primaryTaskMarkers)
        primaryTaskMarkersIndexRange(c,1) = primaryTaskMarkers(i);
        primaryTaskMarkersIndexRange(c,2) = primaryTaskMarkers(i+1);
        c = c+ 1;
    end
    c = 1;
    % Associate Baseline marker to primary task
    for i = 1:size(baselineMarkersIndexRangeBreakCorrected,1)
        if baselineMarkersIndexRangeBreakCorrected(i,3) == 0
            primaryTaskMarkersIndexRange(c,3:4) = baselineMarkersIndexRangeBreakCorrected(i,1:2);
            c = c+1;
        end
    end

    %% Secondary Task
    markerColumn = rawEEGData(:,23);
    secondaryTaskMarkers = find(markerColumn == 52); % find indices with secondary task marker
    orderedSecondaryTaskIndices = [];
    c = 1;
    secondaryTaskParameters = zeros(24,5);
    count = 1;
    % Extract secondary task parameters
    for i = 1:48
        if(userAnswer(i,4)==1)
            secondaryTaskParameters(count,1:4)= userAnswer(i,8:11);
            secondaryTaskParameters(count,5)= userAnswer(i,7);
            count = count + 1;
        end
    end
    % Order secondary task indices in pairs
    for i = 1:2:numel(secondaryTaskMarkers)
        orderedSecondaryTaskIndices(c,:) = secondaryTaskMarkers(i:i+1)';
        c = c+1;
    end
    % Calculate Secondary Task Reaction time
    reactionTime = (orderedSecondaryTaskIndices(:,2) - orderedSecondaryTaskIndices(:,1))/sampleRate(uu); % reaction time = # of samples between two indices * time period
    % for i = 1:size(orderedSecondaryTaskIndices,1)
    %     reactionTime(i) = (orderedSecondaryTaskIndices(i,2) - orderedSecondaryTaskIndices(i,1))/sampleRate(uu); % reaction time = # of samples between two indices * time period
    % end
    secondaryTaskUserAnswer = [];
    secondaryTaskTrueAnswer = [];
    c = 1;
    % Extract secondary task user answers and true answers
    for i = 1: size(userAnswer,1)
        if(userAnswer(i,6)>-1)
            secondaryTaskUserAnswer(c) = userAnswer(i,6);
            secondaryTaskTrueAnswer(c) = userAnswer(i,9);
            c = c+1;
        end
    end
    taskAccuracy = [];
    % Calculate secondary task accuracy
    for i = 1: numel(secondaryTaskTrueAnswer)
        if (secondaryTaskUserAnswer(i) == 0)
            taskAccuracy(i) = (abs(6-secondaryTaskTrueAnswer(i)) + abs(7-secondaryTaskTrueAnswer(i)) + abs(8-secondaryTaskTrueAnswer(i)))/3;
            secondaryTaskUserAnswer(i) = 8;
        end
        if (secondaryTaskUserAnswer(i) == 1)
            taskAccuracy(i) = (abs(9-secondaryTaskTrueAnswer(i)) + abs(10-secondaryTaskTrueAnswer(i)) + abs(11-secondaryTaskTrueAnswer(i)))/3;
            secondaryTaskUserAnswer(i) = 10;
        end
        if (secondaryTaskUserAnswer(i) == 2)
            taskAccuracy(i) = (abs(12-secondaryTaskTrueAnswer(i)) + abs(13-secondaryTaskTrueAnswer(i)) + abs(14-secondaryTaskTrueAnswer(i)))/3;
            secondaryTaskUserAnswer(i) = 12;
        end
        %             taskAccuracy(i) = abs(secondaryTaskTrueAnswer(i)-secondaryTaskUserAnswer(i));
        %             if(taskAccuracy(i) == 0)
        %                 taskAccuracy(i) = 1;
        %             elseif(taskAccuracy(i) == 1)
        %                 taskAccuracy(i) = 0.5;
        %             elseif(taskAccuracy(i) == 2)
        %                 taskAccuracy(i) = 0;
        %             end
    end
    secondaryTaskStuff1 = [reactionTime taskAccuracy' secondaryTaskUserAnswer' secondaryTaskTrueAnswer'];
    secondaryTaskStuff1 = horzcat(secondaryTaskStuff1,secondaryTaskParameters);
    orderedSecondaryTask = zeros(size(secondaryTaskStuff1));

    % match secondary task and primary task parameters
    for i = 1:24 %primaryTask
        primaryParameters = parameters(i,:);
        for j = 1:24 %secondaryTask
            secondaryParameters = secondaryTaskParameters(j,:);
            if(secondaryParameters(1)== primaryParameters(1) &&secondaryParameters(2)== primaryParameters(2)&&secondaryParameters(3)== primaryParameters(3)&&secondaryParameters(4)==primaryParameters(4)&&secondaryParameters(5)==primaryParameters(5))
                orderedSecondaryTask(i,:) = secondaryTaskStuff1(j,:);
                break;
            end

        end
    end
    %%% Return array column configuration : Cognitive load Channels[1....14], Primary
    %%% Task reaction time, speed, number of fish,fog strength, camera
    %%% distance, type of fish,Secondary Task reaction time, Secondary Task Accuracy, Secondary
    %%% task user answer, Secondary task true answer
    for ii = 1:size( primaryTaskMarkersIndexRange,1)
        userPrimary.baselineTask(ii).data=onlyEEGData(primaryTaskMarkersIndexRange(ii,3):primaryTaskMarkersIndexRange(ii,4),:);
        userPrimary.primaryTask(ii).data=onlyEEGData(primaryTaskMarkersIndexRange(ii,1):primaryTaskMarkersIndexRange(ii,2),:);
        userPrimary.PrimaryTaskReactionTime(ii).data = (primaryTaskMarkersIndexRange(ii,2)-primaryTaskMarkersIndexRange(ii,1))/sampleRate(uu);
        userPrimary.parameters(ii).data = parameters(ii,:);
    end
    userSecondary = [];
    for ii = 1:size( orderedSecondaryTask,1)
        userSecondary1.reactionTime(ii).data = orderedSecondaryTask(ii,1);
        userSecondary1.accuracy(ii).data=orderedSecondaryTask(ii,2);
        userSecondary1.userAnswer(ii).data=orderedSecondaryTask(ii,3);
        userSecondary1.trueAnswer(ii).data=orderedSecondaryTask(ii,4);
        userSecondary1.parameters(ii).data = orderedSecondaryTask(ii,5:end);
        userSecondary(ii,:) = [userSecondary1.accuracy(ii).data, userSecondary1.parameters(ii).data];
    end
    userPrimary.SampleRate = sampleRate(uu);
    temp = cell2mat(userIDs(uu));
    folder = sprintf('../data/TrimData/Subject%s/',temp);
    mkdir(folder)
    filename = sprintf('../data/TrimData/Subject%s/userSecondary.csv',temp);
    %fclose(fopen(filename, 'w'));
    fid = fopen(fullfile(folder, 'userSecondary.csv'), 'w');
    fclose(fid);
    writematrix(userSecondary,fullfile(folder, 'userSecondary.csv'));
    mkdir([postpath 'Subject' char(userIDs(uu)) '/'])
    filename = [postpath 'Subject' char(userIDs(uu)) '/userPrimary_manual_0p1_20.mat'];
    save(filename,'userPrimary')

    %filename = sprintf('data/TrimData/Subject%s/userSecondary_manual_0p1_20.mat',userIDs(uu));
    filename = [postpath 'Subject' char(userIDs(uu)) '/userSecondary_manual_0p1_20.mat'];
    userSecondary = userSecondary1; %changing variable name
    save(filename,'userSecondary')


end