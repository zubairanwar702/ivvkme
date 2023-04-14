IF EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[QuickFilter]') AND OBJECTPROPERTY(object_id,N'IsProcedure') = 1)
DROP PROCEDURE [QuickFilter]
GO
CREATE PROCEDURE [QuickFilter]
(
	@CategoryIds		nvarchar(MAX) = null,	
	@ManufacturerIds	nvarchar(MAX) = null,
	@StoreId			int = 0,
	@VendorIds			nvarchar(MAX) = null,
	@PriceMin			decimal(18, 4) = null,
	@PriceMax			decimal(18, 4) = null,	
	@FilteredSpecs nvarchar(MAX) = null,
	@AllowedCustomerRoleIds	nvarchar(MAX) = null,	
	@AttributesIds nvarchar(MAX) = null,
	@ShowHidden			bit = 0
)
AS
BEGIN
	DECLARE @sql nvarchar(max)
	DECLARE @sql2 nvarchar(max)
	SET @sql2 = ''

	DECLARE @usesql2 bit
	SET @usesql2 = 0

	CREATE TABLE #FILTERS
	(
		[FilterType] nvarchar(3),
		[FilterId] int,
		[FilterCount] int,
		[Name] nvarchar(max),
		[Color] nvarchar(max)
	)

	--filter by category IDs
	SET @CategoryIds = isnull(@CategoryIds, '')	
	CREATE TABLE #FilteredCategoryIds
	(
		CategoryId int not null
	)
	INSERT INTO #FilteredCategoryIds (CategoryId)
	SELECT CAST(data as int) FROM [nop_splitstring_to_table](@CategoryIds, ',')	

	-- filter by manufacturer IDs
	SET @ManufacturerIds = isnull(@ManufacturerIds, '')	
	CREATE TABLE #FilteredManufactureIds
	(
		ManufacturerId int not null
	)
	INSERT INTO #FilteredManufactureIds (ManufacturerId)
	SELECT CAST(data as int) FROM [nop_splitstring_to_table](@ManufacturerIds, ',')	

	-- filter by vendor
	SET @VendorIds = isnull(@VendorIds, '')	
	CREATE TABLE #FilteredVendorIds
	(
		VendorId int not null
	)
	INSERT INTO #FilteredVendorIds (VendorId)
	SELECT CAST(data as int) FROM [nop_splitstring_to_table](@VendorIds, ',')	

	--filter by customer role IDs (access control list)
	SET @AllowedCustomerRoleIds = isnull(@AllowedCustomerRoleIds, '')	
	CREATE TABLE #FilteredCustomerRoleIds
	(
		CustomerRoleId int not null
	)
	INSERT INTO #FilteredCustomerRoleIds (CustomerRoleId)
	SELECT CAST(data as int) FROM [nop_splitstring_to_table](@AllowedCustomerRoleIds, ',')

	--filter by specyfication
	SET @FilteredSpecs = isnull(@FilteredSpecs, '')	
	CREATE TABLE #FilteredSpecs
	(
		SpecificationAttributeOptionId int not null
	)
	INSERT INTO #FilteredSpecs (SpecificationAttributeOptionId)
	SELECT CAST(data as int) FROM [nop_splitstring_to_table](@FilteredSpecs, ',')
	DECLARE @SpecAttributesCount int	
	SET @SpecAttributesCount = (SELECT COUNT(*) FROM #FilteredSpecs)

	--filter by attributes
	SET @AttributesIds = isnull(@AttributesIds, '')	

	
	CREATE TABLE #Attributes
	(
		Attribute nvarchar(max) not null
	)
	INSERT INTO #Attributes (Attribute)
	SELECT data FROM [nop_splitstring_to_table](@AttributesIds, ',')

	declare @minprice decimal(18, 4)
	declare @maxprice decimal(18, 4)

	if(@CategoryIds!='')
	Begin
		select @minprice = min(T0.Price), @maxprice = max(T0.Price) from [Product] T0
		inner join [Product_Category_Mapping] T1 on T1.ProductId = T0.Id
		inner join #FilteredCategoryIds T2 on T2.CategoryId = T1.CategoryId
		where T0.Deleted = 0 and T0.ProductTypeId = 5 and T0.Published = 1
	End
	if(@CategoryIds = '' and @ManufacturerIds!='')
	Begin
		select @minprice = min(T0.Price), @maxprice = max(T0.Price) from [Product] T0
		inner join [Product_Manufacturer_Mapping] T1 on T1.ProductId = T0.Id
		inner join #FilteredManufactureIds T2 on T2.ManufacturerId = T1.ManufacturerId
		where T0.Deleted = 0 and T0.ProductTypeId = 5 and T0.Published = 1

	End


	insert #FILTERS
	select 'MIN', isnull(@minprice,0), 0, '', ''
	insert #FILTERS
	select 'MAX', isnull(@maxprice,0), 0, '', ''

	-- MANUFACTURERS	
	SET @sql = 'insert #FILTERS '
	SET @sql = @sql + ' select TFM.FilterType, TFM.ManufacturerId, count(TFM.Qty), TFM.Name, ''''
	from (
	select distinct ''MAN'' as FilterType, T3.ManufacturerId, T0.Id as Qty, '''' as Name from [Product] T0 '
	if(@CategoryIds!='')
	Begin
				SET @sql = @sql + ' inner join [Product_Category_Mapping] T1 on T1.ProductId = T0.Id
						inner join #FilteredCategoryIds T2 on T2.CategoryId = T1.CategoryId '
	End

	SET @sql = @sql + ' inner join [Product_Manufacturer_Mapping] T3 on T3.ProductId = T0.Id '
		

	if(@AttributesIds!='')
	Begin
		SET @sql = @sql + ' 
			inner join [Product_ProductAttribute_Mapping] T00 on T00.ProductId = T0.Id
			inner join [ProductAttributeValue] T01 on T01.ProductAttributeMappingId = T00.Id
			inner join #Attributes T03 on T03.Attribute = convert(nvarchar(10), T00.ProductAttributeId)+''-''+T01.Name '		   
	End

	if(@VendorIds!='')
	Begin
		SET @sql = @sql + ' inner join #FilteredVendorIds T4 on T4.VendorId = T0.VendorId '

	End
	
	--filter by specs	
	IF @SpecAttributesCount > 0
	BEGIN

			declare @spec nvarchar(max)
			set @spec = ''

			CREATE TABLE #FilteredSpecsWithAttributes
			(
				SpecificationAttributeId int not null,
				SpecificationAttributeOptionId int not null
			)
			INSERT INTO #FilteredSpecsWithAttributes (SpecificationAttributeId, SpecificationAttributeOptionId)
			SELECT sao.SpecificationAttributeId, fs.SpecificationAttributeOptionId
			FROM #FilteredSpecs fs INNER JOIN SpecificationAttributeOption sao ON sao.Id = fs.SpecificationAttributeOptionId
			ORDER BY sao.SpecificationAttributeId 

			select distinct 
			TSWA.SpecificationAttributeId as Id into #Specs from #FilteredSpecsWithAttributes TSWA

			select @spec = @spec +'
			 inner join [Product_SpecificationAttribute_Mapping] TS'+convert(nvarchar(10), TS.Id)+'
			 on TS'+convert(nvarchar(10), TS.Id)+'.ProductId = T0.Id and 
			 TS'+convert(nvarchar(10), TS.Id)+'.SpecificationAttributeOptionId in (select SpecificationAttributeOptionId 
			 from #FilteredSpecsWithAttributes where SpecificationAttributeId = '+convert(nvarchar(10), TS.Id)+'
			 ) 
			' 
			from #Specs TS
			SET @sql = @sql + @spec

	END
	
	

	SET @sql = @sql + ' where T0.Deleted = 0 and T0.ProductTypeId = 5 and T0.Published = 1
					   and (getutcdate() BETWEEN ISNULL(T0.AvailableStartDateTimeUtc, ''1/1/1900'') and ISNULL(T0.AvailableEndDateTimeUtc, ''1/1/2999''))'
	IF @ShowHidden = 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.SubjectToAcl = 0 OR EXISTS (
			SELECT 1 FROM #FilteredCustomerRoleIds [fcr]
			WHERE
				[fcr].CustomerRoleId IN (
					SELECT [acl].CustomerRoleId
					FROM [AclRecord] acl with (NOLOCK)
					WHERE [acl].EntityId = T0.Id AND [acl].EntityName = ''Product''
				)
			))'
	END
	IF @StoreId > 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.LimitedToStores = 0 OR EXISTS (
			SELECT 1 FROM [StoreMapping] sm with (NOLOCK)
			WHERE [sm].EntityId = T0.Id AND [sm].EntityName = ''Product'' and [sm].StoreId=' + CAST(@StoreId AS nvarchar(max)) + '
			))'
	END

	IF @PriceMin is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				
				T0.Price >= ' + CAST(@PriceMin AS nvarchar(max))+'
			)'
	END
	
	--max price
	IF @PriceMax is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price <= ' + CAST(@PriceMax AS nvarchar(max)) + '
			)'
	END

	--filter by specs
	SET @sql = @sql + ' )TFM group by TFM.FilterType, TFM.ManufacturerId, TFM.Name '

	EXEC sp_executesql @sql

	-- VENDORS
	SET @sql = 'insert #FILTERS'
	SET @sql = @sql + ' select ''VEN'', T0.VendorId, count(*) as Qty, '''', '''' from [Product] T0 '

	if(@CategoryIds!='')
	Begin
				SET @sql = @sql + ' inner join [Product_Category_Mapping] T1 on T1.ProductId = T0.Id
						inner join #FilteredCategoryIds T2 on T2.CategoryId = T1.CategoryId '
	End

	--inner join [Product_Category_Mapping] T1 on T1.ProductId = T0.Id
	--inner join #FilteredCategoryIds T2 on T2.CategoryId = T1.CategoryId '

	if(@AttributesIds!='')
	Begin
		SET @sql = @sql + ' 
			inner join [Product_ProductAttribute_Mapping] T00 on T00.ProductId = T0.Id
			inner join [ProductAttributeValue] T01 on T01.ProductAttributeMappingId = T00.Id 
			inner join #Attributes T03 on T03.Attribute = convert(nvarchar(10), T00.ProductAttributeId)+''-''+T01.Name '		   
	End
	if(@ManufacturerIds!='')
	Begin
		SET @sql = @sql + ' inner join [Product_Manufacturer_Mapping] T3 on T3.ProductId = T0.Id
						   inner join #FilteredManufactureIds T30 on T30.ManufacturerId = T3.ManufacturerId '
	End
	if(@VendorIds!='')
	Begin
		SET @sql = @sql + ' inner join #FilteredVendorIds T4 on T4.VendorId = T0.VendorId '

	End
	IF @SpecAttributesCount > 0
	BEGIN
		SET @sql = @sql + ' inner join [Product_SpecificationAttribute_Mapping] TS1 on TS1.ProductId = T0.Id 
						   inner join #FilteredSpecs TS2 on TS2.SpecificationAttributeOptionId = TS1.SpecificationAttributeOptionId '
	END

	SET @sql = @sql + ' where T0.Deleted = 0 and T0.ProductTypeId = 5 and T0.Published = 1 AND T0.VendorId != 0 
					   and (getutcdate() BETWEEN ISNULL(T0.AvailableStartDateTimeUtc, ''1/1/1900'') and ISNULL(T0.AvailableEndDateTimeUtc, ''1/1/2999''))'
	IF @ShowHidden = 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.SubjectToAcl = 0 OR EXISTS (
			SELECT 1 FROM #FilteredCustomerRoleIds [fcr]
			WHERE
				[fcr].CustomerRoleId IN (
					SELECT [acl].CustomerRoleId
					FROM [AclRecord] acl with (NOLOCK)
					WHERE [acl].EntityId = T0.Id AND [acl].EntityName = ''Product''
				)
			))'
	END
	IF @StoreId > 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.LimitedToStores = 0 OR EXISTS (
			SELECT 1 FROM [StoreMapping] sm with (NOLOCK)
			WHERE [sm].EntityId = T0.Id AND [sm].EntityName = ''Product'' and [sm].StoreId=' + CAST(@StoreId AS nvarchar(max)) + '
			))'
	END

	IF @PriceMin is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price >= ' + CAST(@PriceMin AS nvarchar(max)) + '
			)'
	END
	
	--max price
	IF @PriceMax is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price <= ' + CAST(@PriceMax AS nvarchar(max)) + '
			)'
	END
		--filter by specs
		
	IF @SpecAttributesCount > 0
	BEGIN
		SET @sql = @sql + '
		AND NOT EXISTS (
			SELECT 1 FROM #FilteredSpecs [fs]
			WHERE
				[fs].SpecificationAttributeOptionId NOT IN (
					SELECT psam.SpecificationAttributeOptionId
					FROM Product_SpecificationAttribute_Mapping psam with (NOLOCK)
					WHERE psam.AllowFiltering = 1 AND psam.ProductId = T0.Id
				)
			)'
	END
	

	SET @sql = @sql + ' group by T0.VendorId'

	EXEC sp_executesql @sql

	-- FILTER SPECYFICATION
	SET @sql = 'insert #FILTERS '
	SET @sql = @sql + ' select  TF0.FilterType, TF0.SpecificationAttributeOptionId, count(TF0.Qty), TF0.Name, '''' from
	(
	select distinct ''SPE'' as FilterType, T00.SpecificationAttributeOptionId, T0.Id as Qty, '''' as Name from [Product] T0
	inner join Product_SpecificationAttribute_Mapping T00 on T00.ProductId = T0.Id and T00.AllowFiltering = 1 '

	if(@CategoryIds!='')
	Begin
				SET @sql = @sql + ' inner join [Product_Category_Mapping] T1 on T1.ProductId = T0.Id
						inner join #FilteredCategoryIds T2 on T2.CategoryId = T1.CategoryId '
	End

	if(@AttributesIds!='')
	Begin
		SET @sql = @sql + ' 
			inner join [Product_ProductAttribute_Mapping] T001 on T001.ProductId = T0.Id
			inner join [ProductAttributeValue] T002 on T002.ProductAttributeMappingId = T001.Id
			inner join #Attributes T003 on T003.Attribute = convert(nvarchar(10), T001.ProductAttributeId)+''-''+T002.Name '		   
	End
	if(@ManufacturerIds!='')
	Begin
		SET @sql = @sql + 'inner join [Product_Manufacturer_Mapping] T3 on T3.ProductId = T0.Id
						   inner join #FilteredManufactureIds T30 on T30.ManufacturerId = T3.ManufacturerId'
	End
	if(@VendorIds!='')
	Begin
		SET @sql = @sql + ' inner join #FilteredVendorIds T4 on T4.VendorId = T0.VendorId'

	End

	declare @spec1 nvarchar(max)
	set @spec1 = ''
	declare @spec2 nvarchar(max)
	set @spec2 = ''

	IF @SpecAttributesCount > 0
	BEGIN
			declare @specF nvarchar(max)
			set @specF = ''

			CREATE TABLE #FilteredSpecsWithAttributesF
			(
				SpecificationAttributeId int not null,
				SpecificationAttributeOptionId int not null
			)
			INSERT INTO #FilteredSpecsWithAttributesF (SpecificationAttributeId, SpecificationAttributeOptionId)
			SELECT sao.SpecificationAttributeId, fs.SpecificationAttributeOptionId
			FROM #FilteredSpecs fs INNER JOIN SpecificationAttributeOption sao ON sao.Id = fs.SpecificationAttributeOptionId
			ORDER BY sao.SpecificationAttributeId 

			select distinct 
			TSWA.SpecificationAttributeId as Id into #Specs2 from #FilteredSpecsWithAttributesF TSWA
			if(select count(*) from #Specs2) > 1
			Begin
			select @specF = @specF +'
			 inner join [Product_SpecificationAttribute_Mapping] TSF'+convert(nvarchar(10), TSF.Id)+'
			 on TSF'+convert(nvarchar(10), TSF.Id)+'.ProductId = T0.Id and 
			 TSF'+convert(nvarchar(10), TSF.Id)+'.SpecificationAttributeOptionId in (select SpecificationAttributeOptionId 
			 from #FilteredSpecsWithAttributesF where SpecificationAttributeId = '+convert(nvarchar(10), TSF.Id)+'
			 ) 
			' 
			from #Specs2 TSF
			SET @sql = @sql + @specF
			End
			
			else
			Begin
				set @usesql2 = 1

				select @spec1 = '
				 inner join [Product_SpecificationAttribute_Mapping] TSF'+convert(nvarchar(10), TSF.Id)+'
				 on TSF'+convert(nvarchar(10), TSF.Id)+'.ProductId = T0.Id and 
				 TSF'+convert(nvarchar(10), TSF.Id)+'.SpecificationAttributeOptionId in (select SpecificationAttributeOptionId 
				 from #FilteredSpecsWithAttributesF where SpecificationAttributeId = '+convert(nvarchar(10), TSF.Id)+'
				 ) 
				' 
				from #Specs2 TSF

				select @spec2 = '
				 inner join [Product_SpecificationAttribute_Mapping] TSF'+convert(nvarchar(10), TSF.Id)+'
				 on TSF'+convert(nvarchar(10), TSF.Id)+'.ProductId = T0.Id and TSF'+convert(nvarchar(10), TSF.Id)+'.Id = T00.Id and 
				 TSF'+convert(nvarchar(10), TSF.Id)+'.SpecificationAttributeOptionId in (select Id 
				 from [SpecificationAttributeOption] where SpecificationAttributeId = '+convert(nvarchar(10), TSF.Id)+'
				 and Id not in (select SpecificationAttributeOptionId from #FilteredSpecsWithAttributesF)
				 ) 
				' 
				from #Specs2 TSF

				SET @sql = @sql +' @spec1 '
			
			end
	END


	SET @sql = @sql + ' where T0.Deleted = 0 and T0.ProductTypeId = 5 and T0.Published = 1
					   and (getutcdate() BETWEEN ISNULL(T0.AvailableStartDateTimeUtc, ''1/1/1900'') and ISNULL(T0.AvailableEndDateTimeUtc, ''1/1/2999''))'
	IF @ShowHidden = 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.SubjectToAcl = 0 OR EXISTS (
			SELECT 1 FROM #FilteredCustomerRoleIds [fcr]
			WHERE
				[fcr].CustomerRoleId IN (
					SELECT [acl].CustomerRoleId
					FROM [AclRecord] acl with (NOLOCK)
					WHERE [acl].EntityId = T0.Id AND [acl].EntityName = ''Product''
				)
			))'
	END
	IF @StoreId > 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.LimitedToStores = 0 OR EXISTS (
			SELECT 1 FROM [StoreMapping] sm with (NOLOCK)
			WHERE [sm].EntityId = T0.Id AND [sm].EntityName = ''Product'' and [sm].StoreId=' + CAST(@StoreId AS nvarchar(max)) + '
			))'
	END

	IF @PriceMin is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price >= ' + CAST(@PriceMin AS nvarchar(max)) + '
			)'
	END
	
	--max price
	IF @PriceMax is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price <= ' + CAST(@PriceMax AS nvarchar(max)) + '
			)'
	END
	
	SET @sql = @sql + ' )TF0 group by TF0.FilterType, TF0.SpecificationAttributeOptionId, TF0.Name '
	
	if(@usesql2=1)
	Begin
		set @sql2 = @sql
		set @sql = replace(@sql, '@spec1',@spec1)

		set @sql2 = replace(@sql2, '@spec1',@spec2)
		print @sql2
		EXEC sp_executesql @sql2
	End
	EXEC sp_executesql @sql

	-- FILTER ATTRIBUTE
	SET @sql = ''
	SET @sql = @sql + 'insert #FILTERS 
	select TAF.FilterType, TAF.ProductAttributeId, count(TAF.Qty), TAF.Name, TAF.ColorSquaresRgb from (
	select distinct ''ATR'' as FilterType, T00.ProductAttributeId, T0.Id as Qty, T01.Name, T01.ColorSquaresRgb from [Product] T0	
	inner join [Product_ProductAttribute_Mapping] T00 on T00.ProductId = T0.Id
	inner join [ProductAttributeValue] T01 on T01.ProductAttributeMappingId = T00.Id '
	
	if(@CategoryIds!='')
	Begin
				SET @sql = @sql + ' inner join [Product_Category_Mapping] T1 on T1.ProductId = T0.Id
						inner join #FilteredCategoryIds T2 on T2.CategoryId = T1.CategoryId '
	End

	if(@ManufacturerIds!='')
	Begin
		SET @sql = @sql + ' inner join [Product_Manufacturer_Mapping] T3 on T3.ProductId = T0.Id
						    inner join #FilteredManufactureIds T30 on T30.ManufacturerId = T3.ManufacturerId '
	End
	if(@VendorIds!='')
	Begin
		SET @sql = @sql + ' inner join #FilteredVendorIds T4 on T4.VendorId = T0.VendorId'

	End

	declare @attr1 nvarchar(max)
	set @attr1 = ''
	declare @attr2 nvarchar(max)
	set @attr2 = ''

	if(@AttributesIds!='')
	Begin	
			CREATE TABLE #ATTR
			(
				Id int identity(1,1),
				AttributeId int,
				Name nvarchar(max) not null
			)
			INSERT INTO #ATTR (AttributeId, Name)
			SELECT 
			 SUBSTRING(data, 1, CHARINDEX('-', data) - 1) as id, 
			 SUBSTRING(data, CHARINDEX('-', data) + 1, LEN(data)) as Name
			 FROM [nop_splitstring_to_table](@AttributesIds, ',')T0

			select AttributeId into #ATTR2 from #ATTR group by AttributeId
			declare @attrF nvarchar(max)
			set @attrF = ''

			if(select count(*) from #ATTR2) > 1
			Begin
				select @attrF = @attrF +'
				 inner join [Product_ProductAttribute_Mapping] TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'
				 on TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductId = T0.Id and 
				 TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductAttributeId = '+convert(nvarchar(10), TAMF.AttributeId)+' 
				 inner join [ProductAttributeValue] TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+' on TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductAttributeMappingId = TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.Id 
				 and TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+'.Name in (select Name from #ATTR where AttributeId = '+convert(nvarchar(10), TAMF.AttributeId) + ' ) 
				' 
				from #ATTR2 TAMF

				SET @sql = @sql + @attrF
			End
			else
			Begin

				set @usesql2 = 1

				select @attr1 = @attr1 +'
				 inner join [Product_ProductAttribute_Mapping] TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'
				 on TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductId = T0.Id and 
				 TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductAttributeId = '+convert(nvarchar(10), TAMF.AttributeId)+' 
				 inner join [ProductAttributeValue] TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+' on TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductAttributeMappingId = TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.Id 
				 and TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+'.Name in (select Name from #ATTR where AttributeId = '+convert(nvarchar(10), TAMF.AttributeId) + ' ) 
				' 
				from #ATTR2 TAMF

				select @attr2 = @attr2 +'
				 inner join [Product_ProductAttribute_Mapping] TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'
				 on TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductId = T0.Id and TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.Id = T00.Id and 
				 TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductAttributeId = '+convert(nvarchar(10), TAMF.AttributeId)+' 
				 inner join [ProductAttributeValue] TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+' on TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+'.ProductAttributeMappingId = TAMF'+convert(nvarchar(10), TAMF.AttributeId)+'.Id 
				 and TAMVF'+convert(nvarchar(10), TAMF.AttributeId)+'.Name not in (select Name from #ATTR where AttributeId = '+convert(nvarchar(10), TAMF.AttributeId) + ' ) 
				' 
				from #ATTR2 TAMF

				SET @sql = @sql + ' @attr1 '


			End

	End


	SET @sql = @sql + ' where T0.Deleted = 0 and T0.ProductTypeId = 5 and T0.Published = 1'
	IF @ShowHidden = 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.SubjectToAcl = 0 OR EXISTS (
			SELECT 1 FROM #FilteredCustomerRoleIds [fcr]
			WHERE
				[fcr].CustomerRoleId IN (
					SELECT [acl].CustomerRoleId
					FROM [AclRecord] acl with (NOLOCK)
					WHERE [acl].EntityId = T0.Id AND [acl].EntityName = ''Product''
				)
			))'
	END
	IF @StoreId > 0
	BEGIN
		SET @sql = @sql + '
		AND (T0.LimitedToStores = 0 OR EXISTS (
			SELECT 1 FROM [StoreMapping] sm with (NOLOCK)
			WHERE [sm].EntityId = T0.Id AND [sm].EntityName = ''Product'' and [sm].StoreId=' + CAST(@StoreId AS nvarchar(max)) + '
			))'
	END

	IF @PriceMin is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price >= ' + CAST(@PriceMin AS nvarchar(max)) + '
			)'
	END
	
	--max price
	IF @PriceMax is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price <= ' + CAST(@PriceMax AS nvarchar(max)) + '
			)'
	END
		--filter by specs
	IF @SpecAttributesCount > 0
	BEGIN
		SET @sql = @sql + '
		AND NOT EXISTS (
			SELECT 1 FROM #FilteredSpecs [fs]
			WHERE
				[fs].SpecificationAttributeOptionId NOT IN (
					SELECT psam.SpecificationAttributeOptionId
					FROM Product_SpecificationAttribute_Mapping psam with (NOLOCK)
					WHERE psam.AllowFiltering = 1 AND psam.ProductId = T0.Id
				)
			)'
	END

	SET @sql = @sql + ' )TAF group by TAF.FilterType, TAF.ProductAttributeId, TAF.Name, TAF.ColorSquaresRgb '

	if(@usesql2=1)
	Begin
		set @sql2 = @sql
		set @sql = replace(@sql, '@attr1',@attr1)

		set @sql2 = replace(@sql2, '@attr1', @attr2)
		print @sql2
		EXEC sp_executesql @sql2
	End

	EXEC sp_executesql @sql


	select * from #FILTERS
END
GO