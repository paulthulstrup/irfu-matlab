function res = get_ts(dobj,var_s)
%GET_TS(dobj, var_s)  get a variable in as TSeries object
%
% Output:
%			empty, if variable does not exist
%			otherwise TSeries object
%
%  See also: TSeries

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

data = get_variable(dobj,var_s);
if isempty(data), % no such variable, return empty
	res=[];
	return;
end

% MMS special case. This is unly, but convenient.
if isfield(data.GlobalAttributes,'Mission_group') && ...
    strcmpi(data.GlobalAttributes.Mission_group,'mms')
  res = mms.variable2ts(data); return
end
  
fillv = getfillval(dobj,var_s);
if ~ischar(fillv), data.data(data.data==fillv) = NaN;
else irf.log('warning','fill value is character: discarding')
end

if strcmpi(data.DEPEND_0.type,'tt2000')
  Time = EpochTT(data.DEPEND_0.data);
else
  Time = EpochUnix(data.DEPEND_0.data);
end

%userData
ud = data; ud = rmfield(ud,'DEPEND_0'); ud = rmfield(ud,'data');
ud = rmfield(ud,'nrec'); ud = rmfield(ud,'dim'); ud = rmfield(ud,'name');
ud = rmfield(ud,'variance'); ud = rmfield(ud,'UNITS');
repres = [];
if isfield(data,'TENSOR_ORDER') % CAA data has TENSOR_ORDER>=1
  tensorOrder = data.TENSOR_ORDER; ud = rmfield(ud,'TENSOR_ORDER');
  if ischar(tensorOrder), tensorOrder = str2double(tensorOrder); end
  switch tensorOrder
    case 0 % scalar
    case 1 % vector
      if ~isfield(data,'REPRESENTATION_1')
        error('Missing REPRESENTATION_1 for TENSOR_ORDER=1')
      end
      repres = cellstr(data.REPRESENTATION_1.data)';
      ud = rmfield(ud,'REPRESENTATION_1');
    case 2 % tensor
      error('not implemented')
    otherwise
      error('TensorOrder>2 not supported')
  end
else % guessing for Non-CAA data
  tensorOrder = length(data.variance(3:end));
  
  switch tensorOrder
    case 0 % scalar
    case 1 % vector
      if data.dim(1)==2,
        repres = {'x','y'};
      elseif data.dim(1)==3
        repres = {'x','y','z'};
      else tensorOrder = 0; % TENSOR_ORDER=0 can be ommitted in CAA files 
      end
    case 2 % tensor
    otherwise
      error('TensorOrder>2 not supported')
  end
end
if isempty(repres)
  res = TSeries(Time,data.data,'TensorOrder',tensorOrder);
else
  res = TSeries(Time,data.data,'TensorOrder',tensorOrder,...
    'repres',repres);
end
res.name = data.name;
if isfield(data,'UNITS'), res.units = v.UNITS;
else res.units = 'unitless';
end
if isfield(ud,'SI_CONVERSION'), 
  res.siConversion    = ud.SI_CONVERSION;  ud = rmfield(ud,'SI_CONVERSION');
end
if isfield(ud,'COORDINATE_SYSTEM')
  res.coordinateSystem = ud.COORDINATE_SYSTEM;
  ud = rmfield(ud,'COORDINATE_SYSTEM');
end
res.userData = ud;
