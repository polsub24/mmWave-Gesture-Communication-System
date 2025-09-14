% create_tx_signal.m
% Generates baseband OOK/Manchester tx_samples for several packets
clear; close all;

%% PARAMETERS
sps = 8;                    % samples per (manchester) bit
symbol_rate = 1000;         % manchester symbols per second (before sampling)
fs = sps * symbol_rate;     % sample rate
packet_interval = 0.5;      % seconds between packets
sim_time = 5;               % total seconds to generate
num_packets = floor(sim_time / packet_interval);
KEY = uint8([0x3A,0x5C,0x77,0xC1]);  % 4-byte key (must match Rx)

%% helper funcs
crc8 = @(data) compute_crc8_mexstyle(data); % local function below
encrypt_buf = @(buf) alu_encrypt_bytes(buf, KEY);

%% build full tx sample stream
tx_samples = [];
tx_bits = [];    % the manchester bits (0/1) before sample replication
frames = struct('payload_raw',{},'payload_enc',{},'frame_bytes',{});

for p = 1:num_packets
    %% Simulate sensors (simple deterministic / random)
    tstamp = uint32((p-1)); % simple counter instead of real time
    ax = int16(round(1000 * sin(2*pi*0.5*p)));  % example value
    ay = int16(round(800  * cos(2*pi*0.3*p)));
    az = int16(round(600  * sin(2*pi*0.1*p)));
    ir = uint8(randi([0 1]));
    
    % pack payload: big-endian as in earlier sketches
    payload = zeros(1,11,'uint8');
    payload(1) = uint8(bitshift(tstamp,-24));
    payload(2) = uint8(bitshift(tstamp,-16));
    payload(3) = uint8(bitshift(tstamp,-8));
    payload(4) = uint8(tstamp);
    payload(5) = uint8(bitshift(ax, -8));
    payload(6) = uint8(ax);
    payload(7) = uint8(bitshift(ay, -8));
    payload(8) = uint8(ay);
    payload(9) = uint8(bitshift(az, -8));
    payload(10)= uint8(az);
    payload(11)= ir;
    
    % encrypt payload
    payload_enc = encrypt_buf(payload);
    
    % frame bytes
    preamble = uint8([170 170 170]); % 0xAA
    syncb = uint8(45); % 0x2D
    lenb = uint8(numel(payload_enc));
    crc = crc8(payload_enc);
    frame = [preamble, syncb, lenb, payload_enc, crc];
    
    frames(p).payload_raw = payload;
    frames(p).payload_enc = payload_enc;
    frames(p).frame_bytes = frame;
    
    % --- Convert bytes -> bits (MSB-first) ---
    bits = reshape((dec2bin(frame(:),8) - '0').', 1, []);
    
    % --- Manchester encoding: 1->[1 0], 0->[0 1] ---
    man = zeros(1, numel(bits)*2);
    for k = 1:numel(bits)
        if bits(k) == 1
            man(2*k-1:2*k) = [1 0];
        else
            man(2*k-1:2*k) = [0 1];
        end
    end
    
    % --- Expand by sps (sample rate upsampling) ---
    samples = repelem(man, sps);
    
    % --- Insert idle gap before packet (silence) ---
    gap = zeros(1, round(0.02*fs));  % 20 ms silence
    tx_samples = [tx_samples, gap, samples];
    tx_bits = [tx_bits, man];
end

% convert to column and set time base for From Workspace ease
tx_samples = tx_samples(:); % column vector
tvec = (0:length(tx_samples)-1)'/fs;
tx_ts = timeseries(tx_samples, tvec);  % optional timeseries

% save workspace variables for Simulink
save('tx_workspace.mat', 'tx_samples', 'fs', 'sps', 'symbol_rate', 'frames', 'tx_bits', 'tx_ts');

disp('tx_samples and frames saved to workspace variable names: tx_samples, frames, tx_bits, fs, sps');
disp(['Generated ' num2str(num_packets) ' packets.']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% local helper functions
function CRC = compute_crc8_mexstyle(data)
    % Simple CRC-8 (poly 0x07) — input: uint8 vector
    crc = uint8(0);
    for ii = 1:numel(data)
        crc = bitxor(crc, data(ii));
        for b=1:8
            if bitand(crc, 128)
                crc = bitxor( bitshift(crc,1,'uint8'), uint8(7) ); % poly 0x07
            else
                crc = bitshift(crc,1,'uint8');
            end
        end
    end
    CRC = crc;
end

function out = alu_encrypt_bytes(buf, KEY)
    % lightweight ALU-style: for each byte b_i:
    % b1 = xor(b,k); b2 = (b1 + k) mod256; b3 = xor(b2, index)
    L = numel(buf);
    out = zeros(1,L,'uint8');
    for i=1:L
        k = KEY(mod(i-1,4)+1);
        b = buf(i);
        b1 = bitxor(b, k);
        b2 = uint8(mod(double(b1) + double(k), 256));
        b3 = bitxor(b2, uint8(i-1));
        out(i) = b3;
    end
end