
function [] = copy_data (source_dir, destination_dir, varargin)
    %
    % source_dir = the directory containing all the SAC files and the
    %              zp directory.
    %
    % destination_dir = the directory where all files/directories will 
    %                   be copied to.
    %
    % varargin = used only for a verbose option ('-v' turns it on)

    % If a trace has less that 99.99% of what it should for one hour
    % based on the station sample rate, then that trace is thrown away.
    cutoff_ratio = 0.9999;


    
    
    %channel_set = {'HH1','HH2','HHZ'};
    channel_set = {'HE','HN','HZ'};
    data_file_extension = '.SAC';

    % Parse options {{{1
    verbose = false;
    if numel(varargin) > 0
        for i=1:numel(varargin)
            if isstr(varargin{i})
                if strfind(varargin{i}, '-v')
                    verbose = true;
                end
            end
        end
    end

    % Verbose statements {{{1
    if verbose
        fprintf('Source directory: %s\n', source_dir);
        fprintf('Destination directory: %s\n', destination_dir);
        fprintf('');
    end

    % Make sure source exists {{{1
    if isempty(dir(source_dir))
        fprintf(2, 'Source directory does not exist!\n');
    end

    % Make sure destination exists {{{1
    if isempty(dir(destination_dir))
        mkdir (destination_dir)
        if (verbose) fprintf('Making destination directory.\n\n'); end
    end

    % Copy Loop {{{1
    contents = dir(source_dir);
    src_names = {contents.name};
    channel_map = containers.Map('UniformValues',false);

    for i=1:numel(contents)
        src_name = src_names{i};
        src_filepath = strcat(source_dir, '/', src_name);
        copy_ok = true;

        % Check data 
        copy_ok = check_file_type(copy_ok, ...
                                  src_name, ...
                              data_file_extension);
        [copy_ok, c_trace] =  check_data(copy_ok, ...
                                         src_filepath, ...
                                         cutoff_ratio,  ...
                                         verbose);


        % Skip copying if there is any reason to throw away the file.
        if ~copy_ok
            continue;
        end


        % Add to channels triples map.
        % if ENZ are all in it, remove them and copy them
        channel_map = add_to_channel_map(channel_map, ...
                                         c_trace, ...
                                         channel_set, ...
                                         destination_dir, ...
                                         verbose);

    end
    if verbose
        %fprintf('Source item name: %s\n', src_names{i});
        %fprintf('Dest item name: %s\n', src_names{i});
    end
    % }}}1
    % Copy the zp directory {{{1
    zp_src = strcat(source_dir, '/zp');
    zp_dest = strcat(destination_dir, '/zp');
    if isempty(dir(zp_dest))
        mkdir (zp_dest)
    end

    if (verbose) fprintf('Copying zp directory....\n'); end
    copy_command = sprintf('cp %s/*.zp %s', zp_src, zp_dest);
    system(copy_command);
    if (verbose) fprintf('Copied zp directory!\n'); end
    % }}}1
    % Verbose statements {{{1
    if verbose
        lonely_traces_cell = values(channel_map);
        lonely_traces = [lonely_traces_cell{:}];

        fprintf('\n\nToo few channels:\n');
        for i=1:numel(lonely_traces)
            t = lonely_traces(i);
            fprintf('    Station %s Channel %s\n', ...
                t.staCode, t.staChannel);
        end

        clear ('lonely_traces');

        fprintf('All Done!.\n\n');
    end
    % }}}1

    % Clear stuff {{{1
    % Make sure the big things are cleared.
    clear ('contents', 'channel_map');
    % }}}1
end

function [new_copy_ok] = check_file_type ...
(copy_ok, src_name, data_file_extension)
    % {{{1
    if ~copy_ok
        new_copy_ok = copy_ok;
        return
    end
    % Ignore anything that isn't a SAC file.
    if isempty(strfind(src_name, data_file_extension))
        copy_ok = false;
    end
    new_copy_ok = copy_ok;
end
% }}}1

function [new_copy_ok, trace] = check_data ...  
(copy_ok, src_filepath, cutoff_ratio, verbose)
    % {{{1
    if ~copy_ok
        new_copy_ok = copy_ok;
        trace = [];
        return
    end

    % Read the data file to check for the number of data points. 
    trace = coralReadSAC(src_filepath);

    if(verbose)
        fprintf('Examining Station %s Channel %s... ',...
            trace.staCode, trace.staChannel);
    end

    n_data = trace.recNumData;
    rate = 1 / trace.recSampInt; % rate is data points per second.
    t = 3600; % Number of seconds in an hour

    % Calculate the number of data points the trace should have.
    target_n_data = rate * t;
    
    % If there are too few data points, throw away the data.
    if n_data <= target_n_data * cutoff_ratio
        copy_ok = false;
        if(verbose) 
            fprintf('Too few data points, throwing away.\n');
        end
    end

    % Strip data points if there are too many.
    if n_data > target_n_data
        if(verbose)
            fprintf('Trimmed %i data point(s)... ',...
                (n_data - int64(round(target_n_data))));
        end
        %trace.data = trace.data(1:int64(target_n_data));
        trace.data = trace.data(1:(round(target_n_data)));
    end
    trace.recNumData = trace.recNumData - 1;

    if(verbose && copy_ok)
        fprintf('OK.\n');
    end

    new_copy_ok = copy_ok;
end
% }}}1

function [new_channel_map] = add_to_channel_map ...
(channel_map, trace, channel_set, destination_dir, verbose)
    % {{{1
    name = trace.staCode;

    % Add the trace to the map.
    if isKey(channel_map, name)
        existing_traces = channel_map(name);
        channel_map(name) = [existing_traces, trace];
    else
        channel_map(name) = trace;
    end

    traces = channel_map(name);
    channels = {traces.staChannel};

    % Check to see if there is a complete set of traces in channel_map.
    complete = true;
    for i=1:numel(channel_set)
        required = channel_set{i};
        found = false;
        for j=1:numel(channels)
            if ~isempty(strfind(channels{j}, required))
                found = true;
                break
            end
        end
        if ~found
            complete = false;
            break;
        end
    end

    % Store the traces and remove them from the map.
    if complete
        write_traces(traces, destination_dir, verbose);
        remove (channel_map, name);
    end

    new_channel_map = channel_map;
end
% }}}1

function [] = write_traces(traces, destination_dir, verbose)
    % {{{1
    % Template:
    % yyyy.ddd.hh.00.0000.cs.{station}..{channel}.D.SAC
    filenames = arrayfun(@(x) make_dest_filename(x.recStartTime,...
        x.staCode, x.staChannel), traces, 'UniformOutput', false);

    filepaths = cellfun(@(name) strcat(destination_dir, '/', name), ...
        filenames, 'UniformOutput', false);

    coralWriteSAC_inc(filepaths, traces);

    if (verbose)
        fprintf('All channels for Station %s have been copied.\n', ...
            traces(1).staCode);
    end
end
% }}}1

function [filename] = make_dest_filename(date_vec, station, channel)
    % {{{1
    % Template:
    % yyyy.ddd.hh.00.0000.CS.{station}..{channel}.D.SAC

    % Get the time variables
    yr    = date_vec(1);
    month = date_vec(2);
    day   = date_vec(3);
    if date_vec(5) == 59
    	hr    = date_vec(4)+1;
    else
    	hr=date_vec(4);
    end
    min   = date_vec(5);
    sec   = date_vec(6);

    ms = int16(1000 * mod (sec, 1));
    sec = sec - mod(sec,1);

    % Algorithm for day of year based on code provided by Oleg Komarov 
    % on June 26, 2010 at:
    % www.mathworks.com/matlabcentral/fileexchange/27989-day-of-year
    previous_year = yr - 1;
    year_start_num = datenum(previous_year, 12, 31);

    day_num = datenum(yr,month,day);
    day_of_year = day_num - year_start_num;

    time = sprintf('%04i.%03i.%02i.00.0000', yr, day_of_year, hr);
    
    filename = sprintf('%s.7D.%s..%s.D.SAC', time, station, channel);

end
% }}}1
