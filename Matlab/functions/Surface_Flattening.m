function infarct = Surface_Flattening(fv,infarct)

[conn,~,~] = meshconn(fv.faces,length(fv.vertices));

iter = 1;
max_length = 0;

for z = min(infarct.Vertices(:,2)):max(infarct.Vertices(:,2))
    
    full_slice = infarct.Locb(infarct.Vertices(:,2)==z);
    slice = infarct.Locb(infarct.Vertices(:,2)==z);
    
    count = [];
    for i = 1:length(full_slice)
    
        dummy = conn{full_slice(i)};
        [lia,~] = ismember(dummy,slice);
        
        full_neighbor{i} = dummy(lia);
        neighbor{i} = dummy(lia);
        
        if numel(full_neighbor{i}) == 0
            count = [count i];
        end    
        
        clear dummy
    end
    
    slice(count) = []; neighbor(count) = [];
    
    thetas = atan2(fv.vertices(slice,3) - mean(fv.vertices(:,3)),fv.vertices(slice,1) - mean(diff([min(fv.vertices(slice,1)) max(fv.vertices(slice,1))])));
    thetas(thetas<0) = 2*pi + thetas(thetas<0);
    
    [~,temp] = min(thetas);    
    vect = [slice(temp) neighbor{temp}];
    
    if isempty(slice)
        vect = full_slice';
    end    
    
    if length(slice)>2
        
        temp = find(slice==neighbor{temp}); temp = temp(1);
        c = length(vect);
        
        while c < length(slice)

            [lia,~] = ismember(neighbor{temp},vect);
            vect = [vect neighbor{temp}(~lia)];
            
            c = length(vect);
            
            if nnz(~lia)>1
                
                dummy = neighbor{temp}(~lia);
                
                for j = 1:length(dummy)
                    [idx,~] = ismember(neighbor{slice==dummy(j)},vect);
                    
                    if any(~idx)
                        temp = find(slice == dummy(j));
                        break;
                    end
                    clear idx
                end
            elseif isempty(neighbor{temp}(~lia))
                
                [lis,~] = ismember(slice,vect);
                [~,nid] = min(cellfun(@numel,neighbor(~lis)));
                temp = find(~lis==1);
                temp = temp(nid);
                vect = [vect slice(temp)];
                c = length(vect);

            else
                temp = find(slice == neighbor{temp}(~lia));
            end    

        end
        
        for j = 1:length(count)
            
            d = sqrt((fv.vertices(vect,1) - fv.vertices(full_slice(count(j)),1)).^2 + (fv.vertices(vect,3) - fv.vertices(full_slice(count(j)),3)).^2);
            [~,idx] = min(d);
            
            if idx == length(vect)
                vect = [vect(1:end) full_slice(count(j))];
            else
                vect = [vect(1:idx) full_slice(count(j)) vect(idx+1:end)];
            end
          
        end
        
    end    
    
    dist = sqrt((fv.vertices(vect,1) - infarct.center(1)).^2 + (fv.vertices(vect,3) - infarct.center(3)).^2);
    [~,mid_value] = min(dist);
    
    if round(length(vect)/2) ~= mid_value
        if round(length(vect)/2) < mid_value
            vect = padarray(vect,[0 diff([round(length(vect)/2) mid_value])],NaN,'post');
        else    
            vect = padarray(vect,[0 diff([mid_value round(length(vect)/2)])],NaN,'pre');
        end
    end
        
    Gx{iter} = vect;
    
    if length(vect) > max_length
        max_length = length(vect);
    end    
    
    iter = iter + 1;
    
    clear neighbor full_neighbor slice full_slice vect dummy temp count idx
    
end

for j = 1:numel(Gx)
    
    vect = Gx{j};
    new_row = max_length - length(vect);

    if mod(new_row,2) == 0
        nr = 0;
    else 
        nr = 1;
    end

    vect = padarray(vect,[0 nr],NaN,'pre');
    vect = padarray(vect,[0 ((new_row-nr)/2)],NaN);
    
    infarct.projection(j,:) = vect;
end

infarct.projection = flip(infarct.projection);