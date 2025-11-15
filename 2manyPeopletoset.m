% ============================================================
% EEGLAB Batch EEG Preprocessing Script (English version)
% Automatic logging of pre- and post-processing info
% Author: ChatGPT
% Date: 2025-10-12
% ============================================================

clear; clc;
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Start EEGLAB


% ===== List of subject/experiment folders =====
base_input_path  = 'G:/2/';
base_output_path = 'G:/2/';

folders = {'LY','LZ','WL','WRY','WYK'};  % Add more folders here

for f = 1:length(folders)
    % ===== Path settings =====
    input_folder  = fullfile(base_input_path, folders{f},'/','EEG','/');
    output_folder = fullfile(base_output_path, folders{f},'/re/');
    
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    % ===== Log file (UTF-8) =====
    log_file = fullfile(output_folder, sprintf('%s_log.txt', folders{f}));
    fid = fopen(log_file, 'w', 'n', 'UTF-8');
    fprintf(fid, 'EEG Batch Preprocessing Log (RS3 files)\nDate: %s\n============================\n\n', datestr(now));

    % ===== Get all .rs3 files =====
    file_list = dir(fullfile(input_folder, '*.rs3'));

    % ===== Main loop =====
    for i = 1:length(file_list)

        full_path = fullfile(input_folder, file_list(i).name);
        fprintf('\n===== Processing file %d: %s (Full path: %s) =====\n', i, file_list(i).name, full_path);

        fprintf(fid, 'File %d: %s\n', i, file_list(i).name);

        try
            % --- 1. Import RS3 file ---
            EEG = pop_loadcurry(fullfile(input_folder, file_list(i).name));

            [~, name, ~] = fileparts(file_list(i).name);

            % --- Record pre-processing info ---
            pre_srate = EEG.srate;
            pre_nchan = EEG.nbchan;
            pre_pnts  = EEG.pnts;
            fprintf(fid, 'Pre-processing: Sampling rate: %d Hz, Channels: %d, Data points: %d\n', pre_srate, pre_nchan, pre_pnts);

            % --- 2. Resample to 500Hz ---
            if EEG.srate ~= 500
                EEG = pop_resample(EEG, 500);
            end
            fprintf(fid, 'Resampled to 500 Hz\n');

            % --- 3. Bandpass filter 1?80 Hz ---
            EEG = pop_eegfiltnew(EEG, 1, 30);
            fprintf(fid, 'Bandpass filter 1?80 Hz applied\n');

            % --- 4. Notch filter 48?52 Hz ---
            EEG = pop_eegfiltnew(EEG, 48, 52, [], 1);
            fprintf(fid, 'Notch filter 48?52 Hz applied\n');

            % --- 5. Select channels ---
            chan_list = {'FP1','FPZ','FP2','F7','F3','FZ','F4','F8', ...
                         'FC3','FC1','FCZ','FC2','FC4','T7','C3','CZ','C4','T8', ...
                         'CP3','CP1','CPZ','CP2','CP4','P7','P3','PZ','P4','P8', ...
                         'POZ','O1','OZ','O2'};
            EEG = pop_select(EEG, 'channel', chan_list);
            fprintf(fid, 'Channels selected (%d channels)\n', EEG.nbchan);

            % --- 6. Run ICA ---
            EEG = pop_runica(EEG, 'extended', 1);
            fprintf(fid, 'ICA completed (%d components)\n', size(EEG.icaweights,1));

            % --- 7. Label components ---
            EEG = pop_iclabel(EEG, 'default');
            fprintf(fid, 'ICA components labeled\n');

            % --- 8. Remove artifacts ---
            EEG = pop_icflag(EEG, [NaN NaN; ...    % Brain
                                   0.8 1; ...      % Muscle
                                   0.8 1; ...      % Eye
                                   NaN NaN; ...    % Heart
                                   NaN NaN; ...    % Line Noise
                                   NaN NaN; ...    % Channel Noise
                                   NaN NaN]);      % Other
            rejected_idx = find(EEG.reject.gcompreject);
            EEG = pop_subcomp(EEG, rejected_idx, 0);
            if isempty(rejected_idx)
                fprintf(fid, 'No ICA components removed\n');
            else
                fprintf(fid, 'Removed ICA components: %s\n', num2str(rejected_idx));
            end

            % --- 9. Re-reference (average reference) ---
            EEG = pop_reref(EEG, []);
            fprintf(fid, 'Re-referencing completed\n');

            % --- Record post-processing info ---
            post_srate = EEG.srate;
            post_nchan = EEG.nbchan;
            post_pnts  = EEG.pnts;
            fprintf(fid, 'Post-processing: Sampling rate: %d Hz, Channels: %d, Data points: %d\n', post_srate, post_nchan, post_pnts);

            % --- 10. Save result (.set file, safe English filename) ---
            new_name = sprintf('re%s.set', name);
            EEG = pop_saveset(EEG, 'filename', new_name, 'filepath', output_folder);
            fprintf(fid, 'Saved file: %s\n\n', new_name);

            fprintf('? Processing completed: %s\n', new_name);

        catch ME
            fprintf('?? Error processing %s: %s\n', file_list(i).name, ME.message);
            fprintf(fid, '?? Error: %s\n\n', ME.message);
        end
    end

    fprintf(fid, '=== Batch processing completed for %d files ===\n', length(file_list));
    fclose(fid);
end
fprintf('\n? All done! Processed folders: %s\n', strjoin(folders, ', '));
