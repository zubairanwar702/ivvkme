IF EXISTS (
		SELECT *
		FROM sys.objects
		WHERE object_id = OBJECT_ID(N'[QuickFilterProduct]') AND OBJECTPROPERTY(object_id,N'IsProcedure') = 1)
DROP PROCEDURE [QuickFilterProduct]
GO
CREATE PROCEDURE [QuickFilterProduct]
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
	@ShowHidden			bit = 0,
	@OrderBy			int = 0,
	@PageIndex			int = 0, 
	@PageSize			int = 2147483644,
	@TotalRecords		int = null OUTPUT
)
AS
BEGIN

	DECLARE @sql nvarchar(max)
	DECLARE @sql_orderby nvarchar(max)

	CREATE TABLE #PageIndex 
	(
		[IndexId] int IDENTITY (1, 1) NOT NULL,
		[ProductId] int NOT NULL
	)
	CREATE TABLE #PageIndexHelper 
	(
		[IndexId] int IDENTITY (1, 1) NOT NULL,
		[ProductId] int NOT NULL
	)

	--filter by category IDs
	SET @CategoryIds = isnull(@CategoryIds, '')	
	CREATE TABLE #FilteredCategoryIds
	(
		CategoryId int not null
	)
	INSERT INTO #FilteredCategoryIds (CategoryId)
	SELECT CAST(data as int) FROM [nop_splitstring_to_table](@CategoryIds, ',')	

	DECLARE @CategoryIdsCount int	
	SET @CategoryIdsCount = (SELECT COUNT(1) FROM #FilteredCategoryIds)

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

	DECLARE @FilteredCustomerRoleIdsCount int	
	SET @FilteredCustomerRoleIdsCount = (SELECT COUNT(1) FROM #FilteredCustomerRoleIds)

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
		Id int identity(1,1),
		AttributeId int,
		Name nvarchar(max) not null
	)
	if(LEN(@AttributesIds)>1)
	Begin
		INSERT INTO #Attributes (AttributeId, Name)
		SELECT 
			SUBSTRING(data, 1, CHARINDEX('-', data) - 1) as id, 
			SUBSTRING(data, CHARINDEX('-', data) + 1, LEN(data)) as Name
		FROM [nop_splitstring_to_table](@AttributesIds, ',')T0

	End
	--paging
	DECLARE @PageLowerBound int
	DECLARE @PageUpperBound int
	DECLARE @RowsToReturn int
	SET @RowsToReturn = @PageSize * (@PageIndex + 1)	
	SET @PageLowerBound = @PageSize * @PageIndex
	SET @PageUpperBound = @PageLowerBound + @PageSize + 1

		
	SET @sql = 'INSERT INTO #PageIndexHelper ([ProductId]) '
	SET @sql = @sql + 'select T0.Id from [Product] T0 '
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

	if(@AttributesIds!='')
	Begin		
		select 
		@sql = @sql + 
		' 
		   inner join [Product_ProductAttribute_Mapping] TA2_'+convert(nvarchar(10), TA4.AttributeId)+' on TA2_'+convert(nvarchar(10), TA4.AttributeId)+'.ProductId = T0.Id and TA2_'+convert(nvarchar(10), TA4.AttributeId)+'.ProductAttributeId = '+CONVERT(nvarchar(10), TA4.AttributeId)+'
		   inner join [ProductAttributeValue] TA3_'+convert(nvarchar(10), TA4.AttributeId)+' on TA3_'+convert(nvarchar(10), TA4.AttributeId)+'.ProductAttributeMappingId = TA2_'+convert(nvarchar(10), TA4.AttributeId)+'.Id and TA3_'+convert(nvarchar(10), TA4.AttributeId)+'.Name in (select Name from #Attributes where AttributeId = '+CONVERT(nvarchar(10), TA4.AttributeId)+')
		'
		from #Attributes TA4 group by AttributeId


	End


	SET @sql = @sql + ' where T0.Deleted = 0 and T0.ProductTypeId = 5 and T0.Published = 1
					   and (getutcdate() BETWEEN ISNULL(T0.AvailableStartDateTimeUtc, ''1/1/1900'') and ISNULL(T0.AvailableEndDateTimeUtc, ''1/1/2999'')) '
	--show hidden and ACL
	IF  @ShowHidden = 0 and @FilteredCustomerRoleIdsCount > 0
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
			)) '
	END

	IF @PriceMin is not null
	BEGIN
		SET @sql = @sql + '
		AND (
				T0.Price >= ' + CAST(@PriceMin AS nvarchar(max)) + '
			) '
	END
	
	--max price
	IF @PriceMax is not null
	BEGIN
		SET @sql = @sql + ' 
		AND (
				T0.Price <= ' + CAST(@PriceMax AS nvarchar(max)) + '
			) '
	END
	
	--sorting
	SET @sql_orderby = ''	
	IF @OrderBy = 5 /* Name: A to Z */
		SET @sql_orderby = ' T0.[Name] ASC'
	ELSE IF @OrderBy = 6 /* Name: Z to A */
		SET @sql_orderby = ' T0.[Name] DESC'
	ELSE IF @OrderBy = 10 /* Price: Low to High */
		SET @sql_orderby = ' T0.[Price] ASC'
	ELSE IF @OrderBy = 11 /* Price: High to Low */
		SET @sql_orderby = ' T0.[Price] DESC'
	ELSE IF @OrderBy = 15 /* creation date */
		SET @sql_orderby = ' T0.[CreatedOnUtc] DESC'
	ELSE /* default sorting, 0 (position) */
	BEGIN
		--category position (display order)
		IF @CategoryIdsCount > 0 SET @sql_orderby = ' T1.DisplayOrder ASC'
	
		
		--name
		IF LEN(@sql_orderby) > 0 SET @sql_orderby = @sql_orderby + ', '
		SET @sql_orderby = @sql_orderby + ' T0.[Name] ASC'
	END
	
	SET @sql = @sql + '
	ORDER BY ' + @sql_orderby + ' '
	EXEC sp_executesql @sql
	set @sql = 'INSERT INTO #PageIndex(ProductId) select ProductId from #PageIndexHelper GROUP BY ProductId ORDER BY MAX(IndexId) '
	EXEC sp_executesql @sql
	--total records
	SET @TotalRecords = @@rowcount

	--return products
	SELECT TOP (@RowsToReturn)
		p.*
	FROM
		#PageIndex [pi]
		INNER JOIN Product p with (NOLOCK) on p.Id = [pi].[ProductId]
	WHERE
		[pi].IndexId > @PageLowerBound AND 
		[pi].IndexId < @PageUpperBound
	ORDER BY
		[pi].IndexId
	
	DROP TABLE #PageIndex
	DROP TABLE #PageIndexHelper

END
GO