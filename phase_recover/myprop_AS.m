% by HITsz, School of Computer Science and Technology 光学成像组 请勿用于商业用途
function [H2outGPU] = myprop_AS(imGPU,wlength,psize,z)
%=========input GPU=============
%imGPU:输入图像
%wlength:波长
%psize:CCD的Pixelsize
%z:传播距离
%=========output GPU============

% im=single(im);%single 1
[~,N]=size(imGPU); %get input field array size
k=2*pi/wlength;

kmax=1/(2*psize);%the max wave vector of the OTF
kxm0 = (gpuArray.linspace(-kmax,kmax,N));
kym0= kxm0;%
[kxm,kym]=meshgrid(kxm0,kym0);

%==========must be double during calculation==========
H2=exp(1i*k*z)*exp(-1i*z*pi*wlength.*(kxm.^2+kym.^2)); 
H2=single(H2);
H2outGPU=ifft2(ifftshift(H2.*fftshift(fft2(imGPU))));
end