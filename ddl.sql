/* DDL assumes objects are being created in a SQL Server/Express database */

use master
go

if not exists ( select name from sys.databases where name = 'travelsearch' )
	begin
		create database travelsearch
	end
go

/* this setting will depend upon whether or not this is going in production and option availability for maintenance */

alter database travelsearch
set recovery simple
go

/* DDL */

use travelsearch
go

create table dbo.searchlog (
	search_user varchar( 32 ) not null ,
	search_date datetime not null default getdate() ,
	search_cx_id bigint not null ,
	search_string varchar( 256 ) null
	)
go

create clustered index cidx_searchlog_date on dbo.searchlog( search_date )
go

create nonclustered index ncidx_searchlog_cxid on dbo.searchlog( search_cx_id )
go

create table dbo.customer (
	cx_id bigint not null identity( 1000, 1 ) primary key nonclustered ,
	cx_lastnm varchar( 64 ) not null ,
	cx_firstnm varchar( 32 ) not null ,
	cx_midinit char( 1 ) null ,
	cx_email varchar( 64 ) not null ,
	cx_insert_date datetime not null default getdate() ,
	cx_update_date datetime not null default getdate()
	)
go

create clustered index cidx_cx_insertdt on dbo.customer( cx_insert_date )
go

create trigger dbo.trg_cx_updatedt
on dbo.customer
for update
as
	begin

		set nocount on

		update a
		set a.cx_update_date = getdate()
		from dbo.customer a
		join inserted b
		on a.cx_id = b.cx_id

		set nocount off

	end

go

create table dbo.customer_detail (
	cx_id bigint not null foreign key references dbo.customer( cx_id ),
	cx_street1 varchar( 128 ) not null ,
	cx_street2 varchar( 64 ) null ,
	cx_city varchar( 32 ) not null ,
	cx_state varchar( 32 ) not null ,
	cx_zip tinyint not null ,
	cx_phone int not null ,
	cx_ismblphn bit not null default( 1 )
	)
go

create nonclustered index ncidx_cxdetail_cxid on dbo.customer_detail( cx_id )
go

/* will need to add encryption steps prior to production deployment */

create table dbo.cx_payment (
	cx_id bigint not null foreign key references dbo.customer( cx_id ) ,
	cx_card_type char( 8 ) not null ,
	cx_nmbr varchar( 32 ) not null ,
	cx_exp char( 5 ) not null ,
	cx_seccode int not null ,
	cx_insertdt datetime not null default getdate() ,
	cx_updatedt datetime not null
	)
go

create clustered index cidx_cxpay_insertdt on dbo.cx_payment( cx_insertdt )
go

create trigger dbo.trg_pay_updatedt
on dbo.cx_payment
for update
as
	begin

		set nocount on

		update a
		set a.cx_updatedt = getdate()
		from dbo.cx_payment a
		join inserted b
		on a.cx_id = b.cx_id

		set nocount off

	end

go