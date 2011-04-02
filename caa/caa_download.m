function caa_download(tint,dataset,flag)
% CAA_DOWNLOAD Download CAA data in CDF format
%       CAA_DOWNLOAD - check the status of jobs in current directory
%
%       CAA_DOWNLOAD(tint,dataset) - download dataset from given time interval
%
%       CAA_DOWNLOAD(tint,'list') - list all datasets available
%       CAA_DOWNLOAD(tint,'list:filter') - list all datasets corresponding to filter
%
%
% Downloads CAA data in CDF format into subdirectory "CAA/"
%
%   tint   - time interval in epoch
%  dataset - dataset name, can uses also wildcard * (? is changed to *)
%
%  Examples:
%   caa_download(tint,'list:*FGM*')
%   caa_download(tint,'C3_CP_FGM_5VPS')
%   caa_download(tint,'C?_CP_FGM_5VPS')   %    download all satellites
%
% The example list of datasets:
% FGM
%   caa_download(tint,'C?_CP_FGM_5VPS');
%   caa_download(tint,'C?_CP_FGM_FULL');
% EFW
%   caa_download(tint,'C?_CP_EFW_L2_E3D_INERT'); % full resolution
%   caa_download(tint,'C?_CP_EFW_L3_E3D_INERT'); % 4s resolution
%   caa_download(tint,'C?_CP_EFW_L2_P'); % full resolution
%   caa_download(tint,'C?_CP_EFW_L3_P'); % 4s resolution
% CIS
%   caa_download(tint,'C?_CP_CIS_HIA_ONBOARD_MOMENTS');
%   caa_download(tint,'C?_CP_CIS_CODIF_HS_H1_MOMENTS');
%   caa_download(tint,'C?_CP_CIS_HIA_HS_1D_PEF');
%   caa_download(tint,'C?_CP_CIS_CODIF_H1_1D_PEF');
% PEACE
%   caa_download(tint,'C?_CP_PEA_PITCH_SPIN_DPFlux');
%   caa_download(tint,'C?_CP_PEA_PITCH_SPIN_DEFlux');
% RAPID
%   caa_download(tint,'C?_CP_RAP_ESPCT6');

% $Id$

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

if exist('.caa','file') == 0, caa=cell(0);save -mat .caa caa;end
load -mat .caa caa

if nargin==0,    % check/show status of downloads
    disp('=== status of jobs (saved in file .caa) ====');
    if ~isempty(caa),
        for j=1:length(caa), % go through jobs
            disp([num2str(j) '.' caa{j}.status ' ' caa{j}.dataset '-' caa{j}.tintiso]);
        end
    else
        disp('No active downloads');
        return;
    end
    j_finnished_jobs=[];
    for j=1:length(caa), % go through jobs
        if strcmpi(caa{j}.status,'downloaded') || strcmpi(caa{j}.status,'finnished') , % do nothing
            j_finnished_jobs(end+1)=j;
        elseif strcmpi(caa{j}.status,'submitted'),
            disp(['=== Checking status of job nr: ' num2str(j) '==='])
            [f,status]=urlwrite(caa{j}.zip,'delme.zip');
            if status == 0,
                disp('STILL WAITING TO FINNISH');
            else
                filelist=unzip(f);
                for jj=1:length(filelist),
                    ii=strfind(filelist{1},filesep);
                    dataset=filelist{jj}(ii(1)+1:ii(2)-1);
                    disp(['Data set: ' dataset '--> CAA/']);
                    if ~exist(['CAA/' dataset],'dir'), mkdir(['CAA/' dataset]);end
                    movefile(filelist{jj},['CAA/' dataset]);
                end
                %disp(['REMOVING DATA DIRECTORIES & FILES: ' filelist{jj}(1:ii(1)) ',delme.zip']);
                rmdir(filelist{jj}(1:ii(1)),'s');
                delete(f);
                caa{j}.status='FINNISHED';
                save -mat .caa caa; % changes in caa saved
            end
        else
            disp('ERROR: Unknown status!')
            return
        end
    end
    if numel(j_finnished_jobs)>5, % ask for cleanup
        y=input('Shall I remove FINNISHED from the list? y/n :','s');
        if strcmpi(y,'y'),
            caa(j_finnished_jobs)=[];
            save -mat .caa caa;
        end
    end
    return;
end

if nargin==1, help caa_download;return; end
% caa.url - links to download
% caa.dataset - dataset to download
% caa.tintiso - time interval
% caa.zip - zip files to download
% caa.status - status (0-submitted, 1-downloaded)
% caa.timeofrequest - in matlab time units

if ~exist('CAA','dir') mkdir('CAA');end
caa_data_directory='CAA/';
t1iso=epoch2iso(tint(1));
t2iso=epoch2iso(tint(2));
tintiso=[t1iso '/' t2iso];
dataset(strfind(dataset,'?'))='*'; % substitute  ? to * (to have the same convention as in irf_ssub)

if strfind(dataset,'list'), % list  files
    if strcmpi(dataset,'list'), % list all files
        filter='*';
    else                        % list only filtered files
        filter=dataset(strfind(dataset,':')+1:end);
    end
    url_line_list=['http://caa.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
        filter '&time_range=' tintiso '&format=cdf&list=1'];
    caalog=urlread(url_line_list);
    disp(caalog);
    return;
else  % download data
    
    url_line_list=['http://caa.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
        dataset '&time_range=' tintiso '&format=cdf&list=1'];
    caalist=urlread(url_line_list);
    disp(caalist);
    if ~any(strfind(caalist,'FileName')),% there are no CAA datasets available
        disp('There are no CAA data sets available!');
        return;
    end
    
    url_line=['http://caa.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
        dataset '&time_range=' tintiso '&format=cdf'];
    
    caalog=urlread(url_line);
    disp(caalog);
    
    downloadfile = caalog(strfind(caalog,'http:'):strfind(caalog,'zip')+3);
    
    j=length(caa)+1;
    caa{j}.url=url_line;
    caa{j}.dataset=dataset;
    caa{j}.tintiso=tintiso;
    caa{j}.zip = downloadfile;
    caa{j}.status = 'SUBMITTED';
    caa{j}.timeofrequest = now;
    
    disp('=====');
    disp('To check the status of jobs execute: caa_download');
    
    save -mat .caa caa
end