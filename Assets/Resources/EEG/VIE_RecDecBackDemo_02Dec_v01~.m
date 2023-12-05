%% copy right 2023 Takuya Ibaraki. Vie Style Inc.
clear
%% path setting
defaultpath=pwd;
% defaultpath=defaultpath(1:max(strfind(defaultpath,'\')-1))
[datafile,datapath]  = uigetfile([defaultpath '\data'],'MultiSelect','off');
load([datapath '\' datafile])

addpath(genpath([defaultpath '\script']))

modelsavepath=[defaultpath '\Model'];
mkdir([defaultpath '\Model']);

mkdir([defaultpath '\data']);

outputpath=[defaultpath '\output'];
mkdir([defaultpath '\output'])

%% Filter Setting
SAMPLE_FREQ_VIE=600;
[B1f,A1f] = butter(4,[3/(SAMPLE_FREQ_VIE/2) 40/(SAMPLE_FREQ_VIE/2)]);% 3~40Hzバタワースフィルタ設計
Zf1=[];
FreqWindow=[4:0.5:40];%power calc win
timeWindow=4;

ThuZ=2;%Noise判定　標準波形からの標準偏差


%% Signal Index
NoiseMetricsLabel={'Average Power_L' 'Average Power_R' 'RMS_L' 'RMS_R' 'MaxGradient_L' 'MaxGradient_R' 'ZeroCrossing Rate_L' 'ZeroCrossing Rate_R' 'Kurtosis_L' 'Kurtosis_R'};
NoiseMU=[138.502300000000	138.502300000000	12.1827000000000	12.1827000000000	103.387000000000	103.387000000000	0.0353000000000000	0.0353000000000000	10.1240000000000	10.1240000000000];
NoiseSigma=[123.240600000000	123.240600000000	6.02540000000000	6.02540000000000	69.4416000000000	69.4416000000000	0.00390000000000000	0.00390000000000000	2.89900000000000	2.89900000000000];


%% ICA FIlter の学習
Allfdata=[];
for F=1:size(Data,1)
    alldataV=Data{F,4};
    [Filteredalldata,Zf1]= filter(B1f, A1f,alldataV,Zf1);
    Allfdata=[Allfdata;Filteredalldata];
end
Mdl2 = rica(Allfdata(:,[1 2]),2);
ICAdata2 = transform(Mdl2,Allfdata(:,[1 2]));
[~,icaidx]=max(rms(ICAdata2));%RMSが大きいほうをノイズとする

% figure;plot(Filteredalldata(601:3000,[1 2]),'LineWidth',2);hold on
% plot(ICAdata2(601:3000,:));%h

%% Pre Process
cpower=[];cpowerICA=[]; Timelag=[];   g=1;cNoise=[];NoiseMatsub=[];noiseFlag=[];Annotdata=[];conddata={};
g=1;
for T=1:size(Data,1)
    alldataV=Data{T,4};
    %#1 power
    wlist=0:SAMPLE_FREQ_VIE:length(alldataV)-timeWindow*SAMPLE_FREQ_VIE; % 
    for m=wlist
            cdata= alldataV(m+1:m+SAMPLE_FREQ_VIE*timeWindow,:);
            [cdataf,Zf1]= filter(B1f, A1f,cdata,Zf1);

            %% normal power
            [pxx,f] = pwelch(cdata,SAMPLE_FREQ_VIE*timeWindow,0,FreqWindow,SAMPLE_FREQ_VIE);
            %             figure;plot(f,pxx);%hold on
            for ele=1:3
                cpower(ele,g,:)=[pxx(:,ele)];%Relative Power 1Trial 2windowNo 3freq 4channel
            end
            %% ICA data
            ICAdata = transform(Mdl2,cdataf(:,[1 2]));
            cdata2=[cdataf(:,1)-ICAdata(:,icaidx) cdataf(:,2)-ICAdata(:,icaidx)  cdataf(:,2)-cdataf(:,1)];

            [pxx,f] = pwelch(cdata2,SAMPLE_FREQ_VIE*timeWindow,0,FreqWindow,SAMPLE_FREQ_VIE);
            %             figure;plot(f,pxx);%hold on
            for ele=1:3
                cpowerICA(ele,g,:)=[pxx(:,ele)];%Relative Power 1Trial 2windowNo 3freq 4channel
            end

            %% noise 処理
            [pxx,f] = pwelch(cdata(:,[1 2]),SAMPLE_FREQ_VIE*timeWindow,0,FreqWindow,SAMPLE_FREQ_VIE);
            NoiseMatsub(g,[1 2])=sum(pxx);
            NoiseMatsub(g,[3 4])=rms(cdataf(:,[1 2]));
            NoiseMatsub(g,[5 6])=max(gradient(cdataf(:,[1 2])));
            %             zeroCross = cdataf(1:end-1,[1 2]).*cdataf(2:end,[1 2]) < 0;
            %             NoiseMatsub(g,[7 8])=     sum(zeroCross)./size(cdataf(:,[1 2]),1);
            NoiseMatsub(g,[9 10]) = kurtosis(cdataf(:,[1 2]));
            cNoisez=(NoiseMatsub(g,:)-NoiseMU)./NoiseSigma;
            cNoise(g,:)=cNoisez;

            cNoisezMean=[mean(abs(cNoisez([1 3 5  9]))) mean(abs(cNoisez([2 4 6 10])))];
            if max(cNoisezMean)>ThuZ %%左右の電極の絶対振幅値の平均がTHを超えたら削除
                noiseFlag(g)=1;
                cpower(:,g,:)=NaN;%1Trial 2windowNo 3freq 4channel
                cpowerICA(:,g,:)=NaN;
            else
                noiseFlag(g)=0;
            end
            Annotdata(g,:)=Data{T,5};
            conddata{g,1}=[Data{T,2}  ];
%             conddata{g,2}=[double(Data{T,8})];
            g=g+1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ALLEEG=[squeeze(cpower(1,:,:)) squeeze(cpower(2,:,:)) squeeze(cpower(3,:,:))];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Modeling%% GLM LASSO
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VIEModel={};
useidx=find(not(noiseFlag));
% useidx(strcmp(conddata(useidx,1),'Baseline'))=[]; %delete baseline data

cannot2=conddata(useidx)';
[indx,tf] = listdlg('ListString',conditionlist,'PromptString','Select a target state','SelectionMode','single');
Targetstate=conditionlist{indx};
Trueidx=find(strcmp(cannot2,Targetstate));%
Falseidx=find(not(strcmp(cannot2,Targetstate)));%

%% adjust no of labels
if length(Falseidx)>length(Trueidx)
    Falseidx2=Falseidx(sort(randperm(length(Falseidx),length(Trueidx))));%resample
    Trueidx2=Trueidx;
    c = cvpartition(length(Trueidx),'KFold',10);
    Trainidx = find(training(c,1));
    Testidx = find(test(c,1));

    Trainidx2=[Trueidx(Trainidx) Falseidx2(Trainidx) ];
    Testidx2=[Trueidx(Testidx) Falseidx2(Testidx) ];
else
    Trueidx2=Trueidx(sort(randperm(length(Trueidx),length(Falseidx))));%resample
    Falseidx2=Falseidx;
    c = cvpartition(length(Falseidx),'KFold',10);
    Trainidx = find(training(c,1));
    Testidx = find(test(c,1));

    Trainidx2=[Trueidx2(Trainidx) Falseidx(Trainidx) ];
    Testidx2=[Trueidx2(Testidx) Falseidx(Testidx) ];
end

useidx2=useidx([Trainidx2 Testidx2]);
Trainidx=1:length(Trainidx2);
Testidx=length(Trainidx2)+1:length(useidx2);

Y=strcmp(cannot2([Trainidx2]),conditionlist{indx});
Ytest= strcmp(cannot2([Testidx2]),conditionlist{indx});

%% EEG signal staderize
cpowerz=(ALLEEG(useidx2,:)-nanmean(ALLEEG(useidx2,:)))./nanstd(ALLEEG(useidx2,:));
MU=nanmean(ALLEEG(useidx2,:));
SIGMA=nanstd(ALLEEG(useidx2,:));

%% PCA
[VIEcoeff , VIEscore , latent , tsquared , explained , VIEpcamu ]  = pca(cpowerz);
numscore =150;
if size(VIEscore,2) <numscore
    numscore=size(VIEscore,2);
end
% figure()
% pareto(explained)
% xlabel('Principal Component')
% ylabel('Variance Explained (%)')
VIEscoremu=nanmean(VIEscore(:,1:numscore));
VIEscoresigma=nanstd(VIEscore(:,1:numscore));
VIEscorez=(VIEscore(:,1:numscore)-VIEscoremu)./VIEscoresigma;

X=VIEscorez;%PCAの主成分
[B2,FitInfo2] = lassoglm(X(Trainidx,:),Y','binomial','CV',10,'NumLambda',20,'Options', statset('UseParallel',1)); % Lasso 20分割交差検定 結構時間かかります

lassoPlot(B2,FitInfo2,'PlotType','CV');
idxLambdaMinDeviance = FitInfo2.IndexMinDeviance;    %     idxLambdaMinDeviance = FitInfo2.Index1SE;
B0 = FitInfo2.Intercept(idxLambdaMinDeviance);
VieCoeffGLM= [B0; B2(:,idxLambdaMinDeviance)];


%
h=figure('visible','on');
subplot(1,2,1)
yhat = glmval(VieCoeffGLM,X(Trainidx,:),'logit');
yhatBinom = (yhat>=0.5);
cm = confusionmat(Y,yhatBinom);
c=2;
TP = cm(c,c) ;
FP = sum(cm(:,c))-TP ;
FN = sum(cm(c,:))-TP ;
TN = sum(diag(cm))-TP;
AGLM=(TP+TN)/(TP+TN+FP+FN)*100
confusionchart(Y,yhatBinom);
title(['Train Accuracy=' num2str(AGLM) '%'])

subplot(1,2,2)
yhat = glmval(VieCoeffGLM,X(Testidx,:),'logit');
yhatBinom = (yhat>=0.5);
cm = confusionmat(Ytest',yhatBinom);
c=2;
TP = cm(c,c) ;
FP = sum(cm(:,c))-TP ;
FN = sum(cm(c,:))-TP ;
TN = sum(diag(cm))-TP;
AGLM=(TP+TN)/(TP+TN+FP+FN)*100
confusionchart(Ytest,yhatBinom);
title(['Test Accuracy=' num2str(AGLM) '%'])
sgtitle(['Sub=' subName '  True=' conditionlist{indx}])

saveas(gca,[modelsavepath '\'  strtrim(subName) datestr(now,'yyyymmdd')  'modelAccuracy' '.jpg'])



%% model save
decoderName=[ strtrim(subName) datestr(now,'yyyymmdd')  ' Target=' Targetstate   '.mat'];
save([modelsavepath '\' decoderName ],'B1f','A1f','Zf1','AGLM','VIEscoremu','VIEscoresigma','VIEpcamu','VIEcoeff',...
    'VieCoeffGLM','SAMPLE_FREQ_VIE','MU','SIGMA','numscore','FreqWindow','timeWindow','ThuZ','datafile','datapath','NoiseMetricsLabel','NoiseMU','NoiseSigma',...
    'useidx','Targetstate','subName');%モデルの保存　　後ろ二つ追加→'ViePowerSigma', 'ViePowerMu'
