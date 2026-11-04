function [OutlineOut,cpX,cpY]=CircleScanLivewireGPU(nextframe, previousframe, previousoutline, startpoint, reps, Step,varargin)
%%This function calculates the peak-oriented circle scan from refimage
%%masked with innermask and outtermask from startpoint.  Values from circle
%%are derived from compimage.  maskout is the circle trace.  The remaining
%%outputs are x values, y values, standard deviations, and number of data
%%points for each value.


if startpoint==1
    watershedridgefilled=imfill(previousoutline,'holes');
    bounds=bwboundaries(watershedridgefilled);
    bounds=bounds{1,1};
    x=bounds(:,2);
    y=bounds(:,1);
    cpX=x(1:Step:end,:);
    cpY=y(1:Step:end,:);
else
    Dev=gpuDevice();
    nextframegpu=gpuArray(nextframe);
previousframegpu=gpuArray(previousframe);
wait(Dev);
[D,movingReg]=imregdemons(previousframegpu, nextframegpu,100);
xGrid = (1:size(D,2));
yGrid = (1:size(D,1));
[xGrid,yGrid] = meshgrid(xGrid,yGrid);
D=round(D);
xGrid = xGrid + D(:,:,1);
yGrid = yGrid + D(:,:,2);
xGrid=gather(xGrid);
yGrid=gather(yGrid);
    gpuDevice(1);
    cpX=varargin{1};
    cpY=varargin{2};
    idx = cpY+((cpX-1)*size(xGrid,1));
    cpX=xGrid(idx);
    cpY=yGrid(idx);
end


if reps >= 1
    w=8;

    cp=[cpX,cpY];
    PathLW=cell(size(cp,1),1);
    
    for ee=1:size(cp,1)
        if ee==size(cp,1)
            if max(abs(cp(ee,:)-cp(1,:)))<=1
                path=[cp(ee,:),0;cp(1,:),0];
            else
                path = livewireNoDIP(nextframe, cp(ee,:), cp(1,:),10);
                while isempty(path)
                    cstart=cp(ee,:);
                    cstop=cp(1,:);
                    save(strcat('dump', num2str(randi(30))) ,'nextframe', 'cstart', 'cstop')
                    cp(1,1)=cp(1,1)+1
                    path = livewireNoDIP(nextframe, cp(ee,:), cp(1,:),10);
                end
            end
        else
            if max(abs(cp(ee,:)-cp(ee+1,:)))<=1
                path=[cp(ee,:),0;cp(ee+1,:),0];
            else
                path = livewireNoDIP(nextframe, cp(ee,:), cp(ee+1,:),10);
                while isempty(path)
                    cstart=cp(ee,:);
                    cstop=cp(ee+1,:);
                    save(strcat('dump', num2str(randi(30))) ,'nextframe', 'cstart', 'cstop')
                    cp(ee+1,1)=cp(ee+1,1)+1
                    path = livewireNoDIP(nextframe, cp(ee,:), cp(ee+1,:),10);
                end
            end
        end
        PathLW{ee}=path(1:end-1,:);
    end
    PathLW=vertcat(PathLW{:});
    x=PathLW(:,1);
    y=PathLW(:,2);
    
    if reps >=2
        for i = 2:reps
            
            p1coord=find(x==cpX(1)&y==cpY(1),1);
            p2coord=find(x==cpX(2)&y==cpY(2),1);
            newbounds(1,:)=PathLW(round(mean([p1coord,p2coord])),:);
            for i=2:length(cpX)-1
                p1coord=find(x==cpX(i)&y==cpY(i));
                p2coord=find(x==cpX(i+1)&y==cpY(i+1));
                newbounds(i,:)=PathLW(round(mean([max(p1coord),max(p2coord)])),:);
            end
            
            cpX=newbounds(:,1);
            cpY=newbounds(:,2);
            cp=[cpX,cpY];
            PathLW=[];
            for ee=1:size(cp,1)
                if ee==size(cp,1)
                    if max(abs(cp(ee,:)-cp(1,:)))<=1
                        path=[cp(ee,:),0;cp(1,:),0];
                    else
                        path = livewireNoDIP(nextframe, cp(ee,:), cp(1,:),10);
                        while isempty(path)
                            cstart=cp(ee,:);
                            cstop=cp(1,:);
                            save(strcat('dump', num2str(randi(30))) ,'nextframe', 'cstart', 'cstop')
                            cp(1,1)=cp(1,1)+1
                            path = livewireNoDIP(nextframe, cp(ee,:), cp(1,:),10);
                        end
                    end
                else
                    if max(abs(cp(ee,:)-cp(ee+1,:)))<=1
                        path=[cp(ee,:),0;cp(ee+1,:),0];
                    else
                        path = livewireNoDIP(nextframe, cp(ee,:), cp(ee+1,:),10);
                        while isempty(path)
                            cstart=cp(ee,:);
                            cstop=cp(ee+1,:);
                            save(strcat('dump', num2str(randi(30))) ,'nextframe', 'cstart', 'cstop')
                            cp(ee+1,1)=cp(ee+1,1)+1
                            path = livewireNoDIP(nextframe, cp(ee,:), cp(ee+1,:),10);
                        end
                    end
                end
                PathLW=[PathLW;path(1:end-1,:)];
            end
            x=PathLW(:,1);
            y=PathLW(:,2);
        end
    end
end

bw = zeros(size(nextframe)); % Create an m by n array of 0's
idx = y+((x-1)*size(bw,1)); % linear index into bw
bw(idx) = 1;
OutlineOut=bw;
