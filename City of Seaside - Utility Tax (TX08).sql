----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- File: SeasideTax.SQL
-- Author: Teo Espero (IT Administrator, MCWD)
-- Date: 03/05/2025
-- Description:
--				This is to gather all the charged (billing) and collected (payment) taxes (TX08) amounts from Seaside customers.
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------
-- STEP 01
-- GENERATE THE BASE TAX DATA TABLE
-------------------------------------------------------------------

-- THE DATES BELOW ARE ARBITRATY AND CAN BE CHANGED ANYTIME TO REFLECT THE RANGE OF THE DATA TO BE CAPTURED
DECLARE @sp_StartDate DATETIME = '07/01/2023'
DECLARE @sp_EndDate DATETIME = '06/30/2024'

select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.tax_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_tax_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	bd.tax_code like 'tx08'
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_tax_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #tax_payment_summary
from #base_tax_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr


-----------------------------
select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.tax_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_tax_data_billing
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	--and l.city like 'sea%'
where
	bd.tax_code like 'tx08'
	and bd.tran_type='billing'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_tax_data_billing
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #tax_billing_summary
from #base_tax_data_billing
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr

-------------------------------
-- water
select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.service_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_water_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	bd.service_code IN (
	select 
	distinct
	service_code
from ub_service
where
	ub_service_id in (
			select 
				distinct
				ub_service_id
			from ub_service_detail
			where
				ub_service_detail_id in (
				select 
					distinct
					ub_service_detail_id
				from ub_service_to_tax
				where
					ub_tax_id='0052529452'
				)
		)
	)
	and (bd.transaction_id in (
		select 
			distinct
			transaction_id
		from ub_bill_detail
		where
			tax_code='TX08'
	))
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_water_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #water_payment_summary
from #base_water_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr

--SELECT *
--FROM #water_payment_summary

---------------------------------------------------
-- FIRE


select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.service_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_fire_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	bd.service_code like 'fi%'
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
	and (bd.transaction_id in (
		select 
			distinct
			transaction_id
		from ub_bill_detail
		where
			tax_code='TX08'
	))
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_fire_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #fire_payment_summary
from #base_fire_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr

-----------------------------------------------------
-- sewer

select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.service_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_sewer_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	bd.service_code like 'SF%'
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
	and (bd.transaction_id in (
		select 
			distinct
			transaction_id
		from ub_bill_detail
		where
			tax_code='TX08'
	))
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_sewer_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #sewer_payment_summary
from #base_sewer_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr

-----------------------------------------------------
-- water cap
select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.service_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_water_cap_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	(bd.service_code like 'CS%' or bd.service_code like 'WC%')
	and bd.service_number=1
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
	and (bd.transaction_id in (
		select 
			distinct
			transaction_id
		from ub_bill_detail
		where
			tax_code='TX08'
	))
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_water_cap_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #water_cap_payment_summary
from #base_water_cap_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr

------------------------------------------------------
-- sewer cap
select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.service_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_sewer_cap_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	(bd.service_code like 'CS%' or bd.service_code like 'SC%')
	and bd.service_number=2
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
	and (bd.transaction_id in (
		select 
			distinct
			transaction_id
		from ub_bill_detail
		where
			tax_code='TX08'
	))
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_sewer_cap_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #sewer_cap_payment_summary
from #base_sewer_cap_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr

-----------------------------------------------------
-- penalty
select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.fee_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_penalty_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	bd.fee_code like 'PE%'
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
	and (bd.transaction_id in (
		select 
			distinct
			transaction_id
		from ub_bill_detail
		where
			tax_code='TX08'
	))
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_penalty_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #penalty_payment_summary
from #base_penalty_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr

-----------------------------------------------------
-- reconnect fee
select 
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar) AS AcctNum,
	(
		-- THIS IS TO DETERMINE THE FISCAL YEAR BASED ON THE YEAR FROM THE TRANSACTION DATE
		-- MCWD FOLLOWS A FISCAL YEAR THAT RANGES FROM JULY 1 TO JUNE 30 OF THE FOLLOWING YEAR
		case
			when month(bd.tran_date) in (1,2,3,4,5,6) then year(bd.tran_date)
			when month(bd.tran_date) in (7,8,9,10,11,12) then year(bd.tran_date) + 1
		end
	) as Fiscal_Year,
	(
		-- SINCE MCWD FOLLOWS AN FY CALENDAR THAT CROSSES YEARS, THE PERIODS 
		-- INCLUDED PER QUARTER ARE DIFFERENT:
		--		MONTH {7,8,9} = 1ST QTR
		--		MONTH {10,11,12} = 2ND QTR
		--		MONTH {1,2,3} = 3RD QTR
		--		MONTH {4,5,6} = 4TH QTR
		case
			-- 1st quarter
			when month(bd.tran_date) = 7 then 1
			when month(bd.tran_date) = 8 then 1
			when month(bd.tran_date) = 9 then 1
			-- 2nd quarter
			when month(bd.tran_date) = 10 then 2
			when month(bd.tran_date) = 11 then 2
			when month(bd.tran_date) = 12 then 2
			-- 3rd quarter
			when month(bd.tran_date) = 1 then 3
			when month(bd.tran_date) = 2 then 3
			when month(bd.tran_date) = 3 then 3
			-- 4th quarter
			when month(bd.tran_date) = 4 then 4
			when month(bd.tran_date) = 5 then 4
			when month(bd.tran_date) = 6 then 4
		end
	) as Qtr,
	cast(bd.tran_date as DATE) as tran_date,
	bd.tran_type,
	bd.fee_code,
	bd.amount,
	mast.billing_cycle,
	l.city
	into #base_reconnect_fee_data_payment
from ub_bill_detail bd
inner join
	ub_master mast
	on replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)=replicate('0', 6 - len(mast.cust_no)) + cast (mast.cust_no as varchar)+ '-'+replicate('0', 3 - len(mast.cust_sequence)) + cast (mast.cust_sequence as varchar)
inner join
	lot l
	on l.lot_no=mast.lot_no
	-- SEASIDE CUSTOMERS ONLY
	--and l.city like 'sea%'
where
	-- 
	bd.fee_code like 'RC%'
	and bd.tran_type='payment'
	and bd.tran_date between @sp_StartDate and @sp_EndDate
	and (bd.transaction_id in (
		select 
			distinct
			transaction_id
		from ub_bill_detail
		where
			tax_code='TX08'
	))
order by
	Fiscal_Year,
	Qtr,
	bd.tran_date,
	replicate('0', 6 - len(bd.cust_no)) + cast (bd.cust_no as varchar)+ '-'+replicate('0', 3 - len(bd.cust_sequence)) + cast (bd.cust_sequence as varchar)

--select *
--from #base_reconnect_fee_data_payment
--order by
--	Fiscal_Year,
--	Qtr,
--	tran_date,
--	AcctNum

select 
	Fiscal_year,
	Qtr,
	sum(amount) as Tax_Collected
	into #reconnect_fee_payment_summary
from #base_reconnect_fee_data_payment
Group by
	Fiscal_year,
	Qtr
order by
	Fiscal_year,
	Qtr
-----------------------------------------------------


select *
from #base_water_data_payment

select *
from #base_water_cap_data_payment


select *
from #base_sewer_data_payment

select *
from #base_sewer_cap_data_payment

select *
from #base_fire_data_payment

select *
from #base_penalty_data_payment

select *
from #base_reconnect_fee_data_payment

select *
from #base_tax_data_payment
-----------------------------------------------------

select 
	tps.Fiscal_Year,
	tps.Qtr,
	FORMAT(ISNULL(wps.Tax_Collected,0), 'C') AS Water_Charges,
	FORMAT(ISNULL(wcps.Tax_Collected,0), 'C') AS Water_Cap_Surcharges,
	FORMAT(ISNULL(sps.Tax_Collected,0), 'C') AS Sewer_Charges,
	FORMAT(ISNULL(scps.Tax_Collected,0), 'C') AS Sewer_Cap_Surcharges,
	FORMAT(ISNULL(fps.Tax_Collected,0), 'C') AS Fire_Charges,
	FORMAT(ISNULL(pps.Tax_Collected,0), 'C') AS Penalty_Charges,
	FORMAT(ISNULL(rfps.Tax_Collected,0), 'C') AS Meter_Reconnect_Fees,
	FORMAT(((ISNULL(wps.Tax_Collected,0) + ISNULL(wcps.Tax_Collected,0) + ISNULL(rfps.Tax_Collected,0)) * 0.06), 'C') AS Calculated_water_tax,
	FORMAT(ISNULL(tps.Tax_Collected,0), 'C') AS Payment,
	FORMAT((tps.Tax_Collected - ((ISNULL(wps.Tax_Collected,0) + ISNULL(wcps.Tax_Collected,0) + ISNULL(rfps.Tax_Collected,0)) * 0.06)), 'C') AS Payment_Variance
from #tax_billing_summary tbs
left join
	#tax_payment_summary tps
	on tps.Fiscal_Year=tbs.Fiscal_Year
	and tbs.Qtr=tps.Qtr
left join
	#water_payment_summary wps
	on wps.Fiscal_Year=tbs.Fiscal_Year
	and wps.Qtr=tbs.Qtr
left join
	#fire_payment_summary fps
	on fps.Fiscal_Year=tbs.Fiscal_Year
	and fps.Qtr=tbs.Qtr
left join
	#sewer_payment_summary sps
	on sps.Fiscal_Year=tbs.Fiscal_Year
	and sps.Qtr=tbs.Qtr
left join
	#water_cap_payment_summary wcps
	on wcps.Fiscal_Year=tbs.Fiscal_Year
	and wcps.Qtr=tbs.Qtr
left join
	#sewer_cap_payment_summary scps
	on scps.Fiscal_Year=tbs.Fiscal_Year
	and scps.Qtr=tbs.Qtr
left join
	#penalty_payment_summary pps
	on pps.Fiscal_Year=tbs.Fiscal_Year
	and pps.Qtr=tbs.Qtr
left join
	#reconnect_fee_payment_summary rfps
	on rfps.Fiscal_Year=tbs.Fiscal_Year
	and rfps.Qtr=tbs.Qtr
order by
	tps.Fiscal_Year,
	tps.Qtr




---------------------------------------

-- clean up
drop table #base_tax_data_billing
drop table #base_tax_data_payment
drop table #tax_billing_summary
drop table #tax_payment_summary
drop table #base_water_data_payment
drop table #water_payment_summary
drop table #base_fire_data_payment
drop table #fire_payment_summary
drop table #base_sewer_data_payment
drop table #sewer_payment_summary
drop table #base_water_cap_data_payment
drop table #water_cap_payment_summary
drop table #base_sewer_cap_data_payment
drop table #sewer_cap_payment_summary
drop table #base_penalty_data_payment
drop table #penalty_payment_summary
drop table #base_reconnect_fee_data_payment
drop table #reconnect_fee_payment_summary