% init_receiver.m
clear; close all; clc;

% Parameters
fs = 8000;              % Sample rate (Hz)
sps = 8;                % Samples per symbol
symbol_rate = fs/sps;   % Symbol rate

% Encryption key
KEY = uint8([0x3A, 0x5C, 0x77, 0xC1]);

% Load test signal and convert to proper format
load('tx_workspace.mat'); % Your transmitted signal

% Convert to proper From Workspace format: [time, data]
t = (0:length(tx_samples)-1)' / fs;  % Time vector
tx_signal_matrix = [t, double(tx_samples(:))];  % Required format

% Simulation parameters
sim_time = 10; % seconds

% Save to workspace
assignin('base', 'tx_signal_matrix', tx_signal_matrix);
assignin('base', 'KEY', KEY);
assignin('base', 'fs', fs);

disp('Simulink Model Configuration Ready');