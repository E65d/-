clc; clear; close all;

%% 读入音频文件
[fileName, filePath] = uigetfile({'*.wav;*.mp3;*.flac', 'Audio Files'});
[x, fs] = audioread(strcat(filePath, fileName));

%% 窗口数据计算
screenSize = get(0, 'ScreenSize');
screenLength = screenSize(3);
screenWidth = screenSize(4);
figWidth = 200;
figHeight = 300;
figX = (screenLength - figWidth) / 2;
figY = (screenWidth - figHeight) / 2;

%% 基本数据输入
global uit1 fig1 info;
data1 = zeros(4, 1);

fig1 = uifigure('name', '基本数据', ...
    'NumberTitle', 'off', ...
    'Position', [figX, figY, figWidth, figHeight - 40]);
uilabel(fig1, ...
    'Text', ['不建议极点幅值过于接近1', newline, ...
    '极点可能超出单位圆', newline, ...
    '导致信号发散', newline, ...
    '系统增益输入0默认归一化输出'], ...
    'Position', [20, 5, 180, 60]);
uit1 = uitable(fig1, 'Data', data1, ...
    'ColumnEditable', true, ...
    'ColumnName', '基本数据', ...
    'Position', [20 70 160 140], ...
    'RowName', {'目标频率个数', '极点幅值', '系统增益', '最大频率(Hz)'});
btn1 = uibutton(fig1, 'push', ...
    'Text', '完成', ...
    'Position', [50 220 100 30], ...
    'ButtonPushedFcn', @(btn1, event) getTable1Data());
drawnow;
uiwait(fig1);

numElements = info(1);
rp = info(2);
K = info(3);
lim = info(4);

%% 目标频率（Hz）输入
global uit2 fig2 f_vu2;
data2 = zeros(numElements, 1);

fig2 = uifigure('name', '目标频率(Hz)', ...
    'NumberTitle', 'off', ...
    'Position', [figX, figY, figWidth, figHeight-10]);
uit2 = uitable(fig2, 'Data', data2, ...
    'ColumnEditable', true, ...
    'ColumnName', '目标频率(Hz)', ...
    'Position', [20 20 160 200]);
btn2 = uibutton(fig2, 'push', ...
    'Text', '完成', ...
    'Position', [50 240 100 30], ...
    'ButtonPushedFcn', @(btn2, event) getTable2Data());
drawnow;
uiwait(fig2);

w_vu = 2*pi*f_vu2/fs;

%% 构造零点（单位圆上）+ 共轭
z_vu = exp(1j*w_vu);
Z = [z_vu; conj(z_vu)];
Z = Z(:);

%% 构造极点（靠近单位圆）+ 共轭
p_vu = rp * exp(1j*w_vu);
P = [p_vu; conj(p_vu)];
P = P(:);

%% 归一化判断
flag = 0;
if (K == 0)
    K = 1;
    flag = 1;
end

%% 零极点→传递函数
[b, a] = zp2tf(Z, P, K);

%% 滤波
y = filter(b, a, x);

%% 归一化
if (flag == 1)
    y = y / max(abs(y(:)));
end

%% 频谱对比
N = length(x);
f = (0:N/2-1)*fs/N;
X = fft(x);
Y = fft(y);

figure;
subplot(2,1,1); plot(f, abs(X(1:N/2))); xlim([0 lim]);
title('原始信号频谱'); xlabel('f /Hz'); ylabel('|X|');
subplot(2,1,2); plot(f, abs(Y(1:N/2))); xlim([0 lim]);
title('滤波后信号频谱'); xlabel('f /Hz'); ylabel('|Y|');

%% 文件输出
audiowrite(strcat('processed_', fileName), y, fs);

%% 表格数据传回函数实现
function getTable1Data()
    global info uit1 fig1;
    info = uit1.Data;
    assignin('base', 'col_vector', info)
    delete(fig1);
end

function getTable2Data()
    global f_vu2 uit2 fig2;
    f_vu2 = uit2.Data;
    assignin('base', 'col_vector', f_vu2)
    delete(fig2);
end