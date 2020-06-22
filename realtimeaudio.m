clear, clc, close all

%% Real-Time Audio Stream Processing
%
% The Audio System Toolbox provides real-time, low-latency processing of
% audio signals using the System objects audioDeviceReader and
% audioDeviceWriter.
%
% This example shows how to acquire an audio signal using your microphone,
% perform basic signal processing, and play back your processed
% signal.
%

% read a sound file (carrier signal)
[x, fsx] = audioread('sounds/piano-classic-chords_67bpm_D#.wav');
x = x(:, 1);

fsy = 44100;
if fsx < fsy
        x = resample(x, fsy, fsx);
end

if length(x) > 66150
    x = x(1:66150);
end


%% Create input and output objects
deviceReader = audioDeviceReader('SamplesPerFrame', length(x));
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);

%% Specify an audio processing algorithm
% For simplicity, only add gain.
process = @(x) x.*5;

%% Code for stream processing
% Place the following steps in a while loop for continuous stream
% processing:
%   1. Call your audio device reader with no arguments to
%   acquire one input frame. 
%   2. Perform your signal processing operation on the input frame.
%   3. Call your audio device writer with the processed
%   frame as an argument.

disp('Begin Signal Input...')
tic
while toc<30
    % read a sound file (modulating signal)
    y = deviceReader();
    y = y(:, 1);

    % make x and y with equal sampling rate
    fs = max(fsx, fsy);
%     if fsx > fsy
%         y = resample(y, fsx, fsy);
%     else
%         x = resample(x, fsy, fsx);
%     end

    % make x and y with equal length
    xlen = length(x);
    ylen = length(y);
    if xlen > ylen
        x = x(1:ylen);
    else
        y = y(1:xlen);
    end

    % define the analysis and synthesis parameters
    wlen = 1024;
    hop = wlen/4;
    nfft = wlen;

    % perform time-frequency analysis
    % [X_stft, f ,t] = spectrogram(x, wlen, 10, nfft, fs);
    % [Y_stft, ~ ,~] = spectrogram(y, wlen, 10, nfft, fs);

    [X_stft, f, t ] = stft(x, wlen, hop, nfft, fs);
    [Y_stft, ~, ~ ] = stft(y, wlen, hop, nfft, fs);
    
    % extract spectral envelope of the carrier signal
    X_stft_amp = abs(X_stft);
    for k = 1:size(X_stft_amp, 2)
        X_env(:, k) = specenv(X_stft_amp(:, k), f);
    end

    % extract spectral envelope of the modulating signal
    Y_stft_amp = abs(Y_stft);
    for k = 1:size(Y_stft_amp, 2)
        Y_env(:, k) = specenv(Y_stft_amp(:, k), f);
    end
    
    p = 0.5;
    q = 5/10;
    % cross-synthesis
%     Z_stft = ((X_stft./X_env).^p.*(Y_env).^(1-p)).^q;
    Z_stft = ((X_stft./X_env).*(Y_env)).^q;
    z = istft(Z_stft, wlen, hop, nfft, fs);
    clear X_stft Z_stft X_env Y_env
    clear X_stft_amp Y_stft_amp Y_stft
    clear y
    
    z = z.';
    deviceWriter(z);
end
disp('End Signal Input')

release(deviceReader)
release(deviceWriter)