% This project aims to find preamble signals in the encoded signal
% provided, analyze the following 8FSK encoded frequency keying and output
% the decoded data 

clc; clear; 

%% Known input information
symbols_key = [1,2,3,4,5,6,7,8];
%symbols_bny = [0,0,0;0,0,1;0,1,0;1,0,0;0,1,1;1,0,1;1,1,0;1,1,1];
symbol_freqs = [15800, 15950, 16100, 16250, 16400, 16550, 16700, 16850];
num_symbols_per_phrase = 100;
symbol_length = 0.02;

%% Initial read-in and signal initialization 
[preamble,preamble_Fs] = audioread('preamble.flac');
preamble_Ts = 1/preamble_Fs;
preamble_length = length(preamble);%0.03s in time
preamble_length_time = preamble_length/preamble_Fs;

[signal,signal_Fs] = audioread('signal.flac');
signal_Ts = 1/signal_Fs;
signal_length = length(signal); 
signal_length_time = signal_length/signal_Fs;

symbol_length = symbol_length*signal_Fs;
symbol_phrase_length = symbol_length*num_symbols_per_phrase;

%% Finding preamble with cross-correlation (single-side) and outputting preamble indices
xcorr_zeropad = signal_length - preamble_length;
% xcorr only needed for single-side
new_preamble = [preamble;zeros(xcorr_zeropad,1)];
[cross_corr, preamble_lag] = xcorr(signal,new_preamble);
cross_corr = abs(cross_corr(signal_length:end));
preamble_lag = preamble_lag(signal_length:end);
xcorr_thresh = round(max(cross_corr) - 1);

preamble_start_indices = preamble_lag(cross_corr > xcorr_thresh);
preamble_end_indices = preamble_lag(cross_corr > xcorr_thresh) + preamble_length;
preamble_indices = [preamble_start_indices;preamble_end_indices];

%% Extrapolation and extractions from preamble indexing for symbol analysis
num_phrases = length(preamble_indices);
indexed_matrix = zeros(symbol_phrase_length,num_phrases);
output_phrases = zeros(num_symbols_per_phrase,num_phrases);

%initialize indexing
strt = 1;
nend = symbol_length; % 0.02s or 960 samp

for n = 1:num_phrases
    indexed_matrix(:,n) = signal(preamble_indices(2,n)+1:preamble_indices(2,n)+symbol_phrase_length,1);
    
    for m = 1:num_symbols_per_phrase
    %instantiate freq-domain signal frame
    Indexed_Signal_Amp = abs(fft(indexed_matrix(strt:nend,n)));

    % Reduce response to all < Nyquist for single sided freq response
    Signal_Amp = Indexed_Signal_Amp(1:symbol_length/2+1);
    Signal_Amp(2:end-1) = 2*Signal_Amp(2:end-1);
    freqBins = signal_Fs*(0:(symbol_length/2))/symbol_length;
    signal_symbol_response = [Signal_Amp,(freqBins')];
    % Find 8FSK frequency-symbol match
    [~,I] = max(signal_symbol_response(:,1));
    if signal_symbol_response(I,2) == symbol_freqs(1)
        output_phrases(m,n) = symbols_key(1);
    elseif signal_symbol_response(I,2) == symbol_freqs(2)
        output_phrases(m,n) = symbols_key(2);
    elseif signal_symbol_response(I,2) == symbol_freqs(3)
        output_phrases(m,n) = symbols_key(3);
    elseif signal_symbol_response(I,2) == symbol_freqs(4)
        output_phrases(m,n) = symbols_key(4);
    elseif signal_symbol_response(I,2) == symbol_freqs(5)
        output_phrases(m,n) = symbols_key(5);
    elseif signal_symbol_response(I,2) == symbol_freqs(6)
        output_phrases(m,n) = symbols_key(6);
    elseif signal_symbol_response(I,2) == symbol_freqs(7)
        output_phrases(m,n) = symbols_key(7);
    elseif signal_symbol_response(I,2) == symbol_freqs(8)
        output_phrases(m,n) = symbols_key(8);
    end

    strt = nend+1;
    nend = nend+symbol_length;
    
    end
    % Re-initialize indexing for new phrase
    strt = 1;
    nend = symbol_length;
end


%% Final Outputs
preamble_indices

output_phrases


%% Anwers to questions:
% Decrease Audibility

% I think there are a few different ways to tackle all of these improvements, 
% but a crucial concern with audibility is Fs or sampling rate- As so many components 
% of audio software are dependent on sampling rate, having a higher sampling rate has the potential 
% to increase Nyquist and thus increase the top-end of what modulated frequencies can be output. 
% A choice such as Fs = 96000  would ensure that, from a software standpoint, the signals would be 
% imperceivable to the average adult. 


% Increase throughput

% To increase throughput of data, reduction of symbol duration as a ratio of Fs such that: 
% symbol_duration ≤ Fs/100. This size can be even smaller if Fs is increased as stated prior. 
% Additionally, multiple frequencies can be used in a single symbol duration, provided that these are 
% in harmonic series which do not interact with each other (ensuring isolation for each frequency found 
% from frequency-domain transform. With this, the potential for enhanced encryption is possible. 
% For example, multiple frequencies can be played for a given symbol, however the analysis device would 
% know to look for highest or lowest frequencies per-frame across a group of symbols-frequency pairs. 
% In short, smaller symbol duration increases the number of symbols able to be processed in the same timeframe. 
% However, symbol length reduction can be detrimental to accuracy of the frequency-domain transform, 
% which makes Fs-to-symbol_length ratio so important to consider.


% Increase reliability

% To increase reliability of analysis for symbol output, ensuring a minimum length of time between preambles 
% would be preferable. The rationale being, the smaller the gap between symbol phrase and the next preamble, 
% the shorter the signal length will be. Reliability in terms of the frequency-domain transform used in this 
% algorithm showed 100 percent accuracy for frequency identification at a Fs to symbol_duration ratio of 100:1. 
% The ability to make this even smaller of a frame size while achieving reasonable accuracy would make processing 
% times quicker theoretically.
