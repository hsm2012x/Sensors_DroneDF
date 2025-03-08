clearvars;
clc;

datatype = 0; % -> CW dataset
datatype = 1; % -> drone dataset(ch 11,  2.455GHz, DJI Phantom 4)
if datatype == 1
load('dataset_2.455GHz/DroneDataset_Configs.mat');
antennaConfigs = DroneDataset_Configs;
clear('DroneDataset_Configs');
else 
load('dataset_cwsingnal/CWDataset_Configs.mat');
antennaConfigs = CWDataset_Configs;
clear('CWDataset_Configs');
    
end


RfConfigs = struct('fs', 10e6, 'Tsw', 100e-6, 'SamplesPerSwitch', 10e6 * 100e-6);
SamplesPerSegment = RfConfigs.SamplesPerSwitch * 12; % Number of samples per segment

%%
plotCount = 50; % Sampling index
sampling_index = SamplesPerSegment * plotCount; % Calculate sampling index

uniVector_angles= exp(1i * deg2rad((0:60:300)')); % Complex representation
estimated_angles = zeros(6, plotCount); % Store estimated angles for 6 antennas

    % switching Transient를 피하기 위한 offset
    startOffset = 300;
    endOffset = RfConfigs.SamplesPerSwitch - 300;

for j = 1:6
    % Load antenna data
    config = struct('truthValue', antennaConfigs{j, 2}, ...
                    'filename', antennaConfigs{j, 3}, ...
                    'shift', antennaConfigs{j, 4});
    RawData = load(config.filename); % Load I1 and Q1 data

    % Calculate signal magnitude
    Mag = RawData.I1.^2 + RawData.Q1.^2; 

    % Arrange data
    Magslice = Mag(config.shift:  config.shift-1 + SamplesPerSegment * plotCount );
    Magslice = reshape(Magslice, SamplesPerSegment, []);
    Direction = zeros(6, plotCount);
    
    
    % Calculate direction vector
    for i = 1:plotCount
        for k = 1:6
            base = (k-1) * RfConfigs.SamplesPerSwitch;
            Direction(k, i) = sum(Magslice(base + startOffset : base + endOffset, i));
        end
    end
    % Transform direction vector
    power_Sixantenna = Direction .* repmat(uniVector_angles, 1, plotCount);
    % Calculate total vector and angle
    R = sum(power_Sixantenna);


    % estimated_angle = mod(rad2deg(angle(reB(1:50))), 360); % Convert to 0~360 degrees
    estimated_angle = rad2deg(angle(R(1:plotCount)));
    % Save data
    estimated_angles(j, :) = estimated_angle;
end
% Convert to -90~360 degrees
estimated_angles(5, :) = estimated_angles(5, :) + 360;
estimated_angles(6, :) = estimated_angles(6, :) + 360;


if datatype == 1
    j = 4;
    config = struct('truthValue', antennaConfigs{j, 2}, ...
                    'filename', antennaConfigs{j, 3}, ...
                    'shift', antennaConfigs{j, 4});
    [estimated_angles(j, :)] = resyncDirectionDetection(config, RfConfigs, sampling_index, 40, uniVector_angles, 50, 41500, 0);
    
    
    j = 5;
    config = struct('truthValue', antennaConfigs{j, 2}, ...
                    'filename', antennaConfigs{j, 3}, ...
                    'shift', antennaConfigs{j, 4});
    [estimated_angles(j, :)] = resyncDirectionDetection(config, RfConfigs, sampling_index, 39, uniVector_angles, 50, 26400000 + 6495, 360);


end

clear('i','j','k','base')

%%
figure(1);
hold on;
plotCount = 50;
num_antennas = 6; % Total number of antennas
filtered_x_groups = []; % Store filtered X values
filtered_y_values = []; % Store filtered Y values
mean_values = zeros(1, num_antennas); % Store mean values (per antenna)

for j = 1:num_antennas
    %  Calculate the 10%-90% range for each individual antenna
    low_cutoff = prctile(estimated_angles(j, 1:plotCount), 20); % Lower 10% value
    high_cutoff = prctile(estimated_angles(j, 1:plotCount), 85); % Upper 90% value

    %  Keep only data within the range
    filtered_indices = (estimated_angles(j, 1:plotCount) >= low_cutoff) & (estimated_angles(j, 1:plotCount) <= high_cutoff);
    y_filtered = estimated_angles(j, filtered_indices); % Filtered Y values

    %  Set x-axis values from 1 to 6 to prevent the boxchart from being too spread out
    x_filtered = j * ones(size(y_filtered));

    % Calculate and store the mean value
    mean_values(j) = mean(y_filtered);
    median_values(j) = median(y_filtered);
    % Store filtered data
    filtered_x_groups = [filtered_x_groups, x_filtered]; 
    filtered_y_values = [filtered_y_values, y_filtered];
end

boxchart(filtered_x_groups, filtered_y_values, 'BoxFaceColor', 'blue', 'MarkerStyle', 'none');
scatter(1:num_antennas, mean_values, 30, 'r'); % Display the mean values as red circles

%  Display mean value numbers (with adjusted position to avoid overlap)
y_offset = -10; % Adjust text position
for j = 1:num_antennas
    if j == 5 %% for figure 8
         text(j, mean_values(j) + y_offset - 2, sprintf('%.2f', mean_values(j)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    else
         text(j, mean_values(j) + y_offset, sprintf('%.2f', mean_values(j)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    end
end

%  Display median values as points (Scatter)
scatter(1:num_antennas, median_values, 30, 'b'); % Display the median values as blue markers

%  Display median value numbers (with adjusted position to avoid overlap)
y_offset = +10; % Adjust text position
for j = 1:num_antennas
    if j == 5  %% for figure 8
        text(j, median_values(j) + y_offset + 3, sprintf('%.2f', median_values(j)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'blue');
    else
        text(j, median_values(j) + y_offset, sprintf('%.2f', median_values(j)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'blue');
    end
end
hold off;

%Set the x-axis to 6 values and display the actual angles [0, 60, ..., 300]
xticks(1:num_antennas); % Set x-axis ticks from 1 to 6
xticklabels(string([0, 60, 120, 180, 240, 300])); % Convert x-axis labels to actual angles

% Set the y-axis in 30° increments to improve readability
ylim([-30 330]); % Adjust y-axis range
yticks(-30:30:330); % Set ticks at 30° increments

%  Set grid lines in 30° increments
ax = gca;
ax.YGrid = 'on';
ax.YTick = 0:60:300;

% Graph settings
xlabel('Angle (Degrees)');
ylabel('Estimated Angle (Degrees)');
% title('Estimated Angle with Mean & Median');
grid on;
legend({'Boxplot Data', 'Mean Values', 'Median Values'}, 'Location', 'Best');
%Estimated Angle Errors
figure(2);
hold on;

num_points = length(filtered_y_values)/num_antennas; % 각 안테나당 표시할 데이터 수
x_positions = [0, 60, 120, 180, 240, 300];


colors = lines(num_antennas); 
filtered_y_values6 = reshape(filtered_y_values, num_points, 6)';
for i = 1:num_antennas
    x_center = x_positions(i); %  안테나의 Ground Truth Angle
    x_range = randi([x_center - 5, x_center + 5], 1, num_points);  % Generate random X values within a ±5° range
    
    % Calculate Estimated Angle Errors 
    y_values = abs(x_center - filtered_y_values6(i,:)); 

    % Scatter plot
    scatter(x_range, y_values, 20, colors(i, :), 'x' ); 
end

hold off;


xticks(x_positions); 
xticklabels(string(x_positions)); 


ymax = 60;
ytick = 5;
ylim([-1, ymax ]); 
yticks(0:ytick:ymax )

% Set grid
ax = gca;
ax.YGrid = 'on';
ax.YTick = 0:5:ymax ;
yline(0, '--k', 'LineWidth', 1); % 

% Graph setting
xlabel('Ground Truth Angle (Degrees)');
ylabel('Estimated Angle Errors (Degrees)');
% title('Estimated Angle Errors by 100 cases');
grid on;
legend({'0° AoA', '60° AoA', '120° AoA', '180° AoA', '240° AoA', '300° AoA'}, 'Location', 'Best');

