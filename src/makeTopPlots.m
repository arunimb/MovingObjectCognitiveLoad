clear variables

datadir = '../../data/OriginalData/';
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
electrodePostions = [AF3 ;F7 ;F3 ;FC5; FC6 ;F4 ;F8 ;AF4];

%% aggregated x,y locations of focal electrodes
x = [];
y = [];
for i = 1:numel(electrodeNames)
    temp = findLoc(electrodeNames(i));
    x(i) = temp(1); y(i) = temp(2);
end

%% Define Gaussain Centroids and standard deviation
sig = [0.1, 0.5, 1]; %standard deviation of weights
MeanL = [AF3 ;F7; F3; FC5]; % Left hemishpere centroids
MeanR = [AF4 ;F8; F4; FC6]; % Right hemisphere centroids
%% Define Cog Load measures
cogLoadType = {'alphathetadiff','alphaDiff'};
baseLineType = {'first', 'immediate'}; %cogLoad varying w/ trial 1 baseline, cogLoad w/ every trial baseline
specmethod = 'fft'; % 'fft' or 'stockwell'

accumulatorMatrix = [];  % matrix cleared when cogLoadType is changed
finalMatrix = []; % Final matrix to be written to file
c = 1;
for meanLoc = 1:4 % iterate weight location 1-AF3 AF4, 2- F7 F8, 3-F3 F4, 4- FC5 FC6, 5- uniform
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
%             weightsL = 1/8*ones(4,1);
%             weightsR = 1/8*ones(4,1);
        wts = [weightsL', 0,0,0,0,0,0, weightsR'];
        figure(1)
        electrodeNames = {'AF3', 'F7', 'F3', 'FC5', 'T7', 'P7' ,'O1', 'O2', 'P8', 'T8', 'FC6', 'F4' ,'F8' ,'AF4'};
        subplot(4,3,c)
        plot_topography(electrodeNames, wts, ...
            false, '10-20', false, false, 300);
        caxis([0 0.4]);
        cb=colorbar;
        c = c+1;
    end
end

function pos = findLoc(ChannelName)
load('Standard_10-20_81ch.mat');
temp = locations(strcmp(locations.labels,ChannelName),:);
pos = [temp.X temp.Y];
end