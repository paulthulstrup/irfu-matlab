function caa_pl_summary_l1(iso_t,dt,sdir,varargin)
%CAA_PL_SUMMARY_L1  CAA summary plot for L1 & L2 P data & EF
%
% caa_pl_summary_l1(iso_t,dt,sdir,[options])
%   options:
%           savepdf   - save PDF
%           saveps    - same as 'savepdf' (deprecated)
%           savepng   - save JPG
%           savepng   - save PNG
%           save      - save PNG, PS and PDF
%           nosave
%           fullscale - use full scale (up to 180 Hz) on spectrograms
%           nospec    - do not plot spectrum
%           usextra   - use and plot DdsiX offsets
%
% In iso_t='-1' and dt=-1, they will be determined automatically
%
% $Id$

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

if nargin==0, sdir = pwd; iso_t = -1; dt = -1; end

if ~exist(sdir,'dir'), error(['directory ' sdir ' does not exist']), end

savePDF = 0;
savePNG = 0;
saveJPG = 0;
fullscale = 0;
plotspec = 1;
plotbitmask = 1;
usextra = 0;
data_level = 2;
QUALITY = 3;

int_s = realmax;
int_e = -1;

if nargin > 3, have_options = 1; args = varargin;
else have_options = 0;
end
while have_options
	l = 1;
	switch(args{1})
		case 'nosave'
			savePDF = 0;
			savePNG = 0;
		case 'save'
			savePDF = 1;
			savePNG = 1;
		case 'saveps'
			savePDF = 1;
		case 'savepdf'
			savePDF = 1;
		case 'savepng'
			savePNG = 1;
		case 'savejpg'
			saveJPG = 1;
		case 'fullscale'
			fullscale = 1;
		case 'nospec'
			plotspec = 0;
		case 'usextra'
			usextra = 1;
		otherwise
			irf_log('fcal,',['Option ''' args{1} '''not recognized'])
	end
	if length(args) > l, args = args(l+1:end);
	else break
	end
end

old_pwd = pwd;

% Save the screen size
sc_s = get(0,'ScreenSize');
if sc_s(3)==1600 && sc_s(4)==1200, scrn_size = 2;
else scrn_size = 1;
end

% Load data
r = [];
ri = [];
fmax = 12.5;
c_eval('p?=[];spec?={};es?=[];rspec?=[];in?={};wamp?=[];pswake?=[];lowake?=[];edi?=[];')

for cli=1:4
	cdir = [sdir '/C' num2str(cli)];
	in = {};
	
	if ~exist(cdir, 'dir'), continue, end
	d = dir([cdir '/2*_*']);
	if isempty(d), continue, end

	for jj=1:length(d)
		curdir = [cdir '/' d(jj).name];
		if ~exist([curdir '/.interval'],'file'), continue, end
		cd(curdir)

		% Load intervals & TM mode
		[st_s,dt1] = caa_read_interval;
		t1 = iso2epoch(st_s);
		if t1<int_s, int_s = t1; end
		if t1+dt1>int_e, int_e = t1+dt1; end
		in_tmp.interv = [t1 dt1];
		in_tmp.st_s = st_s(12:16);
        in_tmp.probeID= caa_sfit_probe(cli);
		tm = c_load('mTMode?',cli,'var');
		if ~isempty(tm) && tm(1,1)~=-157e8
			if tm(1), in_tmp.tm = 1; else in_tmp.tm = 0; end
		else in_tmp.tm = -1;
		end
		in = [in; {in_tmp}];
		clear in_tmp

		cd(old_pwd)
	end
	if ~isempty(in), c_eval('in?=in;',cli), end, clear in
end

if ( strcmp(iso_t,'-1') || (isnumeric(iso_t) && iso_t==-1) ) && dt==-1
	st = int_s;
	dt = int_e - int_s;
else st = iso2epoch(iso_t);
end

dEx = cell(4,1);
for cli=1:4
	cdir = [sdir '/C' num2str(cli)];
	p = []; spec = {}; es = []; rspec = []; wamp = [];
	pswake = []; lowake = []; edi = [];
	
	if exist(cdir, 'dir')
		d = dir([cdir '/2*_*']);
		if isempty(d), continue, end
		
		for jj=1:length(d)
			curdir = [cdir '/' d(jj).name];
			if ~exist([curdir '/.interval'],'file'), continue, end
			cd(curdir)
			
			% Load R
			if isempty(r) || ri==cli
				r_tmp = c_load('R?',cli,'var');
				if ~isempty(r_tmp) && r_tmp(1,1)~=-157e8, r = [r; r_tmp]; end
				if isempty(ri), ri = cli; end
			end
			clear r_tmp
			
			% Load EDI
			edi_tmp = c_load('diEDI?',cli,'var');
			if ~isempty(edi_tmp) && edi_tmp(1,1)~=-157e8
				edi = [edi; edi_tmp];
			end
			clear edi_tmp
			
			% Load P
			p_tmp = c_load('P?',cli,'var');
			if ~isempty(p_tmp) && p_tmp(1,1)~=-157e8, p = [p; p_tmp]; end
			clear p_tmp
			
            % Load SW WAKE amplitude
            for pp=[12 32 34]
                wamp_tmp = c_load(['WAKE?p' num2str(pp)],cli,'var');
                if ~isempty(wamp_tmp) && wamp_tmp(1,1)~=-157e8
                    wamp = [wamp; wamp_tmp(:,[1 3])];
                end
                clear wamp_tmp
            end
            
			% Load PS/LO WAKEs
            for pp=[12 32 34]
                pswake_tmp = c_load(['PSWAKE?p' num2str(pp)],cli,'var');
                if ~isempty(pswake_tmp) && pswake_tmp(1,1)~=-157e8
                    pswake = [pswake; pswake_tmp];
                end
                clear pswake_tmp
                lowake_tmp = c_load(['LOWAKE?p' num2str(pp)],cli,'var');
                if ~isempty(lowake_tmp) && lowake_tmp(1,1)~=-157e8
                    lowake = [lowake; lowake_tmp];
                end
                clear lowake_tmp
            end
            
			% Load spectrum
			spec_tmp = c_load('diESPEC?p1234',cli,'var');
			if ~isempty(spec_tmp) && isstruct(spec_tmp)
				spec = [spec; {spec_tmp}];
				if spec_tmp.f(end)>fmax, fmax = spec_tmp.f(end); end
			end
			clear spec_tmp
			
			% Load Es
			pp = caa_sfit_probe(cli);
            es_tmp = c_load(['diEs?p' num2str(pp)],cli,'var');
			if ~isempty(es_tmp) && es_tmp(1,1)~=-157e8
			   
%			   E_info = c_load('diESPEC?p1234_info', cli, 'var');  % Load info; need list of probe pairs!
            E_info = c_load('diE?p1234_info', cli, 'var');    % Load info; need list of probe pairs!
            if isempty(E_info) || ~isfield(E_info, 'probe')
               error('Could not load probe pair info!')
            end

            % Remove saturation due to too high bias current        
            for probepair=[12 32 34]
                [ok,hbias,msg] = c_load(irf_ssub('HBIASSA?p!',cli,probepair));
                if ok
                    if ~isempty(hbias)
                        irf_log('proc','blanking HB saturation')
                        es_tmp = caa_rm_blankt(es_tmp,hbias);
                    end
                else irf_log('load',msg)
                end
                clear ok hbias msg
            end
            
             % Remove whisper pulses    
             [ok,whip,msg] = c_load('WHIP?',cli);
             if ok
                 if ~isempty(whip)
                     irf_log('proc','blanking Whisper pulses')
                     es_tmp = caa_rm_blankt(es_tmp,whip);
                 end
             else irf_log('load',msg)
             end
             clear ok whip msg
           
            
            %%% Fill gaps in data???? %%%
            

			   % Extend data array to accept bitmask and quality flag (2 columns at the end)
			   es_tmp = [es_tmp zeros(size(es_tmp, 1), 2)];
			   es_tmp(:, end) = QUALITY;    % Default quality column to best quality, i.e. good data/no problems.
			   quality_column = size(es_tmp, 2);
			   bitmask_column = quality_column - 1;

			   % Identify and flag problem areas in data with bitmask and quality factor:
            es_tmp = caa_identify_problems(es_tmp, data_level, E_info.probe, cli, bitmask_column, quality_column);
			   
				% Delta offsets
				Del_caa = c_efw_delta_off(es_tmp(1,1),cli);
				if ~isempty(Del_caa)
					[ok,Delauto] = c_load('D?p12p34',cli);
					if ~ok || isempty(Delauto)
						irf_log('load',irf_ssub('Cannot load/empty D?p12p34',cli))
					else
						es_tmp = caa_corof_delta(es_tmp,pp,Delauto,'undo');
						es_tmp = caa_corof_delta(es_tmp,pp,Del_caa,'apply');
					end
				end
				
				
				% DSI offsets
				dsiof = c_ctl(cli,'dsiof');
				if isempty(dsiof)
					[ok,Ps,msg] = c_load('Ps?',cli,'var');
					if ~ok, irf_log('load',msg), end
					if caa_is_sh_interval
						[dsiof_def, dam_def] = c_efw_dsi_off(es_tmp(1,1),cli,[]);
					else
						[dsiof_def, dam_def] = c_efw_dsi_off(es_tmp(1,1),cli,Ps);
					end
					clear ok Ps msg
					
					if usextra % Xtra offset
						[ok1,Ddsi] = c_load('DdsiX?',cli);
						if ~ok1
							[ok1,Ddsi] = c_load('Ddsi?',cli);
							if ~ok1, Ddsi = dsiof_def; end
						else
							iso_t = caa_read_interval;
							dEx(cli)={[dEx{cli}, {[iso2epoch(iso_t) real(Ddsi)]}]};
						end
					else
						[ok1,Ddsi] = c_load('Ddsi?',cli);
						if ~ok1, Ddsi = dsiof_def; end
					end
					[ok2,Damp] = c_load('Damp?',cli); if ~ok2, Damp = dam_def; end

					if ok1 || ok2, irf_log('calb',...
							['Saved DSI offsets on C' num2str(cli)])
					%else irf_log('calb','Using default DSI offsets')
					end
					clear dsiof_def dam_def
				else
					Ddsi = dsiof(1); Damp = dsiof(2);
					irf_log('calb',['User DSI offsets on C' num2str(cl_id)])
				end
				clear dsiof
				
				es_tmp = caa_corof_dsi(es_tmp,Ddsi,Damp); clear Ddsi Damp
				es = [es; es_tmp];
			end
			clear es_tmp
			
			% Load RSPEC
			rspec_tmp = c_load(['RSPEC?p' num2str(pp)],cli,'var');
			if ~isempty(rspec_tmp) && rspec_tmp(1,1)~=-157e8 
				rs = rspec_tmp;
				rs(:,2) = sqrt(rspec_tmp(:,2).^2+rspec_tmp(:,3).^2);
				rs(:,3) = sqrt(rspec_tmp(:,4).^2+rspec_tmp(:,5).^2);
				rs(:,4) = sqrt(rspec_tmp(:,6).^2+rspec_tmp(:,7).^2);
				rs(:,5) = sqrt(rspec_tmp(:,8).^2+rspec_tmp(:,9).^2);
				rs(:,6) = sqrt(rspec_tmp(:,10).^2+rspec_tmp(:,11).^2);
				rs(:,7:end) = [];
				rspec = [rspec; rs];
				clear rs
			end
			clear rspec_tmp
			
			cd(old_pwd)
		end
		if ~isempty(edi), c_eval('edi?=edi;',cli), end, clear edi
		if ~isempty(p), c_eval('p?=p;',cli), end, clear p
		if ~isempty(wamp), c_eval('wamp?=wamp;',cli), end, clear wamp
		if ~isempty(pswake)
			c_eval('pswake?=pswake;',cli)
%			if ~isempty(es), es = caa_rm_blankt(es,pswake); end
		end
		clear pswake
		if ~isempty(lowake)
			c_eval('lowake?=lowake;',cli)
%			if ~isempty(es), es = caa_rm_blankt(es,lowake); end
		end
		clear lowake
        
		if ~isempty(es), c_eval('es?=es;',cli), end, clear es
		if ~isempty(rspec), c_eval('rspec?=rspec;',cli), end, clear rspec
		if ~isempty(spec), c_eval('spec?=spec;',cli), end, clear spec
	end
end

ds = irf_fname(st);
tit = ['EFW E and P 5Hz (' ds(1:4) '-' ds(5:6) '-' ds(7:8) ' ' ds(10:11) ':'...
	ds(12:13) ', produced ' date ')'];
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spectrum figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if plotspec

figure(75)
if scrn_size==1 ,set(gcf,'position',[91  40 909 640])
else set(gcf,'position',[7   159   790   916])
end
clf

h = 1:7;
for pl=1:7, h(pl) = irf_subplot(7,1,-pl); end

figure_start_epoch(st);

ytick =  [.25 .5 1 10];
if fullscale && fmax>100, ytick = [ytick 100]; end
for cli=1:4
	axes(h(cli))
	hold on
	c_eval('spec=spec?;',cli)
	if ~isempty(spec)
		for k=1:length(spec), caa_spectrogram(h(cli),spec{k}), end
	end
	ylabel(sprintf('Ex C%d freq [Hz]',cli))
	set(gca,'YTick',ytick,'YScale','log')
	grid
	caxis([-4 1])
	hold off
	if fullscale, set(h(cli),'YLim',[0 fmax])
	else set(h(cli),'YLim',[0 12.5])
	end
	if cli==1
		if isempty(r), title(h(1),tit)
		else title(h(1),[tit ', GSE Position C' num2str(ri)])
		end
	end
	if dt>0, irf_zoom(st +[0 dt],'x',h(cli)), end
	set(gca,'XTickLabel',[])
end

% Plot quality
plot_quality(h(5), {es1, es2, es3, es4}, st)
irf_zoom(st + [0 dt], 'x', h(5))


% Plot P
axes(h(6))
c_pl_tx('p?')
ylabel('P L2 [-V]')
a = get(gca,'YLim');
if a(1)<-70, a(1)=-70; set(gca,'YLim',a); end
irf_zoom(st +[0 dt],'x',h(6))

if dt>0 
	plot_intervals(h(7),{in1,in2,in3,in4},st)
	irf_zoom(st +[0 dt],'x',h(7))
	if ~isempty(r), add_position(h(7),r), end
end

orient(75,'tall')

end % if plotspec

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% E-field figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Resample EDI
if dt>0
	TAV = 180;
	ndata = ceil(dt/TAV);
	t = st + (1:ndata)*TAV - TAV/2; t = t'; %#ok<NASGU>   '
	c_eval('if ~isempty(edi?), edi?_tmp=irf_resamp(edi?,t,''fsample'',1/TAV,''thresh'',1.3); if size(edi?,1)>1,edi?=irf_tlim(edi?_tmp,[edi?(1,1) edi?(end,1)]); else edi?=edi?_tmp; end, clear edi?_tmp, end')
end
% Limit EDI
c_eval('if ~isempty(edi?) && ~isempty(es?) && any(~isnan(es?(:,2))), for c=2:3, edi?( edi?(:,c)>max(es?(~isnan(es?(:,c)),c)) & edi?(:,c)<min(es?(~isnan(es?(:,c)),c)), c) = NaN; end, end')

figure(76)
if scrn_size==1 ,set(gcf,'position',[91  40 909 640])
else set(gcf,'position',[807   159   790   916])
end
clf

he = 1:8;
for pl=1:8,	he(pl) = irf_subplot(8,1,-pl); end

figure_start_epoch(st);

% Plot E
axes(he(1)), c_pl_tx('edi?',2,'.'), hold on
c_pl_tx('es?',2), hold off, ylabel('Ex [mV/m]'), axis tight
if isempty(r), title(he(1),tit)
else title(he(1),[tit ', GSE Position C' num2str(ri)])
end

axes(he(2)), c_pl_tx('edi?',3,'.'), hold on
c_pl_tx('es?',3), hold off, ylabel('Ey [mV/m]'), axis tight

% Plot RSPEC
for cli=1:4
    c_eval('axes(he(2+?)),if ~isempty(rspec?),irf_plot(rspec?), if ~isempty(lowake?),hold on,irf_plot(caa_rm_blankt(rspec?(:,1:2),lowake?,1),''rO''),end,if ~isempty(pswake?),hold on,irf_plot(caa_rm_blankt(rspec?(:,1:2),pswake?,1),''gd''),end,axis tight,end, ylabel(''Rspec C?''), grid on, hold off',cli);
	c_eval('in = in?;',cli);
	if isempty(in), continue, end 
	for k=1:length(in)
		in_tmp = in{k};
        yrange = get(gca,'YLim');
		text(in_tmp.interv(1)-figure_start_epoch(st)+60,yrange(2)*0.8,['p' num2str(in_tmp.probeID)])
	end

end

t_start_epoch = figure_start_epoch(st);
for cli=1:4
	if ~isempty(dEx{cli})
		axes(he(2+cli));
		yy=get(gca,'YLim');
		yy=yy(1)+0.7*(yy(2)-yy(1));
		for in=1:length(dEx{cli})
			text(dEx{cli}{in}(1) - t_start_epoch, yy, ...
				sprintf('%.2f',dEx{cli}{in}(2)),'color','g')
		end
	end
end

% Plot P
axes(he(7))
if ~isempty(wamp1) || ~isempty(wamp2)|| ~isempty(wamp3)|| ~isempty(wamp4)
	c_pl_tx('wamp?')
	ylabel('Wake [mV/m]')
else
	c_pl_tx('p?')
	ylabel('P L2 [-V]')
	a = get(gca,'YLim');
	if a(1)<-70, a(1)=-70; set(gca,'YLim',a); end
end

if dt>0 
	plot_intervals(he(8),{in1,in2,in3,in4},st)
	irf_zoom(st +[0 dt],'x',he)
	if ~isempty(r), add_position(he(8),r), end
end

orient(76,'tall')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Quality bitmask figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if plotbitmask
   
figure(77)
if scrn_size==1 ,set(gcf,'position',[91  40 909 640])
else set(gcf,'position',[7   159   790   916])
end
clf

h = 1:6;
for pl=1:6, h(pl) = irf_subplot(6,1,-pl); end

figure_start_epoch(st);

% Plot bits in bitmask
ytick_label =  1:16;
ytick_offset = fix( (ytick_label-1) / 4 );
ytick = ytick_label + ytick_offset;

for cli=1:4
	axes(h(cli))
	hold on
	c_eval('es=es?;',cli)
	if ~isempty(es)
%	   keyboard
	   for k = 1:16
	      plot([es(1,1) es(end,1)] - t_start_epoch, [k k] + fix((k-1)/4), 'k')
	      index = find( bitget(es(:,bitmask_column), k) );
	      if ~isempty(index)
	         ind_d = find( diff(index) > 1 );
	         if ~isempty(ind_d)
%               disp('Several intervals!')
%	            keyboard               
               ind_start = 1;
               for ii = 1:length(ind_d)
                  ind_stop = ind_d(ii);
                  plot([es(index(ind_start),1) es(index(ind_stop),1)] - t_start_epoch, ...
                     [ytick(k) ytick(k)], 'r', 'LineWidth', 2);
                  ind_start = ind_d(ii)+1;
               end
               plot([es(index(ind_start),1) es(index(end),1)] - t_start_epoch, ...
                     [ytick(k) ytick(k)], 'r', 'LineWidth', 2);
	         else
	            plot([es(index(1),1) es(index(end),1)] - t_start_epoch, ...
	               [ytick(k) ytick(k)], 'r', 'LineWidth', 2);
	         end
	      end
	   end
%		for k=1:length(es), caa_spectrogram(h(cli),spec{k}), end
%      keyboard
	end
	if cli==1
		if isempty(r), title(h(1),tit)
		else title(h(1),[tit ', GSE Position C' num2str(ri)])
		end
	end
	ylabel(sprintf('Bitmask C%d [bit no.]',cli))
	set(gca,'YTick',ytick, 'YTickLabel', ytick_label, 'FontSize', 6)
	grid
%	caxis([-4 1])
	hold off
%	if fullscale, set(h(cli),'YLim',[0 fmax])
%	else set(h(cli),'YLim',[0 12.5])
%	end
	
	if dt>0, irf_zoom(st +[0 dt],'x',h(cli)), end
%	set(gca,'XTickLabel',[])
%	keyboard
end

% Plot quality
plot_quality(h(5), {es1, es2, es3, es4}, st)
irf_zoom(st + [0 dt], 'x', h(5))

if dt>0 
	plot_intervals(h(6),{in1,in2,in3,in4},st)
	irf_zoom(st +[0 dt],'x',h(6))
	if ~isempty(r), add_position(h(6),r), end
end

orient(77, 'tall')
%keyboard
end % if plotbitmask

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export figures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if fullscale,fn = sprintf('EFW_SPLOT_L1FULL__%s',irf_fname(st));
else fn = sprintf('EFW_SPLOT_L1ESPEC__%s',irf_fname(st));
end
fne = sprintf('EFW_SPLOT_L1ERSPEC__%s',irf_fname(st));
fnq = sprintf('EFW_SPLOT_L1QUAL__%s',irf_fname(st));
fone = sprintf('EFW_SPLOT_L1__%s',irf_fname(st));

if savePDF
	irf_log('save',['saving ' fn '.pdf'])
	irf_log('save',['saving ' fne '.pdf'])
	irf_log('save',['saving ' fnq '.pdf'])
	print( 75, '-dpdf', fn), print( 76, '-dpdf', fne), print( 77, '-dpdf', fnq)
	if exist('/usr/local/bin/pdfjoin','file')
		irf_log('save',['joining to ' fone '.pdf'])
		s = unix(['LD_LIBRARY_PATH="" /usr/local/bin/pdfjoin ' fn '.pdf ' fne '.pdf ' fnq '.pdf --outfile ' fone '.pdf']);
		if s~=0, irf_log('save','problem with pdfjoin'), end
	else
		irf_log('proc',...
			'cannot join PDFs: /usr/local/bin/pdfjoin does not exist')
	end
end
if savePNG
	if exist('/usr/local/bin/eps2png','file')
		irf_log('save',['saving ' fn '.png'])
		irf_log('save',['saving ' fne '.png'])
		irf_log('save',['saving ' fnq '.png'])
		print( 75, '-depsc2', fn), print( 76, '-depsc2', fn), print( 77, '-depsc2', fnq)
		s = unix(['/usr/local/bin/eps2png -res 150 ' fn '.eps; rm -f ' fn '.eps']);
		if s~=0, irf_log('save','problem with eps2png'), end
		s = unix(['/usr/local/bin/eps2png -res 150 ' fne '.eps; rm -f ' fne '.eps']);
		if s~=0, irf_log('save','problem with eps2png'), end
		s = unix(['/usr/local/bin/eps2png -res 150 ' fnq '.eps; rm -f ' fnq '.eps']);
		if s~=0, irf_log('save','problem with eps2png'), end
	else
		irf_log('proc',...
			'cannot save JPG: /usr/local/bin/eps2png does not exist')
	end
end
if saveJPG
	if exist('/usr/local/bin/eps2png','file')
		irf_log('save',['saving ' fn '.jpg'])
		irf_log('save',['saving ' fne '.jpg'])
		irf_log('save',['saving ' fnq '.jpg'])
		print( 75, '-depsc2', fn), print( 76, '-depsc2', fn), print( 77, '-depsc2', fnq)
		s = unix(['/usr/local/bin/eps2png -jpg -res 150 ' fn '.eps; rm -f ' fn '.eps']);
		if s~=0, irf_log('save','problem with eps2png'), end
		s = unix(['/usr/local/bin/eps2png -jpg -res 150 ' fne '.eps; rm -f ' fne '.eps']);
		if s~=0, irf_log('save','problem with eps2png'), end
		s = unix(['/usr/local/bin/eps2png -jpg -res 150 ' fnq '.eps; rm -f ' fnq '.eps']);
		if s~=0, irf_log('save','problem with eps2png'), end
	else
		irf_log('proc',...
			'cannot save JPG: /usr/local/bin/eps2png does not exist')
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Help functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_intervals(h,ints,st)
% Plot intervals

krgb = 'krgb';
cli_pos = [4 3 2 1];

axes(h)
t_start_epoch = figure_start_epoch(st);

hold(h,'on')
for cli=1:4
	in = ints{cli};
	if isempty(in), continue, end 
	for k=1:length(in)
		in_tmp = in{k};
		pp = plot(in_tmp.interv(1)-t_start_epoch + [0 in_tmp.interv(2)],...
			[cli_pos(cli) cli_pos(cli)],krgb(cli));
		set(pp,'Marker','+');
		if in_tmp.tm==1, set(pp,'LineWidth',3)
		elseif in_tmp.tm==-1, set(pp,'LineStyle','--')
		end
		text(in_tmp.interv(1)-t_start_epoch+60,cli_pos(cli)+0.2,in_tmp.st_s)
	end
end
hold(h,'off')
set(h,'YLim',[0 5],'YTick',1:4,'YTickLabel',4:-1:1)
ylabel(h,'proc intrerv/SC')
grid(h,'on')


function plot_quality(h, dataset, st)
% Plot quality factor
   
   linecolor = 'yrgb';
   cli_pos = [4 3 2 1];
   
   axes(h)
   t_start_epoch = figure_start_epoch(st);
   
   hold(h,'on')
   for cli=1:4
   	data = dataset{cli};
   	if isempty(data), continue, end
      quality = data(:, end);
      indexes = [];
      start_ind = 1;
      finished = 0;

   	while ~finished
   	   if isnan(quality(start_ind))
   	      next_ind = find(~isnan(quality(start_ind:end)), 1);
   	   else
   	      next_ind = find(quality(start_ind:end) ~= quality(start_ind), 1);
   	   end
   	   if isempty(next_ind)
            next_ind = length(quality(start_ind:end)) + 1;
            finished = 1;
         end

   	   end_ind = start_ind + next_ind - 2;
   	   indexes = [indexes; [start_ind end_ind] quality(start_ind)];

   	   if ~isnan(quality(start_ind))
            pp = plot([data(start_ind, 1) data(end_ind, 1)] - t_start_epoch, ...
               [cli_pos(cli) cli_pos(cli)], linecolor(quality(start_ind)+1), ...
                  'LineWidth', 3-quality(start_ind)+0.5);
         end
   	   
   	   start_ind = start_ind + next_ind - 1;
   	end
%   	for pl = 1:size(indexes, 1)
%   	   if ~isnan(indexes(pl, 3))
%   	      start_time = data(indexes(pl, 1), 1);
%   	      end_time = data(indexes(pl, 2), 1);
%   	      pp = plot([start_time, end_time] - t_start_epoch, ...
%   	         [cli_pos(cli) cli_pos(cli)], linecolor(indexes(pl, 3)+1), 'LineWidth', 2);
%         end
%      end
%      keyboard
   	
%      pp = plot([data(:,1), data(:,end)], [cli_pos(cli) cli_pos(cli)], linecolor(cli));
   end
   hold(h,'off')
   set(h,'YLim',[0 5],'YTick',1:4,'YTickLabel',4:-1:1)
   ylabel(h,'Quality/SC')
   grid(h,'on')


function t_start_epoch = figure_start_epoch(st)
ud = get(gcf,'userdata');
if isfield(ud,'t_start_epoch'), 
	t_start_epoch = ud.t_start_epoch;
else
	t_start_epoch = st;
	ud.t_start_epoch = t_start_epoch;
	set(gcf,'userdata',ud);
	irf_log('proc',['user_data.t_start_epoch is set to '...
		epoch2iso(t_start_epoch,1)]);
end
