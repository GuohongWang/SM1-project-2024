%% 
% %% %%%%%%%%%%%%%%%%%%%%%%%
% 
% % Built: 2023
% 
% % Creator: Guohong Wang, Pain Group, Fudan University
% 
% % Contact: fudanwgh@163.com
%% Setting

%fps=9.6;      %2p recoring fps
%triger=  ;     %define triger time (fps)
Tcontrol=25 ;   %define control time (fps)
Tpre_post=50 ;  %define post time (fps)
Filename=['FP1-Pin-test'];

Do_dFF=0    ;   %deltaFF for all trace=1, deltaFF for control time=0
Smooth_F=1  ;   %smooth data, Yes=1, No=0

%Define behavior start time and end time (fps)
T_behavior(:,1)=[3944,4163,4189,4390];
T_behavior(:,2)=[3945,4164,4190,4391];
%% 
% 
%% Load mat

[Fall,path]=uigetfile;
cd(path);
load(Fall);
%% *Identify cell*

% extract cell calciun signal
cellROI=find(iscell(:,1)==1);
Fcell=F(cellROI,:);
cellROI_suite2p=cellROI-1;

% smooth data
if Smooth_F==1
    Fcell_original=Fcell;
    Fcell=smoothdata(Fcell,2,"movmean",5); 
end
%% Create behavior array

% behavior_on=1  behavior_off=0
fps=size(F,2);
Behavior=zeros(1,fps);
for n=1:size(T_behavior,1)
   Behavior(1,T_behavior(n,1):T_behavior(n,2))=1;
end
clear n
%% Calculate deltaF/F for all cell

if Do_dFF==1
   % calculate deltaF/F for all frames
   for i=1:size(cellROI)
       Fcell_dFF(i,:)=deltaFF(Fcell(i,:),mean(Fcell(i,:)));
   end
   clear i
else
    Fcell_dFF=Fcell;
end
% plot trace and heatmap of all cells
sigt=Fcell_dFF;
for i=1:size(cellROI)
    sigt(i,:)=normalize(sigt(i,:));
end

figure
plot((sigt+(1:size(sigt,1))')')
axis tight
title('All trace')
saveas(gcf,'All trace');

figure
heatmap(sigt,'Colormap',parula,'ColorLimits',[0,3],'GridVisible','off');
title('All cell');
saveas(gcf,'All heatmap');
clear sigt
%% Extract single trial

% from F extract single trials calcium signal based behavior time
for n=1:size(T_behavior,1)
    F_trial_dFF(:,:,n)=Fcell_dFF(:,T_behavior(n,1)-Tpre_post:T_behavior(n,1)+Tpre_post);
end
clear n

% plot
%%
if Do_dFF==0
%%Average and plot deltaF/F for each cell
%Calculate deltaF/F
   for n=1:size(T_behavior,1)
       Fcontrol(:,n)=mean(F_trial_dFF(:,((Tpre_post-Tcontrol):Tpre_post),n),2);
   end
   
   for n=1:size(T_behavior,1)
       F_trial_dFF(:,:,n)=deltaFF(F_trial_dFF(:,:,n),Fcontrol(:,n));
   end
   clear n
end

% Average deltaF/F for each cell from trials

for i=1:size(cellROI)
    for n=1:size(T_behavior,1)
        F_cell_dFF(n,:,i)=F_trial_dFF(i,:,n);
    end
end
clear i
clear n

% calculate mean deltaF/F for each cell
for i=1:size(cellROI)
    F_mean_dFF(i,:)=mean(F_cell_dFF(:,:,i),1);
end
clear i


% calculate std deltaF/F for each cell
for i=1:size(cellROI)
    F_std_dFF(i,:)=std(F_cell_dFF(:,:,i));
end
clear i
% Plot deltaF/F for each cell

n=ceil(size(cellROI,1)/5);
b=mod(size(cellROI,1),5);
if b>0 & b<5
    n=n+1;
end

figure
for i=1:size(cellROI)
    subplot(n, 5, i, 'align');
    plot(F_mean_dFF(i,:));
end
saveas(gcf,'All cell deltaFF');

figure
for i=1:size(cellROI)
    subplot(n, 5, i, 'align');
    heatmap(F_cell_dFF(:,:,i),'Colormap',parula,'ColorLimits',[0 5],'GridVisible','off');
end
clear i
clear n
saveas(gcf,'All cell heatmap');
%% Identify ON/OFF cell

for i=1:size(cellROI)
    F_mean_control(i,1)=mean(F_mean_dFF(i,(Tpre_post-Tcontrol):Tpre_post));             % calculate mean of pre stimuli
    F_mean_control(i,2)=mean(F_mean_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));           % calculate mean of post stimuli
    F_mean_control(i,3)=std(F_mean_dFF(i,(Tpre_post-Tcontrol):Tpre_post));              % calculate std of pre stimuli
    F_mean_control(i,4)=std(F_mean_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));            % calculate std of pre stimuli
    F_mean_control(i,5)=F_mean_control(i,1)+5*F_mean_control(i,3);  % calculate +5 times of pre std
    F_mean_control(i,6)=F_mean_control(i,1)-5*F_mean_control(i,3);  % calculate -5 times of pre std
    F_mean_control(i,7)=min(F_mean_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));              % calculate -peak of post stimuli
    F_mean_control(i,8)=max(F_mean_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));            % calculate peak of post stimuli
  
   %% ON cell or not baseed on post-mean
   %if F_mean_control(i,2)> F_mean_control(i,4)                      
    %     F_mean_control(i,5)=1;
    %else
    %  F_mean_control(i,5)=0;
   %end
   
   %% ON cell or not baseed on post-max
    if F_mean_control(i,8)> F_mean_control(i,5)                      
       cell_ON_OFF(i,1)=1;
    else
       cell_ON_OFF(i,1)=0;
    end
    
   %% OFF cell or not baseed on pre-max
    if F_mean_control(i,7)< F_mean_control(i,6)                      
       cell_ON_OFF(i,2)=1;
    else
       cell_ON_OFF(i,2)=0;
    end
end

ON_cellROI_suite2p=find(cell_ON_OFF(:,1)==1)-1;
OFF_cellROI_suite2p=find(cell_ON_OFF(:,2)==1)-1;
%% 
% 
%% Extract ON/OFF cell signal

F_ON_cell=F_mean_dFF((ON_cellROI_suite2p+1),:);
F_OFF_cell=F_mean_dFF((OFF_cellROI_suite2p+1),:);

% plot heatmap for ON/OFF cells
figure
subplot(1,1,1,'align')
heatmap(F_ON_cell,'Colormap',parula,'ColorLimits',[0 5],'GridVisible','off');
title('ON cell');
saveas(gcf,'ON cell');

figure
subplot(1,1,1,'align')
heatmap(F_OFF_cell,'Colormap',parula,'ColorLimits',[-1 1],'GridVisible','off');
title('OFF cell');
saveas(gcf,'OFF cell');
%% Save processed data

Name=[Filename '_result' '.mat'];
save(Name,"Fcell","Fcell_dFF","F_mean_dFF","F_ON_cell","F_OFF_cell","F_cell_dFF", ...
    "Behavior","cellROI_suite2p","cell_ON_OFF","F_ON_cell","ON_cellROI_suite2p","F_OFF_cell","OFF_cellROI_suite2p");
clear
disp('All have done!!');
%% %% define deltaF/F0 fuction

function [normDat] = deltaFF (dat1, controlFit)
    
normDat = (dat1 - controlFit)./ controlFit; %this gives deltaF/F
normDat = normDat * 100; % get %
end