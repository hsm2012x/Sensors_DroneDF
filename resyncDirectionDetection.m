function [refined_angles] = resyncDirectionDetection(config, RfConfigs, sampling_index, index_sync, antenna_complex, totalIndices, offset, modValue)
% resyncDirectionDetection performs additional synchronization and 
% direction detection for an antenna channel that requires extra processing.
%
% Inputs:
%   config          - Structure containing 'truthValue', 'filename', and 'shift'
%   RfConfigs       - Structure with RF configuration parameters (e.g., SamplesPerSwitch)
%   sampling_index  - Total number of samples to use in each segment
%   index_sync      - Index separating the initial and additional synchronization segments
%   antenna_complex - Complex representation of the antenna angles
%   totalIndices    - Total number of indices (e.g., 50) to process
%
% Outputs:
%   refined_angles  - The refined estimated angles (in degrees) after re-synchronization
%   angle_error     - The error computed relative to a reference angle (here assumed as 240°)
%
% Example:
%   [refined_angles, angle_error] = resyncDirectionDetection(config, RfConfigs, sampling_index, 39, antenna_complex, 50);

    % Load the raw antenna data (expecting variables I1 and Q1)
    data = load(config.filename);
    
    % Calculate the signal magnitude
    Mag = data.I1.^2 + data.Q1.^2;
    
    % Define SamplesPerSegment (assumed to be 12 times the SamplesPerSwitch)
    SamplesPerSegment = RfConfigs.SamplesPerSwitch * 12;
    
    % Pre-allocate the direction matrix for all indices
    Direction = zeros(6, totalIndices);
    
    % Process the first segment (up to index_sync)
    Magslice = Mag(config.shift : config.shift + sampling_index - 1);
    Magslice = reshape(Magslice, SamplesPerSegment, []);
    for i = 1:index_sync
        for k = 1:6
            base = (k-1) * RfConfigs.SamplesPerSwitch;
            start_idx = base + 300;
            end_idx   = base + (RfConfigs.SamplesPerSwitch - 300);
            Direction(k, i) = sum(Magslice(start_idx:end_idx, i));
        end
    end
    
    % Process the second segment (for the remaining indices)
    % The following offset values come from your original code.
    % offset = 26400000 + 6495;
    Magslice2 = Mag(offset : offset + sampling_index - 1);
    Magslice2 = reshape(Magslice2, SamplesPerSegment, []);
    for i = 1:(totalIndices - index_sync)
        for k = 1:6
            base = (k-1) * RfConfigs.SamplesPerSwitch;
            start_idx = base + 300;
            end_idx   = base + (RfConfigs.SamplesPerSwitch - 300);
            Direction(k, index_sync + i) = sum(Magslice2(start_idx:end_idx, i));
        end
    end
    
    % Transform the direction vectors using the antenna complex representation
    reA = Direction .* repmat(antenna_complex, 1, totalIndices);
    reB = sum(reA);
    
    % Calculate the estimated angles in degrees and adjust by adding 360 (as in your code)
    
    refined_angles = rad2deg(angle(reB(1:totalIndices))) + modValue;
    
    % Compute the angle error relative to a reference (e.g., 240°)
    % angle_error = refined_angles - 240;
end
