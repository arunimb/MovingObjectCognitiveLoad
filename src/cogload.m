function [muF_theta, psd_theta, muF_alpha, psd_alpha, clu, clw]=cogload(eeg_baseline, eeg_trial, dt,  wts, loadType,trantype, ...
    T, theta_r, alpha_r )
%
% This function calculates cognitive load from EEG data
%
% Input parameters:
%       eeg_baseline is nchan x L_b eeg data for baseline
%       eeg_trial is nchan x L_t eeg data for trial
%       nchan is # of channels
%       n is the # of samples
%       dt is the sampling rate
%       wts is the weighting parameters in the order of the channels
%       T is the segment length, 0 for full segment (TBD)
%       theta_r is range of frequencies for theta
%       alpha_r is range of frequencies for alpha
%       trantype is 'stockwell', or 'fft'
%
% Output parameters:
%       muF_* is nchan x 2 vector of mean frequencies for each channel, baseline and
%                           trial
%       psd_* is nchan x 2 vector of psd for each channel at the mean frequency
%       clu is nchan x 1 vector of cl for each channel (unweighted)
%       clw is 1 x 1 weighted cognitive load
%
% References:
%       Klimesch, W. (1999). EEG alpha and theta oscillations reflect
%       cognitive and memory performance: a review and analysis.
%       Brain research reviews, 29(2-3), 169-195.
%
%       Anderson, E. W., Potter, K. C., Matzen, L. E., Shepherd, J. F.,
%       Preston, G. A., & Silva, C. T. (2011, June). A user study of
%       visualization effectiveness using EEG and cognitive load.
%       In Computer graphics forum (Vol. 30, No. 3, pp. 791-800).
%
% v1: 1/30/2022

if nargin < 7
    %     theta_r=[4, 7.5];
    %     alpha_r=[7.5, 12]; % standard partition
    %     wts=ones(14,1);
    theta_r=[4, 9.5];
    alpha_r=[9.5, 11.5]; % "... for young healthy adults" (Klimesch1999)
    %trantype='fft';
    %T=0;
end


% clip eeg_trial
% if size(eeg_trial,2) > 3/dt
%     eeg_trial=eeg_trial(:,1:round(3/dt));
% end


[~, L_b]=size(eeg_baseline);
[nchan, L_t]=size(eeg_trial);

% if T is nonzero split trial data into segments (TBD)

% initialize
muF_theta=zeros(nchan,2);
muF_alpha=zeros(nchan,2);
psd_theta=muF_theta;
psd_alpha=muF_theta;

for cc=1:nchan                              % for each channel
    if strcmp(trantype, 'stockwell')
        [st, ~, freq_b]=sTransform(eeg_baseline(cc,:), 4, 13, dt, 1);
        freq_b=freq_b'*size(eeg_baseline,2)*dt;
        psd_b=mean(abs(st)/L_b,2);      % Mean power divided by length ??
        %         psd_b=mean(abs(st).^2,2);     % Square ??
        %         psd_b=max(abs(st).^2,[],2);   % maximum value??

        [st, ~, freq_t]=sTransform(eeg_trial(cc,:), 4, 13, dt, 1);
        freq_t=freq_t'*size(eeg_trial,2)*dt;
        psd_t=mean(abs(st)/L_t,2);      % ??
        %         psd_t=mean(abs(st).^2,2);     %   ??
        %         psd_t=max(abs(st).^2, [],2);  %
    elseif strcmp(trantype, 'fft')
        [freq_b, psd_b] = run_fft(eeg_baseline(cc,:), 1/dt);
        [freq_t, psd_t] = run_fft(eeg_trial(cc,:), 1/dt);
    end

    % calculate mean frequencies for theta
    idx_b_theta=freq_b>theta_r(1) & freq_b<=theta_r(2);      % index baseline
    idx_t_theta=freq_t>theta_r(1) & freq_t<=theta_r(2);      % index trial

    muF_theta(cc,1)=sum(freq_b(idx_b_theta).*psd_b(idx_b_theta))/sum(psd_b(idx_b_theta));
    muF_theta(cc,2)=sum(freq_t(idx_t_theta).*psd_t(idx_t_theta))/sum(psd_t(idx_t_theta));

    % calculate mean frequencies for alpha
    idx_b_alpha=freq_b>alpha_r(1) & freq_b<=alpha_r(2);
    idx_t_alpha=freq_t>alpha_r(1) & freq_t<=alpha_r(2);

    muF_alpha(cc,1)=sum(freq_b(idx_b_alpha).*psd_b(idx_b_alpha))/sum(psd_b(idx_b_alpha));
    muF_alpha(cc,2)=sum(freq_t(idx_t_alpha).*psd_t(idx_t_alpha))/sum(psd_t(idx_t_alpha));


    % max power (for TAR)
    max_psd_theta(cc,1)=max(psd_b(idx_b_theta));
    max_psd_theta(cc,2)=max(psd_t(idx_t_theta));

    max_psd_alpha(cc,1)=max(psd_b(idx_b_alpha));
    max_psd_alpha(cc,2)=max(psd_t(idx_t_alpha));


    % calculate power associated with mean frequencies
    % first column baseline, second column trial
    psd_theta(cc,1)=interp1(freq_b(idx_b_theta), psd_b(idx_b_theta), muF_theta(cc,1));
    psd_theta(cc,2)=interp1(freq_t(idx_t_theta), psd_t(idx_t_theta), muF_theta(cc,2));

    psd_alpha(cc,1)=interp1(freq_b(idx_b_alpha), psd_b(idx_b_alpha), muF_alpha(cc,1));
    psd_alpha(cc,2)=interp1(freq_t(idx_t_alpha), psd_t(idx_t_alpha), muF_alpha(cc,2));

end


% calculate the differences
% diff([base, trial], 1, 2)= trial-base, e.g. diff([3, 5], 1, 2) = 2
df_theta=diff(muF_theta,1,2);
df_alpha=diff(muF_alpha,1,2);

dpsd_theta=diff(psd_theta,1,2);
dpsd_alpha=diff(psd_alpha,1,2);

if loadType == "alphathetadiff"
    clu=dpsd_alpha.*df_alpha - dpsd_theta.*df_theta;
    clu = clu';
    clw=clu*wts';
end
if loadType == "alphaDiff"
    clu=-(dpsd_alpha);
    clu = clu';
    clw=clu*wts';
end

if loadType == "TAR"
    clu=(psd_theta(3,2)+psd_theta(12,2))/(psd_alpha(6,2)+psd_alpha(9,2));
    clw=clu;
end

% measures
%clu=-(dpsd_alpha);                          % alpha power difference
% clu=dpsd_theta;                           % theta power difference
% clu=-max(dpsd_alpha);                     % max alpha power difference (use mean clu below)
% clu=max(dpsd_theta);                      % max alpha power difference (use mean clu below)
% clu=log10(max_psd_theta(:,2)./max_psd_alpha(:,2));        % TAR w/o baseline
% clu=log10(max_psd_theta(:,2)./max_psd_alpha(:,2))./log10(max_psd_theta(:,1)./max_psd_alpha(:,1)); % TAR1
% clu=abs(dpsd_alpha).*df_alpha - abs(dpsd_theta).*df_theta;    % as is from Bales
% clu=-(dpsd_alpha).*df_alpha + (dpsd_theta).*df_theta;         % Bales but sign change
% clu=abs(dpsd_alpha).*abs(df_alpha) + abs(dpsd_theta).*abs(df_theta);  % Rectangular areas w/ freq. shift
% clu=+(dpsd_alpha) - (dpsd_theta);                             % Just the shift
% clu=max_psd_theta(2,2)/max_psd_alpha(6,2);                    % (theta F7/alpha P7)

% weighting

% clw=mean(clu([1:4, 11:14]));            %   AF and F channels
% clw=mean(clu([1, 14]));               %   AF3 and AF4
% clw=mean(clu([2, 13]));               %   F7 and F8
% clw=mean(clu);                        %   all channels

function [f, d_mag]=run_fft(d, fps)

Y = fft(d);
L=round(length(d)/2)*2;
f=fps*(0:(L/2))/L;
P2 = abs(Y/L);
% d_ph = angle(Y);
d_mag = P2(1:L/2+1);
d_mag(2:end-1) = 2*d_mag(2:end-1);      % one-sided FFT

