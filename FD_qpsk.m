%%
figure
plot(real(data_matchfilter));
figure
plot(imag(data_matchfilter));

scatterplot(data_matchfilter,4,0,'kx');
title('matchfilter');

%% AGC
agc=comm.AGC(...
    'AveragingLength', 16, ...
    'DesiredOutputPower', 2, ...
    'AdaptationStepSize', 0.005, ...
    'MaxPowerGain', 30);
v_rx_agc = agc(data_matchfilter);

% saturation control
v_rx_agc_real = min(real(v_rx_agc),2);
v_rx_agc_real = max(v_rx_agc_real,-2);
v_rx_agc_imaginary = min(imag(v_rx_agc),2);
v_rx_agc_imaginary = max(v_rx_agc_imaginary,-2);
v_rx_agc_bound = v_rx_agc_real + v_rx_agc_imaginary*1i;
scatterplot(v_rx_agc_bound);
%% Symbol Syncronization
% the SamplesPerSymbol should be larger or equal to 2!
symbolSync = comm.SymbolSynchronizer(...
    'SamplesPerSymbol',4, ...
    'NormalizedLoopBandwidth',0.01*4, ...
    'DampingFactor',1, ...
    'TimingErrorDetector','Early-Late (non-data-aided)');
% symbolSync = comm.SymbolSynchronizer(...
%     'TimingErrorDetector','Mueller-Muller (decision-directed)',...
%     'DampingFactor',1, ...
%     'NormalizedLoopBandwidth',0.1, ...
%     'SamplesPerSymbol',8);

sym_syncronized = symbolSync(v_rx_agc_bound);
scatterplot(sym_syncronized,1,0,'kx');
title('SS');

%% Carrier Syncronization
CarrierSyncronize = comm.CarrierSynchronizer( ...
'DampingFactor',0.707, ...
'NormalizedLoopBandwidth',0.01*3, ...    
'SamplesPerSymbol',1, ...
'Modulation','QPSK');

carrier_syncronized_signals = CarrierSyncronize(sym_syncronized);
scatterplot(carrier_syncronized_signals,1,0,'kx')
title('CS');
%% preable detection
prb = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]'*(1+1i)/sqrt(2);

prbdet = comm.PreambleDetector(prb);
prbdet.Threshold = 1.5;
[idx,detmet] = prbdet(carrier_syncronized_signals);
[~,fl] = max(detmet(1:45));
v_rx_fram_sync = 3*carrier_syncronized_signals(fl-12:fl+plength); 
scatterplot(v_rx_fram_sync);
%% Equalizer
lineq = comm.LinearEqualizer('Algorithm','LMS', ...
    'NumTaps',1, ...
    'ReferenceTap',1, ...
    'StepSize',0.02);
lineq.WeightUpdatePeriod = 1;
[v_rx_equalized,err,weight] = lineq(v_rx_fram_sync,prb);
% stem(abs(weight));
scatterplot(v_rx_equalized,1,0,'kx')

%% demodulate
A = v_rx_equalized(14:end);
dmd = comm.QPSKDemodulator('BitOutput',true);
dmd.SymbolMapping = 'Gray';
d_A = dmd(A);
d_Am = reshape(d_A,7,plength*2/7)';
d_I = bi2de(d_Am,'left-msb');
d_str = char(d_I)';
