USE [Commercial]
GO

/****** Object:  StoredProcedure [dbo].[usp_insertSvcrateDetailRRNew]    Script Date: 17/09/2022 17:55:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

  ALTER PROCEDURE [dbo].[usp_insertSvcrateDetailRRNew] 

@id varchar(20),                                                                                                                      
@st  varchar(2),
@fmc  varchar(1),
@dupvalue  varchar(1)

AS                                               

SET NoCount on /* Released in S1.9.15.0.126*/                                              

BEGIN                                                                                                                             

--                                                                                              

DECLARE @CRA_NO varchar(20)                                                                                               

DECLARE @INDEX_NO INT                                                                                                            

DECLARE @PREFIX VARCHAR(10)                                                              

DECLARE @EXEP VARCHAR(1200)                                    

DECLARE @MID INT  

Declare @Cracode1 varchar(20) 

SET  @Cracode1= @id                                                                                 

--                                                                                               

--tmpMatch                                                                                                        

CREATE table  #tmpMatch(custCode varchar(15),pol varchar(5),pod varchar(5),                                                                                        

eqptype varchar(4),validFrom datetime,validTo datetime,                                                              

Tservice varchar(75),class varchar(4),commodity varchar(20),vizname varchar(5000),dgDetail varchar(300),

soc varchar(1),nor varchar(1),status varchar(1),tos varchar(3),servicecode varchar(4),oogDetail varchar(150))                                                                                        

--tmpMatch1                                                                                        

CREATE table  #tmpMatch1(corporateno varchar(20),custCode varchar(15),pol varchar(5),pod varchar(5),                                                                                        

eqptype varchar(4),validFrom datetime,validTo datetime,                                                              

Tservice varchar(75),class varchar(4),commodity varchar(20),vizname varchar(5000),dgDetail varchar(300),

soc varchar(1),nor varchar(1),status varchar(1),tos varchar(3),servicecode varchar(4),oogDetail varchar(150))                                                                                        

--@tmpMatchDate                                                                                        

CREATE table  #tmpMatchDate(corporateno varchar(20),custCode varchar(15),pol varchar(5),pod varchar(5),                                                                                        

eqptype varchar(4),validFrom datetime,validTo datetime,Tservice varchar(75),

class varchar(4),commodity varchar(20),vizname varchar(5000),dgDetail varchar(300),soc varchar(1),

nor varchar(1),status varchar(1),tos varchar(3),servicecode varchar(4),oogDetail varchar(150))                                                              

---        

--if(@dupvalue='N')   --- fr chkin dup    
--begin

                                                                          
if( (@st='TF') or (@st='SR' AND @dupvalue='N') )
begin

Insert into #tmpMatch(custCode,pol,pod,eqptype,validFrom,validTo,Tservice,class,commodity,vizname,

dgDetail,soc,nor,status,tos,servicecode,oogDetail)                                                                        

SELECT  tmpsvcratetMaster.custCode, tmsv.loadPort, tmsv.dischPort, tmsv.eqpType, tmsv.validFrom,                                           

tmsv.validTo,tmsv.Tservice,tmsv.class,tmc.commodity,tmc.vizname,

tmsv.dgDetail,tmsv.soc,tmsv.nor,tmsv.status,tmsv.tos,tmsv.servicecode,tmsv.oogDetail      

FROM tmpsvcratetMaster (nolock) 

Inner JOIN tmpsvcratedetail tmsv on tmpsvcratetMaster.Sid =tmsv.sid  

Inner JOIN tmpsvcratecommodity tmc on tmpsvcratetMaster.Sid =tmc.sid  

where tmpsvcratetMaster.Sid = @id                         

--select * from #tmpmatch                                                           

--                                                               

if(@st='TF')       --- customer not mandatory for tariff
begin

if(@fmc='Y')       --- tariff filled
begin
print 'tarif FMC'

Insert into #tmpMatch1(corporateno,custCode ,pol ,pod ,eqptype ,validFrom ,validTo,Tservice,       

class,commodity,vizname,dgDetail,soc,nor,tos,servicecode,oogDetail)                

SELECT del.contractNo,svcratetMaster.custCode, del.loadPort, del.dischPort, del.eqpType,                                                                        

del.validFrom,del.validTo,del.Tservice,del.class,com.commodity,com.vizname,

del.dgDetail,del.soc,del.nor,del.tos,del.servicecode,del.oogDetail FROM svcratetMaster (nolock) 

Inner JOIN  svcratedetail del on  del.contractNo=svcratetMaster.contractNo  

Inner JOIN  svcratecommodity com on  com.contractNo=svcratetMaster.contractNo 

inner join #tmpMatch tm (nolock) on tm.pol = del.loadPort  -- and tm.custcode= svcratetMaster.custcode                                                                                       

and tm.pod = del.dischPort and tm.eqptype = del.eqptype and tm.Tservice = del.Tservice      

and tm.dgDetail = del.dgDetail and tm.soc = del.soc  and tm.nor = del.nor and tm.tos = del.tos and tm.servicecode = del.servicecode    

and tm.oogDetail = del.oogDetail and tm.class = del.class and tm.commodity = com.commodity  and tm.vizname = com.vizname    

-- TM-crnt rcrd , del-prev recrd                                                                

AND (

( ((Tm.validFrom = del.validFrom OR Tm.validTo = del.validFrom) OR 

(Tm.validFrom < del.validFrom AND Tm.validTo > del.validFrom)) AND del.status in ('A','F','S','C') )                                                                                         
    
OR (  

( (Tm.validFrom = del.validTo) 

OR (Tm.validFrom > del.validFrom AND Tm.validFrom < del.validTo)  

-- OR (Tm.validFrom between (del.validFrom AND del.validTo))   --same as prev cnditn

OR (Tm.validFrom < del.validFrom AND Tm.validTo > del.validFrom) ) AND del.status in ('A','S','C')   

) 

)  

where tm.status='S' and svcratetMaster.shipmentType = 'TF'

                 

--select * from  #tmpMatch1           

--                                                                                        

insert into #tmpMatchDate (corporateNo,custcode,pol,pod,eqptype,validFrom,ValidTo,Tservice,

class,commodity,vizname,dgDetail,soc,nor,tos,servicecode,oogDetail)    --- added                                             

select distinct T.CorporateNo,T.custcode,T.pol,T.pod,T.eqptype,T.validFrom,T.ValidTo,T.Tservice,                                         

T.class,T.commodity,T.vizname,T.dgDetail,T.soc,T.nor,T.tos,T.servicecode,T.oogDetail from #tmpMatch M (nolock),#tmpMatch1 T (nolock)                                                              

where T.pol = M.pol AND T.pod = M.pod AND T.eqpType = M.eqpType and T.Tservice=M.Tservice                                                             

and T.class=M.class and T.commodity=M.commodity and T.vizname=M.vizname and T.tos=M.tos and T.servicecode=M.servicecode

and T.oogDetail=M.oogDetail and t.dgDetail = m.dgDetail and t.soc = m.soc and t.nor = m.nor                                                          

----  M-currnt recrd , T-Prev recrd                                    

--AND ( 

--(T.validFrom = M.validFrom OR T.validTo = M.validFrom)                                                                             
    
--OR  (T.validFrom = M.validTo)  --added  by jp  

--OR  (T.validFrom > M.validFrom)  --added  by jp (fr validfrm less thn prev rcrd)   

--OR (T.validFrom > M.validFrom AND T.validFrom < M.validTo)    --- (no need)                
   
-- )

 AND (

( ((M.validFrom = T.validFrom OR M.validTo = T.validFrom) OR 

(M.validFrom < T.validFrom AND M.validTo > T.validFrom))  )                                                                                         
    
OR (  

( (M.validFrom = T.validTo) 

OR (M.validFrom > T.validFrom AND M.validFrom < T.validTo)  

-- OR (M.validFrom between (T.validFrom AND T.validTo))   --same as prev cnditn

OR (M.validFrom < T.validFrom AND M.validTo > T.validFrom) )   

) 

)  

end
-- end of tariff fmc


else if(@fmc='N')       --- tariff Approved fr nfmc
begin
print 'tarif NN-FMC'

Insert into #tmpMatch1(corporateno,custCode ,pol ,pod ,eqptype ,validFrom ,validTo,Tservice,       

class,commodity,vizname,dgDetail,soc,nor,tos,servicecode,oogDetail)                

SELECT del.contractNo,svcratetMaster.custCode, del.loadPort, del.dischPort, del.eqpType,                                      

del.validFrom,del.validTo,del.Tservice,del.class,com.commodity,com.vizname,

del.dgDetail,del.soc,del.nor,del.tos,del.servicecode,del.oogDetail FROM svcratetMaster (nolock) 

Inner JOIN  svcratedetail del on  del.contractNo=svcratetMaster.contractNo  

Inner JOIN svcratecommodity com on com.contractNo=svcratetMaster.contractNo  

inner join #tmpMatch tm (nolock) on tm.pol = del.loadPort and tm.custcode= svcratetMaster.custcode                                                                                       

and tm.pod = del.dischPort and tm.eqptype = del.eqptype and tm.Tservice = del.Tservice      

and tm.dgDetail = del.dgDetail and tm.soc = del.soc and tm.nor = del.nor and tm.tos = del.tos and tm.servicecode = del.servicecode   

and tm.oogDetail = del.oogDetail and tm.class = del.class and tm.commodity = com.commodity and tm.vizname = com.vizname  

-- TM-crnt rcrd , del-prev recrd                                                                

AND (

( ((Tm.validFrom = del.validFrom OR Tm.validTo = del.validFrom) OR 

(Tm.validFrom < del.validFrom AND Tm.validTo > del.validFrom)) AND del.status in ('A','S','C') )                                                                                         
    
OR (  

( (Tm.validFrom = del.validTo) 

OR (Tm.validFrom > del.validFrom AND Tm.validFrom < del.validTo)  

-- OR (Tm.validFrom between (del.validFrom AND del.validTo))     -- same as prev cnditn

OR (Tm.validFrom < del.validFrom AND Tm.validTo > del.validFrom) ) AND del.status in ('S','C')   

) 

)  

where tm.status='S' and svcratetMaster.shipmentType = 'TF'

                 

--select * from  #tmpMatch1           

--                                                                                        

insert into #tmpMatchDate (corporateNo,custcode,pol,pod,eqptype,validFrom,ValidTo,Tservice,

class,commodity,vizname,dgDetail,soc,nor,tos,servicecode,oogDetail)                                              

select distinct T.CorporateNo,T.custcode,T.pol,T.pod,T.eqptype,T.validFrom,T.ValidTo,T.Tservice,                                         

T.class,T.commodity,T.vizname,T.dgDetail,T.soc,T.nor,T.tos,T.servicecode,T.oogDetail from #tmpMatch M (nolock),#tmpMatch1 T (nolock)                                                              

where  T.custCode = M.custCode AND  

T.pol = M.pol AND T.pod = M.pod AND T.eqpType = M.eqpType and T.Tservice=M.Tservice                                                             

and T.class=M.class and T.commodity=M.commodity and T.vizname=M.vizname   
 
and t.dgDetail = m.dgDetail and t.soc = m.soc and t.nor = m.nor and t.tos = m.tos and t.servicecode = m.servicecode  --and t.corporateno<>@contractno                                                              

----  M-currnt recrd , T-Prev recrd    

and t.oogDetail = m.oogDetail           

AND (

( ((M.validFrom = T.validFrom OR M.validTo = T.validFrom) OR 

(M.validFrom < T.validFrom AND M.validTo > T.validFrom))  )                                                                                         
    
OR (  

( (M.validFrom = T.validTo) 

OR (M.validFrom > T.validFrom AND M.validFrom < T.validTo)  

-- OR (M.validFrom between (T.validFrom AND T.validTo))   --same as prev cnditn

OR (M.validFrom < T.validFrom AND M.validTo > T.validFrom) )    

) 

)  

end
-- end of tariff nfmc

end
-- end of tariff 

else if(@st='SR')     --- customer  mandatory for tariff
begin
print 'SRRRR'

Insert into #tmpMatch1(corporateno,custCode ,pol ,pod ,eqptype ,validFrom ,validTo,Tservice,       

class,commodity,vizname,dgDetail,soc,nor,tos,servicecode,oogDetail)                

SELECT del.contractNo,svcratetMaster.custCode, del.loadPort, del.dischPort, del.eqpType,                                                                    

del.validFrom,del.validTo,del.Tservice,del.class,com.commodity,com.vizname,

del.dgDetail,del.soc,del.nor,del.tos,del.servicecode,del.oogDetail FROM svcratetMaster (nolock) 

Inner JOIN svcratedetail del on del.contractNo=svcratetMaster.contractNo  

Inner JOIN svcratecommodity com on  com.contractNo=svcratetMaster.contractNo  

inner join #tmpMatch tm (nolock) on tm.pol = del.loadPort and tm.custcode= svcratetMaster.custcode                                                                                       

and tm.pod = del.dischPort and tm.eqptype = del.eqptype and tm.Tservice = del.Tservice      

and tm.dgDetail = del.dgDetail and tm.soc = del.soc and tm.nor = del.nor and tm.tos = del.tos and tm.servicecode = del.servicecode   

and tm.oogDetail = del.oogDetail and tm.class = del.class and tm.commodity = com.commodity and tm.vizname = com.vizname       

-- TM-crnt rcrd , del-prev recrd      

AND (

( ((Tm.validFrom = del.validFrom OR Tm.validTo = del.validFrom) OR 

(Tm.validFrom < del.validFrom AND Tm.validTo > del.validFrom)) AND del.status in ('A','S','C') )                                                                                         
    
OR (  

( (Tm.validFrom = del.validTo) 

OR (Tm.validFrom > del.validFrom AND Tm.validFrom < del.validTo)  

-- OR (Tm.validFrom between (del.validFrom AND del.validTo))     -- same as prev cnditn

OR (Tm.validFrom < del.validFrom AND Tm.validTo > del.validFrom) ) AND del.status in ('S','C')   

) 

)  

where tm.status='S' and svcratetMaster.shipmentType = 'SR'

                 

--select * from  #tmpMatch1           

--                                                                                        

insert into #tmpMatchDate (corporateNo,custcode,pol,pod,eqptype,validFrom,ValidTo,Tservice,

class,commodity,vizname,dgDetail,soc,nor,tos,servicecode,oogDetail)                                              

select distinct T.CorporateNo,T.custcode,T.pol,T.pod,T.eqptype,T.validFrom,T.ValidTo,T.Tservice,                                         

T.class,T.commodity,T.vizname,T.dgDetail,T.soc,T.nor,T.tos,T.servicecode,T.oogDetail from #tmpMatch M (nolock),#tmpMatch1 T (nolock)                                                              

where T.custCode = M.custCode AND  

T.pol = M.pol AND T.pod = M.pod AND T.eqpType = M.eqpType and T.Tservice=M.Tservice                                                             

and T.class=M.class and T.commodity=M.commodity and T.vizname=M.vizname  
 
and t.dgDetail = m.dgDetail  and t.soc = m.soc and t.nor = m.nor and t.tos = m.tos and t.servicecode = m.servicecode --and t.corporateno<>@contractno                                                         

----  M-currnt recrd , T-Prev recrd        

and t.oogDetail = m.oogDetail                                                                                        

AND (

( ((M.validFrom = T.validFrom OR M.validTo = T.validFrom) OR 

(M.validFrom < T.validFrom AND M.validTo > T.validFrom))  )                                                             
    
OR (  

( (M.validFrom = T.validTo) 

OR (M.validFrom > T.validFrom AND M.validFrom < T.validTo)  

-- OR (M.validFrom between (T.validFrom AND T.validTo))   --same as prev cnditn

OR (M.validFrom < T.validFrom AND M.validTo > T.validFrom) )    

) 

)  

end                                                               
-- end of srr
                                                   
                                                                                                                 
end
-- end of tariff and srr

--end
-- end of dupchkin

IF((SELECT count(custCode) from #tmpMatchDate M )=0)  
                                                                                 

BEGIN                                                                                        

BEGIN TRANSACTION                                                            

BEGIN TRY
  ---                                        

  --set @CRA_NO = 'CRA786'                                          

-- End of getting CRANO                                                                   

--Detail 
print 'vegeta'   


insert into svcratetMaster(contractNo,CustCode,FMC,SalesRepCode,carrierCode,reqdate,compdate,
ValidFrom,ValidTo,status,amendmentNo,mqc,mqcnotes,gri,submqc,signatoryname,designation,
effectivedate,shipmentType,liqudation,remarks,agencycode,counterby,shiptype,
usrcr,usrdate,dateup,userup,controlloc,pricing,raterefno,otherprovision,
pricingremarks,contractnote,commitment,teus,teusby,saveasflag,Salescode,systype,prntrmks)
select contractNo,CustCode,FMC,SalesRepCode,carrierCode,reqdate,compdate,ValidFrom,ValidTo,
status,amendmentNo,mqc,mqcnotes,gri,submqc,signatoryname,designation,effectivedate,
shipmentType,liqudation,remarks,agencycode,counterby,shiptype,usrcr,usrdate,
dateup,userup,controlloc,pricing,raterefno,otherprovision,pricingremarks,
contractnote,commitment,teus,teusby,saveasflag,Salescode,systype,prntrmks from tmpsvcratetMaster (nolock) where Sid = @id

 INSERT INTO svcratedetail (contractNo, itemNo, loadPort, dischPort, eqpType, class, amt, tservice,validFrom, validTo,
 soc, nor, dg, dgFlag,dgDetail, oog,oogFlag,oogDetail,remarks,liquidation,VID,allIn,eqpWt,unit,carriercode,pol,
 pod,status,amendmentNo,effectivedate,ratenoteno,requestedrate,pricingoffer,quantity,currency,allinamt,amendflag,
 amendnewno,usrcr,usrdate,userup,dateup,contrino,CTA,totalcost,totalrev,missingterm,quotestatus,prevamdno,
 lkvalidfrm,lkvalidto,minrate,dimensions,tlino,contractstatus,usrdetail,grpcode,tarfamt,orgrate,totaldim,reqtype,
 mqcDet,mqcnotesDet,submqcDet,commitmentDet,teusDet,teusbyDet,contractnoteDet,otherprovDet,
 minrateqty,effectivefromchk,effectivetochk,allinf,tos,servicecode,ooglength,oogwidth,oogheight,amtusd ) 
 select contractNo,itemNo, loadPort, dischPort, eqpType, class, amt, tservice,validFrom, validTo,
 soc, nor, dg, dgFlag,dgDetail, oog,oogFlag,oogDetail,remarks,liquidation,VID,allIn,eqpWt,unit,carriercode,pol,
 pod,status,amendmentNo,effectivedate,ratenoteno,requestedrate,pricingoffer,quantity,currency,allinamt,amendflag,
 amendnewno,usrcr,usrdate,userup,dateup,contrino,CTA,totalcost,totalrev,missingterm,quotestatus,prevamdno,
 lkvalidfrm,lkvalidto,minrate,dimensions,tlino,contractstatus,usrdetail,grpcode,tarfamt,orgrate,totaldim,reqtype,
 mqcDet,mqcnotesDet,submqcDet,commitmentDet,teusDet,teusbyDet,contractnoteDet,otherprovDet,
 minrateqty,effectivefromchk,effectivetochk,allinf,tos,servicecode,ooglength,oogwidth,oogheight,amtusd  from tmpsvcratedetail (nolock) where Sid = @id                               


INSERT INTO svcraterouting (contractNo,itemNo,origin,originMode,pol,polter,polSer,polmode,trans1,trans1Ter,trans1Ser,
trans1mode,trans2,trans2Ter,trans2Ser,trans2mode,trans3,trans3Ter,trans3Ser,trans3mode,
trans4,trans4Ter,trans4Ser,trans4mode,trans5,trans5Ter,trans5Ser,trans5mode,
pod,podTer,podMode,delivery,svcCode,defRout,AmendFlag,UpdateFlag,statusflag,routeid,TransitTime)
select contractNo,itemNo,origin,originMode,pol,polter,  polSer,polmode,trans1,trans1Ter,trans1Ser,
trans1mode,trans2,trans2Ter,trans2Ser,trans2mode,trans3,trans3Ter,trans3Ser,trans3mode,
trans4,trans4Ter,trans4Ser,trans4mode,trans5,trans5Ter,trans5Ser,trans5mode,
pod,podTer,podMode,delivery,svcCode,defRout,AmendFlag,UpdateFlag,
statusflag,routeid,TransitTime from tmpsvcrateroutingdetail (nolock) where Sid = @id   

INSERT INTO svcratecommodity (contractNo,class, commodity,vizname,status,amendmentNo,prevamdno,reqtype,orgCommodity,cmdtyFlag)                                             
select contractNo,class, commodity,vizname,status,amendmentNo,prevamdno,reqtype,orgCommodity,cmdtyFlag
from tmpsvcratecommodity (nolock) where Sid = @id 

INSERT INTO svcrateSurcharge (contractNo, itemNo, chargeCode, currency, amount,chargemode,amtusd,Allin,vatos,tariff,
status,amendFlag,statusflag,roe,orgTariff,chargeType,localroe,formula,surEqp,orgcurr,surflag) 
select contractNo,itemNo, chargeCode, currency, amount,chargemode,amtusd,Allin,vatos,tariff,status,
amendFlag,statusflag,roe,orgTariff,chargeType,localroe,formula,surEqp,orgcurr,surflag
from tmpsvcrateSurcharge (nolock) where Sid = @id 
                                                                                    
INSERT INTO SvcrateCustomer (contractNo, itemNo, custCode,status,amendmentNo,customercategory,aff,nac)
select contractNo,itemNo,custCode,status,amendmentNo,customercategory,aff,nac
from tmpSvcrateCustomer (nolock) where Sid = @id

INSERT INTO svcratenote (contractNo,rateno,ratedescription,status,amendmentNo,prevamdno,itemNo,reqtype)
select contractNo,rateno,ratedescription,status,amendmentNo,prevamdno,itemNo,reqtype
from tmpsvcratenote (nolock) where Sid = @id

INSERT INTO svcratetrucking (contractNo, itemNo, origin, delivery, eqpType,
amt,status,amendmentNo,nor,soc,service,remarks,prevamdno,currency,reqtype,tservice)                                                                                     
select contractNo,itemNo, origin, delivery, eqpType,amt,status,
amendmentNo,nor,soc,service,remarks,prevamdno,currency,reqtype,tservice 
from tmpsvcratetrucking (nolock) where Sid = @id    

INSERT INTO svcsurchargerule (contractNo,chargecode,amt,status,amendmentNo,
currency,eqpType,soc,nor,prevamdno,origin,delivery,class,tservice,reqtype,pol,pod)
select contractNo,chargecode,amt,status,amendmentNo,
currency,eqpType,soc,nor,prevamdno,origin,delivery,class,tservice,reqtype,pol,pod
from tmpsvcsurchargerule (nolock) where Sid = @id

INSERT INTO svcrateFreeDays (contractNo, itemNo, Expdet, Impdet, ImpStorage,expstorage,Impeng,expeng,ExpCombined,
ImpCombined,Expcomdays,Impcomdays,status,amendmentNo,Expdettariff, Impdettariff, ImpStoragetariff,
expstoragetariff,Impengtariff,expengtariff,Expcomdaystariff,Impcomdaystariff,daytype,expdemu,Impdemu,expdemutariff,Impdemutariff,
edtariffid,idtariffid,estariffid,istariffid,eengtariffid,iengtariffid,ecomtariffid,icomtariffid,edumtariffid,idumtariffid,freedaystype)
select contractNo,itemNo, Expdet, Impdet, ImpStorage,expstorage,Impeng,expeng,ExpCombined,
ImpCombined,Expcomdays,Impcomdays,status,amendmentNo,Expdettariff, Impdettariff, ImpStoragetariff,
expstoragetariff,Impengtariff,expengtariff,Expcomdaystariff,Impcomdaystariff,daytype,expdemu,Impdemu,expdemutariff,Impdemutariff,
edtariffid,idtariffid,estariffid,istariffid,eengtariffid,iengtariffid,ecomtariffid,icomtariffid,edumtariffid,idumtariffid,freedaystype
from tmpsvcrateFreeDays (nolock) where Sid = @id

INSERT INTO svcrateaudittrail(contractNo,actionuser,actiondate,action,stype,amendmentno)                                                      
select contractNo,actionuser,actiondate,action,stype,amendmentno             
from tmpsvcrateaudittrail (nolock) where Sid = @id  

INSERT INTO svcratedimension(contractNo,itemNo,weight,unit,length,width,height,amendmentNo,quantity,dimtotal,package,orderno)                                                  
select contractNo,itemNo,weight,unit,length,width,height,amendmentNo,quantity,dimtotal,package,orderno                                                                       
from tmpsvcratedimension (nolock) where Sid = @id   

INSERT INTO svcratedgdetails(contractNo,itemNo,dgclass,UNNo,amendmentNo)                                                                                              
select contractNo,itemNo,dgclass,UNNo,amendmentNo                                                                                              
from tmpsvcratedgdetails (nolock) where Sid = @id    

--     

COMMIT         

SELECT 'SUCCESS', @CRA_NO   

END TRY                                        

BEGIN CATCH          

SELECT @EXEP = ERROR_MESSAGE()       

SELECT  'Failure',@EXEP  AS ErrorNumber              

ROLLBACK                    
             

END CATCH;      

END                                       

ELSE                    
print 'goku'  
BEGIN                                                      

--SELECT distinct custcode, pol, pod,eqptype,validFrom,ValidTo,namedcust,class from @tmpMatchDate M            

SELECT distinct corporateno,cm.CustName,class,commodity,vizname,dgDetail,soc,nor,pol,pod,eqptype,validFrom,ValidTo from #tmpMatchDate M (nolock) left join customermaster cm on  cm.CustCode=m.custCode                                                       









END                                                                                                

--                                                                                          

DELETE FROM tmpsvcratedetail where sid = @id                                                                                   

DELETE FROM tmpsvcrateroutingdetail where sid = @id                                                                                                               

DELETE FROM tmpsvcratecommodity where sid = @id                                                                                                                         

DELETE FROM tmpsvcrateSurcharge where sid = @id                       

DELETE FROM tmpSvcrateCustomer where sid = @id                                                                                              

DELETE FROM tmpsvcratenote where sid = @id 
    
DELETE FROM tmpsvcratetrucking where sid = @id
   
DELETE FROM tmpsvcsurchargerule where sid = @id 
  
DELETE FROM tmpsvcrateFreeDays where sid = @id 

DELETE FROM tmpsvcratedimension where sid = @id            
                      
DELETE FROM tmpsvcratedgdetails where sid = @id 

DELETE FROM tmpsvcrateaudittrail where sid = @id  
 
DELETE FROM tmpsvcratetMaster where sid = @id 
  
         

DROP TABLE #tmpMatch      

DROP TABLE #tmpMatch1                                                              

DROP TABLE #tmpMatchDate   

-- 

END
  
  

    
GO


