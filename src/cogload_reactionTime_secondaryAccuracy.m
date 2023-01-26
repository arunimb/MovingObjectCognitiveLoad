clear variables

datadir='..\src\data\TrimData\'; 


subjects=dir([datadir, filesep, 'Subject*']);

cldata=[];

wts=[ 0.0398,    0.370,    0.1741 ,   0.6393 ,        0   ,      0   ,      0   ,      0 ,        0  ,       0  ,  0.6393  ,  0.1741 ,0.3706,    0.0398]';
wts(5:10,1)=0;

ntr=24;                                 % trials per subject

cogLoadType = {'alphaDiff'};
baseLineType = {'immediate'}; %'first' or 'immediate' %cogLoad varying w/ trial 1 baseline, cogLoad w/ every trial baseline
specmethod = 'fft'; % 'fft' or 'stockwell'
for ss=1:size(subjects,1)
    fprintf('processing %s ...\n',subjects(ss).name);
    
    load([datadir, subjects(ss).name, filesep, 'userPrimary_manual_0p1_20.mat']);
    st_acc=csvread([datadir, filesep, filesep, ...
           subjects(ss).name, filesep, 'userSecondary.csv']); % secondary task accuracy
    dt=1/userPrimary.SampleRate;        % sampling rate
    clw=zeros(ntr,1);                   % initialize weighted cognitive load
    reaction_time=clw;
    
    for trialno=1:24
        frontal_data=userPrimary.primaryTask(trialno).data(:,[1:4, 11:14]);
        maxeeg=max(abs(frontal_data(:)));
        reaction_time(trialno)=size(userPrimary.primaryTask(trialno).data',2)*dt;
        if maxeeg<1000                 % don't want to process a trial that has very high eeg
            % to use the first baseline, change to baselineTask(1)
%             [~,~,~,~,~,clw(trialno)]=cogload(userPrimary.baselineTask(1).data', ...
%                        userPrimary.primaryTask(trialno).data',...
%                        dt,wts);

            % sanity check 1, we should still get good result if the baseline
            % is during the trial
            [~,~,~,~,~,clw(trialno)]=cogload(userPrimary.baselineTask(trialno).data', ...
                       userPrimary.primaryTask(trialno).data',...
                       dt, wts',cogLoadType,specmethod);
%                    
            % sanity check 2, comparing baselines during the trial should not
            % register high cognitive load
            
%             [~,~,~,~,~,clw(trialno)]=cogload(userPrimary.baselineTask(1).data', ...
%                        userPrimary.baselineTask(trialno).data',...
%                        dt); 
%              % because all reaction times will be same, add a tiny bit of noise
%              reaction_time(trialno)=size(userPrimary.baselineTask(trialno).data',2)*dt+randn*0.1;  
                
        end
    end
    
   % remove all rejected triaals
   idx1=clw~=0;
   
   % remove data for rejected trials
   reaction_time=reaction_time(idx1);
   st_acc=st_acc(idx1,1); % what are columns 5 and 6?
   
   % zscore them
   reaction_time=(reaction_time-mean(reaction_time))/std(reaction_time);
   st_acc=(st_acc-mean(st_acc))/std(st_acc);   

   % append to the data array
    try
   if sum(idx1)
cldata=[cldata;
            ss*ones(sum(idx1),1), (1:sum(idx1))', clw(idx1), ...
            reaction_time, st_acc];
   end
    catch
        keyboard
    end

end


size(cldata,1)/(size(subjects,1)*24)        % percent trials used

% regression models 
% reaction time
reactionTime=cldata(:,4);
cognitiveLoad=cldata(:,3);

d=dataset(reactionTime, cognitiveLoad);
% mdl=fitlm(d, 'cognitiveLoad~reactionTime+ageYrs') % use this only if the alpha range is set by age
mdl=fitlm(d, 'cognitiveLoad~reactionTime')
figure(1); gcf; clf;
subplot(121)
plot(mdl);
xlabel('reaction time (s)');
ylabel('cognitive load (v)');

% secondary task accuracy
subplot(122)
secondaryAccuracy=cldata(:,5);
d=dataset(secondaryAccuracy, cognitiveLoad);
% mdl=fitlm(d, 'cognitiveLoad~secondaryAccuracy+ageYrs') % use this only if the alpha range is set by age
mdl=fitlm(d, 'cognitiveLoad~secondaryAccuracy')
plot(mdl);
xlabel('seconadary task accuracy');
ylabel('cognitive load (v)');
