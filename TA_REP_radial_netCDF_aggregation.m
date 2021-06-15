%% TA_REP_radial_netCDF_aggregation.m
% This function lists all the radial files contained in the input folder
% list and aggregates them in standard format in order to produce temporally
% aggregated datasets to be pushed towards CMEMS-INSTAC for the REP products.

% INPUT:
%         networkID: network ID of the current HFR network
%         vers: version of the data model
%         radSite: radial station
%         folders: cell array containing the folder paths where to find
%                  hourly netCDF files to be aggregated
%         initialDate: datenum of the initial date of the aggregation
%         finalDate: datenum of the final date of the aggregation
%         perMonth: monthly aggregation flag (0 = whole aggregation, 1 = monthly aggregation)

% OUTPUT:
%         rnA_err: error flag (0 = correct, 1 = error)

% Author: Lorenzo Corgnati
% Date: March 10, 2020

% E-mail: lorenzo.corgnati@sp.ismar.cnr.it
%%

function [rnA_err] = TA_REP_radial_netCDF_aggregation(networkID,vers,radSite,folders,initialDate,finalDate,perMonth)

%% Setup

disp(['[' datestr(now) '] - - ' 'TA_REP_radial_netCDF_aggregation.m started.']);

rnA_err = 0;

%%

try
    
    %% Set output folders
    
    % Set the folder paths
    aggrFolder = ['..' filesep networkID filesep 'REP_Aggregated'];
    RADaggrFolder = [aggrFolder filesep 'Radials' filesep vers filesep radSite];
    
    % Check the existence of the output folders
    if (exist(aggrFolder, 'dir') ~= 7)
        mkdir(aggrFolder);
    end
    if (exist(RADaggrFolder, 'dir') ~= 7)
        mkdir(RADaggrFolder);
    end
    
    %%
    
    %% Create the list of files to be aggregated
    
    fileList = rdir([folders{1} filesep '**' filesep '*.nc']);
    for folder_idx=2:length(folders)
        curDirFiles = rdir([folders{folder_idx} filesep '**' filesep '*.nc']);
        fileList = [fileList; curDirFiles];
        clear curDirFiles
    end
    
    %%
    
    if(~isempty(fileList))
        %% Prepare the aggregated netCDF file
        
        % Set output filename
        startVec = datevec(initialDate);
        endVec = datevec(finalDate);
        % Check if the monthly aggregation is needed
        if(perMonth == 1)
            time_str = sprintf('%.4d%.2d',startVec(1),startVec(2));
        else
            time_str = sprintf('%.4d%.2d%.2d_%.4d%.2d%.2d',startVec(1),startVec(2),startVec(3),endVec(1),endVec(2),endVec(3));
        end
%         aggrFilename = [RADaggrFolder filesep 'RV_HF_Aggregated_' networkID '-' radSite '_' time_str '.nc'];
        aggrFilename = [RADaggrFolder filesep 'RV_HF_' networkID '-' radSite '.nc'];
        
        % Get schema of the netCDF files to be aggregated
        HFRnetcdfRadSchema = ncinfo(fileList(end).name);
        
        % Modify TIME dimension according to the number of files to be aggregated
        HFRnetcdfRadSchema.Dimensions(1).Length=length(fileList);
        for var_idx=1:length(HFRnetcdfRadSchema.Variables)
            for dim_idx=1:length(HFRnetcdfRadSchema.Variables(var_idx).Dimensions)
                if(strcmp(HFRnetcdfRadSchema.Variables(var_idx).Dimensions(dim_idx).Name,'TIME'))
                    HFRnetcdfRadSchema.Variables(var_idx).Dimensions(dim_idx).Length = length(fileList);
                end
            end
        end
        
        % Modify the data_mode attribute for all variables
        for var_idx=1:length(HFRnetcdfRadSchema.Variables)
            for attr_idx=1:length(HFRnetcdfRadSchema.Variables(var_idx).Attributes)
                if(strcmp(HFRnetcdfRadSchema.Variables(var_idx).Attributes(attr_idx).Name,'data_mode'))
                    HFRnetcdfRadSchema.Variables(var_idx).Attributes(attr_idx).Value = char('D');
                end
            end
        end
        
        % Delete the eventually present netCDF file with the same name
        delete(aggrFilename);
        
        % Create the aggregated netCDF file with the modified schema
        ncwriteschema(aggrFilename,HFRnetcdfRadSchema);
        
        %%
        
        %% Read and concatenate data from all the netCDF files and write them into the aggregated file
        
        % Set time references
        timeref = datenum(1950,1,1);  % days since 1950-01-01T00:00:00Z
        
        for file_idx=1:length(fileList)
            % Retrieve manufacturer info
            sensorATT = ncreadatt(fileList(file_idx).name,'/','sensor');
            
            % Time variable
            nc.time(file_idx) = ncread_cf_time(fileList(file_idx).name,'TIME') - timeref;
            
            if(file_idx ==1)
                % Coordinate variables
                if(contains(sensorATT,'codar','IgnoreCase',true))
                    nc.bear = ncread(fileList(file_idx).name,'BEAR');
                    nc.rnge = ncread(fileList(file_idx).name,'RNGE');
                end
                nc.latitude = ncread(fileList(file_idx).name,'LATITUDE');
                nc.longitude = ncread(fileList(file_idx).name,'LONGITUDE');
                nc.deph = ncread(fileList(file_idx).name,'DEPH');
                nc.crs = ncread(fileList(file_idx).name,'crs');
                if(contains(sensorATT,'codar','IgnoreCase',true))
                    nc.xdst = ncread(fileList(file_idx).name,'XDST');
                    nc.ydst = ncread(fileList(file_idx).name,'YDST');
                end
            end
            
            % SDN namespace variables
            nc.sdn_cruise(:,file_idx) = ncread(fileList(file_idx).name,'SDN_CRUISE');
            nc.sdn_station(:,file_idx) = ncread(fileList(file_idx).name,'SDN_STATION');
            nc.sdn_local_cdi_id(:,file_idx) = ncread(fileList(file_idx).name,'SDN_LOCAL_CDI_ID');
            nc.sdn_edmo_code(:,file_idx) = ncread(fileList(file_idx).name,'SDN_EDMO_CODE');
            nc.sdn_references(:,file_idx) = ncread(fileList(file_idx).name,'SDN_REFERENCES');
            nc.sdn_xlink(:,:,file_idx) = ncread(fileList(file_idx).name,'SDN_XLINK');
            
            % Data variables
            nc.rdva(:,:,:,file_idx) = ncread(fileList(file_idx).name,'RDVA');
            nc.drva(:,:,:,file_idx) = ncread(fileList(file_idx).name,'DRVA');
            nc.ewct(:,:,:,file_idx) = ncread(fileList(file_idx).name,'EWCT');
            nc.nsct(:,:,:,file_idx) = ncread(fileList(file_idx).name,'NSCT');
            if(contains(sensorATT,'wera','IgnoreCase',true))
                nc.hcss(:,:,:,file_idx) = ncread(fileList(file_idx).name,'HCSS');
                nc.eacc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'EACC');
            elseif(contains(sensorATT,'codar','IgnoreCase',true))
                nc.espc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'ESPC');
                nc.etmp(:,:,:,file_idx) = ncread(fileList(file_idx).name,'ETMP');
                nc.maxv(:,:,:,file_idx) = ncread(fileList(file_idx).name,'MAXV');
                nc.minv(:,:,:,file_idx) = ncread(fileList(file_idx).name,'MINV');
                nc.ersc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'ERSC');
                nc.ertc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'ERTC');
                nc.sprc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'SPRC');
            end
            nc.narx(file_idx) = ncread(fileList(file_idx).name,'NARX');
            nc.natx(file_idx) = ncread(fileList(file_idx).name,'NATX');
            nc.sltr(:,file_idx) = ncread(fileList(file_idx).name,'SLTR');
            nc.slnr(:,file_idx) = ncread(fileList(file_idx).name,'SLNR');
            nc.sltt(:,file_idx) = ncread(fileList(file_idx).name,'SLTT');
            nc.slnt(:,file_idx) = ncread(fileList(file_idx).name,'SLNT');
            nc.scdr(:,:,file_idx) = ncread(fileList(file_idx).name,'SCDR');
            nc.scdt(:,:,file_idx) = ncread(fileList(file_idx).name,'SCDT');
            
            % QC variables
            nc.time_qc(file_idx) = ncread(fileList(file_idx).name,'TIME_QC');
            nc.position_qc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'POSITION_QC');
            nc.depth_qc(file_idx) = ncread(fileList(file_idx).name,'DEPH_QC');
            nc.qcflag(:,:,:,file_idx) = ncread(fileList(file_idx).name,'QCflag');
            nc.owtr_qc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'OWTR_QC');
            nc.mdfl_qc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'MDFL_QC');
            nc.vart_qc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'VART_QC');
            nc.cspd_qc(:,:,:,file_idx) = ncread(fileList(file_idx).name,'CSPD_QC');
            nc.avrb_qc(file_idx) = ncread(fileList(file_idx).name,'AVRB_QC');
            nc.rdct_qc(file_idx) = ncread(fileList(file_idx).name,'RDCT_QC');
        end
        
        %%
        
        %% Write concatenated data into the aggregated file
        
        % Time variable
        ncwrite(aggrFilename,'TIME',nc.time);
        
        % Coordinate variables
        if(contains(sensorATT,'codar','IgnoreCase',true))
            ncwrite(aggrFilename,'BEAR',nc.bear);
            ncwrite(aggrFilename,'RNGE',nc.rnge);
        end
        ncwrite(aggrFilename,'LATITUDE',nc.latitude);
        ncwrite(aggrFilename,'LONGITUDE',nc.longitude);
        ncwrite(aggrFilename,'DEPH',nc.deph);
        ncwrite(aggrFilename,'crs',0);
        
        % SDN namespace variables
        ncwrite(aggrFilename,'SDN_CRUISE',nc.sdn_cruise);
        ncwrite(aggrFilename,'SDN_STATION',nc.sdn_station);
        ncwrite(aggrFilename,'SDN_LOCAL_CDI_ID',nc.sdn_local_cdi_id);
        ncwrite(aggrFilename,'SDN_EDMO_CODE',nc.sdn_edmo_code);
        ncwrite(aggrFilename,'SDN_REFERENCES',nc.sdn_references);
        ncwrite(aggrFilename,'SDN_XLINK',nc.sdn_xlink);
        
        % Data variables
        ncwrite(aggrFilename,'RDVA',nc.rdva);
        ncwrite(aggrFilename,'DRVA',nc.drva);
        ncwrite(aggrFilename,'EWCT',nc.ewct);
        ncwrite(aggrFilename,'NSCT',nc.nsct);
        if(strcmp(sensorATT,'WERA'))
            ncwrite(aggrFilename,'HCSS',nc.hcss);
            ncwrite(aggrFilename,'EACC',nc.eacc);
        elseif(strcmp(sensorATT,'CODAR SeaSonde'))
            ncwrite(aggrFilename,'XDST',nc.xdst);
            ncwrite(aggrFilename,'YDST',nc.ydst);
            ncwrite(aggrFilename,'ESPC',nc.espc);
            ncwrite(aggrFilename,'ETMP',nc.etmp);
            ncwrite(aggrFilename,'MAXV',nc.maxv);
            ncwrite(aggrFilename,'MINV',nc.minv);
            ncwrite(aggrFilename,'ERSC',nc.ersc);
            ncwrite(aggrFilename,'ERTC',nc.ertc);
            ncwrite(aggrFilename,'SPRC',nc.sprc);
        end
        ncwrite(aggrFilename,'NARX',nc.narx);
        ncwrite(aggrFilename,'NATX',nc.natx);
        ncwrite(aggrFilename,'SLTR',nc.sltr);
        ncwrite(aggrFilename,'SLNR',nc.slnr);
        ncwrite(aggrFilename,'SLTT',nc.sltt);
        ncwrite(aggrFilename,'SLNT',nc.slnt);
        ncwrite(aggrFilename,'SCDR',nc.scdr);
        ncwrite(aggrFilename,'SCDT',nc.scdt);
        
        % QC variables
        ncwrite(aggrFilename,'TIME_QC',nc.time_qc);
        ncwrite(aggrFilename,'POSITION_QC',nc.position_qc);
        ncwrite(aggrFilename,'DEPH_QC',nc.depth_qc);
        ncwrite(aggrFilename,'QCflag',nc.qcflag);
        ncwrite(aggrFilename,'OWTR_QC',nc.owtr_qc);
        ncwrite(aggrFilename,'MDFL_QC',nc.mdfl_qc);
        ncwrite(aggrFilename,'VART_QC',nc.vart_qc);
        ncwrite(aggrFilename,'CSPD_QC',nc.cspd_qc);
        ncwrite(aggrFilename,'AVRB_QC',nc.avrb_qc);
        ncwrite(aggrFilename,'RDCT_QC',nc.rdct_qc);
        
        %%
        
        %% Modify some attributes
        
        % Data mode
        ncwriteatt(aggrFilename,'/','data_mode',char('D'));
        
        % File creation datetime
        dateCreated = [datestr(now, 'yyyy-mm-dd') 'T' datestr(now, 'HH:MM:SS') 'Z'];
        ncwriteatt(aggrFilename,'/','date_created',char(dateCreated));
        ncwriteatt(aggrFilename,'/','date_modified',char(dateCreated));
        ncwriteatt(aggrFilename,'/','date_update',char(dateCreated));
        ncwriteatt(aggrFilename,'/','date_issued',char(dateCreated));
        ncwriteatt(aggrFilename,'/','metadata_date_stamp',char(dateCreated));
        
        % Set collection time
        time_coll{1} = [datestr(initialDate, 'yyyy-mm-dd') 'T' datestr(initialDate, 'HH:MM:SS') 'Z'];
        time_coll{2} = [datestr(finalDate, 'yyyy-mm-dd') 'T' datestr(finalDate, 'HH:MM:SS') 'Z'];
        ncwriteatt(aggrFilename,'/','history',char(['Data collected from ' time_coll{1} ' to ' time_coll{2} '. ' dateCreated ' aggregated netCDF file created by the European HFR Node']));
        
        % Data coverage period
        timeCoverageStart = ncreadatt(fileList(1).name,'/','time_coverage_start');
        timeCoverageEnd = ncreadatt(fileList(end).name,'/','time_coverage_end');
        ncwriteatt(aggrFilename, '/','time_coverage_start',char(timeCoverageStart));
        ncwriteatt(aggrFilename, '/','time_coverage_end',char(timeCoverageEnd));
        
        % Temporal duration
        t1=datetime(datevec(nc.time(1)));
        t2=datetime(datevec(nc.time(end)));
        durationVec = datevec(between(t1,t2));
        timeCoverageDuration = 'P';
        if(durationVec(1)~=0)
            timeCoverageDuration = [timeCoverageDuration num2str(durationVec(1)) 'Y'];
        end
        if(durationVec(2)~=0)
            timeCoverageDuration = [timeCoverageDuration num2str(durationVec(2)) 'M'];
        end
        if(durationVec(3)~=0)
            timeCoverageDuration = [timeCoverageDuration num2str(durationVec(3)) 'D'];
        end
        timeCoverageDuration = [timeCoverageDuration 'T'];
        if(durationVec(4)~=0)
            timeCoverageDuration = [timeCoverageDuration num2str(durationVec(4)) 'H'];
        end
        if(durationVec(5)~=0)
            timeCoverageDuration = [timeCoverageDuration num2str(durationVec(5)) 'M'];
        end
        if(durationVec(6)~=0)
            timeCoverageDuration = [timeCoverageDuration num2str(durationVec(6)) 'S'];
        end
        ncwriteatt(aggrFilename, '/','time_coverage_duration',char(timeCoverageDuration));
        
        % Define ID
        platform_code = ncreadatt(fileList(1).name,'/','platform_code');
        dataID = [platform_code '_' time_coll{1} '_' time_coll{2}];
        ncwriteatt(aggrFilename,'/','id',char(dataID));
        
        %%
        
        %%
        
        [aFpath,aFfile,aFext] = fileparts(aggrFilename);
        disp(['[' datestr(now) '] - - ' aFfile aFext ' aggregated dataset successfully created and stored.']);
        
        %%
        
        %% Retrieve information about the nc file
        
        ncfileInfo = dir(aggrFilename);
        ncFilesize = ncfileInfo.bytes/1024;
        
        %%
        
    end
    
catch err
    disp(['[' datestr(now) '] - - ERROR in ' mfilename ' -> ' err.message]);
    rnA_err = 1;
end

if(rnA_err==0)
    disp(['[' datestr(now) '] - - ' 'TA_REP_radial_netCDF_aggregation successfully executed.']);
else
    disp(['[' datestr(now) '] - - ' 'TA_REP_radial_netCDF_aggregation exited with an error.']);
end

return

