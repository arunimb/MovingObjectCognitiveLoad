
function [EEG] = EEGFilter(eeg_data,fsamp)
N_ch=size(eeg_data,2);
f_low = 20;
f_high = 0.1;


% High-pass EEG filter
[b1,a1]=butter(2,2*f_high/fsamp,'high');
for i=1:N_ch
    eeg_data2(:,i)=transpose(filtfilt(b1,a1,eeg_data(:,i)));
end

% Low-pass EEG filter
[b,a]=butter(2,2*f_low/fsamp,'low');

for i=1:N_ch
    EEG(:,i)=transpose(filtfilt(b,a,eeg_data2(:,i)));
end



% % Notch filter
%  Wn = [58 62]/fsamp*2;                % Cutoff frequencies
% [bn,an] = butter(order,Wn,'stop');        % Calculate filter coefficients
% for i=1:N_ch
%     EEG(:,i)=transpose(filtfilt(bn,an,eeg_data2(:,i)));
% end

end