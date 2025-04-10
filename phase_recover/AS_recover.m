%% para settings
% by HITsz, School of Computer Science and Technology 光学成像组 请勿用于商业用途
clear all;clc;
wvl = 520e-9;   %波长
delta4 = 3.45e-6;  %CCD的pixelsize
delta_SLM = 12.5e-6;  %SLM的pixelsize

num=169; %选取调制图像数量
% 
load('newpattern32.mat');
ipattern=newpatterns(:,1:768,1);
ratio=delta_SLM/delta4;
pattern = imresize(ipattern,ratio);
%%
arraysize = 13;             
xx=spiral(arraysize);
xlocation = zeros(1,arraysize^2);
ylocation = zeros(1,arraysize^2);

% pattern平移模式
for tt=1:arraysize^2
    [xlocationTemp,ylocationTemp] = find(xx==tt);
    xlocation(1,tt) = 2*ratio*(xlocationTemp-round(arraysize/2));
    ylocation(1,tt) = 2*ratio*(ylocationTemp-round(arraysize/2));
end
DB=single(zeros(2048,2448,num));
% 
xlocation=[0 xlocation];xlocation(end)=[]; %若第一张和第二张pattern相同，则添加这两句
ylocation=[0 ylocation];ylocation(end)=[];

%读取采集图像
for tt=1:num
    DB(:,:,tt)=DB(:,:,tt)+im2single(imread(['../data/USAF/test',num2str(tt-1),'.png']));
end
DB=padarray(DB,[100,100]);

centerx=-10.0; %标定图像中心偏置距离
centery=25.0; %标定图像中心偏置距离
temp1=single(zeros(2248,2648,num));
for tt=1:num
    temp1(:,:,tt)=gather(abs(subpixelshift3GPU(DB(:,:,tt),centerx,centery))); %平移
end
a=-2.30;  %标定图像中心旋转角度
N=2000;
for tt=1:num
    temp2(:,:,tt)=imrotate(temp1(:,:,tt),a);
    temp2(:,:,tt)=rot90(temp2(:,:,tt),2); %旋转翻转 采集图像的pattern和实际pattern是翻转的
%                     s1=size(temp2,1);s2=size(temp2,2);
%                     imSeqCapture(:,:,tt)=imcrop(abs(temp2(:,:,tt)),[floor((s2-N+1)/2) floor((s1-N+1)/2) N-1 N-1]);
end
%clear temp1;
imSeqCapture=known_processSLM_forward(temp2,N);  %图像裁剪 2783*2783->2000*2000
%%  initialize object and pattern
clear temp2;
for d2=  0.0552%0.0545
    disp(['d2:',num2str(d2)]);
    PatternRecovery = gpuArray(known_processSLM_forward(pattern,N)); %初始化恢复Pattern 2783*2783->2000*2000
    
    sum_o = zeros(N,N);   % Sum all raw images to get the intial guess of object
    usenum=169;  %采集图像数目

    for tt=1:usenum
        sum_o = sum_o + myprop_AS(gpuArray(sqrt(imSeqCapture(:,:,tt)) ),wvl,delta4,-d2).*conj(subpixelshift3GPU(PatternRecovery,xlocation(tt),ylocation(tt))); %衍射反传播回SLM平面  
    end
    lowres_iniGuess =  sum_o./usenum; %初始化恢复图像幅值
    %% recovery process
    ObjectRecoveryProp = gpuArray(lowres_iniGuess);
    imRandNum = randperm(usenum);      % Random sequence recovery
    gamaO=1;    % rPIE parameters, now using ePIE
    gamaP=1;
    alphaO=1;
    alphaP=1;
    LoopN1=40;  % Loops
    cost  = zeros(LoopN1,1);

    for loopnum=1:LoopN1
        disp(['Recovering, loop:',num2str(loopnum)]);
        for tt=1:usenum%arraysize^2         
            
            patternshift = subpixelshift3GPU(PatternRecovery,xlocation(imRandNum(tt)),ylocation(imRandNum(tt)));    % Shift the diffuser        
            Pattern_plane = ObjectRecoveryProp.*patternshift;   % Multiply object wavefront with diffuser 相位调制

            CCD_plane = myprop_AS(Pattern_plane,wvl,delta4,d2);  % Propogate wavefront to the CCD 正向传播到CCD平面
            t1=sqrt(imSeqCapture(:,:,imRandNum(tt)));
            t2=gather(abs(CCD_plane));
            coff=mean(t2(:))/mean(t1(:)); %计算采集图像与正向传播图像复振幅幅值的相关性
            CCD_plane_new = gpuArray(sqrt(imSeqCapture(:,:,imRandNum(tt))).*exp(1j*angle(CCD_plane)));%.*CCD_plane./abs(CCD_plane) 替换幅值
            cost(loopnum) = cost(loopnum) + gather(sum(sum((  abs(CCD_plane)-coff*sqrt(imSeqCapture(:,:,imRandNum(tt)))    ).^2))); %计算损失 abs(CCD_plane)-sqrt(img)

            Pattern_plane_new = myprop_AS(CCD_plane_new,wvl,delta4,-d2); % Propogate back to the diffuser  反传播回slm平面
            ObjectRecoveryProp = ObjectRecoveryProp + gamaO*conj(patternshift).*(Pattern_plane_new-Pattern_plane)./(max(max(abs(patternshift).^2)));  %rPIE 更新Obj
            
            if loopnum>1
            patternshift = patternshift + gamaP*conj(ObjectRecoveryProp).*(Pattern_plane_new-Pattern_plane)./(max(max(abs(ObjectRecoveryProp).^2))); %更新当前pattern
            PatternRecovery = subpixelshift3GPU(patternshift,-xlocation(imRandNum(tt)),-ylocation(imRandNum(tt)) );  % Shift back diffuser  更新实际pattern
            end

            if sum(sum(isnan(ObjectRecoveryProp)))~=0
                disp(['NaN ,failure at image:',num2str(tt)]);
                return
            end
        end
    end
    ObjectRecoveryProp=myprop_AS(ObjectRecoveryProp,wvl,delta4,-0.03950);
    B1=angle(ObjectRecoveryProp);
    B1=(B1-min(B1(:)))/(max(B1(:))-min(B1(:))); %归一化
    B2=abs(ObjectRecoveryProp);
    B2=(B2-min(B2(:)))/(max(B2(:))-min(B2(:)));
    imwrite(gather(B2),['./result/abs',sprintf('%.1f',centerx),'+',sprintf('%.1f',centery),'+', sprintf('%.5f',d2),'+', sprintf('%.2f',a),'.png']);
    imwrite(gather(B1),['./result/pha',sprintf('%.1f',centerx),'+',sprintf('%.1f',centery),'+', sprintf('%.5f',d2),'+', sprintf('%.2f',a),'.png']);
end


