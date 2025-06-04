function [sampleArr, final_voltage, final_std, avg_array, std_array] = voltage_read(input_voltage)
% take an MANUAL input voltage and output it
% clear object
clib.libm2k.libm2k.context.contextCloseAll();
clear m2k
% create object
m2k = clib.libm2k.libm2k.context.m2kOpen();
pause(1)

% check m2k connectivity
if clibIsNull(m2k)
    clib.libm2k.libm2k.context.contextCloseAll();
    clear m2k
    error("m2k object is null, please restart MATLAB, check device connection or check search path");
end

% retrieve analog input object and power supply object
analogInputObj = m2k.getAnalogIn();       % corresponds to oscilloscope
powerSupplyObj = m2k.getPowerSupply();

% calibrate ADC and DAC
m2k.calibrateADC();
m2k.calibrateDAC();

% read every 0.5 seconds -> 100 kHz / 500k samples / every 50k samples
sampling_Rate = 100000;
num_Sample = 500000;

%%%

% set input range of channel 1 and 2 to +/- 2.5 V
CHANNEL_1 = clib.libm2k.libm2k.analog.ANALOG_IN_CHANNEL.ANALOG_IN_CHANNEL_1;
CHANNEL_2 = clib.libm2k.libm2k.analog.ANALOG_IN_CHANNEL.ANALOG_IN_CHANNEL_2;
RANGE_2_5V = clib.libm2k.libm2k.analog.M2K_RANGE.PLUS_MINUS_2_5V;
analogInputObj.setRange(CHANNEL_1, 0, 5); %note: was formerly RANGE_2_5V

powerSupplyObj.enableChannel(0,true);
%input_voltage = 1.7;
conv_in_voltage = input_voltage + 2.5;
powerSupplyObj.pushChannel(0,conv_in_voltage); 


% enable analog input channel 0 (1+, 1-)
analogInputObj.setSampleRate(sampling_Rate); 
analogInputObj.enableChannel(0,true)
pause(1) % allow m2k to configure the sample rate

%get sampling rate
%inputRate = analogInputObj.getSampleRate();

% Clearing the buffer  
for k=1:4
    % the getSamplesInterleaved() returns voltage readings from both
    % 1+/1- and 2+/2-
    data = analogInputObj.getSamplesInterleaved_matlab(100 * 2);
end

% read signal
samples = analogInputObj.getSamplesInterleaved_matlab(num_Sample * 2);
sample_Array = double(samples);
sampleArr = sample_Array(1:2:end);
sampleArr = sampleArr - 2.5;
% calculate mean and standard deviation at 0.5 second intervals
    for i = 1:10
        start = (i-1)*(num_Sample/10) + 1;
        fin = i * (num_Sample/10);
        avg_array(i) = mean(sampleArr(start:fin));
        std_array(i) = std(sampleArr(start:fin));
    end
    
    final_voltage = mean(avg_array);
    final_std = std(sampleArr); 

% clear m2k object
clib.libm2k.libm2k.context.contextCloseAll();
clear m2kend

end