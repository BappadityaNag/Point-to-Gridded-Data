function sat2grid_onthefly(variable,dim,longname,units)
% Reads satellite data and makes gridded output
% Output : <varname>.txt or/and <varname>.nc
% 
% The No. of Footings in a day is 2759
% 
% Caveats
% Only the first 10km are written for 3D variables

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Parameters

npts      = 2759;

% yyyy = 1;
% ntime     = 184; % For 2006
yyyy = 5;
ntime     = 181; % For 2010
% yyyy = 3;

nbinlon   = 360;
nbinlat   = 40;

nlev      = double(dim);
varname   = char(variable);
longname  = char(longname);
longname  = strrep(longname, '_', ' ');
units     = char(units);
disp(longname);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

varlon=zeros(npts);
varlat=zeros(npts);
varfile=zeros([nlev,npts]);
tmp1=zeros([nlev,npts]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read Vertical Heights

froute = './../../c3mdata/';
% froute = '/tank/users/bnag/c3mdata/';
fname = [froute,'C3Marcticcloud20060701MERRA300.nc'];
ncid = netcdf.open(fname,'NC_NOWRITE');

if (nlev == 1)
    lev   = 1;
    nlev1 = 1;
    nlev2 = 1;
else
    if (nlev == 113) % Cloud Fraction
        varid = netcdf.inqVarID(ncid,'cldheight');
        nlev1 = 55; % 10.08 km
        nlev2 = 109; % 0.06 km
    elseif (nlev == 137) % Cloud Liquid and Ice Water Content
        varid = netcdf.inqVarID(ncid,'irradcenter');
        nlev1 = 79; % 10.08 km
        nlev2 = 133; % 0.06 km
    elseif (nlev == 138)
        varid = netcdf.inqVarID(ncid,'irradlevel');
        nlev1 = 79; % 10.08 km
        % nlev2 = 80;
        nlev2 = 134; % 0.0 km
    end
    tmp3 = netcdf.getVar(ncid,varid);
    lev = zeros(1,nlev2-nlev1+1);
    for ilev = 1:nlev2-nlev1+1
        lev(ilev) = tmp3(nlev2-ilev+1);
    end
    if (nlev == 137 || nlev == 138)
        lev = lev/1000.0;
    end
end
netcdf.close(ncid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Binning Variables

dlon = (360.0-0.0)/nbinlon;
dlat = (80.0-70.0)/nbinlat;

lon    = linspace(0.0,360.0-dlon,nbinlon) + dlon/2;
lat    = linspace(70.0,80.0-dlat,nbinlat) + dlat/2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Reading .....')
disp(['Binning at ',num2str(nbinlon),'x',num2str(nbinlat),' .....'])

days = [31,28,31,30,31,30,31,31,30,31,30,31];
t = 1;
indx0 = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for yyyy=1:4
% for yyyy=1:5
    for mm=7:12
    % for mm=1:6
    % for mm=1:12
        for dd=1:days(mm)
% mm = 1;
% for dd = 1:2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reading ...            
            if ((yyyy==1 && mm<7) || (yyyy==5 && mm>6))
                break; % break statement breaks out of the outer loop
            end

            if dd<10
                day_name = ['0',num2str(dd)];
            else
                day_name = num2str(dd);
            end   
            if mm<10
                month_name = ['0',num2str(mm)];
            else
                month_name = num2str(mm);
            end
            disp([month_name,'/',day_name,'/',num2str(2006+yyyy-1)])
            
%             fname = [froute,'C3Marcticcloud',num2str(2006+yyyy),...
%                      month_name,day_name,'MERRA300.nc'];
            fname = [froute,'C3Marcticcloud',num2str(2006+yyyy-1),...
                     month_name,day_name,'MERRA300.nc'];
            ncid = netcdf.open(fname,'NC_NOWRITE');
            
            varid = netcdf.inqVarID(ncid,'lon');
            tmp1 = netcdf.getVar(ncid,varid);
            indx1 = size(tmp1);
            varlon(indx0:indx1) = tmp1;

            varid = netcdf.inqVarID(ncid,'lat');
            tmp1 = netcdf.getVar(ncid,varid);
            varlat(indx0:indx1) = tmp1;

            varid = netcdf.inqVarID(ncid,varname);
            tmp1 = netcdf.getVar(ncid,varid);
            varfile(:,indx0:indx1) = tmp1;

% % sfctype has 2 components, hence tmp2 has 2 dimensions
%             varid = netcdf.inqVarID(ncid,varname);
%             tmp2 = netcdf.getVar(ncid,varid);
%             varfile(:,indx0:indx1) = squeeze(tmp2(1,:));

            netcdf.close(ncid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Binning : Recast into lat and lon with averages over the area dlat x dlon

            nfts = zeros(nbinlon,nbinlat,1);
            var = zeros(nbinlon,nbinlat,nlev2-nlev1+1);
            for ilon = 1:nbinlon
                for ilat = 1:nbinlat
                    for ipts = 1:npts
                        if (varlon(ipts) > lon(ilon)-dlon/2.0 && ...
                            varlon(ipts) <= lon(ilon)+dlon/2.0 && ...
                            varlat(ipts) > lat(ilat)-dlat/2.0 && ...
                            varlat(ipts) <= lat(ilat)+dlat/2.0)
                            nfts(ilon,ilat,1) = nfts(ilon,ilat,1) + 1;
                            for ilev = 1:nlev2-nlev1+1
%                                 var(ilon,ilat,ilev,t) = var(ilon,ilat,ilev,t) + ...
%                                     varfile(nlev2-nlev1+2-ilev,ipts);
                                var(ilon,ilat,ilev) = var(ilon,ilat,ilev) + ...
                                    varfile(nlev2-ilev+1,ipts);
                            end
                        end
                    end
                end
            end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Averaging the summed bins

            parfor ilon = 1:nbinlon
                for ilat = 1:nbinlat
                    for ilev = 1:nlev2-nlev1+1
                        var(ilon,ilat,ilev) = var(ilon,ilat,ilev)/nfts(ilon,ilat,1);
                    end
                end
            end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Quality Control
% Dividing by 0 produces NaN values for grids with no coverage
% Need to replace with a known missing value (-999)
            var(nfts==0)    = -999.0;
            var(isnan(var)) = -999.0;
            var(var==0)     = -999.0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Writing in a netcdf file

            % fout = ['./../../gridded_c3mdata/',varname,'.nc'];
            % fout = ['/tank/users/bnag/gridded_c3mdata/',varname,'.nc'];
            fout = ['./../../gridded_c3mdata_',num2str(nbinlon),'x',num2str(nbinlat),'/',varname,'_',num2str(2006+yyyy-1),'.nc'];
            % fout = ['/tank/users/bnag/gridded_c3mdata_',num2str(nbinlon),'x',num2str(nbinlat),'/',varname,'.nc'];
            
            if (t == 1)
                system(['rm ',fout]);

                nccreate(fout, 'lon', 'Dimensions',{'lon',nbinlon}, 'Format','classic');
                ncwrite(fout, 'lon', lon);
                ncwriteatt(fout, 'lon', 'long_name', 'Longitude');
                ncwriteatt(fout, 'lon', 'units', 'degrees_east');

                nccreate(fout, 'lat', 'Dimensions',{'lat',nbinlat}, 'Format','classic');
                ncwrite(fout, 'lat', lat);
                ncwriteatt(fout, 'lat', 'long_name', 'Latitude');
                ncwriteatt(fout, 'lat', 'units', 'degrees_north');

                nccreate(fout, 'lev', 'Dimensions',{'lev',nlev2-nlev1+1}, 'Format','classic');
                ncwrite(fout, 'lev', lev);
                ncwriteatt(fout, 'lev', 'long_name', 'Level');
                if (nlev ~= 1)
                    ncwriteatt(fout, 'lev', 'units', 'km');
                end

%                 nccreate(fout, 'time', 'Dimensions',{'time',ntime}, 'Format','classic');
                nccreate(fout, 'time', 'Dimensions',{'time',netcdf.getConstant('NC_UNLIMITED')}, ...
                                                     'Format','classic');
                % ncwrite(fout, 'time', time);
                ncwrite(fout, 'time', t, t);
                ncwriteatt(fout, 'time', 'long_name', 'Time');
                ncwriteatt(fout, 'time', 'units', 'days since 2007-07-01');

%                 nccreate(fout, varname, 'Dimensions',{'lon',nbinlon,'lat',nbinlat,...
%                          'lev',nlev2-nlev1+1,'time',ntime}, 'Format','classic');
                nccreate(fout, varname, 'Dimensions',{'lon',nbinlon,'lat',nbinlat,...
                         'lev',nlev2-nlev1+1,'time',netcdf.getConstant('NC_UNLIMITED')}, ...
                         'Format','classic');
                ncwrite(fout, varname, var);
                ncwriteatt(fout, varname, 'long_name', longname);
                ncwriteatt(fout, varname, 'units', units);

                % nccreate(fout, 'nfts', 'Dimensions',{'lon',nbinlon,'lat',nbinlat,...
                %          'lev',1,'time',ntime}, 'Format','classic');
                % ncwrite(fout, 'nfts', nfts);
                % ncwriteatt(fout, 'nfts', 'long_name', 'No. of Footings');

            else
                ncwrite(fout, 'time', t, t);
                ncwrite(fout, varname, var, [1 1 1 t]);
            end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            t=t+1;
        end
    end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % Writing in a txt file
% fouttxt = ['./../txt/',varname,'.txt'];
% dlmwrite(fouttxt, var, 'delimiter','\t', 'precision', 8);
% dlmwrite('./../txt/nfts.txt', nfts, 'delimiter','\t', 'precision', 16);


% Check output file
% ncdisp(fout)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear Variables
% clearvars varfile nfts var varlat varlon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
