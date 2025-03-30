%% para settings
% by HITsz, School of Computer Science and Technology ��ѧ������ ����������ҵ��;
clear all;clc;
wvl = 520e-9;   %����
delta4 = 3.45e-6;  %CCD��pixelsize
delta_SLM = 12.5e-6;  %SLM��pixelsize

num=169; %ѡȡ����ͼ������
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

% patternƽ��ģʽ
for tt=1:arraysize^2
    [xlocationTemp,ylocationTemp] = find(xx==tt);
    xlocation(1,tt) = 2*ratio*(xlocationTemp-round(arraysize/2));
    ylocation(1,tt) = 2*ratio*(ylocationTemp-round(arraysize/2));
end
DB=single(zeros(2048,2448,num));
% 
xlocation=[0 xlocation];xlocation(end)=[]; %����һ�ź͵ڶ���pattern��ͬ�������������
ylocation=[0 ylocation];ylocation(end)=[];

%��ȡ�ɼ�ͼ��
for tt=1:num
    DB(:,:,tt)=DB(:,:,tt)+im2single(imread(['../data/USAF/test',num2str(tt-1),'.png']));
end
DB=padarray(DB,[100,100]);

centerx=-10.0; %�궨ͼ������ƫ�þ���
centery=25.0; %�궨ͼ������ƫ�þ���
temp1=single(zeros(2248,2648,num));
for tt=1:num
    temp1(:,:,tt)=gather(abs(subpixelshift3GPU(DB(:,:,tt),centerx,centery))); %ƽ��
end
a=-2.30;  %�궨ͼ��������ת�Ƕ�
N=2000;
for tt=1:num
    temp2(:,:,tt)=imrotate(temp1(:,:,tt),a);
    temp2(:,:,tt)=rot90(temp2(:,:,tt),2); %��ת��ת �ɼ�ͼ���pattern��ʵ��pattern�Ƿ�ת��
%                     s1=size(temp2,1);s2=size(temp2,2);
%                     imSeqCapture(:,:,tt)=imcrop(abs(temp2(:,:,tt)),[floor((s2-N+1)/2) floor((s1-N+1)/2) N-1 N-1]);
end
%clear temp1;
imSeqCapture=known_processSLM_forward(temp2,N);  %ͼ��ü� 2783*2783->2000*2000
%%  initialize object and pattern
clear temp2;
for d2=  0.0552%0.0545
    disp(['d2:',num2str(d2)]);
    PatternRecovery = gpuArray(known_processSLM_forward(pattern,N)); %��ʼ���ָ�Pattern 2783*2783->2000*2000
    
    sum_o = zeros(N,N);   % Sum all raw images to get the intial guess of object
    usenum=169;  %�ɼ�ͼ����Ŀ

    for tt=1:usenum
        sum_o = sum_o + myprop_AS(gpuArray(sqrt(imSeqCapture(:,:,tt)) ),wvl,delta4,-d2).*conj(subpixelshift3GPU(PatternRecovery,xlocation(tt),ylocation(tt))); %���䷴������SLMƽ��  
    end
    lowres_iniGuess =  sum_o./usenum; %��ʼ���ָ�ͼ���ֵ
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
            Pattern_plane = ObjectRecoveryProp.*patternshift;   % Multiply object wavefront with diffuser ��λ����

            CCD_plane = myprop_AS(Pattern_plane,wvl,delta4,d2);  % Propogate wavefront to the CCD ���򴫲���CCDƽ��
            t1=sqrt(imSeqCapture(:,:,imRandNum(tt)));
            t2=gather(abs(CCD_plane));
            coff=mean(t2(:))/mean(t1(:)); %����ɼ�ͼ�������򴫲�ͼ�������ֵ�������
            CCD_plane_new = gpuArray(sqrt(imSeqCapture(:,:,imRandNum(tt))).*exp(1j*angle(CCD_plane)));%.*CCD_plane./abs(CCD_plane) �滻��ֵ
            cost(loopnum) = cost(loopnum) + gather(sum(sum((  abs(CCD_plane)-coff*sqrt(imSeqCapture(:,:,imRandNum(tt)))    ).^2))); %������ʧ abs(CCD_plane)-sqrt(img)

            Pattern_plane_new = myprop_AS(CCD_plane_new,wvl,delta4,-d2); % Propogate back to the diffuser  ��������slmƽ��
            ObjectRecoveryProp = ObjectRecoveryProp + gamaO*conj(patternshift).*(Pattern_plane_new-Pattern_plane)./(max(max(abs(patternshift).^2)));  %rPIE ����Obj
            
            if loopnum>1
            patternshift = patternshift + gamaP*conj(ObjectRecoveryProp).*(Pattern_plane_new-Pattern_plane)./(max(max(abs(ObjectRecoveryProp).^2))); %���µ�ǰpattern
            PatternRecovery = subpixelshift3GPU(patternshift,-xlocation(imRandNum(tt)),-ylocation(imRandNum(tt)) );  % Shift back diffuser  ����ʵ��pattern
            end

            if sum(sum(isnan(ObjectRecoveryProp)))~=0
                disp(['NaN ,failure at image:',num2str(tt)]);
                return
            end
        end
    end
    ObjectRecoveryProp=myprop_AS(ObjectRecoveryProp,wvl,delta4,-0.03950);
    B1=angle(ObjectRecoveryProp);
    B1=(B1-min(B1(:)))/(max(B1(:))-min(B1(:))); %��һ��
    B2=abs(ObjectRecoveryProp);
    B2=(B2-min(B2(:)))/(max(B2(:))-min(B2(:)));
    imwrite(gather(B2),['./result/abs',sprintf('%.1f',centerx),'+',sprintf('%.1f',centery),'+', sprintf('%.5f',d2),'+', sprintf('%.2f',a),'.png']);
    imwrite(gather(B1),['./result/pha',sprintf('%.1f',centerx),'+',sprintf('%.1f',centery),'+', sprintf('%.5f',d2),'+', sprintf('%.2f',a),'.png']);
end


