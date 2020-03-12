%% TA_REP_totals.m
% This application retrieves the data folder to be scanned for aggregating
% the total hourly data in standard format and launches the aggregataion 
% functions in order to produce temporally aggregated datasets to be pushed
% towards CMEMS-INSTAC for the REP products.

% This application works with historical (i.e. not processed for NRT operation
% i.e. not present in the EU HFR Node NRT THREDDS catalog) HFR total files
% in standard format.

% Author: Lorenzo Corgnati
% Date: March 10, 2020

% E-mail: lorenzo.corgnati@sp.ismar.cnr.it
%%

%% Setup

warning('off', 'all');

REPT_err = 0;

disp(['[' datestr(now) '] - - ' 'TA_REP_totals started.']);

%%

try
    
    %% Scan networks, list the input data and run the aggregation
    
    for net_idx=1:length(HFRPnetworks)
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
                    [REPT_err] = TA_REP_total_netCDF_aggregation_v212(HFRPnetworks{net_idx},vers,folderList,nextStart,cur-1,monthlyAggregation);
                    clear folderList
                    day_idx = 1;
                    curMonth = curVec(2); % update current month
                    nextStart = cur; % store the starting datetime for the aggregation process
                end
            end
            dayFolder = [monthFolder '_' curDay(9:10)];
            folderList{day_idx} = ['..' filesep HFRPnetworks{net_idx} filesep 'Totals_nc' filesep vers filesep yearFolder filesep monthFolder filesep dayFolder];
            cur = cur + 1;          % increment day
            day_idx = day_idx + 1;  % increment day index
        end
        
        % Run the aggregation
        [REPT_err] = TA_REP_total_netCDF_aggregation_v212(HFRPnetworks{net_idx},vers,folderList,nextStart,cur-1,monthlyAggregation);
        
    end
    
    %%
    
catch err
    disp(['[' datestr(now) '] - - ERROR in ' mfilename ' -> ' err.message]);
    REPT_err = 1;
end

if(REPT_err==0)
    disp(['[' datestr(now) '] - - ' 'TA_REP_totals successfully executed.']);
else
    disp(['[' datestr(now) '] - - ' 'TA_REP_totals exited with an error.']);
end