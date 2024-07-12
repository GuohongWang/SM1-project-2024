%% %% Merge signal from all mice
% %% %%%%%%%%%%%%%%%%%%%%%%%
% 
% % Built: 2023.12.25
% 
% % Creator: Guohong Wang, Pain Group, Fudan University
% 
% % Contact: fudanwgh@163.com
%% *Setting*

answer = questdlg('Do all mice have the same control time ?','Check','Yes','No','Yes');
switch answer
    case 'Yes'
        Merge=1;
    case 'No'
        Merge=0;
end
if Merge==0
    error('Do single mouse processing');
end
clear answer
clear Merge

% define mice number
n=inputdlg('Input mice number','Input');
n=str2num(n{1});

% define control frames
Tcontrol=inputdlg('Input control frames','Input');
Tcontrol=str2num(Tcontrol{1});
%% Merge signal from different mice

i1=1;

for i=1:n
    [Fall,path]=uigetfile;
    cd(path);
    load(Fall,"-mat","F_mean_dFF","cellROI_suite2p");
    i2=size(cellROI_suite2p,1);
    all_cell_dFF(i1:(i2+i1-1),:)=F_mean_dFF;
    all_cellROI(i1:(i2+i1-1),:)=i;
    all_cellROI(i1:(i2+i1-1),2)=cellROI_suite2p;
    i1=i2+i1;
    clear cellROI_suite2p
    clear F_mean_dFF
end
clear i
clear i1
clear i2
%%
figure
heatmap(all_cell_dFF,'Colormap',parula,'ColorLimits',[0 2],'GridVisible','off');
title('All cell');
saveas(gcf,'All cell heatmap');
%% Identify ON/OFF cell

Tpre_post=ceil(size(all_cell_dFF,2)/2);
for i=1:size(all_cellROI,1)
     all_mean_control(i,1)=mean(all_cell_dFF(i,(Tpre_post-Tcontrol):Tpre_post));             % calculate mean of pre stimuli
     all_mean_control(i,2)=mean(all_cell_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));             % calculate mean of post stimuli
     all_mean_control(i,3)=std(all_cell_dFF(i,(Tpre_post-Tcontrol):Tpre_post));              % calculate std of pre stimuli
     all_mean_control(i,4)=std(all_cell_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));              % calculate std of pre stimuli
     all_mean_control(i,5)=all_mean_control(i,1)+5*all_mean_control(i,3);                    % calculate +5 times of pre std
     all_mean_control(i,6)=all_mean_control(i,1)-5*all_mean_control(i,3);                    % calculate -5 times of pre std
     all_mean_control(i,7)=min(all_cell_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));              % calculate -peak of post stimuli
     all_mean_control(i,8)=max(all_cell_dFF(i,Tpre_post:(Tpre_post+Tcontrol)));              % calculate peak of post stimuli
  
    %% ON cell or not baseed on post-mean
   %if F_mean_control(i,2)> F_mean_control(i,4)                      
   %      F_mean_control(i,5)=1;
   % else
   %     F_mean_control(i,5)=0;
   % end
   
   %% ON cell or not baseed on post-max
    if all_mean_control(i,8)> all_mean_control(i,5)                      
       cell_ON_OFF(i,1)=1;
    else
       cell_ON_OFF(i,1)=0;
    end
    
   %% OFF cell or not baseed on pre-max
    if all_mean_control(i,7)< all_mean_control(i,6)                      
       cell_ON_OFF(i,2)=1;
    else
       cell_ON_OFF(i,2)=0;
    end
end

ON_cellROI=find(cell_ON_OFF(:,1)==1);
OFF_cellROI=find(cell_ON_OFF(:,2)==1);
%% Reshape heatmap

ROI_for_reshape(:,1:2)=all_cellROI;
ROI_for_reshape(:,3:4)=cell_ON_OFF;
ROI_for_reshape(:,6)=all_mean_control(:,2);
ROI_for_reshape(:,7)=all_mean_control(:,8);
i=size(all_mean_control);
ROI_for_reshape(:,8)=(1:i);
clear i
% identify other cell
for i=1:size(all_mean_control)
    if ROI_for_reshape(i,3)==ROI_for_reshape(i,4)
        ROI_for_reshape(i,5)=1;
    end
end
[Reshaped_ROI,Reshape_index]=sortrows(ROI_for_reshape,[3 5 6],"descend");
Reshaped_all_cell=all_cell_dFF(Reshape_index,:);

figure
heatmap(Reshaped_all_cell,'Colormap',parula,'ColorLimits',[0 2],'GridVisible','off');
title('Reshaped cell');
saveas(gcf,'Reshaped cell heatmap');
%% Extract ON/OFF cell signal

F_ON_cell=all_cell_dFF((ON_cellROI),:);
F_OFF_cell=all_cell_dFF((OFF_cellROI),:);

F_ON_mean=mean(F_ON_cell);
F_ON_std=std(F_ON_cell);
F_OFF_mean=mean(F_OFF_cell);
F_OFF_std=std(F_OFF_cell);

figure
% errorbar for ON/OFF cells
subplot(1,2,1,'align')
errorbar(F_ON_mean,F_ON_std);
title('ON cell');
subplot(1,2,2,'align')
errorbar(F_OFF_mean,F_OFF_std);
title('OFF cell');
saveas(gcf,'ON_OFF line');

figure
% heatmap for ON/OFF cells
subplot(1,2,1,'align')
heatmap(F_ON_cell,'Colormap',parula,'ColorLimits',[0 3],'GridVisible','off');
title('ON cell');

subplot(1,2,2,'align')
heatmap(F_OFF_cell,'Colormap',parula,'ColorLimits',[0 3],'GridVisible','off');
title('OFF cell');
saveas(gcf,'ON_OFF heatmap');
%% Save processed data

Name=['All_mice_result' '.mat'];
save(Name,"all_cell_dFF","Reshaped_ROI","F_ON_cell","F_OFF_cell","Reshaped_all_cell","cell_ON_OFF","ROI_for_reshape","ON_cellROI","OFF_cellROI");
clear
disp('All have done!!');