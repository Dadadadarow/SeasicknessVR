%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% by T.Ibaraki @NTTDIOMC,Inc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;close all;sca

%% パスのセッティング
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defaultpath=pwd;
% defaultpath2=defaultpath(1:max(strfind(defaultpath,'\'))-1);

[decoderName,decoderPath] = uigetfile([defaultpath '\Model'],...
    'Select a Decoder');
load([decoderPath,decoderName]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NFduration=64;%sec
movmeanT=5;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subject parameter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subName =strtrim( input('subject name is ', 's')); % 被験者名の入力
mkdir([defaultpath '\data' '\NF'])
savefilename=[defaultpath '\data' '\NF\' subName '-' datestr(now,30)  'NFdata' ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EEG SETTING (VIE ZONE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% selpath = uigetdir([defaultpath '\VIErecording'],'脳波を収録しているPCフォルダを選択してください');
  selpath=defaultpath;

filename=[selpath '\VieOutput\' 'VieRawData.csv' ];  %filename=[filelist(1).folder '\' filelist(1).name ];%VieRawData.csv
filelist=dir([selpath '\VieOutput\VieRawData_*.csv' ]);%
for i=1:length(filelist);        delete([filelist(i).folder '\' filelist(i).name]);end;
opts = detectImportOptions(filename);
opts.SelectedVariableNames = [2 3 4];
SAMPLE_FREQ_VIE=600;
FreqWindow=[4:0.5:40];
%% Filter Setting
[B1f,A1f] = butter(4,[3/(SAMPLE_FREQ_VIE/2) 40/(SAMPLE_FREQ_VIE/2)]);% 3~40Hzバタワースフィルタ設計
Zf1=[];
Zf2=[];

%% Signal Quality Parameter
NoiseMetricsLabel={'Average Power_L' 'Average Power_R' 'RMS_L' 'RMS_R' 'MaxGradient_L' 'MaxGradient_R' 'ZeroCrossing Rate_L' 'ZeroCrossing Rate_R' 'Kurtosis_L' 'Kurtosis_R'};
NoiseMU=[138.502300000000	138.502300000000	12.1827000000000	12.1827000000000	103.387000000000	103.387000000000	0.0353000000000000	0.0353000000000000	10.1240000000000	10.1240000000000];
NoiseSigma=[123.240600000000	123.240600000000	6.02540000000000	6.02540000000000	69.4416000000000	69.4416000000000	0.00390000000000000	0.00390000000000000	2.89900000000000	2.89900000000000];
cNoisez=[NaN NaN];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 実験初期設定
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
KbName('UnifyKeyNames');
%% 押されっぱなしのキーを無効化
tic;
while toc < 1; end;
DisableKeysForKbCheck([]);    % 無効にするキーの初期化
[keyIsDown, secs, keyCode ] = KbCheck;    % 常に押されるキー情報を取得する
% 常に押されている（と誤検知されている）キーがあったら、それを無効にする
if keyIsDown
    fprintf('無効にしたキーがあります\n');
    keys=find(keyCode) % keyCodeの表示
    KbName(keys) % キーの名前を表示
    DisableKeysForKbCheck(keys);
end

%% VIE EEG SETTING
filename=[defaultpath '\VieOutput\' 'VieRawData.csv' ];
filelist=dir([defaultpath '\VieOutput\*.csv']);if length( filelist)>1;for i=2:length( filelist);delete([filelist(i).folder '\' filelist(i).name]);end;end

opts = detectImportOptions(filename);
opts.SelectedVariableNames = [2 3];
opts.DataLines=[2 inf];
craw=size(readmatrix(filename,opts).*18.3./64,1);%

SAMPLE_FREQ=600;

cplotdata=repmat(0,SAMPLE_FREQ*4,3);
cidx=1;cir=1;
cbaseline=[0 0 0];
mtimeWindow=4;

%% Unity送信用のTCP通信の設定
tcpipClient = tcpip('127.0.0.1', 55001, 'NetworkRole', 'Client');
set(tcpipClient, 'Timeout', 30);
fopen(tcpipClient);

%% モニター画面の設定
h=figure('Position',[0	15 1539	418],'CloseRequestFcn',{@myclosereq},'Color','k');
h.MenuBar='none';h.ToolBar='none';
colormap jet;
cmap = colormap;
ThuZ=4;
%% #1 Waveform
subplot(3,2,[1:2]) % L R ele
EEGplot=plot([1:SAMPLE_FREQ*mtimeWindow]/SAMPLE_FREQ,cplotdata-cbaseline,'LineWidth',1);
xlim([0 4]);
titletext=title(['EEG (' num2str(round(toc)) 's)'],'color','w');
% xlabel('time (s)')
ylabel('uV')
yline(0,'w--');
ylim([-50 50])
ha1 = gca;ha1.GridColor=[1 1 1];
set(gca,'Color','k')
h_yaxis = ha1.YAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_yaxis.Color = 'w'; % 軸の色を黒に変更
h_yaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
h_xaxis = ha1.XAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_xaxis.Color = 'w'; % 軸の色を黒に変更
h_xaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
set(gca, 'FontSize', 10);
set(gca, 'LineWidth', 2)
lgd=legend(EEGplot(1:3),{'L' 'R' 'diff'});
lgd.Box='off';lgd.TextColor='w';

cmovmean=[0.5 0.5];
%% #2 Noise (signal quality)
subplot(3,2,[3 4])

cNoiseMat=repmat(0,1,length(NoiseMetricsLabel)); %empty
cNoiseMat=(cNoiseMat-NoiseMU)./NoiseSigma;
cNoisez=[mean(abs(cNoiseMat([1 3 5 9]))) mean(abs(cNoiseMat([2 4 6 10])))];

Noiseplot=bar([cNoiseMat([1:6 9 10]) 0 0]);
xticks(1:length(cNoiseMat([1:6 9 10]))+2);
xticklabels([NoiseMetricsLabel([1:6 9 10]) 'RepidxSub' 'RepidxGen']);
Noisetitle=title(['NoiseLevel L=' num2str(round(cNoisez(1),2)) '  R=' num2str(round(cNoisez(2),2)) '   RepidxSub=' num2str(0) '   RepidxGen=' num2str(0)],'Color','w');
ylim([-5 5])
ha1 = gca;ha1.GridColor=[1 1 1];
set(gca,'Color','k')
h_yaxis = ha1.YAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_yaxis.Color = 'w'; % 軸の色を黒に変更
h_yaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
h_xaxis = ha1.XAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_xaxis.Color = 'w'; % 軸の色を黒に変更
h_xaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
set(gca, 'FontSize', 8);
set(gca, 'LineWidth', 2)
box off

%% # Sedation Estimation GeneralModel
subplot(3,2,[5:6])
decplot2=barh([cmovmean(2)*100],'FaceColor',cmap(ceil(cmovmean(2)*length(cmap)),:));
xlim([0 100]);ylim([0.7 1.3]);
set(gca,'LineWidth',2);
set(gca,'FontSize',10);
ax = gca;
ax.YTickLabel = [];
title(['Decoded' Targetstate 'State(0-100)'],'Color',[1 1 1])
ha1 = gca;ha1.GridColor=[1 1 1];
set(gca,'Color','k');
h_yaxis = ha1.YAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_yaxis.Color = 'w'; % 軸の色を黒に変更
h_yaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
h_xaxis = ha1.XAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_xaxis.Color = 'w'; % 軸の色を黒に変更
h_xaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
pause(0.1)

%% start
alldata=[];decodedstate=[];decodedstateMovMean=[];tsstart=tic;TimeLog=[];NoiseLog=[];NoiseFlagLog=[];
starttime=tic;nextdec=0;cpowerzmeanP=NaN;
while 1
    ctime=toc;
    if ~isgraphics(h) %% figureを閉じたら終了
        break
    end
    % read csv
    opts.DataLines=[craw+1 inf];
    tempdata=readmatrix(filename,opts).*18.3./64;
    if ~isempty(tempdata)
        tempdata=[tempdata tempdata(:,2)-tempdata(:,1)];
        alldata=[alldata;tempdata];
        craw=craw+size(tempdata,1);

        %% plot waveform
        [tempdata1,Zf1] = filter(B1f, A1f, tempdata,Zf1);

        if cidx+size(tempdata,1)-1<SAMPLE_FREQ*4
            cplotdata(cidx:cidx+size(tempdata,1)-1,:)=tempdata1;
            cidx=cidx+size(tempdata,1);
        else
            cplotdata(cidx:end,:)=tempdata1(end-(size(cplotdata,1)-cidx):end,:);
            cidx=1;
            cbaseline=nanmean(cplotdata);
        end

        % #1
        set(titletext,'String',[ ' EEG (' num2str(round(ctime,2)) 's)'])
        set(EEGplot(1),'YData',cplotdata(:,1)'); hold on% freqwidthに当たる部分を表示
        set(EEGplot(2),'YData',cplotdata(:,2)'); % freqwidthに当たる部分を表示
        set(EEGplot(3),'YData',cplotdata(:,3)'); % freqwidthに当たる部分を表示
        drawnow;shg;
    end


    %% state estimation
    if length(alldata) > SAMPLE_FREQ*timeWindow &&  isgraphics(h) && ctime>nextdec
        %% bandpass % get power
        cdata=alldata(end-(SAMPLE_FREQ*timeWindow)+1:end,:);
        [cdataf,Zf1]= filter(B1f,A1f, cdata,Zf1);

        [pxx,f] = pwelch(cdata,SAMPLE_FREQ*timeWindow,0,FreqWindow,SAMPLE_FREQ);

        cpower=[pxx(:,1);pxx(:,2);pxx(:,3)];%1Trial 2windowNo 3freq 4channel

        %% #2 Model
        cpowerz=(cpower'-MU)./SIGMA;
        cVIEscore=(cpowerz-VIEpcamu)/VIEcoeff'; % 座標変換（学習済み主成分空間への変換？）
        cVIEscorez=(cVIEscore(1:numscore)-VIEscoremu)./VIEscoresigma;
        predictV= glmval(VieCoeffGLM,cVIEscorez,'logit');

        decodedstate=[decodedstate;[predictV]];

        %% Noise判定
        cNoiseMat=[];
        cNoiseMat([1 2])=sum(pxx(:,[1 2]));
        cdata=cdataf(:,[1 2]);
        cNoiseMat([3 4])=rms(cdata);
        cNoiseMat([5 6])=max(gradient(cdata));
        %              zeroCross = cdata(1:end-1,:).*cdata(2:end,:) < 0;
        %              cNoiseMat([7 8])= sum(zeroCross)./size(cdata,1);
        cNoiseMat([9 10]) = kurtosis(cdata);
        cNoiseMatz=(cNoiseMat-NoiseMU)./NoiseSigma;
        cNoisez=[mean(abs(cNoiseMatz([1 3 5  9]))) mean(abs(cNoiseMatz([2 4 6  10])))];
        if max(cNoisez)>ThuZ %%左右の電極の絶対振幅値の平均がTHを超えたら削除
            NoiseFlag=1;
        else
            NoiseFlag=0;
        end

        NoiseFlagLog=[NoiseFlagLog;NoiseFlag];
        NoiseLog=[NoiseLog;[cNoiseMatz]];
        TimeLog=[TimeLog ;ctime];

        if sum(~NoiseFlagLog)~=0
            cmovmean=movmean(decodedstate(~NoiseFlagLog,:),[movmeanT 0],'omitnan');
            cmovmean=cmovmean(end,:);
        else
            cmovmean=[0.5];
        end
        decodedstateMovMean=[decodedstateMovMean; cmovmean];

        set(Noiseplot,'YData',[cNoiseMatz([1:6 9 10]) ]); % freqwidthに当たる部分を表示
        set(Noisetitle,'String',['NoiseLevel L=' num2str(round(cNoisez(1),2)) '  R=' num2str(round(cNoisez(2),2)) ]);%'   RepidxSub=' num2str(round(cpowerzmeanP,2)) '   ])
        set(decplot2,'YData',cmovmean(1)*100); % freqwidthに当たる部分を表示
        if ~NoiseFlag
            %         set(decplot1,'YData',cmovmean(1)*100); % freqwidthに当たる部分を表示
            %             set(decplot1,'FaceColor',cmap(ceil(cmovmean(1)*length(cmap)),:)); % freqwidthに当たる部分を表示
            set(decplot2,'FaceColor',cmap(ceil(cmovmean(1)*length(cmap)),:)); % freqwidthに当たる部分を表示
        else
            %             set(decplot1,'FaceColor',[0.5 0.5 0.5]); % freqwidthに当たる部分を表示
            set(decplot2,'FaceColor',[0.5 0.5 0.5]); % freqwidthに当たる部分を表示
        end
        %send to Unity
        fwrite(tcpipClient, num2str(round(toc, 2)));
		%char(10): indent
		fwrite(tcpipClient, 10);

        drawnow;shg;
        ctime=toc;
        nextdec=ctime+1;
    end
end
fclose();
h2=figure;
subplot(2,1,1)
plot(TimeLog,decodedstate,'LineWidth',1);hold on
box off
ctitle=[subName ' Decoded Log'];
title([ctitle] , 'FontSize', 10);
xlabel('Sec')
ylabel(['Prediction(1=' Targetstate]);
% lgd=legend({'PersonalModel' 'GeneralModel'});
% lgd.Box='off';
ylim([0 1])
subplot(2,1,2)
plot(TimeLog,decodedstateMovMean,'LineWidth',1);hold on
box off
ctitle=[subName  ' Decoded Log Mov Mean'];
title([ctitle] , 'FontSize', 10);
xlabel('Sec')
ylabel(['Prediction(1=' Targetstate]);
ylim([0 1])

print('-r0','-djpeg',[savefilename '.jpg']);
save([savefilename '.mat'],'subName','decodedstate','decodedstateMovMean','SAMPLE_FREQ','f','FreqWindow',...
    'timeWindow','datafile','datapath','NoiseFlagLog','NoiseLog','TimeLog');%モデルの保存


function myclosereq(src,evt)
delete(gcf);
return
end
