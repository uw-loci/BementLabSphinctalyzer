function [OutlineOut]=CircleScanLivewire(nextframe, previousframe, previousoutline, startpoint, reps, Step,SmoothNo)
%%This function calculates the peak-oriented circle scan from refimage
%%masked with innermask and outtermask from startpoint.  Values from circle
%%are derived from compimage.  maskout is the circle trace.  The remaining
%%outputs are x values, y values, standard deviations, and number of data
%%points for each value.
nextframe=double(nextframe);
previousframe=double(previousframe);
previousoutline=logical(previousoutline);
if startpoint==1
    NewOutline=previousoutline;
else
D=imregdemonsNoWait(medfilt2(previousframe,[5 5]), medfilt2(nextframe,[5 5]));
NewOutline=imwarp(previousoutline, D, 'bicubic');
end
DL = watershed(NewOutline);
bgm = DL == 0;
if sum(sum(bgm))<=5;
    bgm = previousoutline;
end
   nextframe=medfilt2(nextframe,[5,5]); 

watershedridge=bgm;
watershedridgefilled=imfill(watershedridge,'holes');
bounds=bwboundaries(watershedridgefilled);
bounds=bounds{1,1};
x=bounds(:,2);
y=bounds(:,1);

if reps >= 1
    w=8;
    cpX=x(1:Step:end,:);
    cpY=y(1:Step:end,:);
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

bw = zeros(size(bgm)); % Create an m by n array of 0's
idx = y+((x-1)*size(bw,1)); % linear index into bw
bw(idx) = 1;
if SmoothNo>0 && rem(SmoothNo,1)==0
    bw=PolarSmooth(bw,SmoothNo);
end
OutlineOut=bw;
