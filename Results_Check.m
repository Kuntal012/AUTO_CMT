BR=importdata('Results_s1.txt');
        
        AA=BR.textdata(:,7:8);
        for i=1:size(AA,1)
            kk(i,1)=str2double(AA{i,1});kk(i,2)=str2double(AA{i,2});
        end
        BZ=[kk BR.data(:,2:6)];
        [U,ux,uy]=unique(BZ(:,1:2),'rows');U=BZ(ux,:);p=std(U(:,5:7)');
        BZ=[U p']; 
        UF=[BR.textdata(ux(:),1:9)];
        U=[U p'];
        % Getting stations combinations
        id_ev=find(U(:,8)<15);
        if isempty(id_ev) == 0
        cc_ev=1;
%         for i=1:length(id_ev)
%             
%             s(cc_ev,:)=[strsplit(UF{id_ev(i),2},'_')];
%             c(cc_ev)=extractBefore(s(id_ev(i),1),3);
%             s(cc_ev,1)=extractAfter(s(id_ev(i),1),2);cc_ev=cc_ev+1;
%             
%         end
%          UF=[UF(:,1) c' s(:,1:4) UF(:,3:9)];
         save Results.mat UF U ux uy
         fold_name='RS1'; 
        eval(['!mkdir ' fold_name]);
        eval(['!cp Results.mat ./' fold_name]);
         %clearvars -except hrrr date_start
         %% Returning the Best Resultsload Results.mat
         % Getting only the results where V.R. is greater than CLVD
         load ./RS1/Results.mat
         indx=find(U(:,3)>U(:,4));
         UF=UF(indx,:);U=U(indx,:);
         
         eval(['!cp /rhome/kchau012/bigdata/Data_Ridgecrest/CMT_Ridgecrest/lldistkm.m ./']);
         % Selecting results with event points atleast 1.5 degrees apart
         kk=U(:,1:2);
         for loop_evt=1:size(kk,1)
            for loop_evt2=1:size(kk,1)
                dist_evt(loop_evt,loop_evt2)=lldistkm(kk(loop_evt,:),kk(loop_evt2,:));
            end
         end
         
         for le=1:size(kk,1)
            ex=find(dist_evt(le,:)<50);% & dist_evt(le,:)~=0);
            ep=find(max(U(ex(:),3)));
            num_of_evt(le)=ex(ep);
            for le2=1:length(ex)
                if le2 ==1 && length(ex) ~= 1
                    fprintf('%d\t%d\t',le,ex(le2));
                elseif le2 ~= length(ex) && le2 ~=1
                    fprintf('%d\t',ex(le2));
                elseif le2 == 1 && length(ex) == 1
                    fprintf('%d\t%d\n',le,ex(le2));
                else
                    fprintf('%d\n',ex(le2));
                end
            end      
         
         end
        end