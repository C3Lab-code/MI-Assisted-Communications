rx = comm.SDRuReceiver('Platform','N200/N210/USRP2');
rx.CenterFrequency = 108e3;
rx.MasterClockRate = 100e6;
rx.DecimationFactor = 500;
 plength = 1000; len = (plength+26+1)*40;
rx.SamplesPerFrame = len; % = 223*80
rx.EnableBurstMode = true;
rx.NumFramesInBurst = 20;
rx.Gain = 0;
payload = zeros(plength+1,10); FFF = 1;
%%
while FFF
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
%         data_sps4 = downsample(data1,2);
%         data_sps4 = data_sps4(1:223*4);

        
        h = rcosdesign(0.6,10,40);
%         I = upfirdn(I,h);
%         Q = upfirdn(Q,h);
        
        data_matchfilter = upfirdn(data1,h)*3/32767;
%         C = I+Q*1i;
       
%         C = C/max(abs(C));
        
        FD_img;
end
%% symbol sync test
% downsample_data=zeros(99,40);
% gradient_data=zeros(98,1);
% optimal_point_index=zeros(98,1);
% timeing_err=zeros(20,1);
% for i=1:40
%     downsample_data(:, i)=data_matchfilter(i:40:40*99+i-1);
%     gradient_data(:,1)=diff(downsample_data(:,i));
%     optimal_point_index(:,1)=data_matchfilter(i+20:40:40*98+i);
%    timeing_err(i,1)=sum(abs(optimal_point_index(:,1).*gradient_data(:,1)));
% end
% [M,I]=min(timeing_err);
data = payload(2:1001,:);
data = data(:);
msg = qamdemod(data,16);
img = reshape(msg,[100 100]);
imshow(uint8(img*16));
