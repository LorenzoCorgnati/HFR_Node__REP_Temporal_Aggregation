%% TA_REP_radials.m
% This application retrieves the data folder to be scanned for aggregating
% the radial hourly data in standard format and launches the aggregataion
% functions in order to produce temporally aggregated datasets to be pushed
% towards CMEMS-INSTAC for the REP products.

% This application works with historical (i.e. not processed for NRT operation
% i.e. not present in the EU HFR Node NRT THREDDS catalog) HFR radial files
% in standard format.

% Author: Lorenzo Corgnati
% Date: March 10, 2020

% E-mail: lorenzo.corgnati@sp.ismar.cnr.it
%%

%% Setup

warning('off', 'all');

REPR_err = 0;

disp(['[' datestr(now) '] - - ' 'TA_REP_radials started.']);

%%

try
    
    %% Scan networks, list the input data and run the aggregation
    
    for net_idx=1:length(HFRPnetworks)
        % Find the radial station folders
        radialFolder = dir(['..' filesep HFRPnetworks{net_idx} filesep 'Radials_nc' filesep vers]);
        if(length(radialFolder)>2)
            dot_flag = 1;
            while (dot_flag == 1)
                if (radialFolder(1).name(1) == '.')
                    radialFolder = radialFolder(2:size(radialFolder,1));
                else
                    dot_flag = 0;
                end
            end
            
            % Scan radial stations
            for rad_idx=1:length(radialFolder)
                % Set initial search time
                cur = datenum(procStartDate{net_idx});
                nextStart = cur; % store the starting datetime for the aggregation process
                % Check if the monthly aggregation is needed
                if(monthlyAggregation==1)
                    curVec = datevec(cur);
                    curMonth = curVec(2);
                end
                day_idx = 1;
                while(cur<=datenum(procEndDate{net_idx}))
                    curDay = datestr(cur,'yyyy-mm-dd');
                    yearFolder = curDay(1:4);
                    monthFolder = [yearFolder '_' curDay(6:7)];
                    % Check if the monthly aggregation is needed
                    if(monthlyAggregation==1)
                        curVec = datevec(cur);
                        if(curVec(2) ~= curMonth)
                            % Run the aggregation
                            [REPR_err] = TA_REP_radial_netCDF_aggregation(HFRPnetworks{net_idx},vers,radialFolder(rad_idx).name,folderList,nextStart,cur-1,monthlyAggregation);
                            clear folderList
                            day_idx = 1;
                            curMonth = curVec(2); % update current month
                            nextStart = cur; % store the starting datetime for the aggregation process
                        end
                    end
                    dayFolder = [monthFolder '_' curDay(9:10)];
                    folderList{day_idx} = [radialFolder(rad_idx).folder filesep radialFolder(rad_idx).name filesep yearFolder filesep monthFolder filesep dayFolder];
                    cur = cur + 1;          % increment day
                    day_idx = day_idx + 1;  % increment day index
                end
                
                % Run the aggregation
                [REPR_err] = TA_REP_radial_netCDF_aggregation(HFRPnetworks{net_idx},vers,radialFolder(rad_idx).name,folderList,nextStart,cur-1,monthlyAggregation);
                
            end
            
        end
        
    end
    
    %%
    
catch err
    disp(['[' datestr(now) '] - - ERROR in ' mfilename ' -> ' err.message]);
    REPR_err = 1;
end

if(REPR_err==0)
    disp(['[' datestr(now) '] - - ' 'TA_REP_radials successfully executed.']);
else
    disp(['[' datestr(now) '] - - ' 'TA_REP_radials exited with an error.']);
end