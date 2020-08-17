
% figure
% plot(real(data_matchfilter));
% figure
% plot(imag(data_matchfilter));
% 
 scatterplot(data_matchfilter,40,20,'kx');
% title('matchfilter');

% %% AGC
% v_rx_agc_bound = sqrt(7.5/var(data_matchfilter))*data_matchfilter;
% agc=comm.AGC(...
%     'AveragingLength', 26*40, ...
%     'DesiredOutputPower', 9, ...
%     'AdaptationStepSize', 0.0002/1, ...
%     'MaxPowerGain', 30);%20
% v_rx_agc = agc(data_matchfilter);
% 
% % saturation control
% v_rx_agc_real = min(real(v_rx_agc),6);
% v_rx_agc_real = max(v_rx_agc_real,-6);
% v_rx_agc_imaginary = min(imag(v_rx_agc),6);
% v_rx_agc_imaginary = max(v_rx_agc_imaginary,-6);
% v_rx_agc_bound = v_rx_agc_real + v_rx_agc_imaginary*1i;
% scatterplot(v_rx_agc_bound,40,20,'kx');
%% Symbol Syncronization
% % the SamplesPerSymbol should be larger or equal to 2!
% % symbolSync = comm.SymbolSynchronizer(...
% %     'SamplesPerSymbol',40, ...
% %     'NormalizedLoopBandwidth',0.02, ...
% %     'DampingFactor',0.1, ...
% %     'TimingErrorDetector','Early-Late (non-data-aided)');
% % symbolSync = comm.SymbolSynchronizer(...
% %     'TimingErrorDetector','Mueller-Muller (decision-directed)',...
% %     'DampingFactor',0.1, ..% scatterplot(v_rx_equalized,1,0,'kx')
% % title('EQ');
% % % payloadpayload
% %     'NormalizedLoopBandwidth',0.1, ...
% %     'SamplesPerSymbol',40);
downsample_data=zeros(99,40);
gradient_data=zeros(98,1);
optimal_point_index=zeros(98,1);
timeing_err=zeros(20,1);
for i=1:40
    downsample_data(:, i)=data_matchfilter(i:40:40*99+i-1);
    gradient_data(:,1)=diff(downsample_data(:,i));
    optimal_point_index(:,1)=data_matchfilter(i+20:40:40*98+i);
   timeing_err(i,1)=sum(abs(optimal_point_index(:,1).*gradient_data(:,1)));
end
[M,I]=min(timeing_err);

sym_syncronized = data_matchfilter(I:40:end);
sym_syncronized = sqrt(7.5/var(sym_syncronized))*sym_syncronized;
 scatterplot(sym_syncronized,1,0,'kx');
% % title('SS');
%% AGC
% v_rx_agc_bound = sqrt(7.5/var(sym_syncronized))*sym_syncronized;
% agc=comm.AGC(...
%     'AveragingLength', 26, ...
%     'DesiredOutputPower', 9, ...
%     'AdaptationStepSize', 0.001/1, ...
%     'MaxPowerGain', 30);%20
% v_rx_agc = agc(sym_syncronized*5);
% 
% % saturation control
% v_rx_agc_real = min(real(v_rx_agc),6);
% v_rx_agc_real = max(v_rx_agc_real,-6);
% v_rx_agc_imaginary = min(imag(v_rx_agc),6);
% v_rx_agc_imaginary = max(v_rx_agc_imaginary,-6);
% v_rx_agc_bound = v_rx_agc_real + v_rx_agc_imaginary*1i;
% scatterplot(v_rx_agc_bound);
%% Coarse frequency compensate
% coarseSync = comm.CoarseFrequencyCompensator('Modulation','QAM',...
%     'FrequencyResolution',0.001,'SampleRate',5e3);
% c_sync = coarseSync(data_matchfilter);
% scatterplot(data_matchfilter,4,0,'kx');

%% Coarse frequency compensate
% coarseSync = comm.CoarseFrequencyCompensator('Modulation','QAM',...
%     'FrequencyResolution',0.001,'SampleRate',5e3);
% c_sync = coarseSync(tt);
% scatterplot(c_sync,1,0,'kx')
%% Carrier Syncronization
CarrierSyncronize = comm.CarrierSynchronizer( ...
'DampingFactor',0.707*0.6, ...
'NormalizedLoopBandwidth',0.01/4, ...    
'SamplesPerSymbol',1, ...
'Modulation','QAM');
% 
carrier_syncronized_signals = CarrierSyncronize(sym_syncronized);
 scatterplot(carrier_syncronized_signals,1,0,'kx')
% title('CS');
%% preable detection
prb = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]'*(3+3i);
prb = [prb; conj(prb)];
prbdet = comm.PreambleDetector(prb);
prbdet.Threshold = 20;
[idx,detmet] = prbdet(carrier_syncronized_signals);
[~,fl] = max(detmet(1:45));
%v_rx_fram_sync = carrier_syncronized_signals(fl-25:fl+plength+1); 
v_rx_fram_sync = sym_syncronized(fl-25:fl+plength+1);
%v_rx_fram_sync = v_rx_agc_bound(fl-25:fl+plength+1); 

%% Equalizer
lineq = comm.LinearEqualizer('Algorithm','LMS', ...
    'NumTaps',4, ...
    'ReferenceTap',1, ...
    'Constellation',qammod(0:15,16),...
    'StepSize',0.01*1.2);
  %  ;
lineq.WeightUpdatePeriod = 1;
[v_rx_equalized,err,weight] = lineq(v_rx_fram_sync,prb);
% stem(abs(weight));
  scatterplot(v_rx_equalized,1,0,'kx')
 title('EQ');
% % 
%% demodulate
A = v_rx_equalized(28:end);
n = qamdemod(v_rx_equalized(27),16)+1;
if n<11
    if ~ismember(n,payload(1,:))
        payload(:,n) = [n;A];
    end
end

if payload(1,:)== [1:10]
    FFF = 0;
end



% d_A = qamdemod(A,16);
% d_Ab = de2bi(d_A,4,'left-msb');
% d_Am = reshape(d_Ab',7,200)';
% d_I = bi2de(d_Am,'left-msb');
% d_str = char(d_I)';
