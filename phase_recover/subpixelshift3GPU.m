% by HITsz, School of Computer Science and Technology 光学成像组 请勿用于商业用途
function output_imageGPU=subpixelshift3GPU(AmplitudeGPU,xshift,yshift)
%====input GPU=======
%====output GPU======
% Amplitude=double(Amplitude);%double 1
[m,n]=size(AmplitudeGPU);
fy = ifftshift(gpuArray.linspace(-floor(n/2),ceil(n/2)-1,m));
fx= ifftshift(gpuArray.linspace(-floor(m/2),ceil(m/2)-1,n));
[FX,FY]=meshgrid(fx,fy);
Hs=exp(-1j*2*pi.*(FX.*xshift/m+FY.*yshift/n));
% Hs=double(Hs);%double 2
output_imageGPU=ifft2(fft2(AmplitudeGPU).*Hs);