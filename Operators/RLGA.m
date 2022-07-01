function Offspring = RLGA(Parent,Action,L)

    %% Parameter setting
    [proC,disC,proM,disM] = deal(0.9,20,0.1,20); %proc为交叉的概率，disc为模拟二进制交叉的分布指标，proM为变异比特数的期望，disM为多项式变异的分布指标。

    if isa(Parent(1),'INDIVIDUAL')
        calObj = true;
        Parent = Parent.decs;
    else
        calObj = false;
    end
    Parent1 = Parent(1:floor(end/2),:);
    Parent2 = Parent(floor(end/2)+1:floor(end/2)*2,:);
    [N,D]   = size(Parent1);
    Global  = GLOBAL.GetObj();
 
    Actions = 1/D:1/D:L;
    
    proM = Actions(Action);
    switch Global.encoding
        case 'binary'
            %% Genetic operators for binary encoding
            % One point crossover
            k = repmat(1:D,N,1) > repmat(randi(D,N,1),1,D);
            k(repmat(rand(N,1)>proC,1,D)) = false;
            Offspring1    = Parent1;
            Offspring2    = Parent2;
            Offspring1(k) = Parent2(k);
            Offspring2(k) = Parent1(k);
            Offspring     = [Offspring1;Offspring2];
            % Bitwise mutation
            Site = rand(2*N,D) < proM;
            Offspring(Site) = ~Offspring(Site);
			site = sum(Offspring,2)==0;
            Offspring(site,:) = randi([0,1],sum(site),D);
        case 'one'
            %% Genetic operators for binary encoding
            % One point crossover
            k = repmat(1:D,N,1) > repmat(randi(D,N,1),1,D);
            k(repmat(rand(N,1)>proC,1,D)) = false;
            Offspring1    = Parent1;
            Offspring2    = Parent2;
            Offspring1(k) = Parent2(k);
            Offspring2(k) = Parent1(k);
            Offspring     = [Offspring1;Offspring2];
            % Polynomial mutation
            %Offspring = mutation(Offspring,proM,disM,Global);
            Site = rand(2*N,D) < proM;
            Offspring(Site) = ~Offspring(Site);
			site = sum(Offspring,2)==0;
            Offspring(site,:) = randi([0,1],sum(site),D);
        case 'two'
            %两点交叉
            point = sort(randi(D,N,2),2);
%             C = nchoosek(1:D,2);  %列出所有可能的两个点的组合
%             NC = nchoosek(D,2);   %所有组合的个数
%             point = C(randi(NC,N,1),:);
            k1 = repmat(1:D,N,1) >= point(:,1);
            k2 = repmat(1:D,N,1) <= point(:,2);
            k = k1&k2;
            k(repmat(rand(N,1)>proC,1,D)) = false;
            Offspring1    = Parent1;
            Offspring2    = Parent2;
            Offspring1(k) = Parent2(k);
            Offspring2(k) = Parent1(k);
            Offspring     = [Offspring1;Offspring2];
            % Polynomial mutation
%             Offspring = mutation(Offspring,proM,disM,Global);
            Site = rand(2*N,D) < proM;
            Offspring(Site) = ~Offspring(Site);
			site = sum(Offspring,2)==0;
            Offspring(site,:) = randi([0,1],sum(site),D);
        case 'uniform'
            %均匀交叉
            k = rand(N,D) < 0.5; 
            k(repmat(rand(N,1)>proC,1,D)) = false;
            Offspring1    = Parent1;
            Offspring2    = Parent2;
            Offspring1(k) = Parent2(k);
            Offspring2(k) = Parent1(k);
            Offspring     = [Offspring1;Offspring2];
            % Polynomial mutation
%             Offspring = mutation(Offspring,proM,disM,Global);
            Site = rand(2*N,D) < proM;
            Offspring(Site) = ~Offspring(Site);
			site = sum(Offspring,2)==0;
            Offspring(site,:) = randi([0,1],sum(site),D);
        case '2uniform'
            %两点均匀交叉
            point = sort(randi(D,N,2),2);
            segment = randi(3);
            if segment == 1
                k = repmat(1:D,N,1) <= point(:,1);
            elseif segment == 3
                k = repmat(1:D,N,1) >= point(:,2);
            else
                k1 = repmat(1:D,N,1) >= point(:,1);
                k2 = repmat(1:D,N,1) <= point(:,2);
                k = k1&k2;
            end
            k3 = rand(N,D) <= 0.5; 
            k = k&k3;
            k(repmat(rand(N,1)>proC,1,D)) = false;
            Offspring1    = Parent1;
            Offspring2    = Parent2;
            Offspring1(k) = Parent2(k);
            Offspring2(k) = Parent1(k);
            Offspring     = [Offspring1;Offspring2];
            Site = rand(2*N,D) < proM;
            Offspring(Site) = ~Offspring(Site);
			site = sum(Offspring,2)==0;
            Offspring(site,:) = randi([0,1],sum(site),D);
        case 'order'
            %% Genetic operators for permutation based encoding
            % Order crossover
            Offspring = [Parent1;Parent2];
            k = randi(D,1,2*N);
            for i = 1 : N
                Offspring(i,k(i)+1:end)   = setdiff(Parent2(i,:),Parent1(i,1:k(i)),'stable');
                Offspring(i+N,k(i)+1:end) = setdiff(Parent1(i,:),Parent2(i,1:k(i)),'stable');
            end
            % Slight mutation
            k = randi(D,1,2*N);
            s = randi(D,1,2*N);
            for i = 1 : 2*N
                if s(i) < k(i)
                    Offspring(i,:) = Offspring(i,[1:s(i)-1,k(i),s(i):k(i)-1,k(i)+1:end]);
                elseif s(i) > k(i)
                    Offspring(i,:) = Offspring(i,[1:k(i)-1,k(i)+1:s(i)-1,k(i),s(i):end]);
                end
            end
        otherwise
            %% Genetic operators for real encoding
            % Simulated binary crossover
            beta = zeros(N,D);
            mu   = rand(N,D);
            beta(mu<=0.5) = (2*mu(mu<=0.5)).^(1/(disC+1));
            beta(mu>0.5)  = (2-2*mu(mu>0.5)).^(-1/(disC+1));
            beta = beta.*(-1).^randi([0,1],N,D);
            beta(rand(N,D)<0.5) = 1;  %判断每个维度是否交叉
            beta(repmat(rand(N,1)>proC,1,D)) = 1; %高于交叉率的两个父代不交叉/直接继承父代基因
            Offspring = [(Parent1+Parent2)/2+beta.*(Parent1-Parent2)/2
                         (Parent1+Parent2)/2-beta.*(Parent1-Parent2)/2];
            % Polynomial mutation
            Offspring = mutation(Offspring,proM,disM,Global);
%             Lower = repmat(Global.lower,2*N,1);
%             Upper = repmat(Global.upper,2*N,1);
%             Site  = rand(2*N,D) < proM;
%             mu    = rand(2*N,D);
%             temp  = Site & mu<=0.5;
%             Offspring       = min(max(Offspring,Lower),Upper); %截断
%             Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*((2.*mu(temp)+(1-2.*mu(temp)).*...
%                               (1-(Offspring(temp)-Lower(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1))-1);
%             temp = Site & mu>0.5; 
%             Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*(1-(2.*(1-mu(temp))+2.*(mu(temp)-0.5).*...
%                               (1-(Upper(temp)-Offspring(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)));
    end
    if calObj
        Offspring = INDIVIDUAL(Offspring);
    end
end

function Offspring = mutation(Parent,proM,disM,Global)
    [N,D]   = size(Parent);
    Lower = repmat(Global.lower,N,1);
    Upper = repmat(Global.upper,N,1);
    Site  = rand(N,D) < proM;
    mu    = rand(N,D);
    temp  = Site & mu<=0.5;
    Offspring       = min(max(Parent,Lower),Upper); %截断
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*((2.*mu(temp)+(1-2.*mu(temp)).*...
                      (1-(Offspring(temp)-Lower(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1))-1);
    temp = Site & mu>0.5; 
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*(1-(2.*(1-mu(temp))+2.*(mu(temp)-0.5).*...
                      (1-(Upper(temp)-Offspring(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)));
end