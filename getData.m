function [s1,s2,data_eeg,durations] = getData(subject,data_electrode)
fs = 64; % sampling rate 


%% Filter: Bandpass

% Larger BW used to take care of the transition period.
% Essentially, transition starts around 8 Hz

N = 7;
Rs = 50;
fstop1 = 1;
fstop2 = 10;

Wn = [fstop1 fstop2]/(fs/2);

[z,p,k] = cheby2(N,Rs,Wn,'bandpass');
[fil_bp_nr,fil_bp_dr] = zp2tf(z,p,k);

% % % dirac = [1 zeros(1,255)];
% % % h = filter(fil_bp_nr,fil_bp_dr,dirac);
% % % figure;
% % % freqz(h);
% % % % figure;
% % % % zplane(fil_bp_nr,fil_bp_dr);

clear N Rs fstop1 fstop2 Wn z p k ;

%% Loading Speech Envelope

if strcmp(subject(1:2),'HI')
    SpeechPath = strcat('./../speech/',subject(1:5),'/');
elseif strcmp(subject(1:2),'NH')
    SpeechPath = './../speech/';
end
SpeechStruct = dir(SpeechPath);
SpeechIndex = [SpeechStruct.isdir];
SpeechFiles = {SpeechStruct(~SpeechIndex).name};

% Obtain durations of speech segments
durations = zeros(1,length(SpeechFiles));
index=1;
for s=SpeechFiles
    [y,~] = audioread(char(strcat(SpeechPath,s)));
    durations(index)= length(y);
    index = index+1;
end

% Init s1 and s2
s1 = zeros(max(durations),length(SpeechFiles));
s2 = zeros(max(durations),length(SpeechFiles));

% Load speech
dim=1;
for s=SpeechFiles
  [y,~] = audioread(char(strcat(SpeechPath,s)));
    
  s1(1:durations(dim),dim) = filtfilt(fil_bp_nr, fil_bp_dr, y(:,1));
  s2(1:durations(dim),dim) = filtfilt(fil_bp_nr, fil_bp_dr, y(:,2));
  dim = dim +1;
end

%% Loading Neural Response

% Load random subject data
EEGpath = './../EEGdata/'; 
subject = strcat(EEGpath,subject);
EEGdata = load(string(subject));
Segs = fieldnames(EEGdata);
    
% Concatenate all segments in EEGdata
data_eeg = zeros(max(durations),length(Segs));

dim = 1;
for s=Segs.'
  EEG = getfield(EEGdata,char(s),'eeg_env');
  
  EEG_data = EEG(1:durations(dim),data_electrode);
  EEG_data = filtfilt(fil_bp_nr, fil_bp_dr, EEG_data);
  EEG_data = deleteOutliers(EEG_data);
  data_eeg(1:length(EEG_data),dim) = EEG_data;
  
  dim = dim +1 ;
end

end
