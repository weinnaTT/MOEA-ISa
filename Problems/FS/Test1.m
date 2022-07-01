classdef Test1 < PROBLEM
% <problem><FS>
% Constrained benchmark MOP

%------------------------------- Reference --------------------------------
% Q. Zhang, A. Zhou, S. Zhao, P. N. Suganthan, W. Liu, and S. Tiwari,
% Multiobjective optimization test instances for the CEC 2009 special
% session and competition, School of CS & EE, University of Essex, Working
% Report CES-487, 2009.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2018-2019 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------
    properties
        dataset;
        datamissz;
    end
    
    methods
        %% Initialization
        function obj = Test1() %构造函数
            obj.Global.M = 3;
            if isempty(obj.Global.D)
                obj.Global.D = 13;
            end
            obj.Global.lower    = zeros(1,obj.Global.D);
            obj.Global.upper    = ones(1,obj.Global.D);
            obj.Global.encoding = 'real';
            obj.dataset = load('processed_va_data_train.txt');
            obj.datamissz = load('processed_va_data_train_zo.txt'); %缺失数据相应位置标注为0  的标注数据集   0 1对应是否缺失
        end
        
        %% Calculate objective values
        function PopObj = CalObj(obj,X)  %计算多个的目标函数值  X:种群（parent或者offspring）
            [N,D] = size(X);
            %dataset = load('..\DataSet\trainingdata\processed_va_data_train.txt');
            %datamissz = load('..\DataSet\trainingdata\processed_va_data_train_zo.txt'); %缺失数据相应位置标注为0  的标注数据集   0 1对应是否缺失
            %dataset = load('processed_va_data_train.txt');
            %datamissz = load('processed_va_data_train_zo.txt'); %缺失数据相应位置标注为0  的标注数据集   0 1对应是否缺失
            binary = zeros(N,D); %存放解码后的特征对应的 0 1值
            PopObj = zeros(N,obj.Global.M); %存放目标函数值
            for i = 1 : N
               for j = 1 : D   %解码
                 r1=X(i,j); %产生第i个解第j维的连续值和离散值
                 if r1>0.6
                     val=1;
                 else
                     val=0;
                 end
                 binary(i,j)=val;
               end
            vector=find(binary(i,:)==1);  %离散解等于1的特征
            while size(vector,2)==0   %如果特征集合为空，重新产生第i个解，直到不为空
                for j = 1 : D
                r1=rand(1);
                if r1>0.6
                    val=1;
                else
                    val=0;
                end
                X(i,j) = r1; % i.e f(i,j) = min + (max - min)*rand(1);
                binary(i,j)=val;
                end
                vector=find(binary(i,:)==1);
            end
              x1=binary(i,:);  %选取第i个特征组合方案
              subx=find(x1==1);  %subx = vector

             %  Objective function one
               PopObj(i,1) =size(subx,2)    ;%解大小
               
             %  Objective function two   
                data_tr=obj.dataset(:,subx);  %用特征子集抽取新的数据集 没有标签
                dataLab = obj.dataset(:,end);  %个体的标签
                CVF = 3;       % No. of cross-validation folds 交差验证分组数量
                indices = crossvalind('Kfold',obj.Global.N,CVF); % 将样本按比例分组，得到分组情况数组；
                fac = 0.00000000000000000000001; 
                classif='KNN';
                PopObj(i,2) = Fit_classify(obj, data_tr, dataLab, indices, classif) + fac;  %输入特征集合，标签集合，分组索引            

              %  Objective function three                   
                z1=obj.datamissz(:,subx);%选中的特征
                z2=sum(z1);%每个特征中不缺失的数量
                z=sum(z2,2);%这些选中的特征中总共不缺失的数量
                z3=sum(obj.datamissz(:,1:end-1));
                z4=sum(z3,2);%全部特征中不缺失的数量
                PopObj(i,3)=z/z4;     
             end             
        end
        
        %% Calculate constraint violations
        %function PopCon = CalCon(obj,X)
            %PopObj = obj.CalObj(X);
                    %1-（目标一的平方+目标二的平方）/（1-目标三的平方）  +   sin(2*pi*(目标一的平方-目标二的平方)/（1-1-目标三的平方）)
           % PopCon = 1-(PopObj(:,1).^2+PopObj(:,2).^2)./(1-PopObj(:,3).^2)  +  sin(2*pi*((PopObj(:,1).^2-PopObj(:,2).^2)./(1-PopObj(:,3).^2)+1));
       % end
        %% Sample reference points on Pareto front
%         function P = PF(obj,N)
%             P = UniformPoint(N,obj.Global.M);
%             P = P./repmat(sqrt(sum(P.^2,2)),1,obj.Global.M);
%             P(1e-5<P(:,1) & P(:,1)<sqrt((1-P(:,3).^2)/4) | sqrt((1-P(:,3).^2)/2)<P(:,1) & P(:,1)<sqrt(3*(1-P(:,3).^2)/4),:) = [];
%         end
        %%
        
        %分类方法
        function Fit = Fit_classify(obj, data, dataLab, indices, classif)  
            CVF = max(indices);  %获取交叉验证试验次数，即分组数量
            Fit = zeros(CVF,1);  %存每次交叉试验的错误率，
            for k=1:CVF  
               testn = (indices == k); %得到测试索引，每一次取一组作为测试数据，获得测试数据的索引，用1表示测试数据
               trainn = ~testn;        %得到训练索引，剩下的所有组为训练数据
               NTest = sum(testn);     %得到测试数据个数
           %     nn=sum(trainn)

               switch classif
                   case 'LDA'
                       Ac1 = classify(data(testn,:),data(trainn,:),dataLab(trainn,:));
                       if size(Ac1,1) == sum(testn)
                           Fit(k) = sum(Ac1~=dataLab(testn))/NTest;
                       else
                           Fit(k) = 1;
                       end
                   case 'KNN'
                       %Ac1 = knn(data(trainn,:)', dataLab(trainn)', data(testn,:)', 3);
                       %Fit(k) = sum(Ac1'~=dataLab(testn))/NTest;
                       %输入训练数据集合，训练数据集合的标签，先训练，再输入测试数据集合，预测其类标签。
                       mdl=ClassificationKNN.fit(data(trainn,:),dataLab(trainn),'NumNeighbors',3);%建立模型

                       Ac1=predict(mdl,data(testn,:));  %根据模型预测
                       %Ac1 = knnclassify(data(testn,:),data(trainn,:),dataLab(trainn),3); 
                       if size(Ac1,1) == sum(testn)
                           Fit(k) = sum(Ac1~=dataLab(testn))/NTest;  %计算第K次的预测误差
                           %Fit(k) = sum(Ac1~=dataLab(testn))/NTest;
                       else
                           Fit(k) = 1;  %否则的话错误率100%
                       end
                   case 'SVM'
                       model = train(dataLab(trainn),sparse(data(trainn,:)));
                       [TestPredict,a] = predict(dataLab(testn),sparse(data(testn,:)),model);
                       Fit(k) = (100-a)/100;
           %         case 'SVM-L'
           %             [AlphaY, SVs, Bias, Parameters, nSV, nLabel] = u_LinearSVC(data(trainn,:)', dataLab(trainn)');
           %             Fit(k) = 1 - SVMTest(data(testn,:)', dataLab(testn)', AlphaY, SVs, Bias,Parameters, nSV, nLabel);
           %         case 'SVM-RBF'
           %             [AlphaY, SVs, Bias, Parameters, nSV, nLabel] = RbfSVC(data(trainn,:)', dataLab(trainn)');
           %             Fit(k) = 1 - SVMTest(data(testn,:)', data_tsLab(testn)', AlphaY, SVs, Bias,Parameters, nSV, nLabel);
                  case 'ELM'
                      [TrainingTime, TrainingAcc, ELMmodel] = elm_train_v1(cat(2,(dataLab(trainn)-1),data(trainn,:)), 1,70,'sig', 1);
                      [PreLabels, TYa]= elm_test_v1(cat(2,(dataLab(testn)-1),data(testn,:)),1,ELMmodel); PreLabels = PreLabels + 1;
                      Fit(k) = sum(PreLabels ~= dataLab(testn)')/NTest;
               end
            end
            Fit = mean(Fit);  %取K次的预测误差的平均作为最终预测误差
        end
    end
end