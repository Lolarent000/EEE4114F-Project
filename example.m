clear, clc, close all

% read a sound file (carrier signal)
[x, fsx] = audioread('sounds/string-melody-17_125bpm_C_major.wav');
x = x(:, 1);

% read a sound file (modulating signal)
[y, fsy] = audioread('sounds/longspeech.wav');
y = y(:, 1);

% make x and y with equal sampling rate
fs = max(fsx, fsy);
if fsx > fsy
    y = resample(y, fsx, fsy);
else
    x = resample(x, fsy, fsx);
end

% make x and y with equal length
xlen = length(x);
ylen = length(y);
if xlen < ylen % if x is shorter than y repeat x to the length of y
    x = repmat(x,1, ceil((ylen/xlen)));
    xlen = length(x);
    x = x(1:ylen);
else % else truncate x to match y
    x = x(1:ylen);
end

subplot(6,1,1);
plot(x);
title("carrier")

subplot(6,1,2);
plot(y);
title("modulator ")

% define the analysis and synthesis parameters
wlen = 1024;
hop = wlen/4;
nfft = wlen;

% perform time-frequency analysis
% [X_stft, f ,t] = spectrogram(x, wlen, 10, nfft, fs);
% [Y_stft, ~ ,~] = spectrogram(y, wlen, 10, nfft, fs);

[X_stft, f, t ] = stft(x, wlen, hop, nfft, fs);
[Y_stft, ~, ~ ] = stft(y, wlen, hop, nfft, fs);

subplot(6,1,3);
surf(t, f, 20*log10(abs(X_stft)), 'EdgeColor', 'none');
title("carrier signal")
ylabel("frequency (Hz)")
axis xy; 
axis tight; 
colormap(jet); view(0,90);
colorbar;

subplot(6,1,4);
surf(t, f, 20*log10(abs(Y_stft)), 'EdgeColor', 'none');
title("modulating signal")
ylabel("frequency (Hz)")
axis xy; 
axis tight; 
colormap(jet); view(0,90);
colorbar;

% subplot(4,1,3);
% surf(t_1, f_1, 20*log10(abs(X_stft_1)), 'EdgeColor', 'none');
% axis xy; 
% axis tight; 
% colormap(jet); view(0,90);
% colorbar;
% 
% subplot(4,1,4);
% surf(t_1, f_1, 20*log10(abs(Y_stft_1)), 'EdgeColor', 'none');
% axis xy; 
% axis tight; 
% colormap(jet); view(0,90);
% xlabel('Time (secs)');
% colorbar;

% memory optimization
clear x y

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
% 
% % memory optimization
clear X_stft_amp Y_stft_amp Y_stft
% 
p = 0.5;
q = 10/10;
% cross-synthesis
% X_flat = (X_stft./X_env);
X_flat = X_stft;

Z_stft = (X_flat.*(Y_env));

% X_flat = X_flat.^p;
% Y_env = Y_env.^(1-p);
% Z_stft = (X_flat.*(Y_env)).^(q);

z = istft(Z_stft, wlen, hop, nfft, fs);

subplot(6,1,5);
surf(t, f, 20*log10(abs(Z_stft)), 'EdgeColor', 'none');
title("Output spectrogram")
ylabel("frequency (Hz)")
axis xy; 
axis tight; 
colormap(jet); view(0,90);
colorbar;

subplot(6,1,6);
plot(z);
title("output signal")


% % plot(f, X_stft);
% 
% % memory optimization
% clear X_stft Z_stft X_env Y_env
% 
% % hear the result signal
soundsc(z, fs)