%% VIE Decoding and NF program
clear;close all;

conditionlist ={'Normal' 'Sickness'};
AnnotationFlag=0;%if get subjective record

% subject setting
defaultpath=pwd;
mkdir([defaultpath '\data']);
subName =strtrim( input('subject name is ', 's')); % 被験者名の入力
savefilename=[defaultpath '\data\' subName datestr(now,30) 'EEG'];

% questionnaire setting
Question = {'全体的に気分がよくない', '疲れた', '頭痛がする', '目が疲れた', '目の焦点を合わせにくい', 'つばがよく出る', '汗をかいている', '吐き気がする', '集中するのが難しい', '頭がぼうっとする', 'ぼやけて見える', '目を開けているとふらふらした感じがする', '目を閉じているとふらふらした感じがする', 'ぐるぐるとしためまいがする', '胃に違和感がある', 'げっぷが出る'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EEG SETTING (VIE ZONE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% selpath = uigetdir([defaultpath '\VIErecordingFolder'],'脳波を収録しているPCフォルダを選択してください');
selpath=defaultpath;

filelist=dir([selpath '\VieOutput\VieRawData_*.csv']);
for i=1:length(filelist);delete([filelist(i).folder '\' filelist(i).name]);end

filename=[selpath '\VieOutput\' 'VieRawData.csv' ];%             filename=[filelist(1).folder '\' filelist(1).name ];%VieRawData.csv
opts = detectImportOptions(filename);
opts.SelectedVariableNames = [2 3];

SAMPLE_FREQ_VIE=600;
FreqWindow=[4:0.5:40];

%% filter setting
[B0,A0] = butter(4,[49/(SAMPLE_FREQ_VIE/2) 51/(SAMPLE_FREQ_VIE/2)],'stop');% 50Hzバンドストップ
[B1f,A1f] = butter(4,[3/(SAMPLE_FREQ_VIE/2) 40/(SAMPLE_FREQ_VIE/2)]);% 3~40Hzバタワースフィルタ設計
Zf1=[];

%store EEG data setting
opts.DataLines=[2 inf];
craw=size(readmatrix(filename,opts).*18.3./64,1);% Read Start row

%% EEG Monitor Window
timeWindow=4;
mtimeWindow=4;%monitoring window(sec)
cplotdata=repmat(0,SAMPLE_FREQ_VIE*mtimeWindow,3);
cidx=1;
cbaseline=[0 0 0];

% % Signal Quality Parameter
NoiseMetricsLabel={'Average Power_L' 'Average Power_R' 'RMS_L' 'RMS_R' 'MaxGradient_L' 'MaxGradient_R' 'ZeroCrossing Rate_L' 'ZeroCrossing Rate_R' 'Kurtosis_L' 'Kurtosis_R'};
NoiseMU=[138.502300000000	138.502300000000	12.1827000000000	12.1827000000000	103.387000000000	103.387000000000	0.0353000000000000	0.0353000000000000	10.1240000000000	10.1240000000000];
NoiseSigma=[123.240600000000	123.240600000000	6.02540000000000	6.02540000000000	69.4416000000000	69.4416000000000	0.00390000000000000	0.00390000000000000	2.89900000000000	2.89900000000000];

%Screen setting
ScreenDevices = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices();
MainScreen = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getScreen()+1;
MainBounds = ScreenDevices(MainScreen).getDefaultConfiguration().getBounds();
MonitorPositions = zeros(numel(ScreenDevices),4);
for n = 1:numel(ScreenDevices)
    Bounds = ScreenDevices(n).getDefaultConfiguration().getBounds();
    MonitorPositions(n,:) = [Bounds.getLocation().getX() + 1,-Bounds.getLocation().getY() + 1 - Bounds.getHeight() + MainBounds.getHeight(),Bounds.getWidth(),Bounds.getHeight()];
end
screenid = min(Screen('Screens'));
windowsize=get(0,'MonitorPositions');
[w, rect] = Screen('OpenWindow',screenid, 1, [0 0 1920/2.2 1080/2.2]); %test
[centerX, centerY] = RectCenter(rect);%画面の中央の座標
fontsize=25;
Screen('TextFont',w, 'Courier New');
Screen('TextSize',w, fontsize);
Screen('TextStyle', w, 0);
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextFont', w, '-:lang=ja');


%% Scale Setting

LineHaba = 7; %線分の幅
Linelength = rect(3)/2;
LineVertPos = rect(4)+10; %水平線分の垂直方向の位置
LineColor = [255 255 255];
AgeHeight=280;%テキスト表示位置
AdjustPar=100;%調整用;

minx= centerX-Linelength/2;
maxx= centerX+Linelength/2;



h=figure('Position',[windowsize(1,1) windowsize(1,2) windowsize(1,3) 250],'Color','k');%alwaysontop(h)
h.MenuBar='none';h.ToolBar='none';

plotadjparm=[30 0 -30];% for display waveform
EEGplot=plot([1:SAMPLE_FREQ_VIE*mtimeWindow]/SAMPLE_FREQ_VIE,cplotdata-cbaseline+plotadjparm,'LineWidth',1);
ha1 = gca;ha1.GridColor=[1 1 1];
set(gca,'Color','k')
h_yaxis = ha1.YAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_yaxis.Color = 'w'; % 軸の色を黒に変更
h_yaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
h_xaxis = ha1.XAxis; % 両 Y 軸の NumericRulerオブジェクト(2x1)を取得
h_xaxis.Color = 'w'; % 軸の色を黒に変更
h_xaxis.Label.Color = [1 1 1]; %  軸ラベルの色変更
set(gca,'Color','k')
xlim([0 4]);
titletext=title(['EEG (' num2str(round(0,2)) 's)'],'Color' ,'w','FontSize',20);
xlabel('time (s)');
ylabel('uV');
yline(0,'w--');
ylim([-75 75]);
lgd=legend(EEGplot,{'L' 'R' 'diff'});
lgd.TextColor=[1 1 1];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Experiment Setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Keyboardのチェック
KbName('UnifyKeyNames');  % OSで共通のキー配置にする
DisableKeysForKbCheck([]);% 無効にするキーの初期化
[ keyIsDown, secs, keyCode ] = KbCheck;% 常に押されるキー情報を取得する
if keyIsDown % 常に押されている（と誤検知されている）キーがあったら、それを無効にする
    fprintf('無効化キー\n');
    keys=find(keyCode); % keyCodeの表示
    KbName(keys) % キーの名前を表示
    DisableKeysForKbCheck(keys);
end
ListenChar(1);

EXstart=GetSecs;
EndFlag=0;
Data={};g=1;
while 1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% mode=0 STANDBY
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    alldataV=[];%empty data for EEG
    opts.DataLines=[2 inf];
    craw=size(readmatrix(filename,opts).*18.3./64,1);% Read Start row
    pause(1)
        %prep        
        while 1
            %% store EEG(VIE ZONE)
            opts.DataLines=[craw+1 inf];
            tempdataV=readmatrix(filename,opts).*18.3./64;
            if ~isempty(tempdataV)
                tempdataV=[tempdataV tempdataV(:,2)-tempdataV(:,1)];
                alldataV=[alldataV;tempdataV];
                craw=craw+size(tempdataV,1);
                
                [tempdata1,Zf1] = filter(B1f, A1f, tempdataV,Zf1); %Zf1:初期条件 
                if cidx+size(tempdataV,1)-1<SAMPLE_FREQ_VIE*mtimeWindow
                    cplotdata(cidx:cidx+size(tempdataV,1)-1,:)=tempdata1+plotadjparm;         
                    cidx=cidx+size(tempdataV,1);
                else
                    cplotdata(cidx:end,:)=tempdata1(end-(size(cplotdata,1)-cidx):end,:)+plotadjparm;
                    cidx=1;
                    cbaseline=nanmean(cplotdata);
                end
            end
            
            %% Noise Calc
            cNoiseMat=[];
            cdata=cplotdata(:,[1 2])-plotadjparm(1:2);
            [pxx,f] = pwelch(cdata,SAMPLE_FREQ_VIE*timeWindow,0,FreqWindow,SAMPLE_FREQ_VIE);
            cNoiseMat([1 2])=sum(pxx);
            cNoiseMat([3 4])=rms(cdata);
            cNoiseMat([5 6])=max(gradient(cdata));
            %              zeroCross = cdata(1:end-1,:).*cdata(2:end,:) < 0;
            %              cNoiseMat([7 8])= sum(zeroCross)./size(cdata,1);
            cNoiseMat([9 10]) = kurtosis(cdata);
            cNoiseMatz=(cNoiseMat-NoiseMU)./NoiseSigma;
            cNoisez=[mean(abs(cNoiseMatz([1 3 5  9]))) mean(abs(cNoiseMatz([2 4 6  10])))];
            
            %% Display waveform
            set(titletext,'String',['STANDBY ... ' ' NoiseLevel L=' num2str(round(cNoisez(1),2)) '  R=' num2str(round(cNoisez(2),2)) 'Press SPACE to Start: (ESCAPE to Exit)'] ,'Color','w');
            set(EEGplot(1),'YData',cplotdata(:,1)'); hold on% freqwidthに当たる部分を表示
            set(EEGplot(2),'YData',cplotdata(:,2)'); % freqwidthに当たる部分を表示
            set(EEGplot(3),'YData',cplotdata(:,3)'); % freqwidthに当たる部分を表示
            drawnow;shg;
            
            [ keyIsDown, keyTime, keyCode ] = KbCheck;
            if keyIsDown
                if keyCode(KbName('SPACE'))
                    break; % while 文を抜けます。
                elseif keyCode(KbName('ESCAPE'))
                    EndFlag=1;
                    break; % while 文を抜けます。
                end
            end
        end
        if   EndFlag
            break
        end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% mode=1 Recording
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [indx,tf] = listdlg('ListString',conditionlist,'PromptString','Select a condition','SelectionMode','single');
        ccond = conditionlist{indx};
        %% rec start
        opts.DataLines=[2 inf];
        craw=size(readmatrix(filename,opts).*18.3./64,1);% Read Start row
        alldataV=[];%empty data for EEG
        tsstart=tic;    
        pause(1)
        while 1
            %% store EEG(VIE ZONE)
            opts.DataLines=[craw+1 inf];
            tempdataV=readmatrix(filename,opts).*18.3./64;
            if ~isempty(tempdataV)
                tempdataV=[tempdataV tempdataV(:,2)-tempdataV(:,1)];
                alldataV=[alldataV;tempdataV];
                craw=craw+size(tempdataV,1);

                [tempdata1,Zf1] = filter(B1f, A1f, tempdataV,Zf1); %Zf1:初期条件
                if cidx+size(tempdataV,1)-1<SAMPLE_FREQ_VIE*mtimeWindow
                    cplotdata(cidx:cidx+size(tempdataV,1)-1,:)=tempdata1+plotadjparm;
                    cidx=cidx+size(tempdataV,1);
                else
                    cplotdata(cidx:end,:)=tempdata1(end-(size(cplotdata,1)-cidx):end,:)+plotadjparm;
                    cidx=1;
                    cbaseline=nanmean(cplotdata);
                end
            end

            %% Noise Calc
            cNoiseMat=[];
            cdata=cplotdata(:,[1 2])-plotadjparm(1:2);
            [pxx,f] = pwelch(cdata,SAMPLE_FREQ_VIE*timeWindow,0,FreqWindow,SAMPLE_FREQ_VIE);
            cNoiseMat([1 2])=sum(pxx);
            cNoiseMat([3 4])=rms(cdata);
            cNoiseMat([5 6])=max(gradient(cdata));
            %              zeroCross = cdata(1:end-1,:).*cdata(2:end,:) < 0;
            %              cNoiseMat([7 8])= sum(zeroCross)./size(cdata,1);
            cNoiseMat([9 10]) = kurtosis(cdata);
            cNoiseMatz=(cNoiseMat-NoiseMU)./NoiseSigma;
            cNoisez=[mean(abs(cNoiseMatz([1 3 5  9]))) mean(abs(cNoiseMatz([2 4 6  10])))];

            %% Display waveform
            set(titletext,'String',['Now Recording... cond=' ccond ' ' num2str(round(toc(tsstart),1)) 'sec' ' NoiseLevel L=' num2str(round(cNoisez(1),2)) '  R=' num2str(round(cNoisez(2),2)) ' Press SPACE to Stop ' ] ,'Color','w');
            set(EEGplot(1),'YData',cplotdata(:,1)'); hold on% freqwidthに当たる部分を表示
            set(EEGplot(2),'YData',cplotdata(:,2)'); % freqwidthに当たる部分を表示
            set(EEGplot(3),'YData',cplotdata(:,3)'); % freqwidthに当たる部分を表示
            drawnow;shg;

            [ keyIsDown, keyTime, keyCode ] = KbCheck;
            if keyIsDown
                if keyCode(KbName('SPACE'))
                    break; % while 文を抜けます。
                elseif keyCode(KbName('ESCAPE'))
                    EndFlag=1;
                    break; % while 文を抜けます。
                end
            end
        end
        if   EndFlag
            break
        end        
        opts.DataLines=[craw+1 inf];
        tempdata=readmatrix(filename,opts).*18.3./64;
        if ~isempty(tempdata)
            tempdata=[tempdata tempdata(:,2)-tempdata(:,1)];
            alldataV=[alldataV ;tempdata];
            craw=craw+size(tempdata,1);
        end
        
        %% Annotation
        if AnnotationFlag
            RatingFin=0;
            [Value,RatingFin]=SubjectiveReport(savefilename,conditionlist);
            shg;
        else
            Value=NaN;
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% mode=2 Questionnaire (Simulation Sickness Questionnaire, SSQ)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DrawFormattedText(w,double(['これから表示される質問に回答してください。\n\n タッチパッドでスライドしてクリックで回答。\n←キーでひとつ前の回答を修正\n\n\nSPACEキーを押してして計測スタート']), 'center', 'center',  WhiteIndex(w));
    Screen('Flip', w);%
    WaitSecs(0.5);
    KbWait;
    i = 1;
    while 1
        SetMouse(centerX,centerY);
        [x,y,buttons] = GetMouse(w);
        while (1)
            [x,y,buttons] = GetMouse(w);
    
            if buttons(1)
                Click=GetSecs;
                if x < centerX-Linelength/2
                    x= centerX-Linelength/2;
                elseif x > centerX+Linelength/2
                    x=centerX+Linelength/2;
                end
                Answer=x;
                %                     AnswerHist(T,i)=Answer;
                PercentAns=(Answer-(centerX-Linelength/2))./(Linelength).*100;
                ScaleResult(i,1)=PercentAns;
                WaitSecs(0.5);
                i=i+1;
                break;
            end
    
            if x < centerX-Linelength/2
                x= centerX-Linelength/2;
            elseif x > centerX+Linelength/2
                x=centerX+Linelength/2;
            end
    
            Screen('DrawLines', w, [centerX-Linelength/2 centerX+Linelength/2 ; rect(4)-20 rect(4)-20], LineHaba, LineColor);
            DrawFormattedText(w, double(Question{i}), 'center', rect(4)-100, LineColor); % 質問
            DrawFormattedText(w, double('いいえ'),centerX-Linelength/2-AdjustPar-100,rect(4)-40, LineColor); % 質問左
            DrawFormattedText(w, double('はい'), centerX+Linelength/2+AdjustPar-40,   rect(4)-40, LineColor); % 質問右
            Screen('FillRect', w, [255 0 0], [x-2 rect(4)-40 x+2 rect(4)]);
            Screen('Flip', w); %
    
            [ keyIsDown, keyTime, keyCode ] = KbCheck;
            if keyIsDown
                if keyCode(KbName('ESCAPE'))
                    EndFlag=1;
                    break; % while 文を抜けます。
                elseif keyCode(KbName('leftarrow'))
                    if i>1
                        i=i-1;
                    end
                    WaitSecs(0.2);
                end
            end
        end
        if EndFlag;  break; end
    
        if i > size(Question)
            break
        end
    end
    DrawFormattedText(w, double(['終了！' ]), 'center', 'center');
    Screen('Flip', w);
    %%%%%%%%%%%%%%
    % Data stack
        Data{g,1}=g;
        Data{g,2}=ccond;
        Data{g,3}=[];
        Data{g,4}=alldataV;
        Data{g,5}=Value;
        Data{g,6}=ScaleResult;
        g=g+1;
        save([savefilename  '.mat' ],'Data','SAMPLE_FREQ_VIE','subName','conditionlist');
end
Screen('CloseAll');
beep
close all
ShowCursor();
ListenChar(0);
close all;
Screen('CloseAll');

save([savefilename  '.mat' ],'Data','SAMPLE_FREQ_VIE','subName','conditionlist');
