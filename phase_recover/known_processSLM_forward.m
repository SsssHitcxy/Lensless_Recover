% by HITsz, School of Computer Science and Technology 光学成像组 请勿用于商业用途
function SLM = known_processSLM_forward(slm,N)
    
    %SLM=subpixelshift3GPU(slm,xshift,yshift);
    SLM=slm; %2783*2783
    if size(SLM,1)<N
        SLM=padarray(SLM,[round((N-size(SLM,1))/2) 0]);
    else
        SLM=SLM(round((size(SLM,1)-N)/2)+1:round((size(SLM,1)+N)/2), :,:);
    end    
    if size(SLM,2)<N
        SLM=padarray(SLM,[0 round((N-size(SLM,2))/2)]);
    else
        SLM=SLM(:,round((size(SLM,2)-N)/2)+1:round((size(SLM,2)+N)/2),:);
    end
    
    if size(SLM,1)>N
        SLM(N+1:end,:,:) = [];
    end
    if size(SLM,2)>N
        SLM(:,N+1:end,:) = [];
    end