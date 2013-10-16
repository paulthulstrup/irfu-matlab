function h = c_ri_eventfile_into_fig(time_interval,path_events,panels,flags,dt)
%function h = c_ri_eventfile_into_fig(time_interval,path_events,panels,flags,dt)
%function h = c_ri_eventfile_into_fig(time_interval,path_events,panels,flags)
%function h = c_ri_eventfile_into_fig(time_interval,path_events,panels)
%
%Input:
% time_interval - isdat_epoch [start_time end_time]
% path_events - path where event files are located, ex './'
% panels - structure with list of panels to plot, ex. {'Bx','By','B','B1','Ex','Vps'}
% flags - 'jpg'   print results to jpg-files
%       - 'print' print results to ps-file
%       - 'base' execute in MATLAB base workspace (access to all your variables)
%       - can be combined, ex. flags={'print','base'}
% 
%Output:
%  h - handle to figures
flag_print=0;flag_base=0;flag_jpg=0;
if nargin<3,help c_ri_eventfile_into_fig;return;end
if nargin<4,flags='';end
if nargin<5,dt=[0 0 0 0];end

if ischar(flags),
   eval(['flag_' flags '=1;']);
elseif iscell(flags),
   for j=1:length(flags), eval(['flag_' flags{j} '=1;']);end
end

n_panels=size(panels,2);  if debug, disp(['Figure with ' num2str(n_panels) ' panels.']);end
i_fig=1;

plot_command=struct(...
  'Vps' ,'c_pl_tx(P1,P2,P3,P4,2,1,dt);ylabel(''V_{ps} [V]'');', ...
  'dE1' ,'av_tplot(dE1);ylabel(''E [mV/m] DS, sc1'');', ...
  'dE2' ,'av_tplot(dE2);ylabel(''E [mV/m] DS, sc2'');', ...
  'dE3' ,'av_tplot(dE3);ylabel(''E [mV/m] DS, sc3'');', ...
  'dE4' ,'av_tplot(dE4);ylabel(''E [mV/m] DS, sc4'');', ...
  'E1' ,'av_tplot(E1);ylabel(''E [mV/m] GSE, sc1'');', ...
  'E2' ,'av_tplot(E2);ylabel(''E [mV/m] GSE, sc2'');', ...
  'E3' ,'av_tplot(E3);ylabel(''E [mV/m] GSE, sc3'');', ...
  'E4' ,'av_tplot(E4);ylabel(''E [mV/m] GSE, sc4'');', ...
  'Elmn1' ,'av_tplot(av_abs(Elmn1));ylabel(''E [mV/m] LMN, sc1'');legend(''L'',''M'',''N'');', ...
  'Elmn2' ,'av_tplot(av_abs(Elmn2));ylabel(''E [mV/m] LMN, sc2'');legend(''L'',''M'',''N'');', ...
  'Elmn3' ,'av_tplot(av_abs(Elmn3));ylabel(''E [mV/m] LMN, sc3'');legend(''L'',''M'',''N'');', ...
  'Elmn4' ,'av_tplot(av_abs(Elmn4));ylabel(''E [mV/m] LMN, sc4'');legend(''L'',''M'',''N'');', ...
  'El','c_pl_tx(Elmn1,Elmn2,Elmn3,Elmn4,2,1,dt);ylabel(''Elmn_L [mV/m]'');', ...
  'Em','c_pl_tx(Elmn1,Elmn2,Elmn3,Elmn4,3,1,dt);ylabel(''Elmn_M [mV/m]'');', ...
  'En','c_pl_tx(Elmn1,Elmn2,Elmn3,Elmn4,4,1,dt);ylabel(''Elmn_N [mV/m]'');', ...
  'Bx','c_pl_tx(B1,B2,B3,B4,2,1,dt);ylabel(''B_X [nT] GSE'');', ...
  'By','c_pl_tx(B1,B2,B3,B4,3,1,dt);ylabel(''B_Y [nT] GSE'');', ...
  'Bz','c_pl_tx(B1,B2,B3,B4,4,1,dt);ylabel(''B_Z [nT] GSE'');', ...
  'Bl','c_pl_tx(Blmn1,Blmn2,Blmn3,Blmn4,2,1,dt);ylabel(''Blmn_L [nT]'');', ...
  'Bm','c_pl_tx(Blmn1,Blmn2,Blmn3,Blmn4,3,1,dt);ylabel(''Blmn_M [nT]'');', ...
  'Bn','c_pl_tx(Blmn1,Blmn2,Blmn3,Blmn4,4,1,dt);ylabel(''Blmn_N [nT]'');', ...
  'Vl','c_pl_tx(Vlmn1,Vlmn2,Vlmn3,Vlmn4,2,1,dt);ylabel(''Vlmn_L [km/s]'');', ...
  'Vm','c_pl_tx(Vlmn1,Vlmn2,Vlmn3,Vlmn4,3,1,dt);ylabel(''Vlmn_M [km/s]'');', ...
  'Vn','c_pl_tx(Vlmn1,Vlmn2,Vlmn3,Vlmn4,4,1,dt);ylabel(''Vlmn_N [km/s]'');', ...
  'Vlmn1' ,'av_tplot(av_abs(Vlmn1));ylabel(''V [km/s] LMN, sc1'');legend(''L'',''M'',''N'');', ...
  'Vlmn2' ,'av_tplot(av_abs(Vlmn2));ylabel(''V [km/s] LMN, sc2'');legend(''L'',''M'',''N'');', ...
  'Vlmn3' ,'av_tplot(av_abs(Vlmn3));ylabel(''V [km/s] LMN, sc3'');legend(''L'',''M'',''N'');', ...
  'Vlmn4' ,'av_tplot(av_abs(Vlmn4));ylabel(''V [km/s] LMN, sc4'');legend(''L'',''M'',''N'');', ...
  'B' ,'c_pl_tx(av_abs(B1),av_abs(B2),av_abs(B3),av_abs(B4),5,1,dt);ylabel(''B [nT] GSE'');', ...
  'B1' ,'av_tplot(av_abs(B1));ylabel(''B [nT] GSE, sc1'');', ...
  'B2' ,'av_tplot(av_abs(B2));ylabel(''B [nT] GSE, sc2'');', ...
  'B3' ,'av_tplot(av_abs(B3));ylabel(''B [nT] GSE, sc3'');', ...
  'B4' ,'av_tplot(av_abs(B4));ylabel(''B [nT] GSE, sc4'');', ...
  'Blmn1' ,'av_tplot(av_abs(Blmn1));ylabel(''B [nT] LMN, sc1'');legend(''L'',''M'',''N'');', ...
  'Blmn2' ,'av_tplot(av_abs(Blmn2));ylabel(''B [nT] LMN, sc2'');legend(''L'',''M'',''N'');', ...
  'Blmn3' ,'av_tplot(av_abs(Blmn3));ylabel(''B [nT] LMN, sc3'');legend(''L'',''M'',''N'');', ...
  'Blmn4' ,'av_tplot(av_abs(Blmn4));ylabel(''B [nT] LMN, sc4'');legend(''L'',''M'',''N'');', ...
  'ExB' ,'c_pl_tx(av_abs(ExB1),av_abs(ExB2),av_abs(ExB3),av_abs(ExB4),5,1,dt);ylabel(''|ExB| [km/s]'');', ...
  'ExBx' ,'c_pl_tx(ExB1,ExB2,ExB3,ExB4,2,1,dt);ylabel(''ExB_X [km/s] GSE'');', ...
  'ExBy' ,'c_pl_tx(ExB1,ExB2,ExB3,ExB4,3,1,dt);ylabel(''ExB_Y [km/s] GSE'');', ...
  'ExBz' ,'c_pl_tx(ExB1,ExB2,ExB3,ExB4,4,1,dt);ylabel(''ExB_Z [km/s] GSE'');', ...
  'ExBl' ,'c_pl_tx(ExBlmn1,ExBlmn2,ExBlmn3,ExBlmn4,2,1,dt);ylabel(''ExBlmn_L [km/s]'');', ...
  'ExBm' ,'c_pl_tx(ExBlmn1,ExBlmn2,ExBlmn3,ExBlmn4,3,1,dt);ylabel(''ExBlmn_M [km/s]'');', ...
  'ExBn' ,'c_pl_tx(ExBlmn1,ExBlmn2,ExBlmn3,ExBlmn4,4,1,dt);ylabel(''ExBlmn_N [km/s]'');', ...
  'ExB1' ,'av_tplot(av_abs(ExB1));ylabel(''ExB [km/s] GSE, sc1'');', ...
  'ExB2' ,'av_tplot(av_abs(ExB2));ylabel(''ExB [km/s] GSE, sc2'');', ...
  'ExB3' ,'av_tplot(av_abs(ExB3));ylabel(''ExB [km/s] GSE, sc3'');', ...
  'ExB4' ,'av_tplot(av_abs(ExB4));ylabel(''ExB [km/s] GSE, sc4'');', ...
  'ExBlmn1' ,'av_tplot(av_abs(ExBlmn1));ylabel(''ExB [km/s] LMN, sc1'');legend(''L'',''M'',''N'');', ...
  'ExBlmn2' ,'av_tplot(av_abs(ExBlmn2));ylabel(''ExB [km/s] LMN, sc2'');legend(''L'',''M'',''N'');', ...
  'ExBlmn3' ,'av_tplot(av_abs(ExBlmn3));ylabel(''ExB [km/s] LMN, sc3'');legend(''L'',''M'',''N'');', ...
  'ExBlmn4' ,'av_tplot(av_abs(ExBlmn4));ylabel(''ExB [km/s] LMN, sc4'');legend(''L'',''M'',''N'');', ...
  'test','test' ...
  );

file_list=dir([path_events '*F*t*T*t*.mat']);
for i_file=1:size(file_list,1),
  if c_ri_timestr_within_tint(file_list(i_file).name,time_interval),
    tint_plot=c_ri_timestr_within_tint(file_list(i_file).name);
    if debug, disp(['Using file: ' file_list(i_file).name]);end
    for j=1:n_panels,plot_comms{j}=eval(['plot_command.' panels{j}]);end
    load_comm=['load(''' path_events file_list(i_file).name ''');'];
    fig_comm=['i_fig=' num2str(i_fig) '; n_panels=' num2str(n_panels) '; figure(i_fig); i_panel=1;clear h;'];
    loop_comm=['for i_panel=1:n_panels,h(i_fig,i_panel)=irf_subplot(n_panels,1,-i_panel);eval(plot_comms{i_panel});end'];
    if flag_base,
      assignin('base','plot_comms',plot_comms);
      evalin('base',load_comm);
      evalin('base',fig_comm);
      evalin('base',loop_comm);
      h=evalin('base','h;');
    else,
      eval(load_comm);
      eval(fig_comm);
      eval(loop_comm);
    end
    irf_zoom(tint_plot,'x',h(i_fig,:));
    irf_timeaxis(h(i_fig,:));
    legend;
    i_fig=i_fig+1;
  end
end

if flag_print | flag_jpg,
  for j=1:i_fig-1,
    figure(j);
    panel_str='';
    for jj=1:n_panels, panel_str=[panel_str '_' panels{jj}];end
    orient tall;
    if flag_print,
      print_file_name=[file_list(i_file).name '_' panel_str '.ps'];
      print('-dpsc2',print_file_name);
    elseif flag_jpg,
      print_file_name=[file_list(i_file).name '_' panel_str '.jpg'];
      print('-djpg',print_file_name);
    end
  end
end