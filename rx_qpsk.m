%%
rx = comm.SDRuReceiver('Platform','N200/N210/USRP2');
rx.CenterFrequency = 108e3;
rx.MasterClockRate = 100e6;
rx.DecimationFactor = 500;
 plength = 350; len = (plength+13)*40;
rx.SamplesPerFrame = len; % = 223*80
rx.EnableBurstMode = true;
rx.NumFramesInBurst = 20;
rx.Gain = 0;
% % 
%%
 data = zeros(len*2.1,1);
 T = 1000; 

tmp = rx();i=1;

while i<30
    flag1 = sum(abs(double(tmp(1:10))))<T;
    flag2 = sum(abs(double(tmp(len-10:len))))>T;
    
    if flag1&&flag2
        data(1:len) = tmp;
        tmp = rx();
        data(len+1:len*2) = tmp;
        break;
    end

    tmp = rx(); 
    i = i +1 ;
end
%  release(rx);
 
        t = find(abs(data)>T);
        LSB = max(t(1)-round(len*0.005),1);
        MSB = LSB + round(len*1.01);
        data1 = data(LSB:MSB);
%         I = real(double(data1));
%         Q = imag(double(data1));
        
        %
        %         I = lowpass(I,100e3,400e3);
        %         Q = lowpass(Q,100e3,400e3);
        %
%         I = downsample(I,20);
%         Q = downsample(Q,20);
        data_sps4 = downsample(data1,10);
%         data_sps4 = data_sps4(1:223*4);

        
        h = rcosdesign(0.6,10,4);
%         I = upfirdn(I,h);
%         Q = upfirdn(Q,h);
        
        data_matchfilter = upfirdn(data_sps4,h)*3/32767;
%         C = I+Q*1i;
       
%         C = C/max(abs(C));
        
        FD_qpsk;

