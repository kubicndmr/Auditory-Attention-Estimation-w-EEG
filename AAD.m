close all;
clear variables;
clc;

%% Parameters
fs = 64; % sampling rate
W = floor(2*fs); % windows length
hop_length = floor(1*W); %hop length
Tmax = 312.5; % decoder lag (ms)
lag = ceil(Tmax*fs/1000); % decoder lag (samples) 
val_sample = 10; % number of samples used in validation 

%% Init performance criterias
f1_scores = {};
accs = {};

%% Augment segment order
rng(5)
P = perms(1:6); % All permutaions
% Remove conescutive weak class segments
for p=1:length(P)
    ind_5 = find(P(p,:)==5);
    ind_6 = find(P(p,:)==6);
    
    if abs(ind_5-ind_6)==1
        P(p,:)=zeros(1,6);
    end
end
P(all(~P,2),:)=[];
% Randomly choose  
test_order = P(randsample(length(P),val_sample),:);

%% Load Subject Data
subjects = ls('../EEGData/*.mat');

for to=1:length(test_order)
    te_order = test_order(to,:);
    f1_scores{to+1,1}=[mat2str(te_order)];
    accs{to+1,1}=[mat2str(te_order)];
    
    for m = 1:size(subjects,1)
        subject = subjects(m,:);       
        f1_scores{1,m+1}=subject(1:5);
        accs{1,m+1}=subject(1:5);
        
        data_electrode = selectElectrodes(subject);
        attention = getAttention(subject);

        [s1,s2,eeg,durations] = getData(subject,data_electrode); 


        %% Pepare Data

        % Test Data
        eeg_test = zeros(1,1);
        s1_test = zeros(1,1);
        s2_test = zeros(1,1);
        att_test = zeros(1,1);

        % Duration
        dur = 0;

        for s=te_order % Segments
            t = 1:durations(s);
            dur = dur + durations(s)/60/fs;

            % Load EEG segments
            eeg_test = vertcat(eeg_test, eeg(t,s));

            % Load speech        
            s1_test = vertcat(s1_test, s1(t,s));
            s2_test = vertcat(s2_test, s2(t,s));

            % Store attention info
            att_test = vertcat(att_test,ones(durations(s),1)*attention(s));
        end

        eeg_test = eeg_test(2:end);
        s1_test = s1_test(2:end);
        s2_test = s2_test(2:end);
        att_test = att_test(2:end);

        clear durations eeg noise s1 s2 data_electrode noise_electrode s t 
        %% Marker Extraction

        % Number of windows
        K = floor((length(eeg_test)-W)/hop_length) + 1;

        % Init decoders
        dec_1 = zeros(lag,1);
        dec_2 = zeros(lag,1);

        % Init markers and attention labels
        m_1 = zeros(K,1); 
        m_2 = zeros(K,1); 
        y_true = zeros(K,1);
        y_hat = zeros(K,1);

        % Reset counter
        start = 1;

        % Iterate over windows
        for k=1:K
            % Select window
            stop = start+W-1;

            e_d = eeg_test(start:stop);
            e_d = (e_d - mean(e_d));
            s_1 = s1_test(start:stop);
            s_1 = (s_1 - mean(s_1));
            s_2 = s2_test(start:stop);
            s_2 = (s_2 - mean(s_2));

            y_true(k) = att_test(start+1);

            start = start + hop_length;

            % Compute decoders with LMMSE
            [dec_1,dec_2] = LMMSE(e_d,s_1,s_2,dec_1,dec_2,lag);

            % Extract attention markers
            n1_1 = getMarker(dec_1,1);
            p2_1 = getMarker(dec_1,2);
            n1_2 = getMarker(dec_2,1);
            p2_2 = getMarker(dec_2,2);

            % Store markers
            m_1(k) = p2_1 - n1_1;
            m_2(k) = p2_2 - n1_2;

            % Decision 
            if m_1(k)>=m_2(k)
                y_hat(k) = attention(1);
            else
                y_hat(k) = attention(5);
            end

        end

%         %%%%%%%%%% 1D FEATURE SPACE PLOT %%%%%%%%%%%%%
% 
%         switch_points = [0; diff(y_true)]; 
%         switch_points = find(switch_points);
%
%         figure('units','normalized','outerposition',[0 0 1 1]);
%         plot(linspace(0,dur,K),m_1,'LineWidth',1.25,'Color',[0.8594 0.0781 0.2344]);
%         hold on;
%         plot(linspace(0,dur,K),m_2,'LineWidth',1.25,'Color',[0 0.8047 0.8164]);
%         for sp = switch_points.'
%             sp = sp*W/fs/60;
%             xline(sp,'k--','LineWidth',2)
%         end
%         xlim([0 dur]);
%         legend('Speaker 1','Speaker 2','Attention Switch Points','FontName','Calibri','FontSize',14);
%         legend('boxoff')
%         legend('Location','bestoutside')
%         xlabel('Time(m)','FontName','Calibri','FontSize',18)
%         ylabel('Amplitude','FontName','Calibri','FontSize',18)
%         title(strcat('Attention Markers {P_{200}- N_{100}} Subject:',subject(1:5)),'FontName','Calibri','FontSize',20)
%         name = num2str(te_order);
%         name = strcat('_',name(name~=' '));
%         grid on;

        %% Performance
        y_hat = (y_hat-1.5)*2;
        y_true = (y_true-1.5)*2;

        if attention(1) == 1 
            TP = sum(y_hat(y_hat==1)==y_true(y_hat==1));
            TN = sum(y_hat(y_hat==-1)==y_true(y_hat==-1));
            FP = sum(y_hat(y_hat==1)~=y_true(y_hat==1));
            FN = sum(y_hat(y_hat==-1)~=y_true(y_hat==-1));
        elseif attention(1)== 2
            TP = sum(y_hat(y_hat==-1)==y_true(y_hat==-1));
            TN = sum(y_hat(y_hat==1)==y_true(y_hat==1));
            FP = sum(y_hat(y_hat==-1)~=y_true(y_hat==-1));
            FN = sum(y_hat(y_hat==1)~=y_true(y_hat==1));
        end

        precision = TP/(TP+FP);
        recall = TP/(TP+FN);
        f1score = 2*(precision *recall)/(precision + recall);
        acc = sum(y_hat==y_true)/length(y_true);
        f1_scores{to+1,m+1}=f1score;
        accs{to+1,m+1}=acc;

        disp(strcat('f1 score: ',num2str(f1score)));
        disp(strcat('accuracy: ',num2str(acc)));
    end   
end

%% Plots

f1score = cell2mat(f1_scores(2:end,2:end));
f1score(isnan(f1score))=0;

figure('units','normalized','outerposition',[0 0 1 1]);
hold on;
stem(f1score.','*','LineWidth',2,'LineStyle','none','Color',[.6973 .1328 .1328])
boxplot(f1score,'Colors',[0.2734 0.5078 0.7031]);
hold off;
set(gca,'FontSize',14);
xticks(1:size(subjects,1))
xticklabels(f1_scores(1,2:end))
xtickangle(45)
xlabel('Subjects','FontName','Calibri','FontSize',20)
ylabel('Performance','FontName','Calibri','FontSize',20)
grid on;
legend('F1 Score','FontName','Calibri','FontSize',14)
title('Subjectwise Performance','FontName','Calibri','FontSize',24)
legend('Location','bestoutside')
legend('boxoff')
axis tight; 
ylim([0 1]); 

acc = cell2mat(accs(2:end,2:end));
figure('units','normalized','outerposition',[0 0 1 1]);
hold on;
stem(acc.','*','LineWidth',2,'LineStyle','none','Color',[.6973 .1328 .1328])
boxplot(acc,'Colors',[0.2734 0.5078 0.7031]);
hold off;
set(gca,'FontSize',14);
xticks(1:size(subjects,1))
xticklabels(f1_scores(1,2:end))
xtickangle(45)
xlabel('Subjects','FontName','Calibri','FontSize',20)
ylabel('Performance','FontName','Calibri','FontSize',20)
grid on;
legend('Accuracy','FontName','Calibri','FontSize',14)
title('Subjectwise Performance','FontName','Calibri','FontSize',24)
legend('Location','bestoutside')
legend('boxoff')
axis tight; 
ylim([0 1]);

%% Save
save('results.mat','f1_scores','accs','test_order')