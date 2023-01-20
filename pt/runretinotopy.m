%%%%%%%%%%%%%%%%%%%%%%%%%% EXPERIMENT PARAMETERS (edit as necessary)

% display
ptres = [1920 1080 60 32];  % display resolution. [] means to use current display resolution.

% fixation dot
fixationinfo = {uint8([255 0 0; 0 0 0; 255 255 255]) 0.5};  % dot colors and alpha value
fixationsize = 10;         % dot size in pixels
meanchange = 3;            % dot changes occur with this average interval (in seconds)
changeplusminus = 2;       % plus or minus this amount (in seconds)

% trigger
triggerkey = 't';          % stimulus starts when this key is detected
tfun = @() fprintf('STIMULUS STARTED.\n');  % function to call once trigger is detected

% tweaking
offset = [0 0];            % [X Y] where X and Y are the horizontal and vertical
                           % offsets to apply.  for example, [5 -10] means shift 
                           % 5 pixels to right, shift 10 pixels up.
movieflip = [0 0];         % [A B] where A==1 means to flip vertical dimension
                           % and B==1 means to flip horizontal dimension

% directories
stimulusdir = '/Users/martinszinte/Dropbox/Data/Martin/Experiments/HCPretinotopy/';         
% path to directory that contains the stimulus .mat files

%%%%%%%%%%%%%%%%%%%%%%%%%% DO NOT EDIT BELOW

% set rand state
rand('state',sum(100*clock));
randn('state',sum(100*clock));

% ask the user what to run
expnum = input('What experiment (89=CCW, 90=CW, 91=expand, 92=contract, 93=multibar, 94=wedgeringmash)? ');
runnum = 1;
subjnum = 1;

% edit by Martin Szinte (mail@martinszinte.net) for video maker
switch expnum
    case 89; vid.exp_name = 'wedge_ccw';
    case 90; vid.exp_name = 'wedge_cw';
    case 91; vid.exp_name = 'annulus_expand';
    case 92; vid.exp_name = 'annulus_contract';
    case 93; vid.exp_name = 'multibar';
    case 94; vid.exp_name = 'wedgeringmash';
end
dir = which('runretinotopy');
dir = dir(1:end-19);
vid.make_png = 0;
if vid.make_png
    if ~isfolder(sprintf('%s/vid/%s/',dir,vid.exp_name))
        mkdir(sprintf('%s/vid/%s/',dir,vid.exp_name));
    end
end
vid.vid_image_fn = sprintf('%s/vid/%s/%s',dir,vid.exp_name,vid.exp_name);
vid.vid_fn = sprintf('%s/vid/%s.mp4',dir,vid.exp_name);
vid.vid_obj = VideoWriter(vid.vid_fn,'MPEG-4');
vid.hcp_TR = 1000;              % TR originally used in HCP dataset (in ms)
vid.desired_TR = 1120;          % TR desired (in ms)
vid.stim_rate = 15;
vid.vid_obj.FrameRate = vid.stim_rate/(vid.desired_TR/vid.hcp_TR);
vid.vid_obj.Quality = 100;
vid.vid_num = 0;
vid.ratio_crop = 1.35;
vid.res = [1920,1080];

vid.crop_rect = [(ptres(1)-(ptres(1)/vid.ratio_crop))/2,...
                 (ptres(2)-(ptres(2)/vid.ratio_crop))/2,...
                 ptres(1)/vid.ratio_crop,...
                 ptres(2)/vid.ratio_crop];
             
open(vid.vid_obj);
meanchange = meanchange*(vid.desired_TR/vid.hcp_TR);
changeplusminus = changeplusminus*(vid.desired_TR/vid.hcp_TR);

filename = sprintf('%s/vid/vid_%s.mat',dir,vid.exp_name);

% prepare inputs
trialparams = [];
ptonparams = {ptres,[],0};
dres = [];
frameduration = 4;
grayval = uint8(127);
iscolor = 1;
soafun = @() round(meanchange*(60/frameduration) + changeplusminus*(2*(rand-.5))*(60/frameduration));

% load specialoverlay
a1 = load(fullfile(stimulusdir,'fixationgrid.mat'));

% some prep
if ~exist('images','var')
  images = [];
  maskimages = [];
end

% run experiment
[images,maskimages] = ...
  showmulticlass(vid,filename,offset,movieflip,frameduration,fixationinfo,fixationsize,tfun, ...
                 ptonparams,soafun,0,images,expnum,[],grayval,iscolor,[],[],[],dres,triggerkey, ...
                 [],trialparams,[],maskimages,a1.specialoverlay,stimulusdir);

%%%%%%%%%%%%%%%%%%%%%%%%%%

% video
close(vid.vid_obj);

% create tsv file
fixation_mat = fixationorder(1:4502);
fixation_mat = abs(fixation_mat);
onset_time = [1];
offset_time = [];
fixation_color_val  = [];
for event_num = 1:4500
    if fixation_mat(event_num) ~= fixation_mat(event_num+1)
        offset_time = [offset_time;event_num];
        fixation_color_val = [fixation_color_val ;fixation_mat(event_num)];
        onset_time = [onset_time;event_num+1];
    end
end
fixation_color_val = [fixation_color_val;fixation_mat(event_num)];
offset_time = [offset_time;event_num];
onset_time = (onset_time-1)/vid.vid_obj.FrameRate;
offset_time = (offset_time)/vid.vid_obj.FrameRate;

% Write event file
event_file_fn = sprintf('%s/vid/%s_event.tsv',dir,vid.exp_name);
event_file_fid =   fopen(event_file_fn,'w');
event_txt_head{1} = 'onset'; event_mat_res{1} = onset_time;
event_txt_head{2} = 'duration'; event_mat_res{2} = offset_time;
event_txt_head{3} = 'fixation_color'; event_mat_res{3} = fixation_color_val;

head_line = [];
for trial = 1:size(onset_time)
    if trial == 1
        for tab = 1:size(event_txt_head,2)
            if tab == size(event_txt_head,2); head_line = [head_line,sprintf('%s',event_txt_head{tab})];
            else; head_line = [head_line,sprintf('%s\t',event_txt_head{tab})];
            end
        end
        fprintf(event_file_fid,'%s\n',head_line);
    end
    trial_line = [];
    for tab = 1:size(event_mat_res,2)
        if tab == size(event_mat_res,2); trial_line = [trial_line,sprintf('%1.5g',event_mat_res{tab}(trial))];
        else; trial_line = [trial_line,sprintf('%1.10g\t',event_mat_res{tab}(trial))];
        end
    end
    fprintf(event_file_fid,'%s\n',trial_line);
end

% KK notes:
% - remove performance check at end
% - remove resampling and viewingdistance stuff
% - remove hresgrid and vresgrid stuff
% - hardcode grid and pregenerate
% - trialparams became an internal constant
